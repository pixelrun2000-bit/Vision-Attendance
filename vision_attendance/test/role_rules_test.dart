import 'package:flutter_test/flutter_test.dart';
import 'package:vision_attendance/state/user_profile_state.dart';

void main() {
  test('student role is blocked from vacations', () {
    const profile = UserProfile(
      id: 1,
      fullNameAr: 'Student',
      fullNameEn: 'Student User',
      username: 'student1',
      nationalId: '',
      phoneE164: '',
      gender: Gender.male,
      dateOfBirth: null,
      photoUrl: '',
      role: 'student',
      token: 'token',
    );
    expect(profile.isStudent, isTrue);
  });
}
