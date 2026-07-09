import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../controllers/calculator_controller.dart';
import '../controllers/auth_controller.dart';
import 'subscription_screen.dart';

class DvrCalculatorScreen extends StatelessWidget {
  final bool isSubscribed;
  final int daysLeft;
  final String userId;

  const DvrCalculatorScreen({
    super.key,
    required this.isSubscribed,
    required this.daysLeft,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final calcController = Get.put(CalculatorController());
    final authController = AuthController.instance;

    return Obx(() {
      final isAr = calcController.isArabic.value;
      return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final bool shouldPop =
                await _showExitDialog(context, calcController) ?? false;
            if (shouldPop) {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // تم تصحيح اسم الاستدعاء هنا ليطابق الدالة تحت
                    _buildSubscriptionBanner(
                      isAr,
                      isSubscribed,
                      daysLeft,
                      userId,
                    ),

                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 24.0,
                          ),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 600),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 24,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () => authController.signOut(),
                                      icon: const Icon(
                                        Icons.logout,
                                        color: Colors.red,
                                      ),
                                      tooltip: calcController.texts['logout'],
                                    ),
                                    Image.asset(
                                      'assets/images/logo.png',
                                      width: 60,
                                      height: 60,
                                      errorBuilder: (c, e, s) =>
                                          const SizedBox(),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          calcController.toggleLanguage(),
                                      icon: const Icon(
                                        Icons.language,
                                        size: 18,
                                      ),
                                      label: Text(
                                        calcController.texts['lang']!,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueAccent.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  calcController.texts['mainTitle']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 30),

                                _buildSectionTitle(
                                  calcController.texts['step1']!,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _pickCurrentDateTime(
                                          context,
                                          calcController,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                DateFormat(
                                                  'yyyy-MM-dd   hh:mm a',
                                                ).format(
                                                  calcController
                                                      .currentTime
                                                      .value,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue.shade900,
                                                ),
                                              ),
                                              Icon(
                                                Icons.edit_calendar_rounded,
                                                color: Colors.blue.shade700,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () =>
                                          calcController.refreshCurrentTime(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueAccent.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.refresh,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 6,
                                    left: 4,
                                    right: 4,
                                  ),
                                  child: Text(
                                    isAr
                                        ? 'يمكنك الضغط على التاريخ لتعديله يدويًا'
                                        : 'Tap date to edit manually',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blueGrey.shade400,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                _buildSectionTitle(
                                  calcController.texts['step2']!,
                                ),
                                _buildDateTimePicker(
                                  calcController.dvrTime.value != null
                                      ? DateFormat(
                                          'yyyy-MM-dd   hh:mm a',
                                        ).format(calcController.dvrTime.value!)
                                      : calcController.texts['selectTime']!,
                                  () => _pickDateTime(
                                    context,
                                    true,
                                    calcController,
                                  ),
                                  calcController.dvrTime.value != null,
                                ),

                                const SizedBox(height: 16),
                                _buildSectionTitle(
                                  calcController.texts['step3']!,
                                ),
                                _buildDateTimePicker(
                                  calcController.eventTime.value != null
                                      ? DateFormat(
                                          'yyyy-MM-dd   hh:mm a',
                                        ).format(
                                          calcController.eventTime.value!,
                                        )
                                      : calcController.texts['selectTime']!,
                                  () => _pickDateTime(
                                    context,
                                    false,
                                    calcController,
                                  ),
                                  calcController.eventTime.value != null,
                                ),

                                const SizedBox(height: 32),
                                ElevatedButton(
                                  onPressed: () =>
                                      calcController.calculateDifference(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    calcController.texts['calculate']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                _buildErrorMessage(calcController),

                                ..._buildResults(calcController),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSubscriptionBanner(
    bool isAr,
    bool isSubscribed,
    int daysLeft,
    String userId,
  ) {
    if (isSubscribed) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.shade700,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAr
                  ? 'باقي $daysLeft أيام في الفترة التجريبية'
                  : '$daysLeft days left in free trial',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Get.to(() => SubscriptionScreen(showTrialOption: false)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.amber.shade900,
              minimumSize: const Size(0, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isAr ? 'ترقية' : 'Upgrade',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(CalculatorController controller) {
    if (controller.errorMessage.value != null) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          controller.errorMessage.value!,
          style: TextStyle(
            color: Colors.red.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  List<Widget> _buildResults(CalculatorController controller) {
    if (controller.equivalentTimeResult.value != null) {
      return [
        const SizedBox(height: 24),
        _buildResultCard(
          controller.texts['equivTitle']!,
          controller.equivalentTimeResult.value!,
          Colors.orange,
        ),
        _buildResultCard(
          controller.texts['diffTitle']!,
          controller.timeDifferenceResult.value!,
          Colors.green,
        ),
      ];
    }
    return [];
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(String text, VoidCallback onTap, bool hasData) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasData ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasData ? Colors.blue.shade300 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: hasData ? Colors.blue.shade900 : Colors.grey.shade600,
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: hasData ? Colors.blue.shade700 : Colors.grey.shade500,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String value, MaterialColor color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: color.shade800)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCurrentDateTime(
    BuildContext context,
    CalculatorController calcController,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: calcController.currentTime.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(calcController.currentTime.value),
      );
      if (pickedTime != null) {
        calcController.currentTime.value = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
  }

  Future<void> _pickDateTime(
    BuildContext context,
    bool isDvr,
    CalculatorController calcController,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final selected = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        if (isDvr) {
          calcController.dvrTime.value = selected;
        } else {
          calcController.eventTime.value = selected;
        }
      }
    }
  }

  Future<bool?> _showExitDialog(
    BuildContext context,
    CalculatorController calcController,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(calcController.texts['exitTitle']!),
        content: Text(calcController.texts['exitMsg']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(calcController.texts['cancel']!),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(calcController.texts['exit']!),
          ),
        ],
      ),
    );
  }
}
