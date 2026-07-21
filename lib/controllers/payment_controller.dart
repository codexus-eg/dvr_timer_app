import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class PaymentController extends GetxController {
  final Dio _dio = Dio();

  // بيانات كاشير الحية
  final String _merchantId = "MID-10201-314";
  final String _paymentApiKey = "72b61bc7-9a2e-4ea3-8509-81ebc060776e";
  final String _secretKey =
      "d5388953d5a65b43f3d9c5b8b5f501fc\$a66a1d554769ea9ab62d17d6c76d658675ccea752650133a32ebdf8fd54fa46242d3be008b44c16eede8bb90ae639a42";

  final String _amount = "50.00"; // المبلغ بالتنسيق المطلوب
  final String _currency = "EGP";

  /// إنشاء جلسة دفع جديدة والحصول على sessionUrl المباشر
  Future<String?> createPaymentSession() async {
    try {
      final String orderId = "DVR_${DateTime.now().millisecondsSinceEpoch}";
      final String userEmail =
          AuthController.instance.firebaseUser.value?.email ??
          "customer@dvr-timer.com";

      // انتهاء الجلسة بعد ساعة من إنشائها
      final String expireAt = DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String();

      const String endpoint = "https://api.kashier.io/v3/payment/sessions";

      final Map<String, dynamic> bodyData = {
        "expireAt": expireAt,
        "maxFailureAttempts": 3,
        "paymentType": "credit",
        "amount": _amount,
        "currency": _currency,
        "order": orderId,
        "merchantRedirect": "https://dvr-timer-app.web.app/payment-success",
        "display": "ar",
        "type": "external",
        "allowedMethods": "card,wallet",
        "merchantId": _merchantId,
        "failureRedirect": false,
        "defaultMethod": "card",
        "description": "Subscription for DVR-Timer App",
        "manualCapture": false,
        "customer": {
          "email": userEmail,
          "reference":
              AuthController.instance.firebaseUser.value?.uid ?? orderId,
        },
        "interactionSource": "ECOMMERCE",
        "enable3DS": true,
      };

      final response = await _dio.post(
        endpoint,
        data: bodyData,
        options: Options(
          headers: {
            'Authorization': _secretKey,
            'api-key': _paymentApiKey,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String? sessionUrl = response.data['sessionUrl'];
        debugPrint("✅ Session Created Successfully: $sessionUrl");
        return sessionUrl;
      } else {
        debugPrint("🚨 Failed to create session: ${response.data}");
        return null;
      }
    } on DioException catch (e) {
      debugPrint("🚨 Kashier API Error: ${e.response?.data}");
      Get.snackbar(
        "خطأ في الاتصال",
        "فشل تجهيز جلسة الدفع، برجاء المحاولة لاحقاً.",
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return null;
    } catch (e) {
      debugPrint("🚨 Unexpected Error: $e");
      return null;
    }
  }
}
