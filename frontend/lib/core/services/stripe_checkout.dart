import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../config/app_config.dart';
import '../providers/api_providers_part2.dart';
import '../providers/api_providers_part3.dart';

class StripeCheckoutService {
  const StripeCheckoutService({required this.paymentApi, required this.configApi});

  final PaymentApi paymentApi;
  final ConfigApi configApi;

  Future<String> _getPublishableKey() async {
    final fromBackend = await configApi.getStripePublishableKey();
    if (fromBackend != null && fromBackend.isNotEmpty) return fromBackend;
    if (AppConfig.stripePublishableKey.isNotEmpty) return AppConfig.stripePublishableKey;
    throw Exception('Stripe no está configurado. Configura la clave publicable de Stripe.');
  }

  Future<void> pay(String paymentId) async {
    final publishableKey = await _getPublishableKey();
    Stripe.publishableKey = publishableKey;

    final clientSecret = await paymentApi.createStripeIntent(paymentId);
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('No se pudo crear la intención de pago');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'AppSecurity',
        style: ThemeMode.light,
        primaryButtonLabel: 'Pagar',
      ),
    );

    final result = await Stripe.instance.presentPaymentSheet();
    if (result == null) {
      throw Exception('Pago cancelado');
    }
  }
}