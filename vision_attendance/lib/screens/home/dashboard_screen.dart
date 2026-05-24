// lib/screens/home/dashboard_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../state/user_profile_state.dart';
import '../../state/notification_state.dart';
import '../../services/socket_service.dart';
import '../../services/api_service.dart';
import '../../state/attendance_refresh_state.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late DateTime _now;
  Timer? _clockTimer;
  Timer? _refreshTimer;

  Map<String, dynamic>? _today;
  Map<String, dynamic>? _summary;
  bool _isCheckedIn = false;
  bool _loadingStatus = true;
  late ApiService _api;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(userProfileProvider).user?.token ?? '';
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

  String _fmtTime(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) { return '—'; }
  }

  String _workedHours() {
    if (_today == null) return '0h';
    final inTime = DateTime.tryParse(_today?['checkin_time']?.toString() ?? '')?.toLocal();
    if (inTime == null) return '0h';
    
    final rawOut = _today?['checkout_time'];
    final outTime = (rawOut != null)
        ? (DateTime.tryParse(rawOut.toString())?.toLocal() ?? DateTime.now())
        : DateTime.now();
        
    final diff = outTime.difference(inTime);
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).user;
    final notificationState = ref.watch(notificationProvider);
    ref.watch(socketServiceProvider);

    ref.listen<int>(attendanceRefreshProvider, (prev, next) {
      if (next > (prev ?? 0)) _loadData();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              elevation: 0,
              backgroundColor: AppColors.background,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  backgroundImage: (user?.photoUrl != null && user?.photoUrl != '')
                      ? NetworkImage(user?.photoUrl ?? '')
                      : null,
                  child: (user?.photoUrl == null || user?.photoUrl == '')
                      ? Text(
                          ((user?.fullNameEn != null && user?.fullNameEn != '') 
                              ? (user?.fullNameEn ?? 'U')[0] 
                              : 'U').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Day,', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                  Text(user?.fullNameEn.split(' ').first ?? 'User', style: AppTextStyles.titleLarge),
                ],
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                      onPressed: () => context.push(AppRoutes.notifications),
                    ),
                    if (notificationState.unreadCount > 0)
                      Positioned(
                        right: 12, top: 12,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  
                  // Clock
                  Center(
                    child: Column(
                      children: [
                        Text(DateFormat('EEEE, MMMM d').format(_now),
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(DateFormat('hh:mm a').format(_now),
                            style: AppTextStyles.displayMedium.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Today's Status Card
                  _TodayCard(
                    isCheckedIn: _isCheckedIn,
                    loading: _loadingStatus,
                    today: _today,
                    workedHours: _workedHours(),
                    checkinTime: _fmtTime(_today?['checkin_time']),
                    roomName: _today?['room_name'] ?? '',
                    onCheckin: () => context.push(AppRoutes.facialRecognitionPrep),
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  if (_summary != null) ...[
                    const AppSectionHeader(title: 'Overview', subtitle: 'Your monthly activity summary'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(children: [
                            Expanded(child: _SummaryStat(label: 'Present', value: '${_summary?['present'] ?? 0}', color: AppColors.success)),
                            _divider(),
                            Expanded(child: _SummaryStat(label: 'Late', value: '${_summary?['late'] ?? 0}', color: AppColors.warning)),
                            _divider(),
                            Expanded(child: _SummaryStat(label: 'Absent', value: '${_summary?['absent'] ?? 0}', color: AppColors.error)),
                          ]),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                          Row(children: [
                            Expanded(child: _SummaryStat(label: 'Worked Today', value: _isCheckedIn ? _workedHours() : '0h', color: AppColors.primary)),
                            _divider(),
                            Expanded(child: _SummaryStat(label: 'Total Days', value: '${_summary?['total_days'] ?? 0}', color: const Color(0xFF6366F1))),
                          ]),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Quick Actions
                  AppSectionHeader(
                    title: 'Quick Actions',
                    subtitle: 'Most used features',
                    action: TextButton(
                      onPressed: () => context.go(AppRoutes.attendanceLog),
                      child: const Text('Full Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.15,
                    children: [
                      _ActionCard(icon: Icons.face_unlock_rounded, title: 'Face Check-in', color: AppColors.primary, onTap: () => context.push(AppRoutes.facialRecognitionPrep)),
                      _ActionCard(icon: Icons.qr_code_2_rounded, title: 'Room QR', color: const Color(0xFF8B5CF6), onTap: () => context.push(AppRoutes.faceScanCheckin)),
                      if (user?.role == 'admin' || user?.role == 'manager')
                        _ActionCard(icon: Icons.monitor_heart_rounded, title: 'Live Rooms', color: AppColors.error, onTap: () => context.go(AppRoutes.attendanceLog)),
                      _ActionCard(icon: Icons.holiday_village_rounded, title: 'Vacations', color: const Color(0xFF10B981), onTap: () => context.go(AppRoutes.vacationOverview)),
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

  Widget _divider() => Container(height: 30, width: 1, color: AppColors.border);
}

class _SummaryStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headlineMedium.copyWith(color: color, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final bool isCheckedIn, loading;
  final Map<String, dynamic>? today;
  final String workedHours, checkinTime, roomName;
  final VoidCallback onCheckin;
  const _TodayCard({required this.isCheckedIn, required this.loading, required this.today, required this.workedHours, required this.checkinTime, required this.roomName, required this.onCheckin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: loading ? const Center(child: CircularProgressIndicator(color: Colors.white)) : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isCheckedIn ? 'ACTIVE SESSION' : 'OFF DUTY', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const Spacer(),
              if (isCheckedIn) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 12),
          Text(isCheckedIn ? 'Checked in at $checkinTime' : 'Not checked in today', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(isCheckedIn ? (roomName.isNotEmpty ? 'Location: $roomName' : 'Working hours: $workedHours') : 'Please check in to start your attendance.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCheckin,
            icon: Icon(isCheckedIn ? Icons.logout_rounded : Icons.login_rounded, size: 18),
            label: Text(isCheckedIn ? 'Check Out' : 'Check In Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
