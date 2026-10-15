// Shabakti — public code sample (copied verbatim from the private repository).
// Calls Gemini through Firebase AI Logic with a JSON context limited to the user's permissions; falls back across models.
// Some inline comments are in Arabic.

import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../models/session_bootstrap.dart';
import '../util/ai_assistant_error_message.dart';
import '../util/ai_assistant_permission.dart';
import 'ai_assistant_context_builder.dart';

class AiAssistantReply {
  final String text;
  final bool fromUser;

  const AiAssistantReply({required this.text, this.fromUser = false});
}

/// استدعاء Gemini عبر Firebase AI Logic — تحليل بيانات التطبيق للأدمن.
class AiAssistantService {
  static const _modelCandidates = [
    'gemini-2.5-flash-lite',
    'gemini-2.5-flash',
    'gemini-3.1-flash-lite',
  ];

  final AiAssistantContextBuilder _contextBuilder = AiAssistantContextBuilder();

  GenerativeModel _modelFor(String modelName, {required bool powerAdmin}) {
    return FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: Content.system(
        powerAdmin ? _adminSystemPrompt : _systemPrompt,
      ),
    );
  }

  static const _systemPrompt = '''
أنت «مساعد شبكتي» لتطبيق إدارة شبكات وبطاقات.
- أجب بالعربية الفصحى البسيطة فقط.
- استخدم الأرقام والأسماء من JSON المرفق فقط — لا تخترع بيانات.
- البيانات في JSON محدودة بصلاحيات المستخدم الحالي.
- إن وُجد activityLogs: لنشاط النظام. إن وُجد users: للمندوبين.
- لا تعرض معرّفات Firebase الطويلة — استخدم الأسماء.
- أنت للعرض والتحليل فقط — لا تتظاهر بتنفيذ أوامر في قاعدة البيانات.
- عند عرض أكثر من صفّين من الأرقام استخدم جدول Markdown.
''';

  static const _adminSystemPrompt = '''
أنت «مساعد شبكتي» للإدارة — محلل بيانات التطبيق للأدمن.
- أجب بالعربية الفصحى البسيطة.
- استخدم JSON المرفق فقط — لا تخترع أرقاماً ولا أسماء.
- لا تعرض معرّفات Firebase — استخدم أسماء المناطق والمستخدمين.

مصادر البيانات (حسب ما وُجد في JSON):
- periodReports.week / periodReports.month: تقارير مالية كاملة لكل منطقة (إجمالي، مؤكد، مصروفات، رواتب، صافي net).
- userPresence: من نشط الآن وآخر نشاط لكل مستخدم.
- activityLogs: حركات النظام (سجل العمليات).
- areasSummary: ملخص ديون/مدفوعات المناطق.
- expensesWeek / salariesMonth: تفاصيل إضافية.

قواعد الإجابة:
1. عند سؤال عن «صافي منطقة X» أو «صافي حمد»: ابحث في periodReports عن المنطقة بالاسم (مطابقة جزئية) واذكر confirmed وexpenses وsalariesPaid وnet من JSON.
2. اشرح الحساب بوضوح: صافي المنطقة = المؤكد − المصروفات − الرواتب المدفوعة (من periodReports.note).
3. «هذا الأسبوع» → periodReports.week. «هذا الشهر» → periodReports.month.
4. «مين نشط» / «مين فاتح التطبيق» → userPresence.activeNow و userPresence.users.
5. «حركات اليوم» → activityLogs.today.
6. عند عرض 3+ صفوف (مناطق، مستخدمين، حركات) استخدم **جدول Markdown** بهذا الشكل:
| العمود | العمود |
|--------|--------|
| قيمة | قيمة |
7. إن لم تجد البيانات في JSON قل ذلك صراحةً ولا تخمّن.
8. لا تتظاهر بحفظ أو تعديل في النظام — أنت تحلّل وتفسّر فقط.
9. كن عملياً: ملخص قصير ثم جدول أو تفاصيل عند الحاجة.
''';

  Future<String> ask({
    required SessionBootstrap session,
    required String userMessage,
    Map<String, dynamic>? cachedContext,
  }) async {
    final question = userMessage.trim();
    if (question.isEmpty) {
      throw ArgumentError('السؤال فارغ');
    }

    final powerAdmin = aiIsPowerAdmin(session.permissions);
    final context = cachedContext ?? await _contextBuilder.build(session);
    final payload = jsonEncode(context, toEncodable: (o) => o);

    final prompt = '''
بيانات التطبيق (JSON):
$payload

سؤال المستخدم:
$question
''';

    Object? lastError;
    for (final modelName in _modelCandidates) {
      try {
        final model = _modelFor(modelName, powerAdmin: powerAdmin);
        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 60));
        final text = response.text?.trim() ?? '';
        if (text.isNotEmpty) return text;
        lastError = Exception('رد فارغ من النموذج $modelName');
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('AI_ASSISTANT_ERROR[$modelName]: $e');
          debugPrintStack(stackTrace: st, label: 'AI_ASSISTANT_STACK');
        }
        lastError = e;
        if (e is ServiceApiNotEnabled ||
            e is UnsupportedUserLocation ||
            e is InvalidApiKey) {
          break;
        }
      }
    }

    if (lastError == null) {
      throw Exception('لم يصل رد من المساعد');
    }
    throw Exception(aiAssistantErrorMessage(lastError));
  }

  Future<Map<String, dynamic>> loadContext(SessionBootstrap session) {
    return _contextBuilder.build(session);
  }
}
