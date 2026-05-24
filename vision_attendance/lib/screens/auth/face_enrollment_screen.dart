import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import '../../services/attendance_camera_gateway.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../state/user_profile_state.dart';

class FaceEnrollmentScreen extends ConsumerStatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  ConsumerState<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends ConsumerState<FaceEnrollmentScreen> {
  late final AttendanceCameraGateway _gateway;
  bool _isInitializing = true;
  bool _isProcessing = false;
  int _currentStep = 1;
  final int _totalSteps = 3;
  String _status = 'Initializing camera...';

  @override
  void initState() {
    super.initState();
    _gateway = DeviceAttendanceCameraGateway();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _gateway.initialize();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _status = 'Capture your face (Photo $_currentStep/$_totalSteps)';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _status = 'Unable to open camera. Check permissions.';
      });
    }
  }

  Future<void> _captureAndEnroll() async {
    if (_isProcessing || !_gateway.isReady) return;

    setState(() {
      _isProcessing = true;
      _status = 'Processing Photo $_currentStep...';
    });

    try {
      final frame = await _gateway.captureFrame();
      if (!mounted) return;

      final api = ref.read(apiServiceProvider);
      final result = await api.enrollSelf(frame.path);

      if (!mounted) return;

      if (result['success'] == true) {
        if (_currentStep < _totalSteps) {
          setState(() {
            _currentStep++;
            _isProcessing = false;
            _status = 'Success! Take Photo $_currentStep/$_totalSteps';
          });
        } else {
          _status = 'Enrollment Complete!';
          // Refresh profile so MainShell knows we have a photo now
          await ref.read(userProfileProvider.notifier).refreshMe();
          
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) context.go(AppRoutes.dashboard);
        }
      } else {
        setState(() {
          _isProcessing = false;
          _status = 'Enrollment failed: ${result['reason'] ?? 'Try again'}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _status = 'Error: ${e.toString().replaceFirst('Exception: ', '')}';
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.go(AppRoutes.dashboard),
                  ),
                  const Expanded(
                    child: Text(
                      'Identity Setup',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _currentStep / _totalSteps,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Capture $_currentStep of $_totalSteps (Different angles)',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            
            const SizedBox(height: 24),
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
                          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    label: _isProcessing ? 'Processing...' : 'Capture Photo $_currentStep',
                    onPressed: (_isInitializing || _isProcessing) ? null : _captureAndEnroll,
                    isLoading: _isProcessing,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
