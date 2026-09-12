import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import '../models/user.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final storageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
));

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider), ref.read(storageProvider));
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) => AuthState(
    user: user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._api, this._storage) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (_api.isAuthenticated) {
      try {
        await _loadUser();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> _loadUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.dio.get('/auth/me');
      final user = User.fromJson(response.data['user']);
      state = state.copyWith(user: user, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      await logout();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.post('/auth/login', data: {'email': email, 'password': password});
      await _api.setTokens(response.data['accessToken'], response.data['refreshToken']);
      final user = User.fromJson(response.data['user']);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? complexId,
    String? unitNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'complexId': complexId,
        'unitNumber': unitNumber,
      });
      await _api.setTokens(response.data['accessToken'], response.data['refreshToken']);
      final user = User.fromJson(response.data['user']);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    await _api.clearTokens();
    state = const AuthState();
  }

  Future<void> changePassword(String current, String next) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.dio.post('/auth/change-password', data: {'currentPassword': current, 'newPassword': next});
      await _api.clearTokens();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      rethrow;
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      return e.response?.data['error'] ?? e.message ?? 'Error desconocido';
    }
    return e.toString();
  }
}