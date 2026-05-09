// lib/widgets/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../navigation/app_router.dart';
import '../state/user_profile_state.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.dashboard)) return 0;
    if (location.startsWith(AppRoutes.attendanceLog)) return 1;
    if (location.startsWith(AppRoutes.vacationOverview)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.login);
      });
      return const SizedBox.shrink();
    }
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      // ─── FAB for Face Scan (center) ────────────────────────────────────
      floatingActionButton: _ScanFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // ─── Bottom Nav Bar ────────────────────────────────────────────────
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
