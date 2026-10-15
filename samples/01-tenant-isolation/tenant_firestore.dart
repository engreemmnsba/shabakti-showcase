// Shabakti — public code sample (copied verbatim from the private repository).
// All business data lives under tenants/{tenantId}/... — helpers make that path the only way in.
// Some inline comments are in Arabic.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'tenant_context.dart';

/// مسارات Firestore تحت `tenants/{tenantId}/...`.
abstract final class TenantCollections {
  static const users = 'users';
  static const roles = 'roles';
  static const areas = 'areas';
  static const distributors = 'distributors';
  static const sections = 'sections';
  static const cardBatches = 'card_batches';
  static const payments = 'payments';
  static const expenses = 'expenses';
  static const discounts = 'discounts';
  static const userStocks = 'user_stocks';
  static const userStockLogs = 'user_stock_logs';
  static const userStockLogAudits = 'user_stock_log_audits';
  static const tasks = 'tasks';
  static const cardStockRequests = 'card_stock_requests';
  static const inventoryUnits = 'inventory_units';
  static const inventoryMovements = 'inventory_movements';
  static const inventoryItemTypes = 'inventory_item_types';
  static const inventoryItemModels = 'inventory_item_models';
  static const inventoryItemNames = 'inventory_item_names';
  static const appNotifications = 'app_notifications';
  static const activityLogs = 'activity_logs';
  static const areaSummaries = 'area_summaries';
  static const distributorSummaries = 'distributor_summaries';
  static const sectionDistributorSummaries = 'section_distributor_summaries';
  static const adminBalances = 'admin_balances';
  static const salaryRecords = 'salary_records';
  static const counters = 'counters';
  static const sectionSummaries = 'section_summaries';
  static const fcmTokens = 'fcm_tokens';
}

abstract final class TenantFirestore {
  static const userTenantIndexCollection = 'user_tenant_index';
  static const platformAdminsCollection = 'platform_admins';
  static const tenantsCollection = 'tenants';

  static FirebaseFirestore get db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> tenants() =>
      db.collection(tenantsCollection);

  static DocumentReference<Map<String, dynamic>> tenant(String tenantId) =>
      tenants().doc(tenantId.trim());

  static CollectionReference<Map<String, dynamic>> collection(
    String tenantId,
    String name,
  ) =>
      tenant(tenantId).collection(name);

  static DocumentReference<Map<String, dynamic>> userTenantIndex(String uid) =>
      db.collection(userTenantIndexCollection).doc(uid.trim());

  static DocumentReference<Map<String, dynamic>> platformAdmin(String uid) =>
      db.collection(platformAdminsCollection).doc(uid.trim());

  /// مجموعة ضمن الشبكة النشطة في الجلسة.
  static CollectionReference<Map<String, dynamic>> current(String name) =>
      collection(TenantContext.requireTenantId, name);
}
