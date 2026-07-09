import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
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
          userData.value = doc.data() ?? {};
        } else {
          _createNewUserRecord(user.uid, user.email ?? '');
        }
      });
    } else {
      userData.clear();
    }
  }

  bool get isSubscribed => userData['isSubscribed'] ?? false;
  bool get trialStarted => userData['trialStarted'] ?? false;

  bool get activeSubscription {
    if (userData.containsKey('subscriptionEndDate') &&
        userData['subscriptionEndDate'] != null) {
      Timestamp endTs = userData['subscriptionEndDate'];
      return DateTime.now().isBefore(endTs.toDate());
    }
    return false;
  }

  int get daysLeft {
    if (userData['createdAt'] == null) return 7;
    Timestamp createTs = userData['createdAt'];
    int daysUsed = DateTime.now().difference(createTs.toDate()).inDays;
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

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      await _googleSignIn.initialize();
      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: clientAuth.accessToken,
      );

      await _auth.signInWithCredential(credential);
    } catch (e) {
      Get.snackbar(
        'تنبيه',
        'تم الإلغاء أو حدث خطأ أثناء الاتصال بجوجل.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isLoading.value = false;
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
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _auth.currentUser?.reload();

        if (!credential.user!.emailVerified) {
          await _auth.signOut();
          onVerificationSent();
        }
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
      String msg = 'حدث خطأ في المصادقة';
      if (e.code == 'user-not-found') {
        msg = 'لا يوجد حساب مرتبط بهذا الإيميل.';
      } else if (e.code == 'wrong-password') {
        msg = 'كلمة المرور غير صحيحة.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'هذا البريد الإلكتروني مسجل مسبقاً.';
      } else if (e.code == 'invalid-credential') {
        msg = 'بيانات الدخول غير صحيحة.';
      }
      Get.snackbar(
        'تنبيه',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startTrial() async {
    await _db.collection('users').doc(firebaseUser.value!.uid).set({
      'trialStarted': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // تم التعديل هنا لاستقبال عدد الأيام كمتغير (int days)
  Future<void> activateSubscription(int days) async {
    final expiryDate = DateTime.now().add(Duration(days: days));
    await _db.collection('users').doc(firebaseUser.value!.uid).set({
      'subscriptionEndDate': Timestamp.fromDate(expiryDate),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      // تجاهل الخطأ في حالة عدم وجود حساب جوجل
    }
    await _auth.signOut();
  }
}
