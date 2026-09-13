import 'package:equatable/equatable.dart';
import 'user.dart';

enum BookingStatus { pending, confirmed, cancelled, completed, rejected }

class Booking extends Equatable {
  final String id;
  final String amenityId;
  final AmenityInfo amenity;
  final String unitId;
  final UnitInfo unit;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final double totalPrice;
  final int guestsCount;
  final String? notes;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.amenityId,
    required this.amenity,
    required this.unitId,
    required this.unit,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalPrice,
    required this.guestsCount,
    this.notes,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  double get durationHours => endTime.difference(startTime).inMinutes / 60;
  String get formattedPrice => '\$${totalPrice.toStringAsFixed(2)} MXN';
  bool get canCancel => status == BookingStatus.pending || status == BookingStatus.confirmed;
  bool get isUpcoming => startTime.isAfter(DateTime.now());

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'],
    amenityId: json['amenityId'],
    amenity: AmenityInfo.fromJson(json['amenity']),
    unitId: json['unitId'],
    unit: UnitInfo.fromJson(json['unit']),
    userId: json['userId'],
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    status: BookingStatus.values.firstWhere((e) => e.name.toLowerCase() == json['status'].toLowerCase()),
    totalPrice: (json['totalPrice'] as num).toDouble(),
    guestsCount: json['guestsCount'] ?? 1,
    notes: json['notes'],
    approvedBy: json['approvedBy'],
    approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
    rejectionReason: json['rejectionReason'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  @override
  List<Object?> get props => [id, amenityId, startTime, endTime, status];
}

class AmenityInfo extends Equatable {
  final String id;
  final String name;
  final String? location;
  final double pricePerHour;
  final String? rules;

  const AmenityInfo({required this.id, required this.name, this.location, required this.pricePerHour, this.rules});

  factory AmenityInfo.fromJson(Map<String, dynamic> json) => AmenityInfo(
    id: json['id'],
    name: json['name'],
    location: json['location'],
    pricePerHour: (json['pricePerHour'] as num).toDouble(),
    rules: json['rules'],
  );

  @override
  List<Object?> get props => [id, name];
}

class BookingSlot extends Equatable {
  final DateTime start;
  final DateTime end;
  final bool available;

  const BookingSlot({required this.start, required this.end, required this.available});

  factory BookingSlot.fromJson(Map<String, dynamic> json) => BookingSlot(
    start: DateTime.parse(json['start']),
    end: DateTime.parse(json['end']),
    available: json['available'] ?? false,
  );

  @override
  List<Object?> get props => [start, end, available];
}