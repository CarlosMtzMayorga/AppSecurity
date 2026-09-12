import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;
  late final FlutterSecureStorage _storage;
  String? _accessToken;
  String? _refreshToken;

  Dio get dio => _dio;

  Future<void> initialize() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    );

    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      compact: true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          try {
            await _refreshAccessToken();
            if (_accessToken != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
              final retry = await _dio.fetch(error.requestOptions);
              return handler.resolve(retry);
            }
          } catch (e) {
            await _clearTokens();
          }
        }
        return handler.next(error);
      },
    ));

    await _loadTokens();
  }

  Future<void> _loadTokens() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
  }

  Future<void> _saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<void> _refreshAccessToken() async {
    final response = await _dio.post('/auth/refresh', data: {'refreshToken': _refreshToken});
    final data = response.data;
    await _saveTokens(data['accessToken'], data['refreshToken']);
  }

  Future<void> setTokens(String access, String refresh) => _saveTokens(access, refresh);
  Future<void> clearTokens() => _clearTokens();
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;
}