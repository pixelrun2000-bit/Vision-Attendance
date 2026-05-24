import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/account_creation_screen.dart';
import '../screens/auth/identity_verification_screen.dart';
import '../screens/auth/permissions_setup_screen.dart';
import '../screens/auth/face_enrollment_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/home/attendance_log_screen.dart';
import '../screens/home/vacation_overview_screen.dart';
import '../screens/home/vacation_request_screen.dart';
import '../screens/home/vacation_request_details_screen.dart';
import '../screens/home/vacation_request_details_screen.dart'; // Duplicate but harmless
import '../screens/home/vacation_calendar_screen.dart';
import '../screens/home/profile_settings_screen.dart';
import '../screens/home/notification_center_screen.dart';
import '../screens/home/attendance_details_screen.dart';
import '../screens/scanner/facial_recognition_prep_screen.dart';
import '../screens/scanner/face_scan_checkin_screen.dart';
import '../screens/scanner/checkin_success_screen.dart';
import '../screens/scanner/checkin_failure_screen.dart';
import '../screens/scanner/checkout_summary_screen.dart';
import '../screens/misc/empty_data_state_screen.dart';
import '../screens/misc/splash_screen.dart';
import '../screens/admin/room_live_status_screen.dart';
import '../state/user_profile_state.dart';
import '../widgets/main_shell.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String accountCreation = '/account-creation';
  static const String identityVerification = '/identity-verification';
  static const String permissionsSetup = '/permissions-setup';
  static const String faceEnrollment = '/face-enrollment';

  static const String dashboard = '/dashboard';
  static const String attendanceLog = '/attendance-log';
  static const String vacationOverview = '/vacation-overview';
  static const String vacationRequest = '/vacation-request';
  static const String vacationRequestDetails = '/vacation-request-details';
  static const String vacationCalendar = '/vacation-calendar';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String attendanceDetails = '/attendance-details';

  static const String facialRecognitionPrep = '/facial-recognition-prep';
  static const String faceScanCheckin = '/face-scan-checkin';
  static const String checkoutFaceScan = '/checkout-face-scan';
  static const String checkinSuccess = '/checkin-success';
  static const String checkinFailure = '/checkin-failure';
  static const String checkoutSummary = '/checkout-summary';

  static const String roomLiveStatus = '/room-live-status';
  static const String emptyDataState = '/empty-data-state';
}

