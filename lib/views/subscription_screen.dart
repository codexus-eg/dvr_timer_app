import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/payment_controller.dart';
import 'payment_webview.dart';

class SubscriptionScreen extends StatelessWidget {
  final bool showTrialOption;
  final PaymentController paymentController = Get.put(PaymentController());
  final RxBool isLoading = false.obs;

  SubscriptionScreen({super.key, required this.showTrialOption});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController.instance;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      showTrialOption
                          ? Icons.rocket_launch_rounded
                          : Icons.lock_clock_rounded,
                      size: 80,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      showTrialOption
                          ? 'مرحباً بك في DVR-Timer!'
                          : 'انتهى الاشتراك أو الفترة التجريبية!',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      showTrialOption
                          ? 'اختر باقتك الآن للبدء، أو جرب التطبيق مجاناً لمدة 7 أيام.'
                          : 'للاستمرار في استخدام التطبيق بكامل ميزاته، يرجى تفعيل أو تجديد الاشتراك الشهري.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // كارت تفاصيل الباقة
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'الباقة الشهرية الكاملة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '50',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'جنيه / شهرياً',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 30),
                          _buildFeatureRow(
                            'حساب توقيت أجهزة الـ DVR بدقة متناهية.',
                          ),
                          _buildFeatureRow('تحديثات مستمرة ودعم فني متواصل.'),
                          _buildFeatureRow('بدون أي إعلانات مزعجة.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // زرار الاشتراك الإلكتروني
                    // استبدل جزء زرار الاشتراك بالـ Obx المحدث ده:
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: isLoading.value
                              ? null
                              : () async {
                                  isLoading.value = true;
                                  final String? sessionUrl =
                                      await paymentController
                                          .createPaymentSession();
                                  isLoading.value = false;

                                  if (sessionUrl != null &&
                                      sessionUrl.isNotEmpty) {
                                    Get.to(
                                      () => PaymentWebView(
                                        paymentUrl: sessionUrl,
                                      ),
                                    );
                                  } else {
                                    Get.snackbar(
                                      "خطأ",
                                      "لم يتم فتح صفحة الدفع بنجاح.",
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                },
                          icon: isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black87,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.bolt, color: Colors.black87),
                          label: Text(
                            isLoading.value
                                ? 'جاري تجهيز بوابة الدفع...'
                                : 'اشترك الآن وفعل التطبيق',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // زرار الفترة التجريبية
                    if (showTrialOption) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () => authController.startTrial(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.white54,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'بدء الفترة التجريبية المجانية (7 أيام)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    // زرار تسجيل الخروج
                    TextButton.icon(
                      onPressed: () => authController.signOut(),
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      label: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.greenAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
