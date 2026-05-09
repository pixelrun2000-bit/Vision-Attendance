// lib/screens/misc/empty_data_state_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../navigation/app_router.dart';
import '../../widgets/shared_widgets.dart';

/// Generic Empty State screen used when there's no data to display.
/// Pass [type] via GoRouter extras to customize for attendance, leave, or notifications.
class EmptyDataStateScreen extends StatelessWidget {
  final EmptyStateType type;

  const EmptyDataStateScreen({
    super.key,
    this.type = EmptyStateType.attendance,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configs[type]!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(config.title),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ─── Illustration ───────────────────────────────────────────
            _EmptyIllustration(type: type),
            const SizedBox(height: 36),

            Text(
              config.heading,
              style: AppTextStyles.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              config.description,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            AppPrimaryButton(
              label: config.primaryAction,
              icon: config.primaryIcon,
              onPressed: () => context.go(config.primaryRoute),
            ),
            const SizedBox(height: 12),

            if (config.secondaryAction != null)
              AppOutlineButton(
                label: config.secondaryAction!,
                onPressed: () => context.pop(),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State Types ────────────────────────────────────────────────────────

enum EmptyStateType { attendance, leave, notifications, scanner }

class _Config {
  final String title;
  final String heading;
  final String description;
  final String primaryAction;
  final IconData primaryIcon;
  final String primaryRoute;
  final String? secondaryAction;

  const _Config({
    required this.title,
    required this.heading,
    required this.description,
    required this.primaryAction,
    required this.primaryIcon,
    required this.primaryRoute,
    this.secondaryAction,
  });
}

const _configs = {
  EmptyStateType.attendance: _Config(
    title: 'No Records',
    heading: 'No Attendance Yet',
    description:
        'Your attendance records will appear here once you complete your first check-in using face recognition.',
    primaryAction: 'Start First Check-In',
    primaryIcon: Icons.face_retouching_natural_rounded,
    primaryRoute: AppRoutes.facialRecognitionPrep,
    secondaryAction: 'Go to Dashboard',
  ),
  EmptyStateType.leave: _Config(
    title: 'No Leave Requests',
    heading: 'No Leave Requests Yet',
    description:
        'You haven\'t submitted any leave requests. Plan your time off easily using the request form.',
    primaryAction: 'Request Leave',
    primaryIcon: Icons.beach_access_rounded,
    primaryRoute: AppRoutes.vacationRequest,
    secondaryAction: 'Back to Overview',
  ),
  EmptyStateType.notifications: _Config(
    title: 'No Notifications',
    heading: 'You\'re All Caught Up!',
    description:
        'No new notifications. We\'ll let you know when something needs your attention.',
    primaryAction: 'Go to Dashboard',
    primaryIcon: Icons.grid_view_rounded,
    primaryRoute: AppRoutes.attendanceLog,
  ),
  EmptyStateType.scanner: _Config(
    title: 'Scanner Unavailable',
    heading: 'Camera Not Available',
    description:
        'The face scanner requires camera access. Please grant permission and try again.',
    primaryAction: 'Grant Camera Access',
    primaryIcon: Icons.camera_alt_rounded,
    primaryRoute: AppRoutes.permissionsSetup,
    secondaryAction: 'Manual Check-In',
  ),
};

// ─── Animated Illustration ────────────────────────────────────────────────────

class _EmptyIllustration extends StatefulWidget {
  final EmptyStateType type;

  const _EmptyIllustration({required this.type});

  @override
  State<_EmptyIllustration> createState() => _EmptyIllustrationState();
}

class _EmptyIllustrationState extends State<_EmptyIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _float.value),
        child: child,
      ),
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.06),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.12),
            width: 2,
          ),
        ),
        child: Icon(
          _illustrationIcon,
          size: 84,
          color: AppColors.primary.withOpacity(0.4),
        ),
      ),
    );
  }

  IconData get _illustrationIcon => switch (widget.type) {
        EmptyStateType.attendance => Icons.calendar_month_outlined,
        EmptyStateType.leave => Icons.beach_access_outlined,
        EmptyStateType.notifications => Icons.notifications_off_outlined,
        EmptyStateType.scanner => Icons.no_photography_outlined,
      };
}
