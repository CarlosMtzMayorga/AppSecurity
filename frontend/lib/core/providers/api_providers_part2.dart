import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';
import 'api_providers.dart';
import '../models/payment.dart';
import '../models/notice.dart';
import '../models/booking.dart';
import '../models/service.dart';
import '../models/accounting.dart';
import '../models/dashboard.dart';
import '../models/unit.dart';
import '../models/amenity.dart';

class PaymentApi extends BaseApi {
  PaymentApi(ApiClient api) : super(api);
  Future<PaginatedResponse<Payment>> getPayments({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? residentId,
    String? unitId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) params['status'] = status;
    if (type != null) params['type'] = type;
    if (residentId != null) params['residentId'] = residentId;
    if (unitId != null) params['unitId'] = unitId;
    if (search != null) params['search'] = search;
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    final response = await dio.get('/payments', queryParameters: params);
    return PaginatedResponse.fromJson(response.data, Payment.fromJson);
  }

  Future<List<Payment>> getMyPayments() async {
    final response = await dio.get('/payments/my-payments');
    return (response.data as List).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaymentSummary> getSummary({DateTime? startDate, DateTime? endDate}) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();
    final response = await dio.get('/payments/stats/summary', queryParameters: params);
    return PaymentSummary.fromJson(response.data);
  }

  Future<Payment> getPayment(String id) async {
    final response = await dio.get('/payments/$id');
    return Payment.fromJson(response.data);
  }

  Future<Payment> createPayment(Map<String, dynamic> data) async {
    final response = await dio.post('/payments', data: data);
    return Payment.fromJson(response.data);
  }

  Future<List<Payment>> createBulkPayments(Map<String, dynamic> data) async {
    final response = await dio.post('/payments/bulk', data: data);
    return (response.data['payments'] as List).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> createStripeIntent(String paymentId) async {
    final response = await dio.post('/payments/$paymentId/stripe-intent');
    return response.data['clientSecret'];
  }

  Future<void> payPayment(String paymentId) async {
    await dio.post('/payments/$paymentId/webhook/test');
  }

  Future<Payment> updatePayment(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/payments/$id', data: data);
    return Payment.fromJson(response.data);
  }

  Future<void> deletePayment(String id) async {
    await dio.delete('/payments/$id');
  }
}

class NoticeApi extends BaseApi {
  NoticeApi(ApiClient api) : super(api);
  Future<PaginatedResponse<Notice>> getNotices({
    int page = 1,
    int limit = 20,
    String? type,
    String? search,
    bool? isPinned,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null) params['type'] = type;
    if (search != null) params['search'] = search;
    if (isPinned != null) params['isPinned'] = isPinned;

    final response = await dio.get('/notices', queryParameters: params);
    return PaginatedResponse.fromJson(response.data, Notice.fromJson);
  }

  Future<int> getUnreadCount() async {
    final response = await dio.get('/notices/unread-count');
    return response.data['count'] ?? 0;
  }

  Future<Notice> getNotice(String id) async {
    final response = await dio.get('/notices/$id');
    return Notice.fromJson(response.data);
  }

  Future<void> markAsRead(String id) async {
    await dio.post('/notices/$id/read');
  }

  Future<Notice> createNotice(Map<String, dynamic> data) async {
    final response = await dio.post('/notices', data: data);
    return Notice.fromJson(response.data);
  }

  Future<Notice> updateNotice(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/notices/$id', data: data);
    return Notice.fromJson(response.data);
  }

  Future<void> deleteNotice(String id) async {
    await dio.delete('/notices/$id');
  }
}

class BookingApi extends BaseApi {
  BookingApi(ApiClient api) : super(api);
  Future<PaginatedResponse<Booking>> getBookings({
    int page = 1,
    int limit = 20,
    String? status,
    String? amenityId,
    String? unitId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) params['status'] = status;
    if (amenityId != null) params['amenityId'] = amenityId;
    if (unitId != null) params['unitId'] = unitId;
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    final response = await dio.get('/bookings', queryParameters: params);
    return PaginatedResponse.fromJson(response.data, Booking.fromJson);
  }

  Future<List<Booking>> getMyBookings() async {
    final response = await dio.get('/bookings/my-bookings');
    return (response.data as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BookingSlot>> getAvailability(String amenityId, {DateTime? date}) async {
    final params = <String, dynamic>{};
    if (date != null) params['date'] = date.toIso8601String().split('T')[0];
    final response = await dio.get('/bookings/availability/$amenityId', queryParameters: params);
    return (response.data['slots'] as List).map((e) => BookingSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Booking> getBooking(String id) async {
    final response = await dio.get('/bookings/$id');
    return Booking.fromJson(response.data);
  }

  Future<Booking> createBooking(Map<String, dynamic> data) async {
    final response = await dio.post('/bookings', data: data);
    return Booking.fromJson(response.data);
  }

  Future<Booking> updateBooking(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/bookings/$id', data: data);
    return Booking.fromJson(response.data);
  }

  Future<void> deleteBooking(String id) async {
    await dio.delete('/bookings/$id');
  }

  Future<Booking> cancelBooking(String id) async {
    final response = await dio.patch('/bookings/$id', data: {'status': 'CANCELLED'});
    return Booking.fromJson(response.data);
  }
}

class ServiceApi extends BaseApi {
  ServiceApi(ApiClient api) : super(api);
  Future<PaginatedResponse<ServiceRequest>> getServiceRequests({
    int page = 1,
    int limit = 20,
    String? status,
    String? priority,
    String? category,
    String? assigneeId,
    String? unitId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (category != null) params['category'] = category;
    if (assigneeId != null) params['assigneeId'] = assigneeId;
    if (unitId != null) params['unitId'] = unitId;
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    final response = await dio.get('/services', queryParameters: params);
    return PaginatedResponse.fromJson(response.data, ServiceRequest.fromJson);
  }

  Future<List<ServiceRequest>> getMyRequests() async {
    final response = await dio.get('/services/my-requests');
    return (response.data as List).map((e) => ServiceRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ServiceRequest>> getAssignedRequests() async {
    final response = await dio.get('/services/assigned');
    return (response.data as List).map((e) => ServiceRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ServiceRequestSummary> getSummary({DateTime? startDate, DateTime? endDate}) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();
    final response = await dio.get('/services/stats/summary', queryParameters: params);
    return ServiceRequestSummary.fromJson(response.data);
  }

  Future<ServiceRequest> getServiceRequest(String id) async {
    final response = await dio.get('/services/$id');
    return ServiceRequest.fromJson(response.data);
  }

  Future<ServiceRequest> createServiceRequest(Map<String, dynamic> data) async {
    final response = await dio.post('/services', data: data);
    return ServiceRequest.fromJson(response.data);
  }

  Future<ServiceRequest> updateServiceRequest(String id, Map<String, dynamic> data) async {
    final response = await dio.patch('/services/$id', data: data);
    return ServiceRequest.fromJson(response.data);
  }

  Future<void> deleteServiceRequest(String id) async {
    await dio.delete('/services/$id');
  }

  Future<ServiceRequest> rateService(String id, {required int rating, String? feedback}) async {
    final response = await dio.patch('/services/$id', data: {'rating': rating, 'feedback': feedback});
    return ServiceRequest.fromJson(response.data);
  }
}