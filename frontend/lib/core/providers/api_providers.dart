import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../network/api_client.dart';
import '../network/api_response.dart';
import 'app_providers.dart';
import '../models/resident.dart';
import '../models/access.dart';
import '../models/payment.dart';
import '../models/notice.dart';
import '../models/booking.dart';
import '../models/service.dart';
import '../models/accounting.dart';
import '../models/dashboard.dart';
import '../models/unit.dart';
import '../models/amenity.dart';
import '../services/stripe_checkout.dart';
import 'api_providers_part2.dart';
import 'api_providers_part3.dart';

export 'api_providers_part2.dart';
export 'api_providers_part3.dart';

final stripeCheckoutProvider = Provider<StripeCheckoutService>((ref) {
  return StripeCheckoutService(
    paymentApi: ref.read(paymentApiProvider),
    configApi: ref.read(configApiProvider),
  );
});

final residentApiProvider = Provider<ResidentApi>((ref) => ResidentApi(ref.read(apiClientProvider)));
final visitorApiProvider = Provider<VisitorApi>((ref) => VisitorApi(ref.read(apiClientProvider)));
final accessApiProvider = Provider<AccessApi>((ref) => AccessApi(ref.read(apiClientProvider)));
final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.read(apiClientProvider)));
final paymentApiProvider = Provider<PaymentApi>((ref) => PaymentApi(ref.read(apiClientProvider)));
final noticeApiProvider = Provider<NoticeApi>((ref) => NoticeApi(ref.read(apiClientProvider)));
final bookingApiProvider = Provider<BookingApi>((ref) => BookingApi(ref.read(apiClientProvider)));
final serviceApiProvider = Provider<ServiceApi>((ref) => ServiceApi(ref.read(apiClientProvider)));
final accountingApiProvider = Provider<AccountingApi>((ref) => AccountingApi(ref.read(apiClientProvider)));
final dashboardApiProvider = Provider<DashboardApi>((ref) => DashboardApi(ref.read(apiClientProvider)));
final unitApiProvider = Provider<UnitApi>((ref) => UnitApi(ref.read(apiClientProvider)));
final amenityApiProvider = Provider<AmenityApi>((ref) => AmenityApi(ref.read(apiClientProvider)));
final configApiProvider = Provider<ConfigApi>((ref) => ConfigApi(ref.read(apiClientProvider)));

class BaseApi {
  final ApiClient _api;
  BaseApi(this._api);
  Dio get dio => _api.dio;
}

class ResidentApi extends BaseApi {
  ResidentApi(ApiClient api) : super(api);
  Future<PaginatedResponse<Resident>> getResidents({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    final response = await dio.get('/residents', queryParameters: {'page': page, 'limit': limit, 'status': status, 'search': search});
    return PaginatedResponse.fromJson(response.data, Resident.fromJson);
  }

  Future<ResidentStats> getStats() async {
    final response = await dio.get('/residents/stats');
    return ResidentStats.fromJson(response.data);
  }

  Future<Resident> getResident(String id) async {
    final response = await dio.get('/residents/$id');
    return Resident.fromJson(response.data);
  }

  Future<Resident> createResident(Map<String, dynamic> data) async {
    final response = await dio.post('/residents', data: data);
    return Resident.fromJson(response.data);
  }

  Future<Resident> updateResident(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/residents/$id', data: data);
    return Resident.fromJson(response.data);
  }

  Future<void> deleteResident(String id) async {
    await dio.delete('/residents/$id');
  }

  Future<Resident> approveResident(String id) async {
    final response = await dio.post('/residents/$id/approve');
    return Resident.fromJson(response.data);
  }

  Future<String> generateQrCode(String id) async {
    final response = await dio.post('/residents/$id/qr-code');
    return response.data['qrCode'];
  }
}

class VisitorApi extends BaseApi {
  VisitorApi(ApiClient api) : super(api);
  Future<PaginatedResponse<Visitor>> getVisitors({
    int page = 1,
    int limit = 20,
    String? residentId,
    String? search,
  }) async {
    final response = await dio.get('/visitors', queryParameters: {'page': page, 'limit': limit, 'residentId': residentId, 'search': search});
    return PaginatedResponse.fromJson(response.data, Visitor.fromJson);
  }

