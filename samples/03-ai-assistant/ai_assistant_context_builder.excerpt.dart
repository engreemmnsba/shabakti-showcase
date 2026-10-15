// Shabakti — excerpt of ai_assistant_context_builder.dart (entry point only).
// Builds the JSON context in parallel; each _appendX method checks the user's permissions and area scope first.

/// يجمع ملخصاً صغيراً من Firestore — نفس نطاق صلاحيات المستخدم.
class AiAssistantContextBuilder {
  final TaskRepository _tasks = TaskRepository();
  final UserStockRepository _stocks = UserStockRepository();
  final AreaSummaryRepository _areaSummaries = AreaSummaryRepository();
  final SectionRepository _sections = SectionRepository();
  final UserRepository _users = UserRepository();
  final PeriodReportLoader _periodReports = PeriodReportLoader();
  final ExpenseRepository _expenses = ExpenseRepository();
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> build(SessionBootstrap session) async {
    final scope = session.areaScope;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartMs = DateTime(weekStart.year, weekStart.month, weekStart.day)
        .millisecondsSinceEpoch;
    final todayStartMs =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final userNamesById = await _loadUserNamesById(session, scope);

    final ctx = <String, dynamic>{
      'userName': session.userName,
      'roleName': session.roleName,
      'isAdmin': session.isAdmin,
      'areaIds': scope.effectiveAreaIds,
      'period': {
        'label': 'هذا الأسبوع',
        'from': weekStart.toIso8601String().split('T').first,
        'to': now.toIso8601String().split('T').first,
        'today': now.toIso8601String().split('T').first,
      },
    };

    await Future.wait([
      _appendTasks(ctx, session, weekStartMs, scope),
      _appendStock(ctx, session),
      _appendAreaSummaries(ctx, session, scope),
      _appendUsersBrief(ctx, session, scope),
      _appendActivityInsights(
        ctx,
        session,
        weekStartMs,
        todayStartMs,
        userNamesById,
      ),
      _appendPeriodReports(ctx, session, scope),
      _appendUserPresence(ctx, session, scope),
      _appendExpensesBrief(ctx, session, scope, weekStartMs),
      _appendSalariesBrief(ctx, session, scope, weekStartMs),
    ]);

    return ctx;
  }

  // ... _appendTasks, _appendStock, _appendPeriodReports, etc. omitted
}
