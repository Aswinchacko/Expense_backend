enum TransactionType { expense, income }

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.userId,
  });

  final String id;
  final String name;
  final String icon;
  final String? userId;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? '📦',
        userId: json['user_id'] as String?,
      );
}

class Expense {
  const Expense({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.date,
    this.note,
    this.merchant,
    this.paymentMethod,
    this.category,
  });

  final String id;
  final String categoryId;
  final double amount;
  final String currency;
  final TransactionType type;
  final String date;
  final String? note;
  final String? merchant;
  final String? paymentMethod;
  final Category? category;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        categoryId: json['category_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'USD',
        type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
        date: json['date'] as String,
        note: json['note'] as String?,
        merchant: json['merchant'] as String?,
        paymentMethod: json['payment_method'] as String?,
        category: json['category'] != null
            ? Category.fromJson(json['category'] as Map<String, dynamic>)
            : null,
      );

  String get displayTitle => merchant ?? category?.name ?? note ?? 'Transaction';
  String get displaySubtitle => category?.name ?? '';
}

class Budget {
  const Budget({
    required this.id,
    required this.name,
    required this.amount,
    required this.period,
    this.categoryId,
    this.spent = 0,
    this.spentPercent = 0,
    this.category,
  });

  final String id;
  final String name;
  final double amount;
  final String period;
  final String? categoryId;
  final double spent;
  final int spentPercent;
  final Category? category;

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        period: json['period'] as String? ?? 'monthly',
        categoryId: json['category_id'] as String?,
        spent: (json['spent'] as num?)?.toDouble() ?? 0,
        spentPercent: (json['spent_percent'] as num?)?.toInt() ?? 0,
        category: json['category'] != null
            ? Category.fromJson(json['category'] as Map<String, dynamic>)
            : null,
      );
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.balance,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.byCategory,
    required this.trend,
  });

  final double balance;
  final double incomeTotal;
  final double expenseTotal;
  final List<CategoryBreakdown> byCategory;
  final List<TrendPoint> trend;

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) => AnalyticsSummary(
        balance: (json['balance'] as num).toDouble(),
        incomeTotal: (json['income_total'] as num).toDouble(),
        expenseTotal: (json['expense_total'] as num).toDouble(),
        byCategory: (json['by_category'] as List<dynamic>? ?? [])
            .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
            .toList(),
        trend: (json['trend'] as List<dynamic>? ?? [])
            .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CategoryBreakdown {
  const CategoryBreakdown({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.total,
    required this.percent,
  });

  final String categoryId;
  final String name;
  final String icon;
  final double total;
  final int percent;

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) => CategoryBreakdown(
        categoryId: json['category_id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? '📦',
        total: (json['total'] as num).toDouble(),
        percent: (json['percent'] as num).toInt(),
      );
}

class TrendPoint {
  const TrendPoint({required this.date, required this.amount});

  final String date;
  final double amount;

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
        date: json['date'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}

class Profile {
  const Profile({
    required this.id,
    required this.currency,
    this.displayName,
  });

  final String id;
  final String currency;
  final String? displayName;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        currency: json['currency'] as String? ?? 'USD',
        displayName: json['display_name'] as String?,
      );
}
