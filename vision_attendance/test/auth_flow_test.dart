import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_attendance/main.dart';
import 'package:vision_attendance/navigation/app_router.dart';

void main() {
  testWidgets('Forgot password link opens forgot password screen',
      (WidgetTester tester) async {
    appRouter.go(AppRoutes.login);
    await tester.pumpWidget(const ProviderScope(child: VisionAttendanceApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('Send Reset Code'), findsOneWidget);
  });

  testWidgets('Forgot password flow reaches OTP screen',
      (WidgetTester tester) async {
    appRouter.go(AppRoutes.login);
    await tester.pumpWidget(const ProviderScope(child: VisionAttendanceApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send Reset Code'));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    expect(find.text('OTP Verification'), findsOneWidget);
    expect(find.text('Verify Code'), findsOneWidget);
  });
}
