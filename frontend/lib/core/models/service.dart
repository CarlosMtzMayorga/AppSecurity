import 'package:equatable/equatable.dart';
import 'user.dart';

enum ServiceRequestPriority { low, medium, high, urgent }
enum ServiceRequestStatus { open, inProgress, resolved, closed, rejected }

class ServiceRequest extends Equatable {
  final String id;
  final String unitId;
  final UnitInfo unit;
  final String userId;
  final UserInfo user;
  final String? assigneeId;
  final UserInfo? assignee;
  final String title;
  final String description;
  final String category;
  final ServiceRequestPriority priority;
  final ServiceRequestStatus status;
  final List<String> images;
  final double? estimatedCost;
  final double? actualCost;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final String? resolutionNotes;
  final int? rating;
  final String? feedback;
  final DateTime createdAt;

  const ServiceRequest({
    required this.id,
    required this.unitId,
    required this.unit,
    required this.userId,
    required this.user,
    this.assigneeId,
    this.assignee,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.images = const [],
    this.estimatedCost,
    this.actualCost,
    this.scheduledAt,
    this.startedAt,
    this.resolvedAt,
    this.closedAt,
    this.resolutionNotes,
    this.rating,
    this.feedback,
    required this.createdAt,
  });

  String get priorityLabel {
    switch (priority) {
      case ServiceRequestPriority.low: return 'Baja';
      case ServiceRequestPriority.medium: return 'Media';
      case ServiceRequestPriority.high: return 'Alta';
      case ServiceRequestPriority.urgent: return 'Urgente';
    }
  }

  String get statusLabel {
    switch (status) {
      case ServiceRequestStatus.open: return 'Abierta';
      case ServiceRequestStatus.inProgress: return 'En Progreso';
      case ServiceRequestStatus.resolved: return 'Resuelta';
      case ServiceRequestStatus.closed: return 'Cerrada';
      case ServiceRequestStatus.rejected: return 'Rechazada';
    }
  }

  factory ServiceRequest.fromJson(Map<String, dynamic> json) => ServiceRequest(
    id: json['id'],
    unitId: json['unitId'],
    unit: UnitInfo.fromJson(json['unit']),
    userId: json['userId'],
    user: UserInfo.fromJson(json['user']),
    assigneeId: json['assigneeId'],
    assignee: json['assignee'] != null ? UserInfo.fromJson(json['assignee']) : null,
    title: json['title'],
    description: json['description'],
    category: json['category'],
    priority: ServiceRequestPriority.values.firstWhere((e) => e.name.toLowerCase() == json['priority'].toLowerCase()),
    status: ServiceRequestStatus.values.firstWhere((e) => e.name.toLowerCase().replaceAll('_', '') == json['status'].toLowerCase()),
    images: List<String>.from(json['images'] ?? []),
    estimatedCost: json['estimatedCost'] != null ? (json['estimatedCost'] as num).toDouble() : null,
    actualCost: json['actualCost'] != null ? (json['actualCost'] as num).toDouble() : null,
    scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
    startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
    resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt']) : null,
    resolutionNotes: json['resolutionNotes'],
    rating: json['rating'],
    feedback: json['feedback'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  @override
  List<Object?> get props => [id, title, status, priority];
}

class UserInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;

  const UserInfo({required this.id, required this.firstName, required this.lastName, this.phone, this.email});
  String get fullName => '$firstName $lastName';

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: json['id'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    phone: json['phone'],
    email: json['email'],
  );

  @override
  List<Object?> get props => [id, firstName, lastName];
}

class ServiceRequestSummary extends Equatable {
  final int total;
  final int open;
  final int inProgress;
  final int resolved;
  final int closed;
  final List<PriorityCount> byPriority;
  final List<CategoryCount> byCategory;

  const ServiceRequestSummary({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.resolved,
    required this.closed,
    required this.byPriority,
    required this.byCategory,
  });

  factory ServiceRequestSummary.fromJson(Map<String, dynamic> json) => ServiceRequestSummary(
    total: json['total'] ?? 0,
    open: json['open'] ?? 0,
    inProgress: json['inProgress'] ?? 0,
    resolved: json['resolved'] ?? 0,
    closed: json['closed'] ?? 0,
    byPriority: (json['byPriority'] as List).map((e) => PriorityCount.fromJson(e)).toList(),
    byCategory: (json['byCategory'] as List).map((e) => CategoryCount.fromJson(e)).toList(),
  );

  @override
  List<Object?> get props => [total, open, inProgress, resolved, closed];
}

class PriorityCount extends Equatable {
  final ServiceRequestPriority priority;
  final int count;
  const PriorityCount({required this.priority, required this.count});
  factory PriorityCount.fromJson(Map<String, dynamic> json) => PriorityCount(
    priority: ServiceRequestPriority.values.firstWhere((e) => e.name.toLowerCase() == json['priority'].toLowerCase()),
    count: json['count'] ?? 0,
  );
  @override List<Object?> get props => [priority, count];
}

class CategoryCount extends Equatable {
  final String category;
  final int count;
  const CategoryCount({required this.category, required this.count});
  factory CategoryCount.fromJson(Map<String, dynamic> json) => CategoryCount(category: json['category'], count: json['count'] ?? 0);
  @override List<Object?> get props => [category, count];
}