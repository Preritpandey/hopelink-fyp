import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:hope_link/config/payment_config.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';

class PaymentService {
  Future<String> processStripePayment({
    required Future<Map<String, dynamic>> Function() initializePayment,
    required Future<bool> Function(String paymentIntentId) verifyPayment,
    String merchantDisplayName = 'Hope Link',
  }) async {
    if (Stripe.publishableKey.isEmpty) {
      await PaymentConfig.fetch();
      final key = PaymentConfig.stripePublishableKey?.trim() ?? '';
      if (key.isNotEmpty) {
        Stripe.publishableKey = key;
        if (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS) {
          Stripe.merchantIdentifier = 'merchant.com.example';
        }
        await Stripe.instance.applySettings();
      }
    }

    if (Stripe.publishableKey.isEmpty) {
      throw Exception(
        'Stripe is not configured. Missing publishable key from /payments/config.',
      );
    }

    final initData = await initializePayment();
    final clientSecret =
        initData['clientSecret']?.toString() ??
        initData['client_secret']?.toString();
    final paymentIntentId = initData['id']?.toString();

    if (clientSecret == null ||
        clientSecret.isEmpty ||
        paymentIntentId == null ||
        paymentIntentId.isEmpty) {
      throw Exception(
        'Failed to initialize Stripe payment. Missing client secret or payment intent id.',
      );
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      final message =
          e.error.localizedMessage ??
          e.error.message ??
          'Stripe payment sheet configuration failed.';
      throw Exception(message);
    } on StripeConfigException catch (e) {
      throw Exception(e.message);
    }

    final verified = await verifyPayment(paymentIntentId);
    if (!verified) {
      throw Exception('Payment verification failed.');
    }
    return paymentIntentId;
  }

  Future<String> processKhaltiPayment({
    required BuildContext context,
    required String publicKey,
    required Environment environment,
    required Future<Map<String, dynamic>> Function() initializePayment,
    required Future<void> Function(String pidx) onPaymentSuccess,
    String confirmationTitle = 'Confirming Payment',
    String confirmationMessage =
        'Your Khalti payment was received. We are finalizing it in the app.',
  }) async {
    final initData = await initializePayment();
    final pidx = initData['pidx']?.toString();

    if (pidx == null || pidx.isEmpty) {
      throw Exception('Failed to initiate Khalti payment.');
    }

    final payConfig = KhaltiPayConfig(
      publicKey: publicKey,
      pidx: pidx,
      environment: environment,
    );

    final completer = Completer<void>();
    var checkoutClosed = false;

    final khalti = await Khalti.init(
      enableDebugging: true,
      payConfig: payConfig,
      onPaymentResult: (paymentResult, khalti) async {
        _closeKhaltiCheckout(
          khalti,
          context,
          completer,
          alreadyClosed: checkoutClosed,
        );
        checkoutClosed = true;
        _showPaymentConfirmationDialog(
          title: confirmationTitle,
          message: confirmationMessage,
        );

        try {
          await onPaymentSuccess(paymentResult.payload?.pidx ?? pidx);
        } finally {
          _dismissActiveDialog();
        }
      },
      onMessage: (
        khalti, {
        description,
        statusCode,
        event,
        needsPaymentConfirmation,
      }) async {
        if (needsPaymentConfirmation == true) {
          await khalti.verify();
        }
        if (event == KhaltiEvent.kpgDisposed) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          checkoutClosed = true;
        }
      },
      onReturn: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    khalti.open(context);
    await completer.future;
    return pidx;
  }

  void _showPaymentConfirmationDialog({
    required String title,
    required String message,
  }) {
    _dismissActiveDialog();
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _dismissActiveDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  void _closeKhaltiCheckout(
    Khalti khalti,
    BuildContext context,
    Completer<void> completer, {
    required bool alreadyClosed,
  }) {
    if (!alreadyClosed) {
      khalti.close(context);
    }
    if (!completer.isCompleted) {
      completer.complete();
    }
  }
}
