import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';
import 'calculator_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());

    return Obx(() {
      final user = authController.firebaseUser.value;

      if (user == null || !user.emailVerified) {
        return const LoginScreen();
      }

      if (authController.userData.isEmpty) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // لو الاشتراك ساري - بدون const
      if (authController.activeSubscription) {
        return DvrCalculatorScreen(
          isSubscribed: true,
          daysLeft: 0,
          userId: user.uid,
        );
      }

      // لو لسه مبدأش الفترة التجريبية - بدون const
      if (!authController.trialStarted) {
        return SubscriptionScreen(showTrialOption: true);
      }

      // لو الفترة التجريبية انتهت - بدون const
      if (authController.daysLeft <= 0) {
        return SubscriptionScreen(showTrialOption: false);
      }

      // لو لسه في الفترة التجريبية - بدون const
      return DvrCalculatorScreen(
        isSubscribed: false,
        daysLeft: authController.daysLeft,
        userId: user.uid,
      );
    });
  }
}
