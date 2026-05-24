import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

enum Gender { male, female }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullNameAr,
    required this.fullNameEn,
    required this.username,
    required this.nationalId,
    required this.phoneE164,
    required this.gender,
    required this.dateOfBirth,
    required this.photoUrl,
    required this.role,
    required this.token,
  });

  final int id;
  final String fullNameAr;
  final String fullNameEn;
  final String username;
  final String nationalId;
  final String phoneE164;
  final Gender gender;
  final DateTime? dateOfBirth;
  final String photoUrl;
  final String role;
  final String token;

  bool get isStudent => role == 'student';

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullNameAr': fullNameAr,
        'fullNameEn': fullNameEn,
        'username': username,
        'nationalId': nationalId,
        'phoneE164': phoneE164,
        'gender': gender.name,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'photoUrl': photoUrl,
        'role': role,
        'token': token,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    try {
      String rawPhoto = (json['photoUrl'] ?? json['photo_url'] ?? '') as String;
      String photoUrl = rawPhoto;
      if (rawPhoto.isNotEmpty && !rawPhoto.startsWith('http')) {
        photoUrl = '${ApiConfig.baseUrl}$rawPhoto';
      }

      return UserProfile(
        id: (json['id'] as num?)?.toInt() ?? 0,
        fullNameAr: (json['fullNameAr'] ?? json['full_name_ar'] ?? '') as String,
        fullNameEn: (json['fullNameEn'] ?? json['full_name_en'] ?? '') as String,
        username: (json['username'] ?? '') as String,
        nationalId: (json['nationalId'] ?? json['national_id'] ?? '') as String,
        phoneE164: (json['phoneE164'] ?? json['phone'] ?? '') as String,
        gender: ((json['gender'] ?? 'male') == 'female')
            ? Gender.female
            : Gender.male,
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.tryParse(json['dateOfBirth'].toString())
            : json['date_of_birth'] != null
                ? DateTime.tryParse(json['date_of_birth'].toString())
                : null,
        photoUrl: photoUrl,
        role: (json['role'] ?? 'employee') as String,
        token: (json['token'] ?? '') as String,
      );
    } catch (e) {
      throw Exception("Invalid user JSON");
    }
  }

  UserProfile copyWith({
    String? fullNameAr,
    String? fullNameEn,
    String? phoneE164,
    DateTime? dateOfBirth,
    String? photoUrl,
  }) {
    return UserProfile(
      id: id,
      fullNameAr: fullNameAr ?? this.fullNameAr,
      fullNameEn: fullNameEn ?? this.fullNameEn,
      username: username,
      nationalId: nationalId,
      phoneE164: phoneE164 ?? this.phoneE164,
      gender: gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role,
      token: token,
    );
  }
}

class UserProfileState {
  final UserProfile? user;
  final bool isInitialized;
  final bool showSplash;

  UserProfileState({
    this.user,
    this.isInitialized = false,
    this.showSplash = true,
  });

  UserProfileState copyWith({
    UserProfile? user,
    bool? isInitialized,
    bool? showSplash,
  }) {
    return UserProfileState(
      user: user ?? this.user,
      isInitialized: isInitialized ?? this.isInitialized,
      showSplash: showSplash ?? this.showSplash,
    );
  }
}

class UserProfileController extends Notifier<UserProfileState> {
  static const _storageKey = 'session_user';

  final ApiClient _api = ApiClient(
    baseUrl: ApiConfig.baseUrl,
  );

  @override
  UserProfileState build() {
    Future.microtask(_restoreSession);
    return UserProfileState();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null) {
      state = state.copyWith(isInitialized: true);
      return;
    }

    try {
      final data = jsonDecode(raw);
      state = UserProfileState(
        user: UserProfile.fromJson(Map<String, dynamic>.from(data)),
        isInitialized: true,
      );
    } catch (_) {
      await prefs.remove(_storageKey);
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> _persist(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(profile.toJson()));
  }

