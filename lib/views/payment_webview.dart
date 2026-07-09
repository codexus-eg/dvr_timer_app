import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'auth_gate.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentKey;

  const PaymentWebView({super.key, required this.paymentKey});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    // تم تثبيت رقم الـ Iframe المعتمد للحساب 311278
    final String iframeId = "311278";
    final String url =
        "https://accept.paymob.com/api/acceptance/iframes/$iframeId?payment_token=${widget.paymentKey}";

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // تتبع نجاح العملية من خلال الرابط الراجع
            if (request.url.contains('success=true')) {
              _handleSuccessfulPayment();
              return NavigationDecision.prevent;
            } else if (request.url.contains('success=false')) {
              Get.back();
              Get.snackbar(
                "فشل الدفع",
                "تم رفض العملية أو إلغاؤها، يرجى إعادة المحاولة.",
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _handleSuccessfulPayment() async {
    // تفعيل الاشتراك لمدة 30 يوم وإعادة توجيه المستخدم
    await AuthController.instance.activateSubscription(30);

    Get.snackbar(
      "تم بنجاح",
      "تمت عملية الدفع وتفعيل اشتراكك بنجاح!",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    Get.offAll(() => const AuthGate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إتمام الدفع الإلكتروني"),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
