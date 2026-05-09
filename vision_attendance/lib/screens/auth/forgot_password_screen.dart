// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../navigation/app_router.dart';
import '../../widgets/shared_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _sendReset() async {
    setState(() => _isLoading = true);
    // ── BACKEND MODULE PLACEHOLDER ──────────────────────────────────────────
    // TODO: Call password reset API
    // await AuthService.sendPasswordReset(email: _emailController.text);
    // ────────────────────────────────────────────────────────────────────────
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (mounted) context.push(AppRoutes.otpVerification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Forgot Password'),
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
              child: const Icon(Icons.lock_reset_rounded,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 24),
            const Text('Reset Your Password',
                style: AppTextStyles.displayMedium),
            const SizedBox(height: 8),
            const Text(
              'Enter your registered email address and we\'ll send you an OTP to reset your password.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Email Address',
              hint: 'Enter your email',
              controller: _emailController,
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            AppPrimaryButton(
              label: 'Send Reset Code',
              onPressed: _sendReset,
              isLoading: _isLoading,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
