import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'auth_gate.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebView({super.key, required this.paymentUrl});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController controller;
  bool isLoading = true;
  bool isPaymentHandled = false;

  // رابط العودة المحدد بدقة
  static const String successRedirectUrl =
      "https://dvr-timer-app.web.app/payment-success";

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(
        "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => isLoading = true);
            debugPrint("🏁 Started loading: $url");
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
            debugPrint("✅ Finished loading: $url");
          },
          onNavigationRequest: (NavigationRequest request) {
            final String url = request.url;
            final String lowerUrl = url.toLowerCase();

            debugPrint("🔍 Navigation Request: $url");

            // 1. إذا كان طلب التنقل داخل نطاق كاشير نفسه (صفحة الفيزا/المحفظة) -> اسمح بالتنقل طبيعي
            if (lowerUrl.contains('kashier.io') ||
                lowerUrl.contains('kashier.mobi')) {
              return NavigationDecision.navigate;
            }

            // 2. التحقق من النجاح: فقط إذا بدأ الـ URL فعلياً برابط العودة المخصص
            if (url.startsWith(successRedirectUrl) ||
                (lowerUrl.contains('paymentstatus=success') &&
                    !lowerUrl.contains('merchantredirect'))) {
              if (!isPaymentHandled) {
                isPaymentHandled = true;
                _handleSuccessfulPayment();
              }
              return NavigationDecision.prevent;
            }

            // 3. التحقق من الفشل أو الإلغاء
            if (lowerUrl.contains('paymentstatus=failed') ||
                lowerUrl.contains('status=failure') ||
                lowerUrl.contains('status=cancelled')) {
              if (!isPaymentHandled) {
                isPaymentHandled = true;
                Get.back();
                Get.snackbar(
                  "فشل الدفع",
                  "تمت إلغاء العملية أو رفض الكارت، يرجى إعادة المحاولة.",
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handleSuccessfulPayment() async {
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
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        ],
      ),
    );
  }
}
