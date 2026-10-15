// Shabakti — public code sample (copied verbatim from the private repository).
// Hard caps on every list query to keep Firestore reads predictable.
// Some inline comments are in Arabic.

/// حدود قراءة Firestore الافتراضية — تقلّل استهلاك الخطة المجانية.
/// عدّل القيم حسب حجم بياناتك الفعلي.
abstract final class FirestoreLimits {
  static const int areas = 80;
  static const int sections = 80;
  static const int roles = 50;
  static const int users = 500;
  static const int usersPicker = 300;
  static const int distributors = 500;
  static const int distributorsByArea = 300;
  static const int tasks = 250;
  static const int tasksAssignee = 150;
  static const int expenses = 400;
  static const int expensesPerScopeQuery = 200;
  static const int payments = 300;
  static const int paymentsByDistributor = 150;
  static const int cardBatchesConfirmed = 300;
  static const int cardBatchesByDistributor = 150;
  static const int discounts = 50;
  static const int inventoryUnits = 500;
  static const int inventoryMovements = 200;
  static const int inventoryCatalog = 300;
  static const int areaSummaries = 80;
  static const int distributorSummaries = 800;
  static const int stockRequestsPending = 100;
  static const int stockRequestsMy = 50;
  static const int stockRequestsRecentFetch = 50;
  static const int stockRequestsRecentShow = 10;
  static const int notificationsUnread = 50;
  static const int notificationsMarkRead = 100;
  static const int notificationsList = 80;
  static const int salaries = 300;
  static const int activityLogs = 500;
  static const int stockLogs = 500;
  static const int stockLogsByUser = 300;
  static const int whereInChunk = 10;
}
