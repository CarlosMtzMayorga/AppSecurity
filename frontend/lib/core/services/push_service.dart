import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import '../network/api_client.dart';

/// Servicio de notificaciones push (Firebase Cloud Messaging).
///
/// Se inicializa de forma perezosa: lee la configuración pública del backend
/// (GET /config/messaging) y solo activa FCM si el complejo/configuración lo
/// permite. Soporta web (VAPID + service worker) y móvil.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  GoRouter? _router;
  String? _fcmToken;
  bool _ready = false;

  bool get isEnabled => _ready && _fcmToken != null;

  void attachRouter(GoRouter router) => _router = router;

  /// Obtiene la config pública y (si hay Firebase) inicializa la app, pide
  /// permiso, obtiene el token FCM y lo registra contra el backend.
  Future<void> initialize(ApiClient api) async {
    if (_ready) return;
    final cfg = await _fetchConfig(api);
    if (cfg == null) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: cfg['options'] as FirebaseOptions);
      }

      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied ||
          permission.authorizationStatus == AuthorizationStatus.notDetermined) {
        return;
      }

      final String? token = kIsWeb
          ? await messaging.getToken(vapidKey: cfg['vapidKey'] as String? ?? '')
          : await messaging.getToken();

      if (token == null) return;

      _ready = true;
      _fcmToken = token;

      _listenForeground(messaging);
      _listenAppOpened(messaging);
      _handleInitialMessage(messaging);

      await api.dio.post('/push/tokens', data: {
        'token': token,
        'platform': kIsWeb ? 'web' : _mobilePlatform(),
        'deviceName': kIsWeb ? 'Web' : _mobilePlatform(),
      });
    } catch (e) {
      debugPrint('Push FCM: no se pudo inicializar ($e)');
    }
  }

  /// Elimina el token registrado del backend (logout).
  Future<void> unregisterFromBackend(ApiClient api) async {
    final token = _fcmToken;
    _fcmToken = null;
    _ready = false;
    if (token == null) return;
    try {
      await api.dio.delete('/push/tokens', queryParameters: {'token': token});
    } catch (e) {
      debugPrint('Push FCM: error al eliminar token ($e)');
    }
  }

  Future<Map<String, dynamic>?> _fetchConfig(ApiClient api) async {
    try {
      final res = await api.dio.get('/config/messaging');
      final data = res.data as Map<String, dynamic>;
      if (data['enabled'] != true) return null;

      final fb = (data['firebase'] as Map<String, dynamic>?) ?? {};
      final options = FirebaseOptions(
        apiKey: fb['apiKey'] as String? ?? '',
        projectId: fb['projectId'] as String? ?? '',
        appId: fb['appId'] as String? ?? '',
        messagingSenderId: fb['messagingSenderId'] as String? ?? '',
        authDomain: fb['authDomain'] as String? ?? '',
        storageBucket: fb['storageBucket'] as String? ?? '',
      );
      if (options.apiKey.isEmpty || options.projectId.isEmpty || options.appId.isEmpty) {
        return null;
      }
      return {
        'options': options,
        'vapidKey': data['vapidKey'] as String? ?? '',
      };
    } catch (e) {
      debugPrint('Push FCM: sin config ($e)');
      return null;
    }
  }

  void _listenForeground(FirebaseMessaging messaging) {
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'AppSecurity';
      final body = message.notification?.body ?? '';
      final route = message.data['route'] as String?;

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('$title\n$body', maxLines: 3),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () => _open(route),
          ),
        ),
      );
    });
  }

  void _listenAppOpened(FirebaseMessaging messaging) {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = message.data['route'] as String?;
      _open(route);
    });
  }

  Future<void> _handleInitialMessage(FirebaseMessaging messaging) async {
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      final route = initial.data['route'] as String?;
      // El router aún puede no existir; se procesa el primer redirect.
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(route));
    }
  }

  void _open(String? route) {
    final router = _router;
    if (router != null && route != null && route.isNotEmpty && route.startsWith('/')) {
      router.go(route);
    }
  }

  String _mobilePlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'web';
  }
}