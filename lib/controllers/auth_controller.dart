import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
// تم حذف مكتبة google_sign_in تماماً من هنا
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Rxn<User> firebaseUser = Rxn<User>();
  RxMap<String, dynamic> userData = <String, dynamic>{}.obs;
  RxBool isLoading = false.obs;
  RxBool isLoginMode = true.obs;
  RxBool isPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _bindFirestoreUser);
  }

  void _bindFirestoreUser(User? user) {
    if (user != null && user.emailVerified) {
      _db.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists) {
          userData.assignAll(doc.data() as Map<String, dynamic>);
        } else {
          _createNewUserRecord(user.uid, user.email ?? '');
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

  int get daysLeft {
    final createdAt = userData['createdAt'];
    if (createdAt == null) return 7;
    int daysUsed = DateTime.now()
        .difference((createdAt as Timestamp).toDate())
        .inDays;
    int left = 7 - daysUsed;
    return left <= 0 ? 0 : left;
  }

  Future<void> _createNewUserRecord(String uid, String email) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'trialStarted': false,
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

  // التعديل الجذري: استخدام مزود جوجل المدمج في فايربيز مباشرة
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // الدالة دي بتغنينا عن المكتبة اللي عاملة المشاكل
      await _auth.signInWithProvider(googleProvider);
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      Get.snackbar('خطأ', 'فشل الاتصال بجوجل');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    // مفيش داعي لـ google sign out لأننا استخدمنا الفايربيز مباشرة
    await _auth.signOut();
  }
}
