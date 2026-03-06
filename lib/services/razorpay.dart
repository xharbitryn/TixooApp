// lib/services/razorpay_service.dart
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

typedef PaymentSuccessCallback = void Function(PaymentSuccessResponse response);
typedef PaymentErrorCallback = void Function(PaymentFailureResponse response);
typedef ExternalWalletCallback = void Function(ExternalWalletResponse response);

class RazorpayService {
  late Razorpay _razorpay;

  RazorpayService({
    required PaymentSuccessCallback onPaymentSuccess,
    required PaymentErrorCallback onPaymentError,
    required ExternalWalletCallback onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  void startPayment({
    required double amount,
    String name = "Tixxo",
    String description = "Ticket Purchase",
    String email = "test@example.com",
    String contact = "9876543210",
  }) {
    var options = {
      'key': 'rzp_test_bVdTllETOFazUu', // Replace with live key later
      'amount': (amount * 100).toInt(),
      'name': name,
      'description': description,
      'prefill': {'contact': contact, 'email': email},
      'theme': {'color': '#B7FF1C'},
      'method': {'upi': true},
      'upi': {
        'vpa': 'success@razorpay', // Test UPI ID
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay Error: $e");
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