  Future<List<Visitor>> getMyVisitors() async {
    final response = await dio.get('/visitors/my-visitors');
    return (response.data as List).map((e) => Visitor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Visitor> getVisitor(String id) async {
    final response = await dio.get('/visitors/$id');
    return Visitor.fromJson(response.data);
  }

  Future<Visitor> createVisitor(Map<String, dynamic> data) async {
    final response = await dio.post('/visitors', data: data);
    return Visitor.fromJson(response.data);
  }

  Future<Visitor> updateVisitor(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/visitors/$id', data: data);
    return Visitor.fromJson(response.data);
  }

  Future<void> deleteVisitor(String id) async {
    await dio.delete('/visitors/$id');
  }
}

class AccessApi extends BaseApi {
  AccessApi(ApiClient api) : super(api);
  Future<PaginatedResponse<AccessLog>> getAccessLogs({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
    String? unitId,
    String? residentId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;
    if (unitId != null) params['unitId'] = unitId;
    if (residentId != null) params['residentId'] = residentId;
    if (search != null) params['search'] = search;
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    final response = await dio.get('/access', queryParameters: params);
    return PaginatedResponse.fromJson(response.data, AccessLog.fromJson);
  }

  Future<List<AccessLog>> getActiveAccesses() async {
    final response = await dio.get('/access/active');
    return (response.data as List).map((e) => AccessLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AccessLog> getAccessLog(String id) async {
    final response = await dio.get('/access/$id');
    return AccessLog.fromJson(response.data);
  }

  Future<AccessLog> createAccessLog(Map<String, dynamic> data) async {
    final response = await dio.post('/access', data: data);
    return AccessLog.fromJson(response.data);
  }

  Future<AccessLog> residentEntry() async {
    final response = await dio.post('/access/resident-entry');
    return AccessLog.fromJson(response.data);
  }

  Future<AccessLog> residentExit() async {
    final response = await dio.post('/access/resident-exit');
    return AccessLog.fromJson(response.data);
  }

  Future<AccessLog> peatonalEntry() async {
    final response = await dio.post('/access/peatonal');
    return AccessLog.fromJson(response.data);
  }

  Future<void> openBotonera() async {
    await dio.post('/access/botonera');
  }

  Future<AccessLog> approveAccess(String id, {required String status, String? notes}) async {
    final response = await dio.patch('/access/$id/approve', data: {'status': status, 'notes': notes});
    return AccessLog.fromJson(response.data);
  }

  Future<AccessLog> registerExit(String id) async {
    final response = await dio.patch('/access/$id/exit');
    return AccessLog.fromJson(response.data);
  }

  Future<AccessStats> getStats({DateTime? startDate, DateTime? endDate}) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();
    final response = await dio.get('/access/stats/summary', queryParameters: params);
    return AccessStats.fromJson(response.data);
  }
}

class AccessStats {
  final int total;
  final int residents;
  final int visitors;
  final int services;
  final int deliveries;
  final int active;
  AccessStats({required this.total, required this.residents, required this.visitors, required this.services, required this.deliveries, required this.active});
  factory AccessStats.fromJson(Map<String, dynamic> json) => AccessStats(
    total: json['total'] ?? 0,
    residents: json['residents'] ?? 0,
    visitors: json['visitors'] ?? 0,
    services: json['services'] ?? 0,
    deliveries: json['deliveries'] ?? 0,
    active: json['active'] ?? 0,
  );
}

class AuthApi extends BaseApi {
  AuthApi(ApiClient api) : super(api);
  Future<Map<String, dynamic>> getMe() async {
    final response = await dio.get('/auth/me');
    return response.data['user'];
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await dio.patch('/auth/me', data: data);
    return response.data['user'];
  }

  Future<Map<String, dynamic>> uploadAvatar(Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await dio.post('/auth/avatar', data: formData);
    return response.data['user'];
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await dio.post('/auth/change-password', data: {'currentPassword': currentPassword, 'newPassword': newPassword});
  }
}