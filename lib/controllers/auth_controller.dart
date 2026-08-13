import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Web Client ID من Firebase Console / google-services.json
  static const String _webClientId =
      '211339829221-esc2as8u9ooipilph9dv92j81vva5qd5.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Rxn<User> firebaseUser = Rxn<User>();
  RxMap<String, dynamic> userData = <String, dynamic>{}.obs;
  RxBool isLoading = false.obs;
  RxBool isLoginMode = true.obs;
  RxBool isPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();

    // تهيئة serverClientId مسبقاً لمنع خطأ clientConfigurationError على أندرويد
    _googleSignIn.initialize(serverClientId: _webClientId);

    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _bindFirestoreUser);
  }

  /// جلب المعرف الفريد للجهاز الحالي
  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_id';
    }
    return 'unknown_device';
  }

  void _bindFirestoreUser(User? user) {
    if (user != null && user.emailVerified) {
      _db.collection('users').doc(user.uid).snapshots().listen((doc) async {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final String currentDeviceId = await _getDeviceId();
          final String? savedDeviceId = data['deviceId'];

          // 1. إذا لم يكن هناك جهاز مسجل بعد، يتم تسجيل الجهاز الحالي كجهاز أساسي
          if (savedDeviceId == null || savedDeviceId.isEmpty) {
            await _db.collection('users').doc(user.uid).update({
              'deviceId': currentDeviceId,
            });
            userData.assignAll(data);
          }
          // 2. إذا كان الجهاز الحالي هو الجهاز المسجل
          else if (savedDeviceId == currentDeviceId) {
            userData.assignAll(data);
          }
          // 3. إذا حاول الدخول من جهاز جديد
          else {
            userData.clear();
            await _auth.signOut();
            _showErrorSnackbar(
              'هذا الحساب مرتبط بجهاز آخر بالفعل. لا يمكنك استخدام الحساب إلا من جهازك الأساسي.',
            );
          }
        } else {
          final String currentDeviceId = await _getDeviceId();
          _createNewUserRecord(user.uid, user.email ?? '', currentDeviceId);
        }
      });
    } else {
      userData.clear();
    }
  }

  bool get trialStarted => userData['trialStarted'] ?? false;

  bool get activeSubscription {
    final endDate = userData['subscriptionEndDate'];
    if (endDate != null && endDate is Timestamp) {
      return DateTime.now().isBefore(endDate.toDate());
    }
    return false;
  }

  int get subscriptionDaysLeft {
    final endDate = userData['subscriptionEndDate'];
    if (endDate != null && endDate is Timestamp) {
      int left = endDate.toDate().difference(DateTime.now()).inDays;
      return left < 0 ? 0 : left;
    }
    return 0;
  }

  // ✅ تم التعديل هنا لتصبح 120 يوم (4 شهور) بدل 14
  int get daysLeft {
    final createdAt = userData['createdAt'];
    if (createdAt == null) return 120;
    int daysUsed = DateTime.now()
        .difference((createdAt as Timestamp).toDate())
        .inDays;
    int left = 120 - daysUsed;
    return left <= 0 ? 0 : left;
  }

  Future<void> _createNewUserRecord(
    String uid,
    String email,
    String deviceId,
  ) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'trialStarted': false,
      'deviceId': deviceId,
    });
  }

  Future<void> startTrial() async {
    if (firebaseUser.value != null) {
      await _db.collection('users').doc(firebaseUser.value!.uid).set({
        'trialStarted': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> activateSubscription(int days) async {
    if (firebaseUser.value != null) {
      final expiryDate = DateTime.now().add(Duration(days: days));
      await _db.collection('users').doc(firebaseUser.value!.uid).set({
        'subscriptionEndDate': Timestamp.fromDate(expiryDate),
      }, SetOptions(merge: true));
    }
  }

  Future<void> submitEmailAuth(
    String email,
    String password,
    Function onVerificationSent,
  ) async {
    try {
      isLoading.value = true;
      if (isLoginMode.value) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await credential.user!.sendEmailVerification();
        await _auth.signOut();
        isLoginMode.value = true;
        onVerificationSent();
      }
    } on FirebaseAuthException catch (e) {
      // اصطياد أخطاء الفايربيز وترجمتها
      _showErrorSnackbar(_getFriendlyErrorMessage(e.code));
    } catch (e) {
      _showErrorSnackbar('حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ الدالة الخاصة بإرسال رابط إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackbar('يرجى إدخال بريد إلكتروني صحيح أولاً.');
      return;
    }
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email.trim());

      // إغلاق النافذة المنبثقة لو كانت مفتوحة
      if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
        Get.back();
      }

      _showSuccessSnackbar(
        'تم بنجاح',
        'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.',
      );
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_getFriendlyErrorMessage(e.code));
    } catch (e) {
      debugPrint("🚨 Reset Password Error: $e");
      _showErrorSnackbar(
        'فشل إرسال الرابط. تأكد من صحة البريد الإلكتروني أو حاول لاحقاً.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// تسجيل الدخول بـ Native Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      // 1. طلب المصادقة
      final googleUser = await _googleSignIn.authenticate();

      // 2. استخراج التوثيق
      final googleAuth = googleUser.authentication;

      // 3. بناء الـ Credential لـ Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. تسجيل الدخول
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_getFriendlyErrorMessage(e.code));
    } catch (e) {
      debugPrint("🚨 Google Native Sign In Error: $e");
      if (!e.toString().contains('canceled')) {
        _showErrorSnackbar('فشل الاتصال بجوجل، يرجى المحاولة لاحقاً.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // -------------------------------------------------------------
  // ✨ دوال مساعدة لترجمة الأخطاء وعرض الإشعارات بشكل شيك
  // -------------------------------------------------------------

  /// دالة لترجمة أكواد أخطاء Firebase إلى رسائل عربية صديقة للمستخدم
  String _getFriendlyErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مسجل لدينا بالفعل، يمكنك تسجيل الدخول مباشرة.';
      case 'user-not-found':
        return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني، يرجى إنشاء حساب جديد.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة، يرجى المحاولة مجدداً.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'user-disabled':
        return 'تم إيقاف هذا الحساب من قبل الإدارة.';
      case 'too-many-requests':
        return 'تم حظر الحساب مؤقتاً بسبب كثرة المحاولات الخاطئة، جرب لاحقاً أو قم باستعادة كلمة المرور.';
      case 'network-request-failed':
        return 'تأكد من اتصالك بالإنترنت والمحاولة مجدداً.';
      case 'operation-not-allowed':
        return 'طريقة تسجيل الدخول هذه غير مفعلة حالياً.';
      default:
        return 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.';
    }
  }

  /// دالة مخصصة لعرض أخطاء العمليات بتصميم احترافي (Snackbar أحمر)
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'تنبيه',
      message,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      borderRadius: 16,
      icon: const Icon(
        Icons.error_outline_rounded,
        color: Colors.white,
        size: 28,
      ),
      duration: const Duration(seconds: 4),
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  /// دالة مخصصة لعرض رسائل النجاح بتصميم احترافي (Snackbar أخضر)
  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      icon: const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
        size: 28,
      ),
      duration: const Duration(seconds: 5),
    );
  }
}
