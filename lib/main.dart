import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const DvrTimerApp());
}

class DvrTimerApp extends StatelessWidget {
  const DvrTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // استخدام GetMaterialApp بدلاً من MaterialApp
      debugShowCheckedModeBanner: false,
      title: 'DVR-Timer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade50,
        useMaterial3: true,
        fontFamily: 'Tajawal',
      ),
      home: const AuthGate(),
    );
  }
}
