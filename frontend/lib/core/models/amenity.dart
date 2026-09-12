import 'package:equatable/equatable.dart';

class Amenity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int capacity;
  final String? location;
  final double pricePerHour;
  final String currency;
  final bool requiresApproval;
  final int maxHoursPerBooking;
  final int minHoursNotice;
  final int maxDaysAdvance;
  final bool isActive;
  final List<String> images;
  final String? rules;
  final List<AmenitySchedule> schedules;

  const Amenity({
    required this.id,
    required this.name,
    this.description,
    required this.capacity,
    this.location,
    required this.pricePerHour,
    required this.currency,
    required this.requiresApproval,
    required this.maxHoursPerBooking,
    required this.minHoursNotice,
    required this.maxDaysAdvance,
    required this.isActive,
    this.images = const [],
    this.rules,
    this.schedules = const [],
  });

  factory Amenity.fromJson(Map<String, dynamic> json) => Amenity(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    capacity: json['capacity'],
    location: json['location'],
    pricePerHour: (json['pricePerHour'] as num).toDouble(),
    currency: json['currency'] ?? 'MXN',
    requiresApproval: json['requiresApproval'] ?? true,
    maxHoursPerBooking: json['maxHoursPerBooking'] ?? 4,
    minHoursNotice: json['minHoursNotice'] ?? 1,
    maxDaysAdvance: json['maxDaysAdvance'] ?? 30,
    isActive: json['isActive'] ?? true,
    images: List<String>.from(json['images'] ?? []),
    rules: json['rules'],
    schedules: (json['schedules'] as List?)?.map((s) => AmenitySchedule.fromJson(s)).toList() ?? [],
  );

  bool isOpenAt(DateTime dateTime) {
    final dayOfWeek = dateTime.weekday % 7; // 0=Sun, 6=Sat
    final schedule = schedules.firstWhere(
      (s) => s.dayOfWeek == dayOfWeek && !s.isClosed,
      orElse: () => const AmenitySchedule(dayOfWeek: -1, openTime: '', closeTime: '', isClosed: true),
    );
    if (schedule.isClosed || schedule.dayOfWeek == -1) return false;

    final timeMinutes = dateTime.hour * 60 + dateTime.minute;
    final openMinutes = _timeToMinutes(schedule.openTime);
    final closeMinutes = _timeToMinutes(schedule.closeTime);
    return timeMinutes >= openMinutes && timeMinutes < closeMinutes;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  List<Object?> get props => [id, name, capacity, pricePerHour];
}

class AmenitySchedule extends Equatable {
  final int dayOfWeek; // 0=Sun, 6=Sat
  final String openTime; // HH:MM
  final String closeTime; // HH:MM
  final bool isClosed;

  const AmenitySchedule({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.isClosed,
  });

  factory AmenitySchedule.fromJson(Map<String, dynamic> json) => AmenitySchedule(
    dayOfWeek: json['dayOfWeek'],
    openTime: json['openTime'],
    closeTime: json['closeTime'],
    isClosed: json['isClosed'] ?? false,
  );

  String get dayName => ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'][dayOfWeek];

  @override
  List<Object?> get props => [dayOfWeek, openTime, closeTime, isClosed];
}