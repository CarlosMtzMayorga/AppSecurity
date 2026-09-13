class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? meta;

  const ApiResponse.success(this.data, {this.meta}) : error = null, statusCode = 200;
  const ApiResponse.error(this.error, {this.statusCode, this.meta}) : data = null;

  bool get isSuccess => error == null;
  bool get isError => error != null;
}

class PaginatedResponse<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return PaginatedResponse(
      data: (json['data'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      page: json['pagination']['page'] ?? 1,
      limit: json['pagination']['limit'] ?? 20,
      total: json['pagination']['total'] ?? 0,
      totalPages: json['pagination']['totalPages'] ?? 0,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}