import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// تأكد إن اسم الباكدج هنا مطابق لاسم مشروعك في pubspec.yaml
import 'package:dvr_timer/main.dart';

void main() {
  testWidgets('App loads successfully smoke test', (WidgetTester tester) async {
    // تشغيل التطبيق بتاعنا
    await tester.pumpWidget(const DvrTimerApp());

    // اختبار بسيط للتأكد إن التطبيق بيفتح بدون مشاكل
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
