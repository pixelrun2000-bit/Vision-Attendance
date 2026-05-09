// lib/screens/home/dashboard_screen.dart
// ─── Real-time Employee Dashboard ────────────────────────────────────────────
// • Loads real today-status + monthly summary from API
// • Auto-refreshes every 60 s (simulating real-time for mobile)
// • Shows actual check-in time, room, attendance history
// • Quick-access to check-in, logs, vacation, profile
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../state/user_profile_state.dart';
import '../../services/api_service.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // ── state ───────────────────────────────────────────────────────────────────
  late DateTime _now;
  Timer? _clockTimer;
  Timer? _refreshTimer;

  Map<String, dynamic>? _today;     // today's check-in record
  Map<String, dynamic>? _summary;   // monthly summary
  bool _isCheckedIn = false;
  bool _loadingStatus = true;
  late ApiService _api;

  // ── lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _now = DateTime.now();

    // clock tick
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Build service with token after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(userProfileProvider)?.token ?? '';
      _api = ApiService(token: token);
      _loadData();
      _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadData());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── data fetching ────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    try {
      final todayRes   = await _api.getTodayStatus();
      final summaryRes = await _api.getMyLogs();

      if (mounted) {
        setState(() {
          _today       = todayRes['today'] as Map<String, dynamic>?;
          _isCheckedIn = todayRes['is_checked_in'] == true;
          _summary     = summaryRes['summary'] as Map<String, dynamic>?;
          _loadingStatus = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────────
  String _fmtTime(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) { return '—'; }
  }

  String _workedHours() {
    if (_today == null) return '0h 0m';
    final inTime = DateTime.tryParse(_today!['checkin_time'] ?? '')?.toLocal();
    if (inTime == null) return '—';
    final outTime = _today!['checkout_time'] != null
        ? DateTime.tryParse(_today!['checkout_time'])?.toLocal()
        : DateTime.now();
    if (outTime == null) return '—';
    final diff = outTime.difference(inTime);
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  // ── build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: AppColors.background,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  backgroundImage: (user?.photoUrl.isNotEmpty == true)
                      ? NetworkImage(user!.photoUrl)
                      : null,
                  child: (user?.photoUrl.isNotEmpty != true)
                      ? Text(
                          (user?.fullNameEn ?? '?')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 14,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,', style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary)),
                  Text(
                    user?.fullNameEn.split(' ').first ?? 'User',
                    style: AppTextStyles.titleLarge,
                  ),
                ],
              ),
              actions: [
                // Live indicator
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Live', style: TextStyle(
                        color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600,
                      )),
                    ],
                  ),
                ),
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
                  const SizedBox(height: 16),

                  // ── Live clock ─────────────────────────────────────────────
                  Text(
                    DateFormat('EEEE, MMMM d').format(_now),
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    DateFormat('hh:mm:ss a').format(_now),
                    style: AppTextStyles.displayMedium.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Today's status card ────────────────────────────────────
                  _TodayCard(
                    isCheckedIn: _isCheckedIn,
                    loading: _loadingStatus,
                    today: _today,
                    workedHours: _workedHours(),
                    checkinTime: _fmtTime(_today?['checkin_time']),
                    roomName: _today?['room_name'] ?? '',
                    onCheckin: () => context.push(AppRoutes.facialRecognitionPrep),
                  ),
                  const SizedBox(height: 16),

                  // ── Monthly summary cards ──────────────────────────────────
                  if (_summary != null) ...[
                    AppSectionHeader(
                      title: 'This Month',
                      subtitle: 'Your attendance summary',
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: AppInfoCard(
                        label: 'Present',
                        value: '${_summary!['present'] ?? 0}',
                        icon: Icons.check_circle_rounded,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: AppInfoCard(
                        label: 'Late',
                        value: '${_summary!['late'] ?? 0}',
                        icon: Icons.access_time_rounded,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: AppInfoCard(
                        label: 'Absent',
                        value: '${_summary!['absent'] ?? 0}',
                        icon: Icons.cancel_rounded,
                      )),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: AppInfoCard(
                        label: 'Hours Today',
                        value: _isCheckedIn ? _workedHours() : '—',
                        icon: Icons.schedule_rounded,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: AppInfoCard(
                        label: 'Total Sessions',
                        value: '${_summary!['total_days'] ?? 0}',
                        icon: Icons.calendar_month_rounded,
                      )),
                    ]),
                    const SizedBox(height: 20),
                  ],

                  // ── Quick actions ──────────────────────────────────────────
                  AppSectionHeader(
                    title: 'Quick Actions',
                    subtitle: 'Access attendance tools quickly.',
                    action: TextButton(
                      onPressed: () => context.go(AppRoutes.attendanceLog),
                      child: const Text('Open Logs'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children: [
                      _ActionGridTile(
                        icon: Icons.face_retouching_natural_rounded,
                        title: 'Face\nCheck-in',
                        color: AppColors.primary,
                        badge: _isCheckedIn ? 'Checked in' : null,
                        onTap: () => context.push(AppRoutes.facialRecognitionPrep),
                      ),
                      _ActionGridTile(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Room\nCheck-in',
                        color: const Color(0xFF8B5CF6), // Purple
                        onTap: () => context.push(AppRoutes.faceScanCheckin),
                      ),
                      _ActionGridTile(
                        icon: Icons.list_alt_rounded,
                        title: 'Attendance\nLogs',
                        color: const Color(0xFFF59E0B), // Amber
                        onTap: () => context.go(AppRoutes.attendanceLog),
                      ),
                      _ActionGridTile(
                        icon: Icons.beach_access_rounded,
                        title: 'Vacation\nRequests',
                        color: const Color(0xFF10B981), // Emerald
                        onTap: () => context.go(AppRoutes.vacationOverview),
                      ),
                      _ActionGridTile(
                        icon: Icons.person_rounded,
                        title: 'Profile\nSettings',
                        color: const Color(0xFF3B82F6), // Blue
                        onTap: () => context.go(AppRoutes.profile),
                      ),
                      _ActionGridTile(
                        icon: Icons.notifications_rounded,
                        title: 'All\nAlerts',
                        color: const Color(0xFFEF4444), // Red
                        onTap: () => context.push(AppRoutes.notifications),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today Status Card ─────────────────────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  final bool isCheckedIn;
  final bool loading;
  final Map<String, dynamic>? today;
  final String workedHours;
  final String checkinTime;
  final String roomName;
  final VoidCallback onCheckin;

  const _TodayCard({
    required this.isCheckedIn, required this.loading, required this.today,
    required this.workedHours, required this.checkinTime,
    required this.roomName, required this.onCheckin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: loading
          ? const Center(
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // status label
                Row(
                  children: [
                    const Text('Today\'s Status',
                        style: TextStyle(color: Colors.white70, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isCheckedIn
                            ? (today?['status'] ?? 'present').toString().toUpperCase()
                            : 'NOT CHECKED IN',
                        style: const TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // main info
                isCheckedIn
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Checked In $checkinTime',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            roomName.isNotEmpty ? 'Room: $roomName' : 'Time worked: $workedHours',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('You haven\'t checked in yet.',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          const Text('Tap below to record your attendance.',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),

                const SizedBox(height: 16),

                // action button
                GestureDetector(
                  onTap: onCheckin,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCheckedIn
                              ? Icons.logout_rounded
                              : Icons.face_retouching_natural_rounded,
                          color: Colors.white, size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCheckedIn ? 'Check Out Now' : 'Check In Now',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Modern Action Grid Tile ───────────────────────────────────────────────────
class _ActionGridTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _ActionGridTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background accent circle
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: AppTextStyles.titleLarge.copyWith(
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


