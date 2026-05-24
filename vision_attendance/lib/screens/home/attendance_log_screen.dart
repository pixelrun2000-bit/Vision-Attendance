// lib/screens/home/attendance_log_screen.dart
// â”€â”€â”€ Attendance Logs â€” Real Data + Face ID + Nearby Rooms â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vision_attendance/navigation/app_router.dart';
import '../../state/user_profile_state.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../state/attendance_refresh_state.dart';

class AttendanceLogScreen extends ConsumerStatefulWidget {
  const AttendanceLogScreen({super.key});
  @override
  ConsumerState<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends ConsumerState<AttendanceLogScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabs;
  final _auth = LocalAuthentication();

  // â”€â”€ state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _biometricPassed = false;
  bool _loadingBio      = true;
  bool _loadingLogs     = true;
  bool _loadingRooms    = true;

  Map<String, dynamic>?        _today;
  bool                         _isCheckedIn = false;
  Map<String, dynamic>?        _summary;
  List<Map<String, dynamic>>   _logs    = [];
  List<Map<String, dynamic>>   _nearby  = [];   // rooms sorted by distance
  Position?                    _pos;
  String                       _month   = DateFormat('yyyy-MM').format(DateTime.now());

  // â”€â”€ lifecycle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _promptBiometric();
    if (_biometricPassed) {
      await Future.wait([_loadLogs(), _loadNearbyRooms()]);
    }
  }

  // â”€â”€ biometric / Face ID â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _promptBiometric() async {
    setState(() => _loadingBio = true);
    try {
      final canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canCheck) {
        // Device doesn't support biometrics â€” allow anyway
        setState(() { _biometricPassed = true; _loadingBio = false; });
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Verify your identity to view attendance logs',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      setState(() { _biometricPassed = ok; _loadingBio = false; });
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed. Tap to retry.'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      // Fall through â€” allow if biometrics unavailable
      setState(() { _biometricPassed = true; _loadingBio = false; });
    }
  }

  // â”€â”€ load attendance logs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _loadLogs() async {
    setState(() => _loadingLogs = true);
    try {
      final profile = ref.read(userProfileProvider).user;
      final api     = ApiService(token: profile?.token ?? '');

      final todayRes = await api.getTodayStatus();
      final logsRes  = await api.getMyLogs(month: _month);

      if (mounted) {
        setState(() {
          _today       = todayRes['today'] as Map<String, dynamic>?;
          _isCheckedIn = todayRes['is_checked_in'] == true;
          _summary     = logsRes['summary'] as Map<String, dynamic>?;
          _logs        = List<Map<String, dynamic>>.from(logsRes['records'] ?? []);
          _loadingLogs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLogs = false);
    }
  }

  // â”€â”€ load nearby rooms via GPS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _loadNearbyRooms() async {
    setState(() => _loadingRooms = true);
    try {
      // Get GPS
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      _pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Fetch all rooms
      final profile = ref.read(userProfileProvider).user;
      final api     = ApiService(token: profile?.token ?? '');
      final data    = await api.getRooms();
      final rooms   = List<Map<String, dynamic>>.from(data['rooms'] ?? []);

      // Compute distance and sort
      final withDist = rooms.where((r) =>
        r['latitude'] != null && r['longitude'] != null).map((r) {
          final dist = _haversine(
            _pos?.latitude ?? 0.0, _pos?.longitude ?? 0.0,
            (r['latitude'] as num).toDouble(),
            (r['longitude'] as num).toDouble(),
          );
          return {...r, '_dist': dist};
        }).toList()
        ..sort((a, b) => (a['_dist'] as double).compareTo(b['_dist'] as double));

      if (mounted) setState(() { _nearby = withDist; _loadingRooms = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRooms = false);
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String _fmtTime(String? iso) {
    if (iso == null) return 'â€”';
    try { return DateFormat('hh:mm a').format(DateTime.parse(iso).toLocal()); }
    catch (_) { return 'â€”'; }
  }

  String _fmtDate(String? iso) {
    if (iso == null) return 'â€”';
    try { return DateFormat('EEE, MMM d').format(DateTime.parse(iso).toLocal()); }
    catch (_) { return 'â€”'; }
  }

  String _duration(String? cin, String? cout) {
    if (cin == null || cout == null) return 'â€”';
    try {
      final diff = DateTime.parse(cout).difference(DateTime.parse(cin));
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return '${h}h ${m}m';
    } catch (_) { return 'â€”'; }
  }

  // â”€â”€ UI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    // Listen for real-time refresh triggers
    ref.listen<int>(attendanceRefreshProvider, (prev, next) {
      if (next > (prev ?? 0)) {
        dev.log('[AttendanceLogScreen] Real-time refresh triggered', name: 'AttendanceLogScreen');
        _loadLogs();
      }
    });

    if (_loadingBio) return _buildBioLoading();
    if (!_biometricPassed) return _buildBioFailed();
    return _buildMain();
  }

  // â”€â”€ Biometric loading â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBioLoading() => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.face_unlock_outlined, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        const Text('Verifying identityâ€¦', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text('Please authenticate to continue', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: AppColors.primary),
      ]),
    ),
  );

  Widget _buildBioFailed() => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.error),
        const SizedBox(height: 16),
        const Text('Authentication Required', style: AppTextStyles.headlineLarge),
        const SizedBox(height: 8),
        Text('Tap below to try again', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _init,
          icon: const Icon(Icons.fingerprint),
          label: const Text('Verify Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ]),
    ),
  );

  // â”€â”€ Main screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMain() => Scaffold(
    backgroundColor: AppColors.background,
    body: CustomScrollView(
      slivers: [
        // â”€â”€ App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          title: const Text('Attendance Logs', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
          )),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _loadLogs,
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(delegate: SliverChildListDelegate([
            const SizedBox(height: 12),

            // â”€â”€ Today's Status Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _TodayCard(
              today: _today,
              isCheckedIn: _isCheckedIn,
              fmtTime: _fmtTime,
              loading: _loadingLogs,
            ),
            const SizedBox(height: 20),

            // â”€â”€ Monthly Summary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_summary != null) ...[
              _SummaryRow(summary: _summary!),
              const SizedBox(height: 20),
            ],

            // â”€â”€ Nearby Rooms â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _SectionHeader(title: 'Nearby Rooms', icon: Icons.location_on_rounded),
            const SizedBox(height: 10),
            _loadingRooms
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.primary)))
              : _nearby.isEmpty
                ? _emptyCard('No rooms with GPS coordinates found')
                : SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _nearby.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _RoomChip(room: _nearby[i]),
                    ),
                  ),
            const SizedBox(height: 24),

            // â”€â”€ Log History â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader(title: 'My History', icon: Icons.history_rounded),
                // Month picker
                GestureDetector(
                  onTap: _pickMonth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_month, style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: AppColors.primary),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _loadingLogs
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.primary)))
              : _logs.isEmpty
                ? _emptyCard('No attendance records for $_month')
                : Column(children: _logs.map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LogCard(
                      log: log,
                      fmtTime: _fmtTime,
                      fmtDate: _fmtDate,
                      duration: _duration,
                    ),
                  )).toList()),
          ])),
        ),
      ],
    ),
  );

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse('$_month-01'),
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      helpText: 'Select month',
    );
    if (picked != null) {
      setState(() => _month = DateFormat('yyyy-MM').format(picked));
      _loadLogs();
    }
  }

  Widget _emptyCard(String msg) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Center(child: Text(msg, style: AppTextStyles.bodyMedium)),
  );
}

