import 'package:equatable/equatable.dart';

enum NoticeType { general, urgent, maintenance, event, security, financial }

class Notice extends Equatable {
  final String id;
  final String title;
  final String content;
  final NoticeType type;
  final int priority;
  final bool isPinned;
  final DateTime publishAt;
  final DateTime? expiresAt;
  final List<String> attachmentUrls;
  final List<UserRole> targetRoles;
  final List<String> targetUnits;
  final List<String> readBy;
  final AuthorInfo author;
  final DateTime createdAt;

  const Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
    required this.isPinned,
    required this.publishAt,
    this.expiresAt,
    this.attachmentUrls = const [],
    this.targetRoles = const [],
    this.targetUnits = const [],
    this.readBy = const [],
    required this.author,
    required this.createdAt,
  });

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isPublished => publishAt.isBefore(DateTime.now());
  bool get isVisible => isPublished && !isExpired;

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    type: NoticeType.values.firstWhere((e) => e.name.toLowerCase() == json['type'].toLowerCase()),
    priority: json['priority'] ?? 0,
    isPinned: json['isPinned'] ?? false,
    publishAt: DateTime.parse(json['publishAt']),
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    attachmentUrls: List<String>.from(json['attachmentUrls'] ?? []),
    targetRoles: (json['targetRoles'] as List?)?.map((r) => UserRole.values.firstWhere((e) => e.name.toUpperCase() == r)).toList() ?? [],
    targetUnits: List<String>.from(json['targetUnits'] ?? []),
    readBy: List<String>.from(json['readBy'] ?? []),
    author: AuthorInfo.fromJson(json['author']),
    createdAt: DateTime.parse(json['createdAt']),
  );

  @override
  List<Object?> get props => [id, title, type, publishAt];
}

class AuthorInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;

  const AuthorInfo({required this.id, required this.firstName, required this.lastName});
  String get fullName => '$firstName $lastName';

  factory AuthorInfo.fromJson(Map<String, dynamic> json) => AuthorInfo(
    id: json['id'],
    firstName: json['firstName'],
    lastName: json['lastName'],
  );

  @override
  List<Object?> get props => [id, firstName, lastName];
}