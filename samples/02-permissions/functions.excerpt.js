// Shabakti — excerpt of functions/index.js (Firebase Cloud Functions v2).
// Server-side tenant resolution + permission checks, and an admin-only callable that sets a user's password.
// Some inline comments are in Arabic.

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const auth = getAuth();
const messaging = getMessaging();

function mergePermissions(rolePerms, userPerms) {
  const set = new Set();
  for (const list of [rolePerms, userPerms]) {
    if (!Array.isArray(list)) continue;
    for (const p of list) {
      if (typeof p === "string" && p.trim()) set.add(p.trim());
    }
  }
  return set;
}

async function resolveTenantIdForUid(uid) {
  const snap = await db.collection("user_tenant_index").doc(uid).get();
  if (!snap.exists) return null;
  const tenantId = String(snap.data()?.tenantId || "").trim();
  return tenantId || null;
}

async function requireTenantContext(request, tenantIdFromClient) {
  const callerUid = request.auth.uid;
  const callerTenantId = await resolveTenantIdForUid(callerUid);
  const tenantId = String(tenantIdFromClient || callerTenantId || "").trim();
  if (!tenantId) {
    throw new HttpsError("failed-precondition", "tenantId مطلوب");
  }
  if (callerTenantId && callerTenantId !== tenantId) {
    throw new HttpsError("permission-denied", "لا يمكن العمل على شبكة أخرى");
  }
  return tenantId;
}

function tenantUsersRef(tenantId) {
  return db.collection("tenants").doc(tenantId).collection("users");
}

function tenantRolesRef(tenantId) {
  return db.collection("tenants").doc(tenantId).collection("roles");
}

function tenantActivityLogsRef(tenantId) {
  return db.collection("tenants").doc(tenantId).collection("activity_logs");
}

async function loadPermissionsForUid(uid, tenantId) {
  if (!tenantId) return new Set();
  const userSnap = await tenantUsersRef(tenantId).doc(uid).get();
  if (!userSnap.exists) return new Set();
  const user = userSnap.data() || {};
  if (user.deleted === true || user.status === "deleted") return new Set();

  const roleId = String(user.roleId || "").trim();
  if (!roleId) {
    return mergePermissions([], user.permissions);
  }
  const roleSnap = await tenantRolesRef(tenantId).doc(roleId).get();
  const role = roleSnap.exists ? roleSnap.data() || {} : {};
  return mergePermissions(role.permissions, user.permissions);
}

async function assertPermission(uid, permission, tenantId) {
  const perms = await loadPermissionsForUid(uid, tenantId);
  if (!perms.has(permission)) {
    throw new HttpsError(
      "permission-denied",
      `ليس لديك صلاحية ${permission}`,
    );
  }
}

function tokenDocId(token) {
  const safe = String(token || "").replace(/[^A-Za-z0-9_-]/g, "_");
  if (safe.length <= 120) return safe;
  return safe.substring(safe.length - 120);
}

async function listFcmTokens(userId, tenantId) {
  const snap = await tenantUsersRef(tenantId)
    .doc(userId)
    .collection("fcm_tokens")
    .limit(50)
    .get();
  const entries = [];
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const token = String(data.token || "").trim();
    if (!token) continue;
    const updatedAt = data.updatedAt?.toMillis?.() ?? Number(data.updatedAt) ?? 0;
    entries.push({ token, updatedAt, docId: doc.id });
  }
  entries.sort((a, b) => b.updatedAt - a.updatedAt);
  const seen = new Set();
  const tokens = [];
  for (const entry of entries) {
    if (seen.has(entry.token)) continue;
    seen.add(entry.token);
    tokens.push(entry.token);
    if (tokens.length >= 20) break;
  }
  return tokens;
}

async function pruneInvalidFcmTokens(userId, tenantId, tokens, responses) {
  const batch = db.batch();
  let pending = 0;
  responses.forEach((resp, i) => {
    if (resp.success) return;
    const code = String(resp.error?.code || "");
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      const token = tokens[i];
      if (!token) return;
      const ref = tenantUsersRef(tenantId)
        .doc(userId)
        .collection("fcm_tokens")
        .doc(tokenDocId(token));
      batch.delete(ref);
      pending += 1;
    }
  });
  if (pending > 0) await batch.commit();
}

async function sendPushToUser(userId, { title, body, data = {} }, tenantId) {
  const tokens = await listFcmTokens(userId, tenantId);
  if (tokens.length === 0) return { sent: 0 };

  const payload = {
    tokens,
    notification: {
      title: String(title || "شبكتي").slice(0, 120),
      body: String(body || "").slice(0, 500),
    },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v ?? "")]),
    ),
    android: {
      priority: "high",
      notification: { channelId: "shabakati_alerts" },
    },
  };

  try {
    const result = await messaging.sendEachForMulticast(payload);
    const errors = [];
    result.responses.forEach((resp, i) => {
      if (!resp.success && resp.error) {
        errors.push(`${tokens[i]?.slice(0, 12)}…: ${resp.error.code}`);
      }
    });
    await pruneInvalidFcmTokens(userId, tenantId, tokens, result.responses);
    return {
      sent: result.successCount,
      failed: result.failureCount,
      errors,
    };
  } catch (e) {
    const msg = String(e?.message || e);
    if (msg.includes("authentication") || msg.includes("credential")) {
      throw new HttpsError(
        "failed-precondition",
        "فعّل Firebase Cloud Messaging API من Google Cloud Console ثم أعد المحاولة.",
      );
    }
    throw new HttpsError("internal", `تعذر إرسال الإشعار: ${msg}`);
  }
}

/** حفظ توكن FCM من التطبيق (Admin SDK) */
// ... (FCM push helpers omitted)

exports.adminSetUserPassword = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يلزم تسجيل الدخول");
  }

  const tenantId = await requireTenantContext(
    request,
    request.data?.tenantId,
  );
  await assertPermission(request.auth.uid, "USERS_SET_PASSWORD", tenantId);

  const targetUserId = String(request.data?.targetUserId || "").trim();
  const newPassword = String(request.data?.newPassword || "").trim();

  if (!targetUserId) {
    throw new HttpsError("invalid-argument", "targetUserId مطلوب");
  }
  if (newPassword.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "كلمة المرور يجب أن تكون 6 أحرف على الأقل",
    );
  }

  const targetTenantId = await resolveTenantIdForUid(targetUserId);
  if (targetTenantId !== tenantId) {
    throw new HttpsError(
      "invalid-argument",
      "المستخدم المستهدف لا ينتمي لهذه الشبكة",
    );
  }

  try {
    await auth.updateUser(targetUserId, { password: newPassword });
  } catch (e) {
    const code = String(e?.code || "");
    if (code.includes("user-not-found")) {
      throw new HttpsError(
        "not-found",
        "المستخدم غير موجود في Firebase Auth",
      );
    }
    throw new HttpsError("internal", `تعذر تحديث كلمة المرور: ${e.message}`);
  }

  await tenantActivityLogsRef(tenantId).add({
    actionType: "admin_set_password",
    entityType: "user",
    entityId: targetUserId,
    createdByUserId: request.auth.uid,
    timestamp: Date.now(),
    extraData: { via: "cloud_function" },
  });

  return { ok: true };
});

