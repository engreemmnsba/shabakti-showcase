// Shabakti — public code sample (copied verbatim from the private repository).
// Which slices of data the AI assistant may see, derived from the user's permissions.
// Some inline comments are in Arabic.

/// من يستطيع فتح مساعد شبكتي.
bool canUseAiAssistant(Set<String> permissions) {
  return permissions.contains('AI_ASSISTANT_VIEW');
}

bool aiCanSeeHomeSummary(Set<String> permissions) {
  return permissions.contains('SCREEN_HOME_ADMIN');
}

bool aiCanSeeUsers(Set<String> permissions) {
  return permissions.contains('USERS_VIEW');
}

bool aiCanSeeActivityLogs(Set<String> permissions) {
  return permissions.contains('LOGS_VIEW');
}

bool aiCanSeeMyTasks(Set<String> permissions) {
  return permissions.contains('TASKS_VIEW');
}

bool aiCanSeeMyStock(Set<String> permissions) {
  return permissions.contains('SCREEN_MY_STOCK') ||
      permissions.contains('CARD_STOCK_VIEW');
}

bool aiCanSeeReports(Set<String> permissions) {
  return permissions.contains('SCREEN_REPORTS') ||
      permissions.contains('Admin_VIEW_AMOUNTS') ||
      permissions.contains('SCREEN_HOME_ADMIN');
}

bool aiCanSeeExpenses(Set<String> permissions) {
  return permissions.contains('EXPENSES_VIEW');
}

bool aiCanSeeSalaries(Set<String> permissions) {
  return permissions.contains('SALARIES_VIEW') ||
      permissions.contains('SALARIES_PAY');
}

bool aiIsPowerAdmin(Set<String> permissions) {
  return permissions.contains('SCREEN_HOME_ADMIN') &&
      (aiCanSeeReports(permissions) || aiCanSeeUsers(permissions));
}
