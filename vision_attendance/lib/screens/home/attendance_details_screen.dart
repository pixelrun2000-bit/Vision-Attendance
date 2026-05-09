// lib/screens/home/attendance_details_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AttendanceDetailsScreen extends StatefulWidget {
  const AttendanceDetailsScreen({super.key});

  @override
  State<AttendanceDetailsScreen> createState() =>
      _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState extends State<AttendanceDetailsScreen> {
  bool _correctionRequested = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Attendance Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Session Header ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('JUN',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600)),
                          Text('14',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  height: 1)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Friday Session',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            Text('Standard Work Day',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('8h 33m',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      _TimeChip(label: 'CHECK IN', time: '08:42 AM'),
                      SizedBox(width: 16),
                      _TimeChip(label: 'CHECK OUT', time: '05:15 PM'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Verification Details ───────────────────────────────────
            const AppSectionHeader(title: 'Verification Log'),
            const SizedBox(height: 14),
            _VerificationTile(
              label: 'Check-In Method',
              value: 'AI Face Recognition',
              icon: Icons.face_retouching_natural_rounded,
              status: 'Verified',
              statusColor: AppColors.success,
            ),
            _VerificationTile(
              label: 'Confidence Score',
              value: '98.4%',
              icon: Icons.analytics_rounded,
              status: 'High',
              statusColor: AppColors.success,
            ),
            _VerificationTile(
              label: 'Location',
              value: 'HQ North Wing · Geofence A-4',
              icon: Icons.location_on_rounded,
              status: 'Confirmed',
              statusColor: AppColors.success,
            ),
            _VerificationTile(
              label: 'IP Address',
              value: '192.168.1.2',
              icon: Icons.wifi_rounded,
              status: 'Trusted',
              statusColor: AppColors.primary,
            ),
            const SizedBox(height: 24),

            // ─── Break Summary ──────────────────────────────────────────
            const AppSectionHeader(title: 'Break Summary'),
            const SizedBox(height: 14),
            _BreakRow('Lunch Break', '12:00 PM', '01:00 PM', '1h 0m'),
            _BreakRow('Short Break', '03:15 PM', '03:30 PM', '15m'),
            const SizedBox(height: 24),

            // ─── AI Analysis ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('AI Attendance Analysis',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ── AI MODULE PLACEHOLDER ──────────────────────────────
                  // TODO: Connect to AI analytics backend
                  // Provide: productivity score, anomaly detection,
                  //          comparison with team avg, recommendations
                  // ──────────────────────────────────────────────────────
                  const Text(
                    'Productivity score: 94/100. You were 8 minutes early today. No anomalies detected. Your average session this week is 8h 41m — above team average by 23 minutes.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Correction Section ─────────────────────────────────────
            const AppSectionHeader(
              title: 'Request a Correction',
              subtitle: 'Noticed an error in your attendance record?',
            ),
            const SizedBox(height: 16),
            if (!_correctionRequested) ...[
              _CorrectionOption(
                label: 'Incorrect Check-In Time',
                onTap: () => _showCorrectionSheet(context, 'Check-In Time'),
              ),
              _CorrectionOption(
                label: 'Incorrect Check-Out Time',
                onTap: () => _showCorrectionSheet(context, 'Check-Out Time'),
              ),
              _CorrectionOption(
                label: 'Missing Session Record',
                onTap: () => _showCorrectionSheet(context, 'Missing Session'),
              ),
              _CorrectionOption(
                label: 'Wrong Location',
                onTap: () => _showCorrectionSheet(context, 'Location'),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Correction request submitted. HR will review within 24 hours.',
                        style: AppTextStyles.bodyMedium,
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

  void _showCorrectionSheet(BuildContext context, String field) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Correct $field',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: 6),
            const Text(
                'Provide the correct value and a brief explanation.',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Correct Value',
              hint: 'e.g. 08:30 AM',
              controller: controller,
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Submit Correction',
              onPressed: () {
                Navigator.pop(context);
                setState(() => _correctionRequested = true);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;

  const _TimeChip({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 10, letterSpacing: 0.5)),
          Text(time,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
        ],
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String status;
  final Color statusColor;

  const _VerificationTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 11)),
                Text(value, style: AppTextStyles.titleLarge),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _BreakRow extends StatelessWidget {
  final String label;
  final String start;
  final String end;
  final String duration;

  const _BreakRow(this.label, this.start, this.end, this.duration);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.titleLarge),
          ),
          Text('$start – $end', style: AppTextStyles.bodyMedium),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(duration,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _CorrectionOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CorrectionOption(
      {required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label, style: AppTextStyles.titleLarge)),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