  // ─────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final data = await _api.postJson(
      '/api/auth/login',
      body: {'username': username, 'password': password},
    );

    if (data['user'] == null) {
      throw Exception(data['message'] ?? 'Login failed');
    }

    final userMap = Map<String, dynamic>.from(data['user']);
    userMap['token'] = data['token'];

    final profile = UserProfile.fromJson(userMap);
    state = state.copyWith(user: profile);
    await _persist(profile);
  }

  // ─────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────
  Future<void> register({
    required String fullNameEn,
    required String fullNameAr,
    required String email,
    required String username,
    required String password,
    required String role,
    String phone       = '',
    String department  = '',
    String gender      = 'male',
  }) async {
    final data = await _api.postJson(
      '/api/auth/register',
      body: {
        'full_name_en': fullNameEn,
        'full_name_ar': fullNameAr.isEmpty ? fullNameEn : fullNameAr,
        'username':     username,
        'email':        email,
        'password':     password,
        'role':         role,
        if (phone.isNotEmpty)      'phone':      phone,
        if (department.isNotEmpty) 'department': department,
        'gender': gender,
      },
    );

    final userMap = Map<String, dynamic>.from(data['user']);
    userMap['token'] = data['token'];

    final profile = UserProfile.fromJson(userMap);
    state = state.copyWith(user: profile);
    await _persist(profile);
  }

  // ─────────────────────────────────────────────
  // REFRESH
  // ─────────────────────────────────────────────
  Future<void> refreshMe() async {
    final current = state.user;
    if (current == null) return;

    final data = await _api.getJson(
      '/api/auth/me',
      token: current.token,
    );

    final userMap = Map<String, dynamic>.from(
      data['user'] ?? data['data']?['user'] ?? {},
    );

    userMap['token'] = current.token;

    state = state.copyWith(user: UserProfile.fromJson(userMap));
    await _persist(state.user!);
  }

  // ─────────────────────────────────────────────
  // UPDATE PROFILE
  // ─────────────────────────────────────────────
  Future<void> updateProfile({
    required String fullNameAr,
    required String fullNameEn,
    required String phone,
  }) async {
    final current = state.user;
    if (current == null) return;

    final data = await _api.putJson(
      '/api/users/me/profile',
      token: current.token,
      body: {
        'full_name_ar': fullNameAr,
        'full_name_en': fullNameEn,
        'phone': phone,
      },
    );

    final updated = Map<String, dynamic>.from(data['user']);
    updated['token'] = current.token;

    final profile = UserProfile.fromJson(updated);
    state = state.copyWith(user: profile);
    await _persist(profile);
  }

  // ─────────────────────────────────────────────
  // UPLOAD IMAGE (FIXED)
  // ─────────────────────────────────────────────
  Future<void> uploadProfileImage(String filePath) async {
    final current = state.user;
    if (current == null) return;

    final data = await _api.postMultipart(
      '/api/users/me/profile-photo',
      fieldName: 'image',
      filePath: filePath,
      token: current.token,
    );

    final photoPath = data['photo_url'] ?? '';

    final updated = current.copyWith(
      photoUrl: photoPath.startsWith('http')
          ? photoPath
          : '${ApiConfig.baseUrl}$photoPath',
    );

    state = state.copyWith(user: updated);
    await _persist(updated);
  }

  // ─────────────────────────────────────────────
  // LOCATION
  // ─────────────────────────────────────────────
  Future<void> sendLocation({
    required double latitude,
    required double longitude,
  }) async {
    final current = state.user;
    if (current == null) return;

    await _api.postJson(
      '/api/users/me/location',
      token: current.token,
      body: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  // ─────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────
  Future<void> signOut() async {
    state = state.copyWith(user: null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  void dismissSplash() {
    state = state.copyWith(showSplash: false);
  }
}

final userProfileProvider =
    NotifierProvider<UserProfileController, UserProfileState>(
  UserProfileController.new,
);