// Shabakti — public code sample (copied verbatim from the private repository).
// Holds the active tenant (network) for the signed-in session.
// Some inline comments are in Arabic.

/// معرّف الشبكة النشطة للجلسة الحالية (يُضبط بعد تسجيل الدخول).
abstract final class TenantContext {
  static String? _tenantId;
  static String? _tenantName;

  static void bind({required String tenantId, String? tenantName}) {
    final id = tenantId.trim();
    _tenantId = id.isEmpty ? null : id;
    final name = (tenantName ?? '').trim();
    _tenantName = name.isEmpty ? null : name;
  }

  static void clear() {
    _tenantId = null;
    _tenantName = null;
  }

  static String? get currentTenantId {
    final id = (_tenantId ?? '').trim();
    return id.isEmpty ? null : id;
  }

  static String? get currentTenantName {
    final name = (_tenantName ?? '').trim();
    return name.isEmpty ? null : name;
  }

  static String get requireTenantId {
    final id = currentTenantId;
    if (id == null) {
      throw StateError('tenantId غير مُعرّف — سجّل الدخول أولاً');
    }
    return id;
  }
}
