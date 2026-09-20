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
    _googleSignIn.initialize(serverClientId: _webClientId);
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _bindFirestoreUser);
  }

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

          if (savedDeviceId == null || savedDeviceId.isEmpty) {
            await _db.collection('users').doc(user.uid).update({
              'deviceId': currentDeviceId,
            });
            userData.assignAll(data);
          } else if (savedDeviceId == currentDeviceId) {
            userData.assignAll(data);
          } else {
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
      _showErrorSnackbar(_getFriendlyErrorMessage(e.code));
    } catch (e) {
      _showErrorSnackbar('حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackbar('يرجى إدخال بريد إلكتروني صحيح أولاً.');
      return;
    }
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email.trim());
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
      _showErrorSnackbar(
        'فشل إرسال الرابط. تأكد من صحة البريد الإلكتروني أو حاول لاحقاً.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final googleUser = await _googleSignIn.authenticate();

      // ✅ تم إزالة await وعلامة ?. بناءً على تعليمات المترجم
      final googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_getFriendlyErrorMessage(e.code));
    } catch (e) {
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

  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).delete();
        await user.delete();
        if (Get.isDialogOpen == true) Get.back();
        _showSuccessSnackbar('تم بنجاح', 'تم حذف حسابك نهائياً.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showErrorSnackbar(
          'لأسباب أمنية، يرجى تسجيل الخروج ثم الدخول مجدداً قبل حذف الحساب.',
        );
      } else {
        _showErrorSnackbar(_getFriendlyErrorMessage(e.code));
      }
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء محاولة حذف الحساب.');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ تحديث الاسم
  Future<void> updateUserName(String newName) async {
    if (newName.trim().isEmpty) return;
    try {
      isLoading.value = true;
      await _auth.currentUser?.updateDisplayName(newName.trim());
      await _auth.currentUser?.reload(); // جلب البيانات الجديدة
      firebaseUser.value = _auth.currentUser;

      if (Get.isDialogOpen == true) Get.back(); // إغلاق نافذة التعديل
      _showSuccessSnackbar('تم بنجاح', 'تم تحديث الاسم.');
    } catch (e) {
      _showErrorSnackbar('فشل تحديث الاسم.');
    } finally {
      isLoading.value = false;
    }
  }

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
