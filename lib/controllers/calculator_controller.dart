import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CalculatorController extends GetxController {
  RxBool isArabic = true.obs;
  Rx<DateTime> currentTime = DateTime.now().obs;
  Rxn<DateTime> dvrTime = Rxn<DateTime>();
  Rxn<DateTime> eventTime = Rxn<DateTime>();

  RxnString timeDifferenceResult = RxnString();
  RxnString equivalentTimeResult = RxnString();
  RxnString differenceTypeResult = RxnString();
  RxnString errorMessage = RxnString();

  Map<String, String> get texts => {
    'mainTitle': isArabic.value
        ? 'حساب فرق توقيت أجهزة التسجيل'
        : 'Calculate DVR Time Difference',
    'step1': isArabic.value
        ? 'خطوة (1) الساعة والتاريخ الآن'
        : 'Step 1: Current Date and Time',
    'refresh': isArabic.value ? 'تحديث' : 'Refresh',
    'note': isArabic.value
        ? 'ملحوظة: ضبط التوقيت يدوياً إذا اختلف.'
        : 'Note: Adjust manually if it differs.',
    'step2': isArabic.value
        ? 'خطوة (2) وقت جهاز التسجيل الحالي'
        : 'Step 2: DVR Current Time',
    'step3': isArabic.value
        ? 'خطوة (3) وقت الحدث الفعلي'
        : 'Step 3: Actual Event Time',
    'reset': isArabic.value ? 'إعادة تعيين' : 'Reset',
    'calculate': isArabic.value ? 'حساب الفرق' : 'Calculate Difference',
    'equivTitle': isArabic.value
        ? 'التوقيت المكافئ للحدث'
        : 'Equivalent Event Time',
    'diffTitle': isArabic.value ? 'فرق التوقيت' : 'Time Difference',
    'typeTitle': isArabic.value ? 'نوع فرق التوقيت' : 'Time Difference Type',
    'lang': isArabic.value ? 'English' : 'العربية',
    'selectTime': isArabic.value
        ? 'اضغط لتحديد الوقت والتاريخ'
        : 'Tap to select date and time',
    'exitTitle': isArabic.value ? 'تأكيد الخروج' : 'Exit Confirmation',
    'exitMsg': isArabic.value
        ? 'هل تريد الخروج من التطبيق؟'
        : 'Do you want to exit the app?',
    'cancel': isArabic.value ? 'إلغاء' : 'Cancel',
    'exit': isArabic.value ? 'خروج' : 'Exit',
  };

  void toggleLanguage() {
    isArabic.value = !isArabic.value;
    resetForm();
  }

  void refreshCurrentTime() => currentTime.value = DateTime.now();

  void resetForm() {
    dvrTime.value = null;
    eventTime.value = null;
    timeDifferenceResult.value = null;
    equivalentTimeResult.value = null;
    differenceTypeResult.value = null;
    errorMessage.value = null;
    refreshCurrentTime();
  }

  void calculateDifference() {
    if (dvrTime.value == null || eventTime.value == null) {
      errorMessage.value = isArabic.value
          ? "برجاء إدخال جميع الأوقات أولاً"
          : "Please enter all times first";
      return;
    }
    if (eventTime.value!.isAfter(currentTime.value)) {
      errorMessage.value = isArabic.value
          ? "خطأ: وقت الحدث الفعلي أكبر من وقت الموبايل!"
          : "Error: Event time is after current time!";
      return;
    }

    errorMessage.value = null;
    Duration diff = currentTime.value.difference(dvrTime.value!);
    int days = diff.inDays.abs();
    int hours = (diff.inHours % 24).abs();
    int minutes = (diff.inMinutes % 60).abs();
    int seconds = (diff.inSeconds % 60).abs();

    timeDifferenceResult.value = isArabic.value
        ? "$days أيام, $hours ساعات, $minutes دقائق, $seconds ثواني"
        : "$days days, $hours hours, $minutes minutes, $seconds seconds";

    if (currentTime.value.isAfter(dvrTime.value!)) {
      differenceTypeResult.value = isArabic.value
          ? "وقت جهاز التسجيل متأخر"
          : "DVR time is behind";
    } else if (dvrTime.value!.isAfter(currentTime.value)) {
      differenceTypeResult.value = isArabic.value
          ? "وقت جهاز التسجيل مقدم"
          : "DVR time is ahead";
    } else {
      differenceTypeResult.value = isArabic.value
          ? "لا يوجد فرق"
          : "No difference";
    }

    Duration eventDiff = eventTime.value!.difference(currentTime.value);
    DateTime equivalent = dvrTime.value!.add(eventDiff);
    String formattedDate = DateFormat('yyyy-MM-dd').format(equivalent);
    String formattedTime = DateFormat('hh:mm:ss a').format(equivalent);
    if (isArabic.value) {
      formattedTime = formattedTime.replaceAll('AM', 'ص').replaceAll('PM', 'م');
    }
    equivalentTimeResult.value = "$formattedDate  &  $formattedTime";
  }
}
