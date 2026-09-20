import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';
import 'calculator_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // ✅ مفتاح التحكم: غيره إلى false مستقبلاً لعودة نظام الاشتراكات
  static const bool isAppTemporarilyFree = true;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.put(AuthController());

    return Obx(() {
      final user = authController.firebaseUser.value;

      // 1. التأكد من تسجيل الدخول وتفعيل الإيميل
      if (user == null || !user.emailVerified) {
        return const LoginScreen();
      }

      // 2. انتظار جلب بيانات المستخدم من فايربيز
      if (authController.userData.isEmpty) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // 🚀 3. وضع التطبيق المجاني (تخطي الدفع بالكامل)
      if (isAppTemporarilyFree) {
        return DvrCalculatorScreen(
          isSubscribed: true, // بنمررها true عشان النظام يعتبره مشترك
          daysLeft: 999, // رقم وهمي مش هيظهر
          userId: user.uid,
        );
      }

      // 🛑 الكود الأصلي للاشتراكات (لن يعمل طالما المفتاح فوق = true)
      if (authController.activeSubscription) {
        return DvrCalculatorScreen(
          isSubscribed: true,
          daysLeft: authController.subscriptionDaysLeft,
          userId: user.uid,
        );
      }

      if (!authController.trialStarted) {
        return SubscriptionScreen(showTrialOption: true);
      }

      if (authController.daysLeft <= 0) {
        return SubscriptionScreen(showTrialOption: false);
      }

      return DvrCalculatorScreen(
        isSubscribed: false,
        daysLeft: authController.daysLeft,
        userId: user.uid,
      );
    });
  }
}
