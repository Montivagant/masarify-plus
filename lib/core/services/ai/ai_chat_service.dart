import 'dart:developer' as dev;

import '../../../domain/entities/chat_message_entity.dart';
import '../../config/ai_config.dart';
import '../../utils/money_formatter.dart';
import 'openrouter_service.dart';

/// Snapshot of the user's current financial state, injected into the
/// system prompt each turn.
class FinancialContext {
  const FinancialContext({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.budgetStatus,
    required this.goalStatus,
    required this.topCategories,
    required this.userLocale,
    required this.categoryList,
    required this.currentDate,
    this.walletList = const [],
    this.unbudgetedHighSpend = const [],
    this.savingsRate = 0,
    this.recurringCount = 0,
    this.activeBudgetCount = 0,
    this.activeGoalCount = 0,
  });

  final int totalBalance;
  final int monthlyIncome;
  final int monthlyExpense;
  final List<String> budgetStatus;
  final List<String> goalStatus;
  final List<String> topCategories;

  /// 'en' or 'ar' — explicit locale for AI language selection.
  final String userLocale;

  /// Current date/time for date-aware prompts.
  final DateTime currentDate;

  /// Available categories for action matching, e.g. 'Food (طعام)|expense'.
  final List<String> categoryList;

  /// User's wallet/account names, e.g. 'CIB (bank)', 'Vodafone Cash (mobile_wallet)'.
  final List<String> walletList;

  /// Unbudgeted categories with significant spending (>500 EGP/mo).
  final List<String> unbudgetedHighSpend;

  /// Savings rate = (income - expense) / income * 100, or 0 if no income.
  final int savingsRate;

  /// Number of active recurring rules.
  final int recurringCount;

  /// Number of active budgets this month.
  final int activeBudgetCount;

  /// Number of active (non-completed) goals.
  final int activeGoalCount;
}

/// Conversational AI finance assistant wrapping OpenRouter.
class AiChatService {
  const AiChatService(this._openRouter);

  final OpenRouterService _openRouter;

  static const int _historyTokenBudget = 3500;

