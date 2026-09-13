import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';
import 'api_providers.dart';
import '../models/accounting.dart';
import '../models/dashboard.dart';
import '../models/unit.dart';
import '../models/amenity.dart';

class AccountingApi extends BaseApi {
  AccountingApi(ApiClient api) : super(api);
  Future<PaginatedResponse<AccountingEntry>> getEntries({
    int page = 1,
    int limit = 20,
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null) params['type'] = type;
    if (category != null) params['category'] = category;
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    final response = await dio.get('/accounting', queryParameters: params);
    return PaginatedResponse.fromJson(response.data, AccountingEntry.fromJson);
  }

  Future<AccountingSummary> getSummary({DateTime? startDate, DateTime? endDate}) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();
    final response = await dio.get('/accounting/summary', queryParameters: params);
    return AccountingSummary.fromJson(response.data);
  }

  Future<List<MonthlyFinance>> getMonthly(int year) async {
    final response = await dio.get('/accounting/monthly', queryParameters: {'year': year});
    return (response.data as List).map((e) => MonthlyFinance.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AccountingEntry> getEntry(String id) async {
    final response = await dio.get('/accounting/$id');
    return AccountingEntry.fromJson(response.data);
  }

  Future<AccountingEntry> createEntry(Map<String, dynamic> data) async {
    final response = await dio.post('/accounting', data: data);
    return AccountingEntry.fromJson(response.data);
  }

  Future<AccountingEntry> updateEntry(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/accounting/$id', data: data);
    return AccountingEntry.fromJson(response.data);
  }

  Future<void> deleteEntry(String id) async {
    await dio.delete('/accounting/$id');
  }
}

class DashboardApi extends BaseApi {
  DashboardApi(ApiClient api) : super(api);
  Future<DashboardOverview> getOverview({DateTime? startDate, DateTime? endDate}) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();
    final response = await dio.get('/dashboard/overview', queryParameters: params);
    return DashboardOverview.fromJson(response.data);
  }

  Future<RecentActivity> getRecentActivity() async {
    final response = await dio.get('/dashboard/recent-activity');
    return RecentActivity.fromJson(response.data);
  }

  Future<List<TrendPoint>> getPaymentTrends({int months = 6}) async {
    final response = await dio.get('/dashboard/payment-trends', queryParameters: {'months': months});
    return (response.data as List).map((e) => TrendPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TrendPoint>> getAccessTrends({int days = 30}) async {
    final response = await dio.get('/dashboard/access-trends', queryParameters: {'days': days});
    return (response.data as List).map((e) => TrendPoint.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class UnitApi extends BaseApi {
  UnitApi(ApiClient api) : super(api);
  Future<PaginatedResponse<Unit>> getUnits({
    int page = 1,
    int limit = 20,
    String? block,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (block != null) params['block'] = block;
    final response = await dio.get('/units', queryParameters: params);
    return PaginatedResponse.fromJson(response.data, Unit.fromJson);
  }

  Future<List<String>> getBlocks() async {
    final response = await dio.get('/units/blocks');
    return List<String>.from(response.data);
  }

  Future<Unit> getUnit(String id) async {
    final response = await dio.get('/units/$id');
    return Unit.fromJson(response.data);
  }

  Future<Unit> createUnit(Map<String, dynamic> data) async {
    final response = await dio.post('/units', data: data);
    return Unit.fromJson(response.data);
  }

  Future<Unit> updateUnit(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/units/$id', data: data);
    return Unit.fromJson(response.data);
  }

  Future<void> deleteUnit(String id) async {
    await dio.delete('/units/$id');
  }
}

class AmenityApi extends BaseApi {
  AmenityApi(ApiClient api) : super(api);
  Future<PaginatedResponse<Amenity>> getAmenities({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dio.get('/amenities', queryParameters: {'page': page, 'limit': limit});
    return PaginatedResponse.fromJson(response.data, Amenity.fromJson);
  }

  Future<Amenity> getAmenity(String id) async {
    final response = await dio.get('/amenities/$id');
    return Amenity.fromJson(response.data);
  }

  Future<Amenity> createAmenity(Map<String, dynamic> data) async {
    final response = await dio.post('/amenities', data: data);
    return Amenity.fromJson(response.data);
  }

  Future<Amenity> updateAmenity(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/amenities/$id', data: data);
    return Amenity.fromJson(response.data);
  }

  Future<void> deleteAmenity(String id) async {
    await dio.delete('/amenities/$id');
  }
}

class ConfigApi extends BaseApi {
  ConfigApi(ApiClient api) : super(api);
  Future<ComplexConfig> getComplexConfig() async {
    final response = await dio.get('/config/complex');
    return ComplexConfig.fromJson(response.data);
  }

  Future<ComplexConfig> updateComplexConfig(Map<String, dynamic> data) async {
    final response = await dio.patch('/config/complex', data: data);
    return ComplexConfig.fromJson(response.data);
  }

  Future<AccessConfig> getAccessConfig() async {
    final response = await dio.get('/config/access');
    return AccessConfig.fromJson(response.data);
  }

  Future<AccessConfig> updateAccessConfig(Map<String, dynamic> data) async {
    final response = await dio.patch('/config/access', data: data);
    return AccessConfig.fromJson(response.data);
  }

  Future<ComplexSettings> getSettings() async {
    final response = await dio.get('/config/settings');
    return ComplexSettings.fromJson(response.data ?? {});
  }

  Future<ComplexSettings> updateSettings(Map<String, dynamic> data) async {
    final response = await dio.patch('/config/settings', data: data);
    return ComplexSettings.fromJson(response.data);
  }

  Future<String?> getStripePublishableKey() async {
    final response = await dio.get('/config/stripe-config');
    return response.data['publishableKey'];
  }
}

class ComplexConfig extends Equatable {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String phone;
  final String email;
  final String? logoUrl;
  final AccessConfig? accessConfig;
  final ComplexSettings? settings;

  const ComplexConfig({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.phone,
    required this.email,
    this.logoUrl,
    this.accessConfig,
    this.settings,
  });

  factory ComplexConfig.fromJson(Map<String, dynamic> json) => ComplexConfig(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    city: json['city'],
    state: json['state'],
    postalCode: json['postalCode'],
    phone: json['phone'] ?? '',
    email: json['email'] ?? '',
    logoUrl: json['logoUrl'],
    accessConfig: json['accessConfig'] != null ? AccessConfig.fromJson(json['accessConfig']) : null,
    settings: json['settings'] != null ? ComplexSettings.fromJson(json['settings']) : null,
  );

  @override
  List<Object?> get props => [id, name, address, city, state, postalCode];
}

class AccessConfig extends Equatable {
  final int maxVisitorHours;
  final bool requirePhoto;
  final bool requireDocument;
  final bool allowRecurring;
  final bool faceRecognition;
  final bool plateRecognition;

  const AccessConfig({
    required this.maxVisitorHours,
    required this.requirePhoto,
    required this.requireDocument,
    required this.allowRecurring,
    required this.faceRecognition,
    required this.plateRecognition,
  });

  factory AccessConfig.fromJson(Map<String, dynamic> json) => AccessConfig(
    maxVisitorHours: json['maxVisitorHours'] ?? 4,
    requirePhoto: json['requirePhoto'] ?? true,
    requireDocument: json['requireDocument'] ?? false,
    allowRecurring: json['allowRecurring'] ?? true,
    faceRecognition: json['faceRecognition'] ?? false,
    plateRecognition: json['plateRecognition'] ?? false,
  );

  @override
  List<Object?> get props => [maxVisitorHours, requirePhoto, requireDocument, allowRecurring, faceRecognition, plateRecognition];
}

class ComplexSettings extends Equatable {
  final double maintenanceFee;
  final double extraordinaryFee;
  final double lateFeePercent;
  final int lateFeeGraceDays;
  final bool allowPartialPayment;
  final bool requirePaymentApproval;
  final List<int> notifyPaymentDueDays;
  final bool notifyNewVisitor;
  final bool notifyAccessEntry;
  final bool notifyServiceUpdates;

  const ComplexSettings({
    required this.maintenanceFee,
    required this.extraordinaryFee,
    required this.lateFeePercent,
    required this.lateFeeGraceDays,
    required this.allowPartialPayment,
    required this.requirePaymentApproval,
    required this.notifyPaymentDueDays,
    required this.notifyNewVisitor,
    required this.notifyAccessEntry,
    required this.notifyServiceUpdates,
  });

  factory ComplexSettings.fromJson(Map<String, dynamic> json) => ComplexSettings(
    maintenanceFee: (json['maintenanceFee'] ?? 0).toDouble(),
    extraordinaryFee: (json['extraordinaryFee'] ?? 0).toDouble(),
    lateFeePercent: (json['lateFeePercent'] ?? 5).toDouble(),
    lateFeeGraceDays: json['lateFeeGraceDays'] ?? 5,
    allowPartialPayment: json['allowPartialPayment'] ?? true,
    requirePaymentApproval: json['requirePaymentApproval'] ?? false,
    notifyPaymentDueDays: List<int>.from(json['notifyPaymentDueDays'] ?? [7, 3, 1]),
    notifyNewVisitor: json['notifyNewVisitor'] ?? true,
    notifyAccessEntry: json['notifyAccessEntry'] ?? false,
    notifyServiceUpdates: json['notifyServiceUpdates'] ?? true,
  );

  @override
  List<Object?> get props => [maintenanceFee, extraordinaryFee, lateFeePercent];
}