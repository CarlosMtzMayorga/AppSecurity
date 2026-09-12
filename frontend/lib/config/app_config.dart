import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'AppSecurity';
  static const String appVersion = '1.0.0';
  
  static String get baseUrl {
    if (kReleaseMode) {
      return const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.appsecurity.com/api/v1');
    }
    return const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api/v1');
  }
  
  static String get stripePublishableKey {
    return const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
  }
  
  static const int defaultPageSize = 20;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const Duration apiTimeout = Duration(seconds: 30);
  
  static const List<String> supportedLocales = ['es', 'en'];
  static const String defaultLocale = 'es';
}