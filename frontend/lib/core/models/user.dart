import 'package:equatable/equatable.dart';

enum UserRole { admin, resident, security, committee }

class User extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final String? complexId;
  final String? residentStatus;
  final UnitInfo? unit;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.complexId,
    this.residentStatus,
    this.unit,
    this.lastLoginAt,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      role: UserRole.values.firstWhere((e) => e.name.toUpperCase() == json['role']),
      complexId: json['complexId'],
      residentStatus: json['residentStatus'],
      unit: json['unit'] != null ? UnitInfo.fromJson(json['unit']) : null,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'role': role.name.toUpperCase(),
    'complexId': complexId,
    'residentStatus': residentStatus,
    'unit': unit?.toJson(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, email, firstName, lastName, role, complexId];
}

class UnitInfo extends Equatable {
  final String id;
  final String number;
  final String? block;
  final int? floor;

  const UnitInfo({required this.id, required this.number, this.block, this.floor});

  String get displayNumber => block != null ? '$block-$number' : number;

  factory UnitInfo.fromJson(Map<String, dynamic> json) => UnitInfo(
    id: json['id'],
    number: json['number'],
    block: json['block'],
    floor: json['floor'],
  );

  Map<String, dynamic> toJson() => {'id': id, 'number': number, 'block': block, 'floor': floor};

  @override
  List<Object?> get props => [id, number, block, floor];
}