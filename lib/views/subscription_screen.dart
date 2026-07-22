import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/payment_controller.dart';
import 'payment_webview.dart';

class SubscriptionScreen extends StatelessWidget {
  final bool showTrialOption;
  final PaymentController paymentController = Get.put(PaymentController());
  final RxBool isLoading = false.obs;
  final Rx<SubscriptionPlan> selectedPlan = SubscriptionPlan.yearly.obs;

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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      showTrialOption
                          ? Icons.rocket_launch_rounded
                          : Icons.lock_clock_rounded,
                      size: 70,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      showTrialOption
                          ? 'مرحباً بك في DVR-Timer!'
                          : 'انتهى الاشتراك أو الفترة التجريبية!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // ✅ تم التعديل هنا في النص
                    Text(
                      showTrialOption
                          ? 'اختر باقتك الآن للبدء، أو جرب التطبيق مجاناً لمدة 14 يوماً.'
                          : 'للاستمرار في استخدام التطبيق بكامل ميزاته، يرجى تفعيل أو تجديد الاشتراك.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // اختيار الباقة (شهرية / سنوية)
                    Obx(() {
                      final mPrice = paymentController.monthlyPrice.value
                          .toInt();
                      final yPrice = paymentController.yearlyPrice.value
                          .toInt();

                      return Column(
                        children: [
                          _buildPlanCard(
                            title: 'الباقة السنوية',
                            priceText: '$yPrice',
                            subText: 'جنيه / سنوياً',
                            badgeText: 'توفير لأكثر من شهرين 🔥',
                            plan: SubscriptionPlan.yearly,
                            isRecommended: true,
                          ),
                          const SizedBox(height: 14),
                          _buildPlanCard(
                            title: 'الباقة الشهرية',
                            priceText: '$mPrice',
                            subText: 'جنيه / شهرياً',
                            plan: SubscriptionPlan.monthly,
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 28),

                    // زرار الاشتراك الإلكتروني
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
                                          .createPaymentSession(
                                            selectedPlan.value,
                                          );
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
                                : selectedPlan.value == SubscriptionPlan.yearly
                                ? 'اشترك في الباقة السنوية الآن'
                                : 'اشترك في الباقة الشهرية الآن',
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
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => authController.startTrial(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.white54,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          // ✅ تم التعديل هنا لتصبح 14 يوم
                          child: const Text(
                            'بدء الفترة التجريبية المجانية (14 يوم)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    // زرار تسجيل الخروج
                    TextButton.icon(
                      onPressed: () => authController.signOut(),
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white70,
                        size: 20,
                      ),
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

  Widget _buildPlanCard({
    required String title,
    required String priceText,
    required String subText,
    required SubscriptionPlan plan,
    String? badgeText,
    bool isRecommended = false,
  }) {
    return Obx(() {
      final isSelected = selectedPlan.value == plan;

      return GestureDetector(
        onTap: () => selectedPlan.value = plan,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.amber.shade600.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.amber.shade600 : Colors.white24,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  _buildRadioIndicator(isSelected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.amber : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              priceText,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              subText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (badgeText != null)
                Positioned(
                  top: -24,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  /// مؤشر دائري مخصص للاختيار
  Widget _buildRadioIndicator(bool isSelected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.amber.shade600 : Colors.white54,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.shade600,
                ),
              ),
            )
          : null,
    );
  }
}
