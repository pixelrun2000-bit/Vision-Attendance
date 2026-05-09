// lib/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/account_creation_screen.dart';
import '../screens/auth/identity_verification_screen.dart';
import '../screens/auth/permissions_setup_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/home/attendance_log_screen.dart';
import '../screens/home/vacation_overview_screen.dart';
import '../screens/home/vacation_request_screen.dart';
import '../screens/home/vacation_request_details_screen.dart';
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
import '../widgets/main_shell.dart';

class AppRoutes {
  static const String login = '/login';
  static const String splash = '/splash';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String accountCreation = '/account-creation';
  static const String identityVerification = '/identity-verification';
  static const String permissionsSetup = '/permissions-setup';

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

  static const String emptyDataState = '/empty-data-state';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
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
      pageBuilder: (context, state) => _buildPage(
        state,
        const CheckinFailureScreen(),
        transitionType: _TransitionType.fadeScale,
      ),
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
      path: AppRoutes.emptyDataState,
      pageBuilder: (context, state) => _buildPage(
        state,
        const EmptyDataStateScreen(),
        transitionType: _TransitionType.fade,
      ),
    ),
  ],
);

// ─── Custom Page Transitions ─────────────────────────────────────────────────

enum _TransitionType { slideLeft, slideUp, fade, fadeScale }

CustomTransitionPage<void> _buildPage(
  GoRouterState state,
  Widget child, {
  _TransitionType transitionType = _TransitionType.slideLeft,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (transitionType) {
        case _TransitionType.slideLeft:
          return _slideLeftTransition(animation, secondaryAnimation, child);
        case _TransitionType.slideUp:
          return _slideUpTransition(animation, secondaryAnimation, child);
        case _TransitionType.fade:
          return _fadeTransition(animation, child);
        case _TransitionType.fadeScale:
          return _fadeScaleTransition(animation, child);
      }
    },
  );
}

Widget _slideLeftTransition(
    Animation<double> a, Animation<double> sa, Widget child) {
  final slide = Tween<Offset>(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic));

  final secondarySlide = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.3, 0.0),
  ).animate(CurvedAnimation(parent: sa, curve: Curves.easeInCubic));

  return SlideTransition(
    position: secondarySlide,
    child: SlideTransition(position: slide, child: child),
  );
}

Widget _slideUpTransition(
    Animation<double> a, Animation<double> sa, Widget child) {
  final slide = Tween<Offset>(
    begin: const Offset(0.0, 1.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic));

  return SlideTransition(
    position: slide,
    child: child,
  );
}

Widget _fadeTransition(Animation<double> a, Widget child) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: a, curve: Curves.easeIn),
    child: child,
  );
}

Widget _fadeScaleTransition(Animation<double> a, Widget child) {
  final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
    CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
  );
  return FadeTransition(
    opacity: CurvedAnimation(parent: a, curve: Curves.easeIn),
    child: ScaleTransition(scale: scale, child: child),
  );
}
