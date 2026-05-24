// lib/screens/scanner/checkin_success_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../navigation/app_router.dart';
import '../../widgets/shared_widgets.dart';

class CheckinSuccessScreen extends StatefulWidget {
  const CheckinSuccessScreen({super.key});

  @override
  State<CheckinSuccessScreen> createState() => _CheckinSuccessScreenState();
}

class _CheckinSuccessScreenState extends State<CheckinSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _cardsController;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeIn),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _checkController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _cardsController.forward();
      });
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // ─── Animated Check ────────────────────────────────────
                AnimatedBuilder(
                  animation: _checkController,
                  builder: (_, child) => Opacity(
                    opacity: _checkOpacity.value,
                    child: Transform.scale(
                      scale: _checkScale.value,
                      child: child,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.08),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      ),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SECURELY\nENCRYPTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                const Text('Check-in Successful',
                    style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                const Text(
                  'Identity verified. Your session has started.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // ─── Info Cards ────────────────────────────────────────
                AnimatedBuilder(
                  animation: _cardsController,
                  builder: (_, child) => Opacity(
                    opacity: _cardsController.value,
                    child: Transform.translate(
                      offset:
                          Offset(0, 20 * (1 - _cardsController.value)),
                      child: child,
                    ),
                  ),
                  child: Column(
                    children: [
                      AppInfoCard(
                        label: 'Recording Time',
                        value:
                            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour < 12 ? 'AM' : 'PM'}',
                        icon: Icons.access_time_rounded,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      AppInfoCard(
                        label: 'Verified Location',
                        value: 'HQ North Wing',
                        icon: Icons.location_on_rounded,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: 12),

                      // ─── Map Placeholder ─────────────────────────
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.map_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            // ── AI MODULE PLACEHOLDER ─────────────
                            // TODO: Replace with real Google Maps or
                            // Flutter Map widget showing geofence
                            // ─────────────────────────────────────
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        )),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'LIVE SYNC ACTIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                AppPrimaryButton(
                  label: 'Back to Dashboard',
                  onPressed: () => context.go(AppRoutes.dashboard),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.attendanceLog),
                  child: const Text(
                    'View Attendance Log',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Check-In Failure Screen ──────────────────────────────────────────────────

class CheckinFailureScreen extends StatelessWidget {
  final String reason;
  const CheckinFailureScreen({super.key, this.reason = 'Verification failed'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withOpacity(0.1),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.error,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Check-in Failed',
                    style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'We could not verify your identity. Please ensure your face is clearly visible and try again.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // ─── Failure Reasons ──────────────────────────────────
                ...[
                  ('Poor Lighting', 'Ensure face is well-lit'),
                  ('Face Obstructed', 'Remove masks or glasses'),
                  ('Camera Angle', 'Look directly at camera'),
                ].map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.$1, style: AppTextStyles.titleLarge),
                              Text(r.$2, style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                AppPrimaryButton(
                  label: 'Try Again',
                  icon: Icons.refresh_rounded,
                  onPressed: () => context.go(AppRoutes.faceScanCheckin),
                ),
                const SizedBox(height: 12),
                AppOutlineButton(
                  label: 'Back to Dashboard',
                  icon: Icons.dashboard_rounded,
                  onPressed: () => context.go(AppRoutes.dashboard),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Checkout Summary Screen ──────────────────────────────────────────────────

class CheckoutSummaryScreen extends StatelessWidget {
  const CheckoutSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Check-out Summary'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Summary Header ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Session Complete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Well done! You\'ve checked out successfully.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const AppSectionHeader(title: 'Today\'s Summary'),
            const SizedBox(height: 16),

            _SummaryRow('Check-In Time', '08:42 AM'),
            _SummaryRow('Check-Out Time', '05:15 PM'),
            _SummaryRow('Total Duration', '8h 33m'),
            _SummaryRow('Location', 'HQ North Wing'),
            _SummaryRow('Status', 'Standard Work Day'),

            const SizedBox(height: 24),
            const AppSectionHeader(title: 'Verification Details'),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: AppColors.success, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Identity Verified',
                            style: AppTextStyles.titleLarge),
                        Text('AI face recognition — 98.4% confidence',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            AppPrimaryButton(
              label: 'Back to Dashboard',
              onPressed: () => context.go(AppRoutes.dashboard),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.titleLarge),
        ],
      ),
    );
  }
}
