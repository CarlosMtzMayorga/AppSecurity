import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/payment.dart';
import '../models/notice.dart';
import '../models/booking.dart';
import '../models/service.dart';
import '../models/accounting.dart';
import '../models/dashboard.dart';
import '../models/unit.dart';
import '../models/amenity.dart';

class PaymentApi extends BaseApi {
  Future<PaginatedResponse<Payment>> getPayments({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? residentId,
    String? unitId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) params['status'] = status;
    if (type != null) params['type'] = type;
    if (residentId != null) params['residentId'] = residentId;
    if (unitId != null) params['unitId'] = unitId;
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    final response = await dio.get('/payments', queryParameters: params);
    return PaginatedResponse.fromJson(response.data, Payment.fromJson);
  }

  Future<List<Payment>> getMyPayments() async {
    final response = await dio.get('/payments/my-payments');
    return (response.data as List).map(Payment.fromJson).toList();
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
    return (response.data['payments'] as List).map(Payment.fromJson).toList();
  }

  Future<String> createStripeIntent(String paymentId) async {
    final response = await dio.post('/payments/$paymentId/stripe-intent');
    return response.data['clientSecret'];
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
  Future<PaginatedResponse<Notice>> getNotices({
    int page = 1,
    int limit = 20,
    String? type,
    bool? isPinned,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null) params['type'] = type;
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
    return (response.data as List).map(Booking.fromJson).toList();
  }

  Future<List<BookingSlot>> getAvailability(String amenityId, {DateTime? date}) async {
    final params = <String, dynamic>{};
    if (date != null) params['date'] = date.toIso8601String().split('T')[0];
    final response = await dio.get('/bookings/availability/$amenityId', queryParameters: params);
    return (response.data['slots'] as List).map(BookingSlot.fromJson).toList();
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
}

class ServiceApi extends BaseApi {
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
    return (response.data as List).map(ServiceRequest.fromJson).toList();
  }

  Future<List<ServiceRequest>> getAssignedRequests() async {
    final response = await dio.get('/services/assigned');
    return (response.data as List).map(ServiceRequest.fromJson).toList();
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
}