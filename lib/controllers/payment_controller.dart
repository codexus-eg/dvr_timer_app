import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

enum SubscriptionPlan { monthly, yearly }

class PaymentController extends GetxController {
  final Dio _dio = Dio();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // بيانات كاشير الحية
  final String _merchantId = "MID-10201-314";
  final String _paymentApiKey = "72b61bc7-9a2e-4ea3-8509-81ebc060776e";
  final String _secretKey =
      "d5388953d5a65b43f3d9c5b8b5f501fc\$a66a1d554769ea9ab62d17d6c76d658675ccea752650133a32ebdf8fd54fa46242d3be008b44c16eede8bb90ae639a42";

  final String _currency = "EGP";

  // أسعار الباقات الافتراضية مع إمكانية التحديث الديناميكي
  RxDouble monthlyPrice = 50.0.obs;
  RxDouble yearlyPrice = 400.0.obs;
  RxBool isFetchingPrices = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPricesFromFirebase();
  }

  /// جلب الأسعار مباشرة من Firestore للتحكم بها بدون تحديث التطبيق
  Future<void> fetchPricesFromFirebase() async {
    try {
      isFetchingPrices.value = true;
      final doc = await _db.collection('settings').doc('pricing').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // تحويل القيمة سواء كانت String أو num
        monthlyPrice.value =
            double.tryParse(data['monthlyPrice'].toString()) ?? 50.0;
        yearlyPrice.value =
            double.tryParse(data['yearlyPrice'].toString()) ?? 400.0;
      }
    } catch (e) {
      debugPrint("⚠️ Failed to fetch pricing config: $e");
    } finally {
      isFetchingPrices.value = false;
    }
  }

  /// إنشاء جلسة دفع بناءً على الباقة المختارة
  Future<String?> createPaymentSession(SubscriptionPlan plan) async {
    try {
      final double selectedPrice = plan == SubscriptionPlan.monthly
          ? monthlyPrice.value
          : yearlyPrice.value;
      final String amountStr = selectedPrice.toStringAsFixed(2);

      final String orderId =
          "DVR_${plan == SubscriptionPlan.yearly ? 'YR' : 'MO'}_${DateTime.now().millisecondsSinceEpoch}";
      final String userEmail =
          AuthController.instance.firebaseUser.value?.email ??
          "customer@dvr-timer.com";

      final String expireAt = DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String();

      const String endpoint = "https://api.kashier.io/v3/payment/sessions";

      final Map<String, dynamic> bodyData = {
        "expireAt": expireAt,
        "maxFailureAttempts": 3,
        "paymentType": "credit",
        "amount": amountStr,
        "currency": _currency,
        "order": orderId,
        "merchantRedirect": "https://dvr-timer-app.web.app/payment-success",
        "display": "ar",
        "type": "external",
        "allowedMethods": "card,wallet",
        "merchantId": _merchantId,
        "failureRedirect": false,
        "defaultMethod": "card",
        "description": plan == SubscriptionPlan.yearly
            ? "Yearly Subscription for DVR-Timer App"
            : "Monthly Subscription for DVR-Timer App",
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
        debugPrint(
          "✅ Session Created Successfully ($amountStr EGP): $sessionUrl",
        );
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
