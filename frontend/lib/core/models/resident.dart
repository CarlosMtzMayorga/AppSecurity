import 'package:equatable/equatable.dart';
import 'user.dart';
import 'access.dart';
import 'payment.dart';

enum ResidentStatus { active, inactive, pending, suspended }

class Resident extends Equatable {
  final String id;
  final User user;
  final UnitInfo unit;
  final ResidentStatus status;
  final String? rut;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final List<String> vehiclePlates;
  final String? qrCode;
  final DateTime joinedAt;
  final DateTime? approvedAt;
  final List<Visitor> visitors;
  final List<AccessLog> accesses;
  final List<Payment> payments;

  const Resident({
    required this.id,
    required this.user,
    required this.unit,
    required this.status,
    this.rut,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.vehiclePlates = const [],
    this.qrCode,
    required this.joinedAt,
    this.approvedAt,
    this.visitors = const [],
    this.accesses = const [],
    this.payments = const [],
  });

  factory Resident.fromJson(Map<String, dynamic> json) {
    return Resident(
      id: json['id'],
      user: User.fromJson(json['user']),
      unit: UnitInfo.fromJson(json['unit']),
      status: ResidentStatus.values.firstWhere((e) => e.name.toLowerCase() == json['status'].toLowerCase()),
      rut: json['rut'],
      emergencyContactName: json['emergencyContactName'],
      emergencyContactPhone: json['emergencyContactPhone'],
      emergencyContactRelation: json['emergencyContactRelation'],
      vehiclePlates: List<String>.from(json['vehiclePlates'] ?? []),
      qrCode: json['qrCode'],
      joinedAt: DateTime.parse(json['joinedAt']),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      visitors: (json['visitors'] as List?)?.map((v) => Visitor.fromJson(v)).toList() ?? [],
      accesses: (json['accesses'] as List?)?.map((a) => AccessLog.fromJson(a)).toList() ?? [],
      payments: (json['payments'] as List?)?.map((p) => Payment.fromJson(p)).toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [id, user, unit, status];
}

class Visitor extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? documentType;
  final String? documentNumber;
  final String? vehiclePlate;
  final bool isRecurring;
  final List<int> recurringDays;
  final DateTime? recurringStart;
  final DateTime? recurringEnd;
  final String? entryCode;
  final String? notes;
  final List<AccessLog> accesses;

  const Visitor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.documentType,
    this.documentNumber,
    this.vehiclePlate,
    this.isRecurring = false,
    this.recurringDays = const [],
    this.recurringStart,
    this.recurringEnd,
    this.entryCode,
    this.notes,
    this.accesses = const [],
  });

  String get fullName => '$firstName $lastName';

  factory Visitor.fromJson(Map<String, dynamic> json) => Visitor(
    id: json['id'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    phone: json['phone'],
    email: json['email'],
    documentType: json['documentType'],
    documentNumber: json['documentNumber'],
    vehiclePlate: json['vehiclePlate'],
    isRecurring: json['isRecurring'] ?? false,
    recurringDays: List<int>.from(json['recurringDays'] ?? []),
    recurringStart: json['recurringStart'] != null ? DateTime.parse(json['recurringStart']) : null,
    recurringEnd: json['recurringEnd'] != null ? DateTime.parse(json['recurringEnd']) : null,
    entryCode: json['entryCode'],
    notes: json['notes'],
    accesses: (json['accesses'] as List?)?.map((a) => AccessLog.fromJson(a)).toList() ?? [],
  );

  @override
  List<Object?> get props => [id, firstName, lastName];
}