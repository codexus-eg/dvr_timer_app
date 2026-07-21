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
    // التأكد من استدعاء الـ Controller
    final AuthController authController = Get.put(AuthController());

    return Obx(() {
      final user = authController.firebaseUser.value;

      if (user == null || !user.emailVerified) {
        return const LoginScreen();
      }

      if (authController.userData.isEmpty) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (authController.activeSubscription) {
        return DvrCalculatorScreen(
          isSubscribed: true,
          daysLeft: 0,
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
