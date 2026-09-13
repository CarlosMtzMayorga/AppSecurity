import 'package:equatable/equatable.dart';
import 'user.dart';

enum AccessType { resident, visitor, service, delivery, emergency }
enum AccessStatus { pending, approved, rejected, expired, completed }

class AccessLog extends Equatable {
  final String id;
  final String? unitId;
  final UnitInfo? unit;
  final String? residentId;
  final ResidentInfo? resident;
  final String? visitorId;
  final VisitorInfo? visitor;
  final AccessType type;
  final AccessStatus status;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final DateTime? scheduledEntry;
  final DateTime? scheduledExit;
  final String? entryMethod;
  final String? exitMethod;
  final String? plateRecognized;
  final bool faceRecognized;
  final String? notes;
  final DateTime createdAt;

  const AccessLog({
    required this.id,
    this.unitId,
    this.unit,
    this.residentId,
    this.resident,
    this.visitorId,
    this.visitor,
    required this.type,
    required this.status,
    this.entryTime,
    this.exitTime,
    this.scheduledEntry,
    this.scheduledExit,
    this.entryMethod,
    this.exitMethod,
    this.plateRecognized,
    this.faceRecognized = false,
    this.notes,
    required this.createdAt,
  });

  String get displayName {
    if (resident != null) return resident!.fullName;
    if (visitor != null) return visitor!.fullName;
    return 'Desconocido';
  }

  String get unitDisplay => unit != null ? '${unit!.block ?? ''}${unit!.number}' : 'N/A';

  factory AccessLog.fromJson(Map<String, dynamic> json) => AccessLog(
    id: json['id'],
    unitId: json['unitId'],
    unit: json['unit'] != null ? UnitInfo.fromJson(json['unit']) : null,
    residentId: json['residentId'],
    resident: json['resident'] != null ? ResidentInfo.fromJson(json['resident']) : null,
    visitorId: json['visitorId'],
    visitor: json['visitor'] != null ? VisitorInfo.fromJson(json['visitor']) : null,
    type: AccessType.values.firstWhere((e) => e.name.toLowerCase() == json['type'].toLowerCase()),
    status: AccessStatus.values.firstWhere((e) => e.name.toLowerCase() == json['status'].toLowerCase()),
    entryTime: json['entryTime'] != null ? DateTime.parse(json['entryTime']) : null,
    exitTime: json['exitTime'] != null ? DateTime.parse(json['exitTime']) : null,
    scheduledEntry: json['scheduledEntry'] != null ? DateTime.parse(json['scheduledEntry']) : null,
    scheduledExit: json['scheduledExit'] != null ? DateTime.parse(json['scheduledExit']) : null,
    entryMethod: json['entryMethod'],
    exitMethod: json['exitMethod'],
    plateRecognized: json['plateRecognized'],
    faceRecognized: json['faceRecognized'] ?? false,
    notes: json['notes'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  @override
  List<Object?> get props => [id, type, status, entryTime];
}

class ResidentInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;

  const ResidentInfo({required this.id, required this.firstName, required this.lastName});
  String get fullName => '$firstName $lastName';

  factory ResidentInfo.fromJson(Map<String, dynamic> json) => ResidentInfo(
    id: json['id'] ?? json['user']?['id'],
    firstName: json['user']?['firstName'] ?? json['firstName'] ?? '',
    lastName: json['user']?['lastName'] ?? json['lastName'] ?? '',
  );

  @override
  List<Object?> get props => [id, firstName, lastName];
}

class VisitorInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;

  const VisitorInfo({required this.id, required this.firstName, required this.lastName});
  String get fullName => '$firstName $lastName';

  factory VisitorInfo.fromJson(Map<String, dynamic> json) => VisitorInfo(
    id: json['id'],
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
  );

  @override
  List<Object?> get props => [id, firstName, lastName];
}