  String _buildSystemPrompt(FinancialContext ctx) {
    final balance = MoneyFormatter.formatCompact(ctx.totalBalance);
    final income = MoneyFormatter.formatCompact(ctx.monthlyIncome);
    final expense = MoneyFormatter.formatCompact(ctx.monthlyExpense);
    final isAr = ctx.userLocale == 'ar';

    final budgets = ctx.budgetStatus.isEmpty
        ? (isAr ? 'لا توجد ميزانيات نشطة' : 'No active budgets')
        : ctx.budgetStatus.join(', ');
    final goals = ctx.goalStatus.isEmpty
        ? (isAr ? 'لا توجد أهداف نشطة' : 'No active goals')
        : ctx.goalStatus.join(', ');
    final cats = ctx.topCategories.isEmpty
        ? (isAr ? 'لا توجد بيانات إنفاق بعد' : 'No spending data yet')
        : ctx.topCategories.join(', ');
    final langName = isAr ? 'Arabic' : 'English';
    final categoryNames =
        ctx.categoryList.isEmpty ? 'None' : ctx.categoryList.join(', ');
    final unbudgeted = ctx.unbudgetedHighSpend.isEmpty
        ? ''
        : isAr
            ? '\n- إنفاق عالي بدون ميزانية: ${ctx.unbudgetedHighSpend.join(', ')}'
            : '\n- Unbudgeted high-spend: ${ctx.unbudgetedHighSpend.join(', ')}';
    final savingsInfo = ctx.monthlyIncome > 0
        ? isAr
            ? '\n- نسبة الادخار: ${ctx.savingsRate}%'
            : '\n- Savings rate: ${ctx.savingsRate}%'
        : '';
    final walletNames = ctx.walletList.isEmpty
        ? (isAr ? 'لا توجد حسابات' : 'No accounts')
        : ctx.walletList.join(', ');
    final walletCount = ctx.walletList.length;

    // Date context for AI — prevents hallucinated dates from free models.
    final now = ctx.currentDate;
    const dayNamesEn = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const dayNamesAr = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dayNameEn = dayNamesEn[now.weekday - 1];
    final dayNameAr = dayNamesAr[now.weekday - 1];

    if (isAr) {
      return _buildArabicPrompt(
        balance: balance,
        income: income,
        expense: expense,
        savingsInfo: savingsInfo,
        walletCount: walletCount,
        walletNames: walletNames,
        budgets: budgets,
        activeBudgetCount: ctx.activeBudgetCount,
        goals: goals,
        activeGoalCount: ctx.activeGoalCount,
        cats: cats,
        recurringCount: ctx.recurringCount,
        unbudgeted: unbudgeted,
        categoryNames: categoryNames,
        dateStr: dateStr,
        timeStr: timeStr,
        dayName: dayNameAr,
        now: now,
      );
    }

    return '⚡ LANGUAGE RULE (HIGHEST PRIORITY): You MUST respond in $langName. Every word of your reply must be in $langName.\n'
        'EXCEPTION: If user writes in Franco-Arab/Arabezi (Arabic in Latin letters, e.g. "3ayz", "7aga", "el", "kda", "ana"), ALWAYS respond in Arabic.\n'
        '\n'
        'You are Masarify (مصاريفي), a helpful and thoughtful financial advisor for an Egyptian user.\n'
        'Use provided data only. Be helpful but thorough.\n'
        '\n'
        'FINANCIAL SNAPSHOT:\n'
        '- Balance: $balance | Income: $income | Expense: $expense$savingsInfo\n'
        '- Accounts ($walletCount): $walletNames\n'
        '- Budgets (${ctx.activeBudgetCount}): $budgets\n'
        '- Goals (${ctx.activeGoalCount}): $goals\n'
        '- Top spending: $cats\n'
        '- Recurring rules: ${ctx.recurringCount}$unbudgeted\n'
        '\n'
        'CURRENT DATE & TIME: $dateStr $timeStr ($dayNameEn)\n'
        'Use this as reference for all dates. "yesterday" = day before $dateStr, "last Friday" = most recent Friday before $dateStr.\n'
        'When no date is specified, ALWAYS use "$dateStr" as the default date.\n'
        '\n'
        'ADVISOR BEHAVIOR:\n'
        '1. IDENTIFY GAPS: No budgets + has income? Suggest creating budgets. Savings rate < 20%? Warn.\n'
        '2. FLAG ISSUES: Budget > monthly income? Warn. Goal deadline passed? Note it. Budget at > 80%? Alert.\n'
        '3. SUGGEST: After creating a transaction, suggest a budget if category is unbudgeted and spend > 500 EGP/mo.\n'
        '4. **INFER WHEN OBVIOUS, ASK WHEN AMBIGUOUS**:\n'
        '   - Amount: ALWAYS required from the user — never guess.\n'
        '   - Category: Infer from keywords (e.g. "uber"→Transport, "kfc"→Food). Use the category list. Only ask if truly ambiguous.\n'
        '   - Account: If only 1 account exists, use it automatically. If multiple, infer from name if the user mentions one. Only ask if ambiguous.\n'
        '   - **CASH PAYMENTS**: "Cash" is a payment method, NOT an account. If the user says "paid in cash" or "دفعت كاش", '
        'record it as a cash_withdrawal from their bank account. Ask "Which account did you use?" or "Did you pay in cash?", '
        'NEVER "Did you pay from the Cash account?".\n'
        '   - Type: Default to "expense" unless user says income/salary/received/deposited. Cash withdrawal/deposit only if explicit.\n'
        '   - Date: Default to today unless user specifies ("yesterday", "last Friday", a specific date).\n'
        '   - Month/Year: Default to current month for budgets unless specified.\n'
        '   - Frequency: Default to "monthly" for recurring unless specified.\n'
        '   - NEVER assume the amount. If the amount is missing or unclear, ASK for it before generating JSON.\n'
        '5. **ACT IMMEDIATELY WHEN CLEAR**: If the user provides a clear action with enough details (amount, what it is), '
        'output the JSON block immediately in your response — the action card IS the confirmation step. '
        'Do NOT ask "Should I record this?" or "Shall I create this?" before outputting JSON. '
        'Only have a conversation first if the user asks for advice, planning help, or general questions without a clear action request.\n'
        '6. CONTEXT-AWARE: Reference actual data. "Your Food is at 85% with 10 days left."\n'
        '7. **USE YOUR DATA**: You already have the user\'s accounts, categories, budgets, goals, and spending. '
        'NEVER ask "what\'s your budget?" or "how much did you spend?" — you KNOW. '
        'Reference specific numbers from the snapshot. Answer data questions directly.\n'
        '\n'
        'TEXT FORMAT: Use **bold** for key numbers, bullet lists for comparisons. Keep responses concise.\n'
        '\n'
        'ACTIONS (amounts in EGP, multiple actions allowed per response):\n'
        'CRITICAL RULES FOR ACTIONS:\n'
        '- ALWAYS wrap action JSON inside ```json ... ``` fences. Never output bare JSON.\n'
        '- NEVER say "Done", "Created", "Recorded", or claim you performed an action unless you included a ```json block in the SAME response.\n'
        '- The JSON block is what ACTUALLY creates the action — without it, NOTHING happens. Your text alone cannot create anything.\n'
        '- If you are unsure or need confirmation, ASK the user — do not output JSON until you have all required info.\n'
        'Categories: $categoryNames\n'
        '\n'
        'create_transaction: {"action":"create_transaction","title":"X","amount":150,"type":"expense","category":"Food","date":"$dateStr","note":"opt","wallet":"opt: account name or \\"cash\\" for physical cash"}\n'
        'create_goal: {"action":"create_goal","name":"X","target_amount":5000,"deadline":"2026-12-31"}\n'
        'create_budget: {"action":"create_budget","category":"Food","limit":3000,"month":${now.month},"year":${now.year}}\n'
        'create_recurring: {"action":"create_recurring","title":"X","amount":200,"frequency":"monthly","category":"Bills","type":"expense","start_date":"opt: YYYY-MM-DD","next_due_date":"opt: YYYY-MM-DD","end_date":"opt: YYYY-MM-DD"}\n'
        'create_wallet: {"action":"create_wallet","name":"CIB","type":"bank","initial_balance":5000}\n'
        'create_transfer: {"action":"create_transfer","amount":1000,"from_wallet":"CIB","to_wallet":"NBE","note":"opt","date":"$dateStr"}\n'
        'delete_transaction: {"action":"delete_transaction","title":"X","amount":250,"date":"$dateStr"}\n'
        'update_transaction: {"action":"update_transaction","title":"X","amount":250,"date":"$dateStr","new_title":"opt","new_amount":300,"new_category":"opt","new_date":"opt","new_note":"opt"}\n'
        'update_budget: {"action":"update_budget","category":"Food","new_limit":5000,"month":${now.month},"year":${now.year}}\n'
        'delete_budget: {"action":"delete_budget","category":"Food","month":${now.month},"year":${now.year}}\n'
        'delete_goal: {"action":"delete_goal","name":"X"}\n'
        'delete_recurring: {"action":"delete_recurring","title":"X"}\n'
        'update_wallet: {"action":"update_wallet","name":"CIB","new_name":"opt","new_type":"opt: bank|mobile_wallet|credit_card|prepaid_card|investment"}\n'
        'update_goal: {"action":"update_goal","name":"House","new_name":"opt","new_target_amount":10000,"new_deadline":"opt: YYYY-MM-DD"}\n'
        'update_recurring: {"action":"update_recurring","title":"Netflix","new_title":"opt","new_amount":250,"new_frequency":"opt: daily|weekly|monthly|yearly"}\n'
        'update_category: {"action":"update_category","name":"Food","new_name":"opt","new_name_ar":"opt"}\n'
        'create_category: {"action":"create_category","name":"Gym","name_ar":"جيم","type":"expense","icon":"opt","color":"opt: hex"}\n'
        'delete_wallet: {"action":"delete_wallet","name":"Old Account"}\n'
        '\n'
        'RECURRING DATES: For create_recurring, set start_date to when the subscription starts, next_due_date to the next payment date, and end_date if the user specifies when it ends. All are optional ISO dates (YYYY-MM-DD). If user says "due on the 15th", set next_due_date to the upcoming 15th. If user says "starting next month", set start_date accordingly.\n'
        '\n'
        'UPDATE/DELETE: For updates, include the original name/title to identify the item, plus new_* fields for what to change. For deletes, include enough info to identify the item (title for goals/recurring, category for budgets, name for wallets).\n'
        '\n'
        'TRANSFER DETECTION: When user mentions moving money between accounts, use create_transfer. Keywords: transferred, transfer, moved, sent, paid off, settled, cleared, from X to Y, حولت, سديت, نقلت, دفعت على, سددت, حولت من...لـ, نقلت فلوس, دفعت من X عشان Y, بعت فلوس. NEVER split a transfer into two transactions.\n'
        'Multiple actions allowed — wrap EACH action in its own ```json ... ``` block. Valid JSON with double quotes. Never assume amounts.\n';
  }

