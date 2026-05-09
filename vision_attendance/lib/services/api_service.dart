// lib/services/api_service.dart
// ─── Vision Attendance — Mobile API Service ───────────────────────────────────
// All HTTP calls from the Flutter app go through this singleton.
// Uses ApiClient from api_client.dart under the hood.
// ─────────────────────────────────────────────────────────────────────────────
import '../config/api_config.dart';
import 'api_client.dart';
import '../state/user_profile_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider so screens can easily read the service
final apiServiceProvider = Provider<ApiService>((ref) {
  // Grab token from the user state if available
  final token = ref.watch(userProfileProvider)?.token ?? '';
  return ApiService(token: token);
});

class ApiService {
  ApiService({this.token = ''});

  final String token;

  final ApiClient _client = ApiClient(baseUrl: ApiConfig.baseUrl);

  // ── AUTH ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) =>
      _client.postJson('/api/auth/login',
          body: {'username': username, 'password': password});

  Future<Map<String, dynamic>> register({
    required String fullNameEn,
    required String fullNameAr,
    required String username,
    required String email,
    required String password,
    String phone      = '',
    String department = '',
    String gender     = 'male',
    String role       = 'employee',
  }) =>
      _client.postJson('/api/auth/register', body: {
        'full_name_en': fullNameEn,
        'full_name_ar': fullNameAr.isEmpty ? fullNameEn : fullNameAr,
        'username':     username,
        'email':        email,
        'password':     password,
        'role':         role,
        if (phone.isNotEmpty)      'phone':      phone,
        if (department.isNotEmpty) 'department': department,
        'gender': gender,
      });

  Future<Map<String, dynamic>> getMe() =>
      _client.getJson('/api/auth/me', token: token);

  // ── ATTENDANCE ────────────────────────────────────────────────────────────

  /// GET /api/attendance/today — user's check-in for today
  /// Returns { is_checked_in: bool, today: { status, checkin_time, room_name, … } }
  Future<Map<String, dynamic>> getTodayStatus() =>
      _client.getJson('/api/attendance/today', token: token);

  /// GET /api/attendance/my-logs?month=YYYY-MM
  /// Returns { summary: { present, late, absent, total_days }, records: [...] }
  Future<Map<String, dynamic>> getMyLogs({String? month}) {
    final q = month != null ? '?month=$month' : '';
    return _client.getJson('/api/attendance/my-logs$q', token: token);
  }

  /// POST /api/attendance/checkin-by-room
  Future<Map<String, dynamic>> checkinByRoom({
    required String roomCode,
    required double latitude,
    required double longitude,
    bool isFailed = false,
    String? failureReason,
  }) =>
      _client.postJson('/api/attendance/checkin-by-room', token: token, body: {
        'room_code': roomCode,
        'latitude':  latitude,
        'longitude': longitude,
        if (isFailed) 'is_failed': true,
        if (failureReason != null) 'failure_reason': failureReason,
      });

  /// POST /api/attendance/checkout
  Future<Map<String, dynamic>> checkout() =>
      _client.postJson('/api/attendance/checkout', token: token, body: {});

  // ── ROOMS ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getRooms() =>
      _client.getJson('/api/rooms', token: token);

  Future<Map<String, dynamic>> getRoomByCode(String code) =>
      _client.getJson('/api/rooms/by-code/$code', token: token);

  // ── PROFILE ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserAttendanceSummary(int userId, {String? month}) {
    final q = month != null ? '?month=$month' : '';
    return _client.getJson('/api/users/$userId/attendance-summary$q', token: token);
  }
}
