import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_attendance/screens/auth/otp_verification_screen.dart';

void main() {
  testWidgets('OTP screen renders six code fields and countdown',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OtpVerificationScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TextFormField), findsNWidgets(6));
    expect(find.text('Resend code in 0:59'), findsOneWidget);
  });
}