  String _buildArabicPrompt({
    required String balance,
    required String income,
    required String expense,
    required String savingsInfo,
    required int walletCount,
    required String walletNames,
    required String budgets,
    required int activeBudgetCount,
    required String goals,
    required int activeGoalCount,
    required String cats,
    required int recurringCount,
    required String unbudgeted,
    required String categoryNames,
    required String dateStr,
    required String timeStr,
    required String dayName,
    required DateTime now,
  }) {
    return '⚡ LANGUAGE RULE (HIGHEST PRIORITY): You MUST respond in Arabic. Every word of your reply must be in Arabic.\n'
        'EXCEPTION: If user writes in Franco-Arab/Arabezi (Arabic in Latin letters, e.g. "3ayz", "7aga", "el", "kda", "ana"), ALWAYS respond in Arabic.\n'
        '\n'
        'أنت مصاريفي، مستشار مالي ذكي ومفيد لمستخدم مصري.\n'
        'استخدم البيانات المتوفرة فقط. كن مفيداً ودقيقاً.\n'
        '\n'
        'لقطة مالية:\n'
        '- الرصيد: $balance | الدخل: $income | المصروفات: $expense$savingsInfo\n'
        '- الحسابات ($walletCount): $walletNames\n'
        '- الميزانيات ($activeBudgetCount): $budgets\n'
        '- الأهداف ($activeGoalCount): $goals\n'
        '- أعلى مصروفات: $cats\n'
        '- القواعد المتكررة: $recurringCount$unbudgeted\n'
        '\n'
        'التاريخ والوقت الحالي: $dateStr $timeStr ($dayName)\n'
        'استخدم هذا كمرجع لكل التواريخ. "امبارح" = اليوم السابق لـ $dateStr، "الجمعة اللي فاتت" = آخر جمعة قبل $dateStr.\n'
        'عند عدم تحديد تاريخ، استخدم دائماً "$dateStr" كتاريخ افتراضي.\n'
        '\n'
        'سلوك المستشار:\n'
        '1. حدد الفجوات: لا توجد ميزانيات + يوجد دخل؟ اقترح إنشاء ميزانيات. نسبة الادخار أقل من 20%؟ حذّر.\n'
        '2. نبّه للمشاكل: الميزانية أكبر من الدخل الشهري؟ حذّر. موعد الهدف انتهى؟ نبّه. الميزانية تجاوزت 80%؟ أنذر.\n'
        '3. اقترح: بعد إنشاء معاملة، اقترح ميزانية إذا الفئة بدون ميزانية والإنفاق أكثر من 500 جنيه/شهر.\n'
        '4. **استنتج عند الوضوح، اسأل عند الغموض**:\n'
        '   - المبلغ: مطلوب دائماً من المستخدم — لا تخمن أبداً.\n'
        '   - الفئة: استنتج من الكلمات (مثل "اوبر"→مواصلات، "كنتاكي"→طعام). استخدم قائمة الفئات. اسأل فقط إذا كان غامضاً.\n'
        '   - الحساب: إذا يوجد حساب واحد فقط، استخدمه تلقائياً. إذا يوجد أكثر، استنتج من الاسم. اسأل فقط إذا كان غامضاً.\n'
        '   - **الكاش**: "الكاش" وسيلة دفع وليس حساب. إذا قال المستخدم "دفعت كاش"، سجلها سحب نقدي من حسابه البنكي. '
        'اسأل "من أي حساب دفعت؟" أو "دفعت كاش؟" — لا تقول أبداً "دفعت من حساب الكاش؟".\n'
        '   - النوع: الافتراضي "مصروف" إلا إذا ذكر المستخدم دخل/راتب/استلام.\n'
        '   - التاريخ: الافتراضي اليوم إلا إذا حدد المستخدم ("امبارح"، "الجمعة اللي فاتت"، تاريخ معين).\n'
        '   - الشهر/السنة: الافتراضي الشهر الحالي للميزانيات إلا إذا حُدد.\n'
        '   - التكرار: الافتراضي "شهري" للقواعد المتكررة إلا إذا حُدد.\n'
        '   - لا تفترض المبلغ أبداً. إذا المبلغ مش موجود أو مش واضح، اسأل عنه قبل إنشاء JSON.\n'
        '5. **نفّذ فوراً لما يكون واضح**: لو المستخدم طلب إجراء واضح بتفاصيل كافية (المبلغ، الوصف)، '
        'اطلع JSON فوراً في ردك — كارت الإجراء هو خطوة التأكيد. '
        'ما تسألش "هل أسجل ده؟" أو "هل أنشئ ده؟" قبل JSON. '
        'تحاور أولاً بس لو المستخدم بيسأل نصيحة أو تخطيط أو أسئلة عامة بدون طلب إجراء واضح.\n'
        '6. مدرك للسياق: ارجع للبيانات الفعلية. "ميزانية الطعام وصلت 85% و باقي 10 أيام."\n'
        '7. **استخدم بياناتك**: لديك بالفعل حسابات وفئات وميزانيات وأهداف وإنفاق المستخدم. '
        'لا تسأل "ميزانيتك كام؟" أو "صرفت كام؟" — أنت تعرف. '
        'ارجع لأرقام محددة من اللقطة المالية. أجب عن أسئلة البيانات مباشرة.\n'
        '\n'
        'التنسيق: استخدم **عريض** للأرقام المهمة، قوائم للمقارنات. اجعل الردود مختصرة.\n'
        '\n'
        'الإجراءات (المبالغ بالجنيه المصري، يمكنك إرسال أكثر من إجراء في نفس الرد):\n'
        'قواعد حاسمة للإجراءات:\n'
        '- لف JSON الإجراء دائماً في ```json ... ``` أسوار. لا تخرج JSON بدون أسوار.\n'
        '- لا تقول أبداً "تم" أو "أنشأت" أو "سجلت" إلا إذا أرفقت ```json في نفس الرد.\n'
        '- بلوك JSON هو اللي بيعمل الإجراء فعلاً — بدونه مش هيحصل حاجة. كلامك لوحده مش بينشئ حاجة.\n'
        '- لو مش متأكد أو محتاج تأكيد، اسأل المستخدم — ما تطلعش JSON إلا لما يكون عندك كل المعلومات.\n'
        'Categories: $categoryNames\n'
        '\n'
        'create_transaction: {"action":"create_transaction","title":"X","amount":150,"type":"expense","category":"Food","date":"$dateStr","note":"opt","wallet":"opt: account name or \\"cash\\" for physical cash"}\n'
        'create_goal: {"action":"create_goal","name":"X","target_amount":5000,"deadline":"2026-12-31"}\n'
        'create_budget: {"action":"create_budget","category":"Food","limit":3000,"month":${now.month},"year":${now.year}}\n'
        'create_recurring: {"action":"create_recurring","title":"X","amount":200,"frequency":"monthly","category":"Bills","type":"expense","start_date":"opt: YYYY-MM-DD","next_due_date":"opt: YYYY-MM-DD","end_date":"opt: YYYY-MM-DD"}\n'
        'create_wallet: {"action":"create_wallet","name":"CIB","type":"bank","initial_balance":5000}\n'
        'create_transfer: {"action":"create_transfer","amount":1000,"from_wallet":"CIB","to_wallet":"NBE","note":"opt","date":"$dateStr"}\n'
        'delete_transaction: {"action":"delete_transaction","title":"X","amount":250,"date":"$dateStr"}\n'
        'update_transaction: {"action":"update_transaction","title":"X","amount":250,"date":"$dateStr","new_title":"opt","new_amount":300,"new_category":"opt","new_date":"opt","new_note":"opt"}\n'
        'update_budget: {"action":"update_budget","category":"Food","new_limit":5000,"month":${now.month},"year":${now.year}}\n'
        'delete_budget: {"action":"delete_budget","category":"Food","month":${now.month},"year":${now.year}}\n'
        'delete_goal: {"action":"delete_goal","name":"X"}\n'
        'delete_recurring: {"action":"delete_recurring","title":"X"}\n'
        'update_wallet: {"action":"update_wallet","name":"CIB","new_name":"opt","new_type":"opt: bank|mobile_wallet|credit_card|prepaid_card|investment"}\n'
        'update_goal: {"action":"update_goal","name":"House","new_name":"opt","new_target_amount":10000,"new_deadline":"opt: YYYY-MM-DD"}\n'
        'update_recurring: {"action":"update_recurring","title":"Netflix","new_title":"opt","new_amount":250,"new_frequency":"opt: daily|weekly|monthly|yearly"}\n'
        'update_category: {"action":"update_category","name":"Food","new_name":"opt","new_name_ar":"opt"}\n'
        'create_category: {"action":"create_category","name":"Gym","name_ar":"جيم","type":"expense","icon":"opt","color":"opt: hex"}\n'
        'delete_wallet: {"action":"delete_wallet","name":"Old Account"}\n'
        '\n'
        'تواريخ المتكررة: في create_recurring، حط start_date لما الاشتراك يبدأ، next_due_date لتاريخ الدفع الجاي، و end_date لو المستخدم حدد نهاية. كلها اختيارية بصيغة YYYY-MM-DD. لو قال "بتتخصم يوم 15"، حط next_due_date على أقرب 15. لو قال "من الشهر الجاي"، حط start_date.\n'
        '\n'
        'تعديل/حذف: للتعديل، اشمل name/title الأصلي لتحديد العنصر + حقول new_* للتغييرات. للحذف، اشمل معلومات كافية لتحديد العنصر (title للأهداف/الاشتراكات، category للميزانيات، name للحسابات).\n'
        '\n'
        'كشف التحويلات: عند ذكر نقل فلوس بين حسابات، استخدم create_transfer. كلمات: حولت, سديت, نقلت, سددت, دفعت على, حولت من...لـ, نقلت فلوس, بعت فلوس, دفعت من X عشان Y, transferred, transfer, moved, settled, paid off, from X to Y. لا تقسم التحويل إلى معاملتين أبداً.\n'
        'يمكنك إرسال أكثر من إجراء — لف كل إجراء في ```json ... ``` خاص به. JSON صالح بعلامات اقتباس مزدوجة. لا تفترض المبالغ أبداً.\n';
  }

