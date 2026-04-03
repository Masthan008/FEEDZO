import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Service to handle Razorpay payment gateway integration.
/// Wraps the Razorpay SDK with a clean async API.
class RazorpayService {
  static final _razorpay = Razorpay();

  /// Razorpay API key — replace with your live key for production.
  static const _apiKey = 'rzp_live_SKlWcTovIQ1j3G';

  /// Opens the Razorpay checkout and returns a Future that resolves
  /// to the payment ID on success, or throws on failure/cancellation.
  static Future<String> openCheckout({
    required double amount,
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String description = 'Feedzo Food Order',
  }) async {
    // Amount in paise (INR × 100)
    final amountInPaise = (amount * 100).toInt();

    final options = {
      'key': _apiKey,
      'amount': amountInPaise,
      'name': 'Feedzo',
      'description': description,
      'order_id': '', // Set from Razorpay server-side order if available
      'prefill': {
        'name': customerName,
        'email': customerEmail,
        'contact': customerPhone,
      },
      'theme': {
        'color': '#16A34A',
      },
      'notes': {
        'feedzo_order_id': orderId,
      },
      'modal': {
        'confirm_close': true,
      },
      'send_sms_hash': true,
      'readonly': {
        'contact': true,
        'email': true,
      },
    };

    // Use completer pattern for clean async
    String? paymentId;
    String? errorMessage;
    bool completed = false;

    void handleSuccess(PaymentSuccessResponse response) {
      paymentId = response.paymentId;
      completed = true;
    }

    void handleError(PaymentFailureResponse response) {
      errorMessage = response.message ?? 'Payment failed';
      completed = true;
    }

    void handleWallet(ExternalWalletResponse response) {
      debugPrint('External wallet: ${response.walletName}');
    }

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleWallet);

    _razorpay.open(options);

    // Wait for callback
    while (!completed) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _razorpay.clear();

    if (paymentId != null) {
      return paymentId!;
    } else {
      throw Exception(errorMessage ?? 'Payment cancelled');
    }
  }

  /// Dispose — call when app is shutting down.
  static void dispose() {
    _razorpay.clear();
  }
}
