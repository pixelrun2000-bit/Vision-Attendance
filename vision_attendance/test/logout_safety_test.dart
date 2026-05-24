
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_attendance/state/user_profile_state.dart';
import 'package:vision_attendance/screens/home/profile_settings_screen.dart';
import 'package:vision_attendance/screens/home/dashboard_screen.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('DashboardScreen handles null user gracefully', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith(() => MockUserNotifier(true)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Trigger logout
    await container.read(userProfileProvider.notifier).signOut();
    
    // Use pump instead of pumpAndSettle to avoid waiting for the infinite clock timer
    await tester.pump(); 
    
    // Verify no render crashes
    expect(tester.takeException(), isNull);
    
    // Manually dispose to stop timers
    container.dispose();
  });

  testWidgets('ProfileSettingsScreen handles null user gracefully', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith(() => MockUserNotifier(true)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileSettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ProfileSettingsScreen), findsOneWidget);

    // Trigger logout
    await container.read(userProfileProvider.notifier).signOut();
    
    await tester.pump(); 
    
    expect(tester.takeException(), isNull);
    container.dispose();
  });
}

class MockUserNotifier extends UserProfileController {
  final bool startLoggedIn;
  MockUserNotifier(this.startLoggedIn);

  @override
  UserProfileState build() {
    if (startLoggedIn) {
      return UserProfileState(
        user: const UserProfile(
          id: 1,
          fullNameAr: 'تجربة',
          fullNameEn: 'Test User',
          username: 'test',
          nationalId: '123',
          phoneE164: '123',
          gender: Gender.male,
          dateOfBirth: null,
          photoUrl: '',
          role: 'employee',
          token: 'abc',
        ),
        isInitialized: true,
      );
    }
    return UserProfileState(isInitialized: true);
  }
}