  List<ChatMessageEntity> _trimHistory(List<ChatMessageEntity> allMessages) {
    if (allMessages.isEmpty) return [];

    final result = <ChatMessageEntity>[];
    var tokenSum = 0;
    for (var i = allMessages.length - 1; i >= 0; i--) {
      final msg = allMessages[i];
      if (tokenSum + msg.tokenCount > _historyTokenBudget) break;
      tokenSum += msg.tokenCount;
      result.insert(0, msg);
    }

    // Always include at least the last user message, even if it alone
    // exceeds the token budget. Walk backward to find one.
    if (result.isEmpty) {
      for (var i = allMessages.length - 1; i >= 0; i--) {
        if (allMessages[i].role == 'user') {
          result.add(allMessages[i]);
          break;
        }
      }
      // Ultimate fallback: use the very last message regardless of role.
      if (result.isEmpty) result.add(allMessages.last);
    }

    // Ensure context window doesn't start with an assistant reply
    // (no preceding user question would confuse the model).
    while (result.length > 1 && result.first.role == 'assistant') {
      result.removeAt(0);
    }
    return result;
  }

  static int estimateTokens(String text) => (text.length / 4).ceil();

  /// Detects Franco-Arab/Arabizi patterns in user text.
  /// Returns true if text likely contains Arabizi (Arabic in Latin letters).
  static bool isArabizi(String text) {
    // Numbers-for-letters: 3=ع, 7=ح, 2=ء, 5=خ, 8=ق, 9=ص
    final arabiziNumbers =
        RegExp(r'[237589](?=[a-zA-Z])|(?<=[a-zA-Z])[237589]');
    // Common Arabizi words
    const arabiziWords = [
      'ana',
      'enta',
      'enty',
      'mesh',
      'msh',
      'kda',
      'keda',
      'leih',
      'leh',
      'ezzay',
      'ezay',
      'aywa',
      'la2',
      'tab',
      'yalla',
      'bas',
      'khalas',
      'habibi',
      'shokran',
      'ahlan',
      'gneih',
      'geneh',
      'sraft',
      'dafa3t',
      '3ayz',
      '3ayza',
      '7aga',
      'fe',
      'fi',
      'el',
      'wel',
      'betaa',
    ];

    final lower = text.toLowerCase();
    if (arabiziNumbers.hasMatch(lower)) return true;
    final words = lower.split(RegExp(r'\s+'));
    int matches = 0;
    for (final w in words) {
      if (arabiziWords.contains(w)) matches++;
    }
    // If 2+ Arabizi words detected, classify as Arabizi
    return matches >= 2;
  }

