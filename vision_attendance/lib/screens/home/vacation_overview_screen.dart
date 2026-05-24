// lib/screens/home/vacation_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../navigation/app_router.dart';
import '../../widgets/shared_widgets.dart';
import '../../state/user_profile_state.dart';
import '../../state/vacation_state.dart';
import 'package:intl/intl.dart';

class VacationOverviewScreen extends ConsumerStatefulWidget {
  const VacationOverviewScreen({super.key});

  @override
  ConsumerState<VacationOverviewScreen> createState() => _VacationOverviewScreenState();
}

class _VacationOverviewScreenState extends ConsumerState<VacationOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vacationProvider.notifier).loadVacations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).user;
    final vacationState = ref.watch(vacationProvider);
    final blocked = user?.isStudent ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.background,
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white, size: 16),
              ),
            ),
            title: const Text('Vision Attendance'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Balance Card ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AVAILABLE BALANCE',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('15',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900)),
                          SizedBox(width: 6),
                          Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text('Days',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 20)),
                          ),
                        ],
                      ),
                      const Text(
                        'Your vacation cycle resets on January 1st. You have 3 pending approval requests.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  blocked
                                      ? ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Students are not allowed to request vacations'),
                                          ),
                                        )
                                      : context.push(AppRoutes.vacationRequest),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Request Leave', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => context.push(AppRoutes.vacationCalendar),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              child: const Text('View Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      if (blocked)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Your role is student: vacation requests are disabled.',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Quick Stats ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _QuickStat(
                        icon: Icons.calendar_today_rounded,
                        label: 'Used This Year',
                        value: '12 Days',
                        iconColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickStat(
                        icon: Icons.hourglass_top_rounded,
                        label: 'Pending Approval',
                        value: '3 Days',
                        iconColor: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ─── Request History ───────────────────────────────
                AppSectionHeader(
                  title: 'Request History',
                  subtitle: 'Manage and track your leave applications.',
                  action: TextButton.icon(
                    onPressed: () => ref.read(vacationProvider.notifier).loadVacations(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (vacationState.isLoading && vacationState.requests.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ))
                else if (vacationState.requests.isEmpty)
                  Center(child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(Icons.beach_access_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No vacation requests found', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ))
                else
                  ...vacationState.requests.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VacationRequestCard(
                          request: _mapToVacationRequest(r),
                          onTap: () =>
                              context.push(AppRoutes.vacationRequestDetails, extra: r),
                        ),
                      )),

                const SizedBox(height: 32),

                // ─── Team Schedule (AI placeholder) ────────────────
                AppSectionHeader(
                  title: 'AI Prediction',
                  subtitle:
                      'Our AI Predictor suggests booking your next leave in June.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.success),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Team availability is highest (85%) in June. Plan ahead for a higher approval chance!',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  _VacationRequest _mapToVacationRequest(Map<String, dynamic> r) {
    final type = r['type'] ?? 'Leave';
    final status = (r['status'] as String? ?? 'pending').toLowerCase();
    final start = DateTime.parse(r['start_date']);
    final end = DateTime.parse(r['end_date']);
    final days = r['days_count'] ?? 0;
    
    final dateRange = "${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)} ($days Days)";

    IconData icon = Icons.beach_access_rounded;
    Color color = const Color(0xFFF59E0B);
    Color bg = const Color(0xFFFEF3C7);

    if (type.toLowerCase().contains('sick')) {
      icon = Icons.medical_services_rounded;
      color = const Color(0xFFEF4444);
      bg = const Color(0xFFFEE2E2);
    } else if (type.toLowerCase().contains('personal')) {
      icon = Icons.people_rounded;
      color = const Color(0xFF10B981);
      bg = const Color(0xFFD1FAE5);
    }

    return _VacationRequest(
      title: type,
      dateRange: dateRange,
      status: status.substring(0, 1).toUpperCase() + status.substring(1),
      icon: icon,
      iconColor: color,
      iconBg: bg,
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.headlineMedium),
        ],
      ),
    );
  }
}

class _VacationRequestCard extends StatelessWidget {
  final _VacationRequest request;
  final VoidCallback onTap;

  const _VacationRequestCard(
      {required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: request.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(request.icon, color: request.iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.title, style: AppTextStyles.titleLarge),
                  Text(request.dateRange, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 6),
                  _buildStatusChip(request.status),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return switch (status) {
      'Pending' => AppStatusChip.pending(status),
      'Approved' => AppStatusChip.approved(status),
      'Rejected' => AppStatusChip.rejected(status),
      _ => AppStatusChip.pending(status),
    };
  }
}

class _VacationRequest {
  final String title, dateRange, status;
  final IconData icon;
  final Color iconColor, iconBg;

  const _VacationRequest({
    required this.title, required this.dateRange, required this.status,
    required this.icon, required this.iconColor, required this.iconBg,
  });
}

// End of helpers

final vacProvider = vacationProvider;
