import 'package:equatable/equatable.dart';
import 'resident.dart';
import 'payment.dart';
import 'service.dart';
import 'accounting.dart';
import 'notice.dart';
import 'access.dart';

class DashboardOverview extends Equatable {
  final ResidentStats residents;
  final UnitStats units;
  final PaymentStats payments;
  final FinanceStats finances;
  final ServiceStats services;
  final int activeAccesses;
  final int noticesCount;

  const DashboardOverview({
    required this.residents,
    required this.units,
    required this.payments,
    required this.finances,
    required this.services,
    required this.activeAccesses,
    required this.noticesCount,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) => DashboardOverview(
    residents: ResidentStats.fromJson(json['residents']),
    units: UnitStats.fromJson(json['units']),
    payments: PaymentStats.fromJson(json['payments']),
    finances: FinanceStats.fromJson(json['finances']),
    services: ServiceStats.fromJson(json['services']),
    activeAccesses: json['security']['activeAccesses'] ?? 0,
    noticesCount: json['communications']['notices'] ?? 0,
  );

  @override
  List<Object?> get props => [residents, units, payments, finances, services, activeAccesses, noticesCount];
}

class ResidentStats extends Equatable {
  final int total;
  final int active;
  final double occupancyRate;
  const ResidentStats({required this.total, required this.active, required this.occupancyRate});
  factory ResidentStats.fromJson(Map<String, dynamic> json) => ResidentStats(
    total: json['total'] ?? 0,
    active: json['active'] ?? 0,
    occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0,
  );
  @override List<Object?> get props => [total, active, occupancyRate];
}

class UnitStats extends Equatable {
  final int total;
  final int occupied;
  final int vacant;
  const UnitStats({required this.total, required this.occupied, required this.vacant});
  factory UnitStats.fromJson(Map<String, dynamic> json) => UnitStats(
    total: json['total'] ?? 0,
    occupied: json['occupied'] ?? 0,
    vacant: json['vacant'] ?? 0,
  );
  @override List<Object?> get props => [total, occupied, vacant];
}

class PaymentStats extends Equatable {
  final int total;
  final int pending;
  final int overdue;
  const PaymentStats({required this.total, required this.pending, required this.overdue});
  factory PaymentStats.fromJson(Map<String, dynamic> json) => PaymentStats(
    total: json['total'] ?? 0,
    pending: json['pending'] ?? 0,
    overdue: json['overdue'] ?? 0,
  );
  @override List<Object?> get props => [total, pending, overdue];
}

class FinanceStats extends Equatable {
  final double income;
  final double expenses;
  final double balance;
  const FinanceStats({required this.income, required this.expenses, required this.balance});
  factory FinanceStats.fromJson(Map<String, dynamic> json) => FinanceStats(
    income: (json['income'] as num).toDouble(),
    expenses: (json['expenses'] as num).toDouble(),
    balance: (json['balance'] as num).toDouble(),
  );
  @override List<Object?> get props => [income, expenses, balance];
}

class ServiceStats extends Equatable {
  final int open;
  const ServiceStats({required this.open});
  factory ServiceStats.fromJson(Map<String, dynamic> json) => ServiceStats(open: json['open'] ?? 0);
  @override List<Object?> get props => [open];
}

class RecentActivity extends Equatable {
  final List<AccessLog> recentAccesses;
  final List<Payment> recentPayments;
  final List<ServiceRequest> recentRequests;
  final List<Notice> recentNotices;

  const RecentActivity({
    required this.recentAccesses,
    required this.recentPayments,
    required this.recentRequests,
    required this.recentNotices,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
    recentAccesses: (json['recentAccesses'] as List).map((e) => AccessLog.fromJson(e)).toList(),
    recentPayments: (json['recentPayments'] as List).map((e) => Payment.fromJson(e)).toList(),
    recentRequests: (json['recentRequests'] as List).map((e) => ServiceRequest.fromJson(e)).toList(),
    recentNotices: (json['recentNotices'] as List).map((e) => Notice.fromJson(e)).toList(),
  );

  @override
  List<Object?> get props => [recentAccesses, recentPayments, recentRequests, recentNotices];
}

class TrendPoint extends Equatable {
  final String label;
  final double value1;
  final double? value2;
  final double? value3;

  const TrendPoint({required this.label, required this.value1, this.value2, this.value3});
  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
    label: json['month'] ?? json['date'] ?? '',
    value1: (json['collected'] ?? json['income'] ?? json['total'] ?? json['residents'] ?? 0).toDouble(),
    value2: (json['pending'] ?? json['expenses'] ?? json['visitors'] ?? 0).toDouble(),
    value3: (json['overdue'] ?? json['balance'] ?? json['services'] ?? 0).toDouble(),
  );
  @override List<Object?> get props => [label, value1, value2, value3];
}