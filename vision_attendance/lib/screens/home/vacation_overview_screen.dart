// lib/screens/home/vacation_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../navigation/app_router.dart';
import '../../widgets/shared_widgets.dart';
import '../../state/user_profile_state.dart';

class VacationOverviewScreen extends ConsumerWidget {
  const VacationOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AVAILABLE BALANCE',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              letterSpacing: 1)),
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
                      const SizedBox(height: 16),
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
                                side: const BorderSide(color: Colors.white54),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Request Leave'),
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
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('View Calendar'),
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
                const SizedBox(height: 16),

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
                const SizedBox(height: 24),

                // ─── Request History ───────────────────────────────
                AppSectionHeader(
                  title: 'Request History',
                  subtitle: 'Manage and track your previous leave applications.',
                  action: GestureDetector(
                    onTap: () {},
                    child: const Text('Export PDF',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 16),

                ..._vacationRequests.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VacationRequestCard(
                        request: r,
                        onTap: () =>
                            context.push(AppRoutes.vacationRequestDetails),
                      ),
                    )),

                const SizedBox(height: 24),

                // ─── Team Schedule (AI placeholder) ────────────────
                AppSectionHeader(
                  title: 'Team Schedule',
                  subtitle:
                      'Our AI Predictor suggests booking your next leave in June when team availability is highest (85%).',
                ),
                const SizedBox(height: 12),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(Icons.map_rounded,
                            size: 48, color: Colors.grey.shade400),
                      ),
                      // ── AI MODULE PLACEHOLDER ───────────────────────
                      // TODO: Show team geolocation / availability map
                      // Using: google_maps_flutter or flutter_map
                      // ───────────────────────────────────────────────
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8)
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('OFFICE STATUS: 65% Hybrid Today',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
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

const _vacationRequests = [
  _VacationRequest(title: 'Summer Break 2024', dateRange: 'Aug 15 - Aug 20 (5 Days)',
      status: 'Pending', icon: Icons.beach_access_rounded,
      iconColor: Color(0xFFF59E0B), iconBg: Color(0xFFFEF3C7)),
  _VacationRequest(title: 'Personal Leave', dateRange: 'Apr 02 - Apr 03 (2 Days)',
      status: 'Approved', icon: Icons.people_rounded,
      iconColor: Color(0xFF10B981), iconBg: Color(0xFFD1FAE5)),
  _VacationRequest(title: 'Sick Leave (Retroactive)', dateRange: 'Feb 14 (1 Day)',
      status: 'Rejected', icon: Icons.medical_services_rounded,
      iconColor: Color(0xFFEF4444), iconBg: Color(0xFFFEE2E2)),
  _VacationRequest(title: 'Annual Winter Trip', dateRange: 'Jan 05 - Jan 15 (10 Days)',
      status: 'Approved', icon: Icons.flight_takeoff_rounded,
      iconColor: Color(0xFF3B82F6), iconBg: Color(0xFFDEF0FE)),
];
