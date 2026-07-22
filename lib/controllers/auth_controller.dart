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
            Get.snackbar(
              'تنبيه الأمان',
              'هذا الحساب مرتبط بجهاز آخر بالفعل. لا يمكنك استخدام الحساب إلا من جهازك الأساسي.',
              backgroundColor: Colors.red.shade800,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
              snackPosition: SnackPosition.BOTTOM,
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

  // ✅ تم التعديل هنا لتصبح 14 يوم بدل 7
  int get daysLeft {
    final createdAt = userData['createdAt'];
    if (createdAt == null) return 14;
    int daysUsed = DateTime.now()
        .difference((createdAt as Timestamp).toDate())
        .inDays;
    int left = 14 - daysUsed;
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
    } catch (e) {
      Get.snackbar('تنبيه', 'خطأ في المصادقة: $e');
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
    } catch (e) {
      debugPrint("🚨 Google Native Sign In Error: $e");
      if (!e.toString().contains('canceled')) {
        Get.snackbar('خطأ', 'فشل الاتصال بجوجل');
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
}
