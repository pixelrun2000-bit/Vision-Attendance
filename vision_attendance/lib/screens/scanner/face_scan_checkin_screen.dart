import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import '../../services/attendance_camera_gateway.dart';
import '../../services/face_match_evaluator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';

enum AttendanceScanMode { checkin, checkout }

class FaceScanCheckinScreen extends StatelessWidget {
  final AttendanceCameraGateway? gateway;
  final FaceMatchEvaluator evaluator;
  final String? successRouteOverride;
  final String? failureRouteOverride;
  final Map<String, dynamic>? roomData;

  const FaceScanCheckinScreen({
    super.key,
    this.gateway,
    this.evaluator = const FaceMatchEvaluator(),
    this.successRouteOverride,
    this.failureRouteOverride,
    this.roomData,
  });

  @override
  Widget build(BuildContext context) {
    return _FaceAttendanceScanScreen(
      mode: AttendanceScanMode.checkin,
      gateway: gateway,
      evaluator: evaluator,
      successRouteOverride: successRouteOverride,
      failureRouteOverride: failureRouteOverride,
      roomData: roomData,
    );
  }
}

class CheckoutFaceScanScreen extends StatelessWidget {
  final AttendanceCameraGateway? gateway;
  final FaceMatchEvaluator evaluator;
  final String? successRouteOverride;
  final String? failureRouteOverride;

  const CheckoutFaceScanScreen({
    super.key,
    this.gateway,
    this.evaluator = const FaceMatchEvaluator(),
    this.successRouteOverride,
    this.failureRouteOverride,
  });

  @override
  Widget build(BuildContext context) {
    return _FaceAttendanceScanScreen(
      mode: AttendanceScanMode.checkout,
      gateway: gateway,
      evaluator: evaluator,
      successRouteOverride: successRouteOverride,
      failureRouteOverride: failureRouteOverride,
    );
  }
}

class _FaceAttendanceScanScreen extends StatefulWidget {
  final AttendanceScanMode mode;
  final AttendanceCameraGateway? gateway;
  final FaceMatchEvaluator evaluator;
  final String? successRouteOverride;
  final String? failureRouteOverride;
  final Map<String, dynamic>? roomData;

  const _FaceAttendanceScanScreen({
    required this.mode,
    this.gateway,
    required this.evaluator,
    this.successRouteOverride,
    this.failureRouteOverride,
    this.roomData,
  });

  @override
  State<_FaceAttendanceScanScreen> createState() => _FaceAttendanceScanScreenState();
}

class _FaceAttendanceScanScreenState extends State<_FaceAttendanceScanScreen> {
  late final AttendanceCameraGateway _gateway;
  bool _isInitializing = true;
  bool _isProcessing = false;
  String _status = 'Initializing camera...';

  bool get _isCheckin => widget.mode == AttendanceScanMode.checkin;

  @override
  void initState() {
    super.initState();
    _gateway = widget.gateway ?? DeviceAttendanceCameraGateway();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _gateway.initialize();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _status = 'Position your face and tap capture';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _status = 'Unable to open camera. Check permissions and retry.';
      });
    }
  }

  Future<void> _captureAndVerify() async {
    if (_isProcessing || !_gateway.isReady) return;

    setState(() {
      _isProcessing = true;
      _status = 'Capturing face frame...';
    });

    try {
      final frame = await _gateway.captureFrame();
      if (!mounted) return;

      setState(() => _status = 'Verifying identity...');

      final result = widget.evaluator.evaluate(frame);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      final successRoute = widget.successRouteOverride ??
          (_isCheckin ? AppRoutes.checkinSuccess : AppRoutes.checkoutSummary);
      final failureRoute = widget.failureRouteOverride ?? AppRoutes.checkinFailure;

      if (result.isMatch) {
        if (_isCheckin && widget.roomData != null) {
          setState(() => _status = 'Registering Attendance...');
          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token') ?? '';
            final api = ApiService(token: token);
            final pos = await Geolocator.getCurrentPosition();
            
            await api.checkinByRoom(
              roomCode: widget.roomData!['room_code'],
              latitude: pos.latitude,
              longitude: pos.longitude,
            );
          } catch (e) {
            setState(() {
              _isProcessing = false;
              _status = 'Check-in failed on server. Try again.';
            });
            return;
          }
        }
        context.go(successRoute);
      } else {
        if (_isCheckin && widget.roomData != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token') ?? '';
            final api = ApiService(token: token);
            final pos = await Geolocator.getCurrentPosition();
            
            await api.checkinByRoom(
              roomCode: widget.roomData!['room_code'],
              latitude: pos.latitude,
              longitude: pos.longitude,
              isFailed: true,
              failureReason: 'Face not recognized, or wearing glasses',
            );
          } catch (_) {}
        }
        context.go(failureRoute);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _status = 'Capture failed. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _gateway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCheckin ? 'Check-in Face Scan' : 'Check-out Face Scan';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            const AiStatusBadge(label: 'AI CORE ACTIVE'),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _gateway.buildPreview(),
                      if (_isInitializing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () => context.pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_isInitializing || _isProcessing) ? null : _captureAndVerify,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt_rounded),
                      label: Text(_isProcessing ? 'Processing' : 'Capture & Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
