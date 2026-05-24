// lib/state/attendance_refresh_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void triggerRefresh() {
    state++;
  }
}

final attendanceRefreshProvider = NotifierProvider<AttendanceRefreshNotifier, int>(() {
  return AttendanceRefreshNotifier();
});
