import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_attendance/main.dart';
import 'package:vision_attendance/navigation/app_router.dart';

void main() {
  testWidgets('App starts on login screen', (WidgetTester tester) async {
    appRouter.go(AppRoutes.login);
    await tester.pumpWidget(const ProviderScope(child: VisionAttendanceApp()));
    await tester.pumpAndSettle();

    expect(find.text('Vision Attendance'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });

  testWidgets('Login button routes to dashboard', (WidgetTester tester) async {
    appRouter.go(AppRoutes.login);
    await tester.pumpWidget(const ProviderScope(child: VisionAttendanceApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'demo');
    await tester.enterText(find.byType(TextFormField).at(1), 'demo123');
    await tester.tap(find.text('Log In'));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
  });
}
