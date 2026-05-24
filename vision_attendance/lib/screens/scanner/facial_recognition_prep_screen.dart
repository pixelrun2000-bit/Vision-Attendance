// lib/screens/scanner/facial_recognition_prep_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../navigation/app_router.dart';
import '../../widgets/shared_widgets.dart';

class FacialRecognitionPrepScreen extends StatelessWidget {
  const FacialRecognitionPrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Vision Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // ─── Animated Face Icon ───────────────────────────────────
            _AnimatedFacePrep(),
            const SizedBox(height: 32),
            const Text('Ready to Scan',
                style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
              'Position your face in good lighting and look directly at the camera for the best results.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // ─── Checklist ────────────────────────────────────────────
            const _PrepChecklist(),
            const Spacer(),

            AppPrimaryButton(
              label: 'Start Check-In',
              icon: Icons.face_retouching_natural_rounded,
              onPressed: () => context.push(AppRoutes.faceScanCheckin),
            ),
            const SizedBox(height: 12),
            AppOutlineButton(
              label: 'Check-Out Instead',
              icon: Icons.logout_rounded,
              onPressed: () => context.push(AppRoutes.checkoutFaceScan),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AnimatedFacePrep extends StatefulWidget {
  @override
  State<_AnimatedFacePrep> createState() => _AnimatedFacePrepState();
}

class _AnimatedFacePrepState extends State<_AnimatedFacePrep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.1),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.face_retouching_natural_rounded,
          size: 90,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _PrepChecklist extends StatelessWidget {
  const _PrepChecklist();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Ensure your face is well-lit',
      'Remove glasses if possible',
      'Look directly at the camera',
      'Stay still during the scan',
    ];

    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 13),
                    ),
                    const SizedBox(width: 12),
                    Text(item, style: AppTextStyles.bodyLarge),
                  ],
                ),
              ))
          .toList(),
    );
  }
}