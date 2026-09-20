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
                    // ✅ تم إيقاف شريط الاشتراك مؤقتاً بجعله تعليقاً
                    // _buildSubscriptionBanner(
                    //   isAr,
                    //   isSubscribed,
                    //   daysLeft,
                    //   userId,
                    // ),
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
                                    // ✅ القائمة الجديدة المنسدلة (الثلاث شرط)
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'account') {
                                          _showAccountDialog(
                                            authController,
                                            isAr,
                                          );
                                        } else if (value == 'logout') {
                                          authController.signOut();
                                        }
                                      },
                                      icon: Icon(
                                        Icons.menu_rounded,
                                        size: 30,
                                        color: Colors.blue.shade900,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      itemBuilder: (BuildContext context) =>
                                          <PopupMenuEntry<String>>[
                                            PopupMenuItem<String>(
                                              value: 'account',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.person,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    isAr
                                                        ? 'حسابي'
                                                        : 'My Account',
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            PopupMenuItem<String>(
                                              value: 'logout',
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.logout,
                                                    color: Colors.red,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    isAr
                                                        ? 'تسجيل الخروج'
                                                        : 'Logout',
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
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
                                                  'yyyy-MM-dd   hh:mm:ss a',
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

  // ✅ نافذة بيانات الحساب (عرض الصورة التلقائية وتعديل الاسم فقط)
  void _showAccountDialog(AuthController authController, bool isAr) {
    Get.dialog(
      Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          backgroundColor: Colors.white,
          content: Obx(() {
            final user = authController.firebaseUser.value;
            final email = user?.email ?? '';
            final name =
                user?.displayName ??
                (isAr ? 'مستخدم بدون اسم' : 'Unnamed User');

            // الكود يسحب صورة الحساب التلقائية مباشرة
            final photoUrl = user?.photoURL;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // عرض الصورة التلقائية أو أيقونة افتراضية
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 45,
                          color: Colors.blue.shade700,
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // خانة الاسم مع زر التعديل بجانبه
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () =>
                          _showEditNameDialog(authController, name, isAr),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showDeleteConfirmationDialog(authController, isAr);
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: Text(
                      isAr
                          ? 'حذف الحساب نهائياً'
                          : 'Delete Account Permanently',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      isAr ? 'إغلاق' : 'Close',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ✅ نافذة تعديل الاسم المنبثقة
  void _showEditNameDialog(
    AuthController authController,
    String currentName,
    bool isAr,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: (currentName == 'مستخدم بدون اسم' || currentName == 'Unnamed User')
          ? ''
          : currentName,
    );

    Get.dialog(
      Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Text(isAr ? 'تعديل الاسم' : 'Edit Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: isAr ? 'أدخل اسمك هنا' : 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                isAr ? 'إلغاء' : 'Cancel',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: authController.isLoading.value
                    ? null
                    : () => authController.updateUserName(nameController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: authController.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isAr ? 'حفظ' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ نافذة تأكيد حذف الحساب
  void _showDeleteConfirmationDialog(AuthController authController, bool isAr) {
    Get.dialog(
      Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(isAr ? 'تحذير هام!' : 'Warning!'),
            ],
          ),
          content: Text(
            isAr
                ? 'هل أنت متأكد أنك تريد حذف الحساب نهائياً؟\nهذا الإجراء سيؤدي إلى مسح كل بياناتك ولا يمكن التراجع عنه.'
                : 'Are you sure you want to delete your account permanently?\nThis action cannot be undone.',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                isAr ? 'إلغاء' : 'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: authController.isLoading.value
                    ? null
                    : () => authController.deleteAccount(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: authController.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isAr ? 'موافق' : 'Confirm',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
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
        calcController.updateCurrentTimeManually(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
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

  // ✅ تم إضافة سطر التجاهل حتى لا يطلب المترجم حذف الدالة
  // ignore: unused_element
  Widget _buildSubscriptionBanner(
    bool isAr,
    bool isSubscribed,
    int daysLeft,
    String userId,
  ) {
    if (isSubscribed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.green.shade600,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isAr
                  ? 'اشتراكك مفعل: باقي $daysLeft يوماً'
                  : 'Active Subscription: $daysLeft days left',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
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
}