// â”€â”€ Sub-widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TodayCard extends StatelessWidget {
  final Map<String, dynamic>? today;
  final bool isCheckedIn;
  final bool loading;
  final String Function(String?) fmtTime;
  const _TodayCard({required this.today, required this.isCheckedIn,
    required this.fmtTime, required this.loading});

  @override
  Widget build(BuildContext context) {
    final checkin  = fmtTime(today?['checkin_time'] as String?);
    final checkout = fmtTime(today?['checkout_time'] as String?);
    final room     = today?['room_name'] as String? ?? 'â€”';
    final status   = today?['status']   as String? ?? 'absent';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B3FC4), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 16, offset: const Offset(0, 6),
        )],
      ),
      child: loading
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.today_rounded, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Spacer(),
            _StatusPill(status: isCheckedIn ? 'checked_in' : status),
          ]),
          const SizedBox(height: 16),
          Text(
            today == null ? 'Not checked in yet' : 'Attendance Recorded âœ“',
            style: const TextStyle(color: Colors.white,
              fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (today != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              _TimeBlock(label: 'Check In',  time: checkin,  icon: Icons.login_rounded),
              const SizedBox(width: 20),
              _TimeBlock(label: 'Check Out', time: checkout, icon: Icons.logout_rounded),
              const SizedBox(width: 20),
              _TimeBlock(label: 'Room',      time: room,     icon: Icons.location_on_rounded),
            ]),
          ],
        ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final map = {
      'checked_in': (Colors.greenAccent[400]!, 'Live'),
      'present':    (Colors.white70, 'Present'),
      'late':       (Colors.orange[200]!, 'Late'),
      'absent':     (Colors.red[200]!, 'Absent'),
    };
    final (color, label) = map[status] ?? (Colors.white54, 'Unknown');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color,
            fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final String label, time;
  final IconData icon;
  const _TimeBlock({required this.label, required this.time, required this.icon});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, size: 11, color: Colors.white54),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ]),
      Text(time, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryRow({required this.summary});
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total', '${summary['total_days'] ?? 0}', AppColors.textPrimary),
      ('Present', '${summary['present'] ?? 0}', AppColors.success),
      ('Late',    '${summary['late']    ?? 0}', AppColors.warning),
      ('Absent',  '${summary['absent']  ?? 0}', AppColors.error),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((t) => Column(children: [
          Text(t.$1, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Text(t.$2, style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: t.$3)),
        ])).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.primary),
    const SizedBox(width: 8),
    Text(title, style: AppTextStyles.headlineMedium),
  ]);
}

