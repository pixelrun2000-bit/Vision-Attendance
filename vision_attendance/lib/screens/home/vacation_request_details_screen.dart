// lib/screens/home/vacation_request_details_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class VacationRequestDetailsScreen extends StatelessWidget {
  const VacationRequestDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Request Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showOptionsSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Status Banner ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.beach_access_rounded,
                        color: Color(0xFFF59E0B), size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Summer Break 2024',
                            style: AppTextStyles.headlineMedium),
                        SizedBox(height: 2),
                        Text('Aug 15 – Aug 20 · 5 Working Days',
                            style: AppTextStyles.bodyMedium),
                        SizedBox(height: 8),
                        AppStatusChip(
                          label: 'Pending',
                          color: Color(0xFFF59E0B),
                          backgroundColor: Color(0xFFFEF9EE),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Details ────────────────────────────────────────────────
            const AppSectionHeader(title: 'Leave Information'),
            const SizedBox(height: 16),
            _DetailRow(label: 'Leave Type', value: 'Annual Leave'),
            _DetailRow(label: 'Start Date', value: 'August 15, 2024'),
            _DetailRow(label: 'End Date', value: 'August 20, 2024'),
            _DetailRow(label: 'Duration', value: '5 Working Days'),
            _DetailRow(label: 'Days Remaining After', value: '10 Days'),
            _DetailRow(label: 'Submitted On', value: 'July 28, 2024'),
            const SizedBox(height: 24),

            // ─── Reason ─────────────────────────────────────────────────
            const AppSectionHeader(title: 'Reason'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Annual family vacation planned for the summer break period. All pending tasks will be completed before the leave commences.',
                style: AppTextStyles.bodyLarge,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Approval Timeline ─────────────────────────────────────
            const AppSectionHeader(title: 'Approval Timeline'),
            const SizedBox(height: 16),
            _TimelineStep(
              label: 'Submitted',
              date: 'Jul 28, 2024',
              isDone: true,
              isLast: false,
            ),
            _TimelineStep(
              label: 'Under Review by HR',
              date: 'Jul 29, 2024',
              isDone: true,
              isLast: false,
            ),
            _TimelineStep(
              label: 'Manager Approval',
              date: 'Pending',
              isDone: false,
              isLast: false,
            ),
            _TimelineStep(
              label: 'Final Confirmation',
              date: 'Pending',
              isDone: false,
              isLast: true,
            ),
            const SizedBox(height: 32),

            // ─── AI Insight ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.06),
                    AppColors.primary.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primary, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Approval Prediction',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.primary,
                            )),
                        SizedBox(height: 4),
                        // ── AI MODULE PLACEHOLDER ──────────────────────
                        // TODO: Connect AI prediction model
                        // Factors: team availability, project timeline,
                        //          historical approval rate, manager patterns
                        // ──────────────────────────────────────────────
                        Text(
                          'Based on team calendar and historical data, your request has a 78% approval probability.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Cancel Button ─────────────────────────────────────────
            AppOutlineButton(
              label: 'Cancel Request',
              icon: Icons.cancel_outlined,
              onPressed: () {
                _showCancelDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
            title: const Text('Edit Request'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded, color: AppColors.primary),
            title: const Text('Share Details'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.primary),
            title: const Text('Export PDF'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Request?', style: AppTextStyles.headlineMedium),
        content: const Text(
          'Are you sure you want to cancel this leave request? This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep It'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      decoration: const BoxDecoration(
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

class _TimelineStep extends StatelessWidget {
  final String label;
  final String date;
  final bool isDone;
  final bool isLast;

  const _TimelineStep({
    required this.label,
    required this.date,
    required this.isDone,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDone ? AppColors.primary : AppColors.border,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : Icons.radio_button_unchecked,
                color: isDone ? Colors.white : AppColors.textSecondary,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone ? AppColors.primary : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.titleLarge),
              Text(date, style: AppTextStyles.bodyMedium),
              SizedBox(height: isLast ? 0 : 12),
            ],
          ),
        ),
      ],
    );
  }
}
