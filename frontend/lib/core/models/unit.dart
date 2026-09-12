import 'package:equatable/equatable.dart';

class Unit extends Equatable {
  final String id;
  final String number;
  final String? block;
  final int? floor;
  final String type;
  final double? area;
  final int? bedrooms;
  final double? bathrooms;
  final bool hasParking;
  final int parkingSpots;
  final double monthlyFee;
  final double extraordinaryFee;
  final bool isActive;
  final ResidentInfo? resident;
  final String? residentStatus;

  const Unit({
    required this.id,
    required this.number,
    this.block,
    this.floor,
    required this.type,
    this.area,
    this.bedrooms,
    this.bathrooms,
    required this.hasParking,
    required this.parkingSpots,
    required this.monthlyFee,
    required this.extraordinaryFee,
    required this.isActive,
    this.resident,
    this.residentStatus,
  });

  String get displayNumber => block != null ? '$block-$number' : number;
  bool get hasResident => resident != null;

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
    id: json['id'],
    number: json['number'],
    block: json['block'],
    floor: json['floor'],
    type: json['type'] ?? 'HOUSE',
    area: json['area'] != null ? (json['area'] as num).toDouble() : null,
    bedrooms: json['bedrooms'],
    bathrooms: json['bathrooms'] != null ? (json['bathrooms'] as num).toDouble() : null,
    hasParking: json['hasParking'] ?? false,
    parkingSpots: json['parkingSpots'] ?? 0,
    monthlyFee: (json['monthlyFee'] as num).toDouble(),
    extraordinaryFee: (json['extraordinaryFee'] as num).toDouble(),
    isActive: json['isActive'] ?? true,
    resident: json['resident'] != null ? ResidentInfo.fromJson(json['resident']) : null,
    residentStatus: json['residentStatus'],
  );

  @override
  List<Object?> get props => [id, number, block, floor];
}

class ResidentInfo extends Equatable {
  final String id;
  final String userId;
  final UserInfo user;
  final ResidentStatus status;

  const ResidentInfo({required this.id, required this.userId, required this.user, required this.status});

  factory ResidentInfo.fromJson(Map<String, dynamic> json) => ResidentInfo(
    id: json['id'],
    userId: json['userId'],
    user: UserInfo.fromJson(json['user']),
    status: ResidentStatus.values.firstWhere((e) => e.name.toLowerCase() == json['status'].toLowerCase()),
  );

  @override
  List<Object?> get props => [id, userId, status];
}

class UserInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;

  const UserInfo({required this.id, required this.firstName, required this.lastName, this.email, this.phone});
  String get fullName => '$firstName $lastName';

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: json['id'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    email: json['email'],
    phone: json['phone'],
  );

  @override
  List<Object?> get props => [id, firstName, lastName];
}

enum ResidentStatus { active, inactive, pending, suspended }