class _RoomChip extends ConsumerWidget {
  final Map<String, dynamic> room;
  const _RoomChip({required this.room});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dist = room['_dist'] as double;
    final label = dist < 1000
      ? '${dist.toStringAsFixed(0)} m'
      : '${(dist / 1000).toStringAsFixed(1)} km';
    final isNear = dist <= 300;
    final userRole = ref.watch(userProfileProvider).user?.role;

    return GestureDetector(
      onTap: () {
        if (userRole == 'admin' || userRole == 'manager') {
          context.push(AppRoutes.roomLiveStatus, extra: room);
        } else if (isNear) {
          context.push(AppRoutes.faceScanCheckin, extra: room);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be within 300 meters to check in.'), backgroundColor: AppColors.error),
          );
        }
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isNear ? AppColors.primary.withOpacity(0.07) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNear ? AppColors.primary.withOpacity(0.4) : AppColors.border,
            width: isNear ? 1.5 : 1,
          ),
        ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.meeting_room_rounded,
            size: 16, color: isNear ? AppColors.primary : AppColors.textSecondary),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isNear ? AppColors.success.withOpacity(0.1) : AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: isNear ? AppColors.success : AppColors.textSecondary,
            )),
          ),
        ]),
        const SizedBox(height: 8),
        Text(room['name'] ?? '', style: AppTextStyles.titleLarge,
          maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(room['room_code'] ?? '', style: AppTextStyles.labelLarge),
        if (isNear) ...[
          const SizedBox(height: 4),
          Text('âœ“ Within range', style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
        ],
      ]),
    ));
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final String Function(String?) fmtTime;
  final String Function(String?) fmtDate;
  final String Function(String?, String?) duration;
  const _LogCard({required this.log, required this.fmtTime,
    required this.fmtDate, required this.duration});

  @override
  Widget build(BuildContext context) {
    final status   = log['status'] as String? ?? 'absent';
    final cin      = log['checkin_time']  as String?;
    final cout     = log['checkout_time'] as String?;
    final roomName = log['room_name']     as String? ?? 'Unknown Room';
    final color    = {'present': AppColors.success, 'late': AppColors.warning,
                      'absent': AppColors.error}[status] ?? AppColors.textHint;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        // Status bar
        Container(width: 4, height: 56, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(fmtDate(cin), style: AppTextStyles.titleLarge)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status.toUpperCase(), style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(roomName, style: AppTextStyles.bodyMedium),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _LogTime(label: 'In',  time: fmtTime(cin)),
            const SizedBox(width: 20),
            _LogTime(label: 'Out', time: fmtTime(cout)),
            const Spacer(),
            Text(duration(cin, cout), style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
        ])),
      ]),
    );
  }
}

class _LogTime extends StatelessWidget {
  final String label, time;
  const _LogTime({required this.label, required this.time});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('$label: ', style: AppTextStyles.bodyMedium),
    Text(time, style: AppTextStyles.titleLarge),
  ]);
}