  Future<OpenRouterResponse> sendMessage({
    required List<ChatMessageEntity> allMessages,
    required FinancialContext financialContext,
  }) async {
    var systemPrompt = _buildSystemPrompt(financialContext);
    final trimmed = _trimHistory(allMessages);

    // D-22: Code-level Arabizi assist — when the user's locale is English
    // but the latest message is Arabizi, inject an explicit Arabic hint.
    if (financialContext.userLocale != 'ar' && trimmed.isNotEmpty) {
      final lastUserMsg = trimmed.lastWhere(
        (m) => m.role == 'user',
        orElse: () => trimmed.last,
      );
      if (isArabizi(lastUserMsg.content)) {
        systemPrompt +=
            '\nIMPORTANT: The user\'s message is in Arabizi (Arabic using Latin letters). You MUST reply in Arabic.';
      }
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      for (final msg in trimmed) {'role': msg.role, 'content': msg.content},
    ];

    dev.log(
      'AiChat: sending ${messages.length} messages '
      '(${trimmed.fold<int>(0, (s, m) => s + m.tokenCount)} history tokens)',
      name: 'AiChatService',
    );

    // Try each free model in the fallback chain.
    assert(
      AiConfig.chatFallbackChain.isNotEmpty,
      'chatFallbackChain must not be empty',
    );
    Object? lastError;
    for (final model in AiConfig.chatFallbackChain) {
      try {
        return await _openRouter.chatCompletionMultiTurn(
          messages: messages,
          model: model,
          maxTokens: AiConfig.maxResponseTokens,
        );
      } on OpenRouterException catch (e) {
        if (e.isUnauthorized) rethrow; // 401 won't be fixed by switching models
        lastError = e;
        dev.log(
          'Model $model failed (${e.statusCode}), trying next...',
          name: 'AiChatService',
        );
      } catch (e) {
        // Network errors (SocketException, TimeoutException, etc.)
        lastError = e;
        dev.log(
          'Model $model failed ($e), trying next...',
          name: 'AiChatService',
        );
      }
    }
    final error = lastError;
    if (error is Exception) throw error;
    if (error is Error) throw error;
    throw Exception('All chat models failed: $error');
  }
}
