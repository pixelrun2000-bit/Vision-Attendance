import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vision_attendance/screens/scanner/face_scan_checkin_screen.dart';
import 'package:vision_attendance/services/attendance_camera_gateway.dart';
import 'package:vision_attendance/services/face_match_evaluator.dart';

class _FakeGateway implements AttendanceCameraGateway {
  final FaceScanFrame frame;
  bool _ready = false;

  _FakeGateway({required this.frame});

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    _ready = true;
  }

  @override
  Widget buildPreview() => Container(key: const Key('fake_camera_preview'));

  @override
  Future<FaceScanFrame> captureFrame() async => frame;

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('check-in scan navigates to success when frame is valid', (tester) async {
    final router = GoRouter(
      initialLocation: '/scan',
      routes: [
        GoRoute(
          path: '/scan',
          builder: (_, _) => FaceScanCheckinScreen(
            gateway: _FakeGateway(frame: const FaceScanFrame(bytesLength: 180000)),
            evaluator: const FaceMatchEvaluator(targetBytes: 100000, threshold: 0.6),
            successRouteOverride: '/success',
            failureRouteOverride: '/failure',
          ),
        ),
        GoRoute(path: '/success', builder: (_, _) => const Text('SUCCESS')),
        GoRoute(path: '/failure', builder: (_, _) => const Text('FAILURE')),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    expect(find.byKey(const Key('fake_camera_preview')), findsOneWidget);

    await tester.tap(find.text('Capture & Verify'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('SUCCESS'), findsOneWidget);
  });

  testWidgets('check-in scan navigates to failure when frame is weak', (tester) async {
    final router = GoRouter(
      initialLocation: '/scan',
      routes: [
        GoRoute(
          path: '/scan',
          builder: (_, _) => FaceScanCheckinScreen(
            gateway: _FakeGateway(frame: const FaceScanFrame(bytesLength: 1000)),
            evaluator: const FaceMatchEvaluator(targetBytes: 100000, threshold: 0.8),
            successRouteOverride: '/success',
            failureRouteOverride: '/failure',
          ),
        ),
        GoRoute(path: '/success', builder: (_, _) => const Text('SUCCESS')),
        GoRoute(path: '/failure', builder: (_, _) => const Text('FAILURE')),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    await tester.tap(find.text('Capture & Verify'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('FAILURE'), findsOneWidget);
  });
}