/// A notifier that translates Riverpod state changes into GoRouter refresh signals.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Watch the auth state and notify listeners (GoRouter) when it changes.
    _ref.listen(userProfileProvider, (_, __) {
      Future.microtask(() => notifyListeners());
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(userProfileProvider);
    final user = authState.user;
    final isInitialized = authState.isInitialized;
    final showSplash = authState.showSplash;

    final bool isSplash = state.uri.toString() == AppRoutes.splash;

    // While NOT initialized OR we still want to show splash, stay on splash
    if (!isInitialized || showSplash) {
      return isSplash ? null : AppRoutes.splash;
    }

    final isAuthPath = state.uri.toString().startsWith('/login') ||
        state.uri.toString().startsWith('/splash') ||
        state.uri.toString().startsWith('/forgot-password') ||
        state.uri.toString().startsWith('/otp-verification') ||
        state.uri.toString().startsWith('/account-creation');

    // If NOT logged in:
    if (user == null) {
      // If NOT on an auth path, force login
      if (!isAuthPath) return AppRoutes.login;
      // If on splash but splash is dismissed, force login
      if (isSplash && !showSplash) return AppRoutes.login;
      // Otherwise stay where we are (login, forgot password, etc.)
      return null;
    }

    // If logged in and on login/splash -> Go to dashboard
    if (isSplash || state.uri.toString() == AppRoutes.login) {
      return AppRoutes.dashboard;
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    debugLogDiagnostics: true,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => const LoginScreen(),
    routes: [
      // ─── Auth Flow ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _buildPage(
          state,
          const SplashScreen(),
          transitionType: _TransitionType.fade,
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildPage(
          state,
          const LoginScreen(),
          transitionType: _TransitionType.fadeScale,
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => _buildPage(
          state,
          const ForgotPasswordScreen(),
          transitionType: _TransitionType.slideUp,
        ),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        pageBuilder: (context, state) => _buildPage(
          state,
          const OtpVerificationScreen(),
          transitionType: _TransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: AppRoutes.accountCreation,
        pageBuilder: (context, state) => _buildPage(
          state,
          const AccountCreationScreen(),
          transitionType: _TransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: AppRoutes.identityVerification,
        pageBuilder: (context, state) => _buildPage(
          state,
          const IdentityVerificationScreen(),
          transitionType: _TransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: AppRoutes.permissionsSetup,
        pageBuilder: (context, state) => _buildPage(
          state,
          const PermissionsSetupScreen(),
          transitionType: _TransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: AppRoutes.faceEnrollment,
        pageBuilder: (context, state) => _buildPage(
          state,
          const FaceEnrollmentScreen(),
          transitionType: _TransitionType.slideLeft,
        ),
      ),

      // ─── Main Shell (Bottom Nav) ─────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => _buildPage(
              state,
              const DashboardScreen(),
              transitionType: _TransitionType.fade,
            ),
          ),
          GoRoute(
            path: AppRoutes.attendanceLog,
            pageBuilder: (context, state) => _buildPage(
              state,
              const AttendanceLogScreen(),
              transitionType: _TransitionType.fade,
            ),
          ),
          GoRoute(
            path: AppRoutes.vacationOverview,
            pageBuilder: (context, state) => _buildPage(
              state,
              const VacationOverviewScreen(),
              transitionType: _TransitionType.fade,
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => _buildPage(
              state,
              const ProfileSettingsScreen(),
              transitionType: _TransitionType.fade,
            ),
          ),
        ],
      ),

      // ─── Inner Screens ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.vacationRequest,
        pageBuilder: (context, state) => _buildPage(
          state,
          const VacationRequestScreen(),
          transitionType: _TransitionType.slideUp,
        ),
      ),
      GoRoute(
        path: AppRoutes.vacationRequestDetails,
        pageBuilder: (context, state) => _buildPage(
          state,
          const VacationRequestDetailsScreen(),
          transitionType: _TransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: AppRoutes.vacationCalendar,
        pageBuilder: (context, state) => _buildPage(
          state,
          const VacationCalendarScreen(),
          transitionType: _TransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => _buildPage(
          state,
          const NotificationCenterScreen(),
          transitionType: _TransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: AppRoutes.attendanceDetails,
        pageBuilder: (context, state) => _buildPage(
          state,
          const AttendanceDetailsScreen(),
          transitionType: _TransitionType.slideLeft,
        ),
      ),

      // ─── Face Scanner Flow ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.facialRecognitionPrep,
        pageBuilder: (context, state) => _buildPage(
          state,
          const FacialRecognitionPrepScreen(),
          transitionType: _TransitionType.slideUp,
        ),
      ),
      GoRoute(
        path: AppRoutes.faceScanCheckin,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _buildPage(
            state,
            FaceScanCheckinScreen(roomData: extra),
            transitionType: _TransitionType.fadeScale,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.checkoutFaceScan,
        pageBuilder: (context, state) => _buildPage(
          state,
          const CheckoutFaceScanScreen(),
          transitionType: _TransitionType.fadeScale,
        ),
      ),
      GoRoute(
        path: AppRoutes.checkinSuccess,
        pageBuilder: (context, state) => _buildPage(
          state,
          const CheckinSuccessScreen(),
          transitionType: _TransitionType.fadeScale,
        ),
      ),
      GoRoute(
        path: AppRoutes.checkinFailure,
        pageBuilder: (context, state) {
          final reason = state.extra as String? ?? 'Verification failed';
          return _buildPage(
            state,
            CheckinFailureScreen(reason: reason),
            transitionType: _TransitionType.fadeScale,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.checkoutSummary,
        pageBuilder: (context, state) => _buildPage(
          state,
          const CheckoutSummaryScreen(),
          transitionType: _TransitionType.slideUp,
        ),
      ),
      GoRoute(
        path: AppRoutes.roomLiveStatus,
        pageBuilder: (context, state) {
          final roomData = state.extra as Map<String, dynamic>?;
          return _buildPage(
            state,
            RoomLiveStatusScreen(roomData: roomData),
            transitionType: _TransitionType.slideLeft,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.emptyDataState,
        pageBuilder: (context, state) => _buildPage(
          state,
          const EmptyDataStateScreen(),
          transitionType: _TransitionType.fade,
        ),
      ),
    ],
  );
});

// ─── Custom Page Transitions ─────────────────────────────────────────────────

enum _TransitionType { fade, slideLeft, slideUp, fadeScale }

Page<T> _buildPage<T>(
  GoRouterState state,
  Widget child, {
  _TransitionType transitionType = _TransitionType.fade,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (transitionType) {
        case _TransitionType.fade:
          return FadeTransition(opacity: animation, child: child);
        case _TransitionType.slideLeft:
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1, 0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        case _TransitionType.slideUp:
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        case _TransitionType.fadeScale:
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation.drive(
                Tween(begin: 0.9, end: 1.0)
                    .chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: child,
            ),
          );
      }
    },
  );
}
