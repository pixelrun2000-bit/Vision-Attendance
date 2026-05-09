// lib/screens/auth/otp_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../navigation/app_router.dart';
import '../../widgets/shared_widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _countdown = 59;
  late Timer _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) {
        t.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _onOtpDigit(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verify() async {
    setState(() => _isLoading = true);
    // ── BACKEND MODULE PLACEHOLDER ──────────────────────────────────────────
    // TODO: Verify OTP against backend
    // final otp = _controllers.map((c) => c.text).join();
    // await AuthService.verifyOtp(otp: otp);
    // ────────────────────────────────────────────────────────────────────────
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (mounted) context.go(AppRoutes.dashboard);
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('OTP Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.sms_outlined,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 24),
            const Text('Enter Verification Code',
                style: AppTextStyles.displayMedium),
            const SizedBox(height: 8),
            const Text(
              'We sent a 6-digit code to your email. Please enter it below.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 40),

            // ─── OTP Fields ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _OtpField(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                onChanged: (v) => _onOtpDigit(i, v),
              )),
            ),
            const SizedBox(height: 32),

            AppPrimaryButton(
              label: 'Verify Code',
              onPressed: _verify,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 24),

            // ─── Resend ──────────────────────────────────────────────────
            Center(
              child: _countdown > 0
                  ? Text(
                      'Resend code in 0:${_countdown.toString().padLeft(2, '0')}',
                      style: AppTextStyles.bodyMedium,
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() => _countdown = 59);
                        _startCountdown();
                        // ── BACKEND MODULE PLACEHOLDER ──────────────────
                        // TODO: Resend OTP
                      },
                      child: const Text(
                        'Resend Code',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
