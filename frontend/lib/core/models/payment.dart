import 'package:equatable/equatable.dart';

enum PaymentType { maintenance, extraordinary, amenity, penalty, other }
enum PaymentStatus { pending, completed, failed, refunded, overdue }

class Payment extends Equatable {
  final String id;
  final String residentId;
  final ResidentInfo? resident;
  final String unitId;
  final UnitInfo? unit;
  final PaymentType type;
  final PaymentStatus status;
  final double amount;
  final String currency;
  final String description;
  final String? reference;
  final DateTime dueDate;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? paidAt;
  final String? receiptUrl;
  final String? notes;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.residentId,
    this.resident,
    required this.unitId,
    this.unit,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.description,
    this.reference,
    required this.dueDate,
    this.periodStart,
    this.periodEnd,
    this.paidAt,
    this.receiptUrl,
    this.notes,
    required this.createdAt,
  });

  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';
  bool get isOverdue => status == PaymentStatus.overdue || (status == PaymentStatus.pending && dueDate.isBefore(DateTime.now()));
  bool get canPay => status == PaymentStatus.pending || status == PaymentStatus.overdue;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'],
    residentId: json['residentId'],
    resident: json['resident'] != null ? ResidentInfo.fromJson(json['resident']) : null,
    unitId: json['unitId'],
    unit: json['unit'] != null ? UnitInfo.fromJson(json['unit']) : null,
    type: PaymentType.values.firstWhere((e) => e.name.toLowerCase() == json['type'].toLowerCase()),
    status: PaymentStatus.values.firstWhere((e) => e.name.toLowerCase() == json['status'].toLowerCase()),
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] ?? 'MXN',
    description: json['description'],
    reference: json['reference'],
    dueDate: DateTime.parse(json['dueDate']),
    periodStart: json['periodStart'] != null ? DateTime.parse(json['periodStart']) : null,
    periodEnd: json['periodEnd'] != null ? DateTime.parse(json['periodEnd']) : null,
    paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    receiptUrl: json['receiptUrl'],
    notes: json['notes'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  @override
  List<Object?> get props => [id, residentId, type, status, amount, dueDate];
}

class PaymentSummary extends Equatable {
  final double totalAmount;
  final int pending;
  final int completed;
  final int failed;
  final int overdue;
  final List<PaymentTypeAmount> byType;

  const PaymentSummary({
    required this.totalAmount,
    required this.pending,
    required this.completed,
    required this.failed,
    required this.overdue,
    required this.byType,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) => PaymentSummary(
    totalAmount: (json['totalAmount'] as num).toDouble(),
    pending: json['pending'] ?? 0,
    completed: json['completed'] ?? 0,
    failed: json['failed'] ?? 0,
    overdue: json['overdue'] ?? 0,
    byType: (json['byType'] as List).map((e) => PaymentTypeAmount.fromJson(e)).toList(),
  );

  @override
  List<Object?> get props => [totalAmount, pending, completed, failed, overdue, byType];
}

class PaymentTypeAmount extends Equatable {
  final PaymentType type;
  final double amount;
  final int count;

  const PaymentTypeAmount({required this.type, required this.amount, required this.count});

  factory PaymentTypeAmount.fromJson(Map<String, dynamic> json) => PaymentTypeAmount(
    type: PaymentType.values.firstWhere((e) => e.name.toLowerCase() == json['type'].toLowerCase()),
    amount: (json['amount'] as num).toDouble(),
    count: json['count'] ?? 0,
  );

  @override
  List<Object?> get props => [type, amount, count];
}