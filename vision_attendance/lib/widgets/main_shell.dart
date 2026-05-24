import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../navigation/app_router.dart';
import '../state/user_profile_state.dart';
import '../services/api_service.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationMonitor();
  }

  void _startLocationMonitor() {
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.disabled) {
        _handleGpsDisabled();
      }
    });
  }

  Future<void> _handleGpsDisabled() async {
    final user = ref.read(userProfileProvider).user;
    if (user == null) return;

    // Show a warning and force checkout if they were checked in
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Location disabled. Automatic check-out triggered for security.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 5),
        ),
      );
      
      try {
        final api = ApiService(token: user.token);
        // Call a dedicated quick-checkout endpoint or the recognize endpoint with a flag
        // For now, we use the specific checkout logic if the backend supports it
        // Or simply notify the server of the location breach
        await api.forceCheckout();
        ref.read(userProfileProvider.notifier).refreshMe(); // Refresh state
      } catch (e) {
        dev.log('Auto-checkout error: $e');
      }
    }
  }

  @override
  void dispose() {
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }

  int _currentIndex(BuildContext context) {
    try {
      final state = GoRouterState.of(context);
      final location = state.uri.toString();
      if (location.startsWith(AppRoutes.dashboard)) return 0;
      if (location.startsWith(AppRoutes.attendanceLog)) return 1;
      if (location.startsWith(AppRoutes.vacationOverview)) return 2;
      if (location.startsWith(AppRoutes.profile)) return 3;
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(userProfileProvider);
    final user = authState.user;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user.photoUrl.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final location = GoRouterState.of(context).uri.toString();
          if (mounted && !location.startsWith(AppRoutes.faceEnrollment)) {
            final currentUser = ref.read(userProfileProvider).user;
            if (currentUser != null && currentUser.photoUrl.isEmpty) {
              context.go(AppRoutes.faceEnrollment);
            }
          }
        } catch (_) {}
      });
    }

    final index = _currentIndex(context);

    return Scaffold(
      body: widget.child,
      floatingActionButton: _ScanFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _AppBottomBar(currentIndex: index),
    );
  }
}

class _ScanFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.facialRecognitionPrep),
      child: Container(
        width: 62,
        height: 62,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x551B3FC4),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.face_retouching_natural_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _AppBottomBar extends StatelessWidget {
  final int currentIndex;

  const _AppBottomBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.grid_view_rounded,
              label: 'Dashboard',
              isSelected: currentIndex == 0,
              onTap: () => context.go(AppRoutes.dashboard),
            ),
            _NavItem(
              icon: Icons.list_alt_rounded,
              label: 'Logs',
              isSelected: currentIndex == 1,
              onTap: () => context.go(AppRoutes.attendanceLog),
            ),
            const SizedBox(width: 60), // FAB space
            _NavItem(
              icon: Icons.beach_access_rounded,
              label: 'Vacation',
              isSelected: currentIndex == 2,
              onTap: () => context.go(AppRoutes.vacationOverview),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              isSelected: currentIndex == 3,
              onTap: () => context.go(AppRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color:
                  isSelected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
