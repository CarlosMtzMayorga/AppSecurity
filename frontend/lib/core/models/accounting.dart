import 'package:equatable/equatable.dart';

enum AccountingType { income, expense }

class AccountingEntry extends Equatable {
  final String id;
  final AccountingType type;
  final String category;
  final String? subcategory;
  final double amount;
  final String currency;
  final String description;
  final String? reference;
  final DateTime date;
  final List<String> attachments;
  final DateTime createdAt;

  const AccountingEntry({
    required this.id,
    required this.type,
    required this.category,
    this.subcategory,
    required this.amount,
    required this.currency,
    required this.description,
    this.reference,
    required this.date,
    this.attachments = const [],
    required this.createdAt,
  });

  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';
  String get typeLabel => type == AccountingType.income ? 'Ingreso' : 'Gasto';

  factory AccountingEntry.fromJson(Map<String, dynamic> json) => AccountingEntry(
    id: json['id'],
    type: AccountingType.values.firstWhere((e) => e.name.toLowerCase() == json['type'].toLowerCase()),
    category: json['category'],
    subcategory: json['subcategory'],
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] ?? 'MXN',
    description: json['description'],
    reference: json['reference'],
    date: DateTime.parse(json['date']),
    attachments: List<String>.from(json['attachments'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
  );

  @override
  List<Object?> get props => [id, type, category, amount, date];
}

class AccountingSummary extends Equatable {
  final double income;
  final double expenses;
  final double balance;
  final List<CategoryAmount> byCategory;

  const AccountingSummary({
    required this.income,
    required this.expenses,
    required this.balance,
    required this.byCategory,
  });

  factory AccountingSummary.fromJson(Map<String, dynamic> json) => AccountingSummary(
    income: (json['income'] as num).toDouble(),
    expenses: (json['expenses'] as num).toDouble(),
    balance: (json['balance'] as num).toDouble(),
    byCategory: (json['byCategory'] as List).map((e) => CategoryAmount.fromJson(e)).toList(),
  );

  @override
  List<Object?> get props => [income, expenses, balance];
}

class CategoryAmount extends Equatable {
  final AccountingType type;
  final String category;
  final double amount;
  final int count;

  const CategoryAmount({required this.type, required this.category, required this.amount, required this.count});

  factory CategoryAmount.fromJson(Map<String, dynamic> json) => CategoryAmount(
    type: AccountingType.values.firstWhere((e) => e.name.toLowerCase() == json['type'].toLowerCase()),
    category: json['category'],
    amount: (json['amount'] as num).toDouble(),
    count: json['count'] ?? 0,
  );

  @override
  List<Object?> get props => [type, category, amount];
}

class MonthlyFinance extends Equatable {
  final int month;
  final double income;
  final double expenses;

  const MonthlyFinance({required this.month, required this.income, required this.expenses});
  double get balance => income - expenses;
  String get monthName => ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'][month - 1];

  factory MonthlyFinance.fromJson(Map<String, dynamic> json) => MonthlyFinance(
    month: json['month'],
    income: (json['income'] as num).toDouble(),
    expenses: (json['expenses'] as num).toDouble(),
  );

  @override
  List<Object?> get props => [month, income, expenses];
}