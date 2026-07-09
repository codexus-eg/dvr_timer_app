import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class PaymentController extends GetxController {
  final Dio _dio = Dio();

  // بيانات الـ Live النهائية المربوطة بحسابك
  final String _apiKey =
      "ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRNNE56QTJMQ0p1WVcxbElqb2lNVGN4TnpNMk5UZzVOUzQ0TVRRME56UWlmUS55V1I5V2dPUVhwS0NKd1N3NFlhSGZRb0g0aGUta1JiaWlYZ1NZbUFZV3BWME9OMDZRRG04YWxsREMtZEhERzhVWmRqVnBzTkFhbGNfWWJKZXhPMTZkUQ==";
  final int _integrationIdVisa = 2290599;
  final int _amountCents = 5000; // 50 جنيه قيمة الاشتراك

  Future<String?> getPaymentKey() async {
    try {
      // 1. مرحلة التوثيق والحصول على رمز الوصول (Authentication)
      var authResponse = await _dio.post(
        "https://accept.paymob.com/api/auth/tokens",
        data: {"api_key": _apiKey},
      );
      String authToken = authResponse.data['token'];

      // 2. مرحلة تسجيل الطلب في السيرفر (Order Registration)
      var orderResponse = await _dio.post(
        "https://accept.paymob.com/api/ecommerce/orders",
        data: {
          "auth_token": authToken,
          "delivery_needed": "false",
          "amount_cents": _amountCents.toString(),
          "currency": "EGP",
          "items": [],
        },
      );
      int orderId = orderResponse.data['id'];

      // 3. مرحلة توليد مفتاح الدفع المربوط بالفيزا (Payment Key Generation)
      var keyResponse = await _dio.post(
        "https://accept.paymob.com/api/acceptance/payment_keys",
        data: {
          "auth_token": authToken,
          "amount_cents": _amountCents.toString(),
          "expiration": 3600,
          "order_id": orderId.toString(),
          "billing_data": {
            "first_name": "User",
            "last_name": "App",
            "email":
                AuthController.instance.firebaseUser.value?.email ??
                "test@test.com",
            "phone_number": "+201000000000",
            "apartment": "NA",
            "floor": "NA",
            "street": "NA",
            "building": "NA",
            "shipping_method": "NA",
            "postal_code": "NA",
            "city": "NA",
            "country": "EG",
            "state": "NA",
          },
          "currency": "EGP",
          "integration_id": _integrationIdVisa,
        },
      );

      return keyResponse.data['token'];
    } on DioException catch (e) {
      print("🚨🚨 Paymob Live Error Info 🚨🚨");
      print("Status Code: ${e.response?.statusCode}");
      print("Error Data: ${e.response?.data}");
      print("🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨");

      Get.snackbar(
        "رفض من بوابة الدفع",
        "حدث خطأ أثناء الاتصال بالبوابة، كود الخطأ: ${e.response?.statusCode}",
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return null;
    } catch (e) {
      print("🚨 General Error: $e");
      return null;
    }
  }
}
