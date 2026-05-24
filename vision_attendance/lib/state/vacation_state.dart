// lib/state/vacation_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'user_profile_state.dart';

class VacationState {
  final List<Map<String, dynamic>> requests;
  final bool isLoading;
  final String? error;

  VacationState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  VacationState copyWith({
    List<Map<String, dynamic>>? requests,
    bool? isLoading,
    String? error,
  }) {
    return VacationState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VacationNotifier extends Notifier<VacationState> {
  @override
  VacationState build() {
    // We can't easily call loadVacations here if it's async,
    // but we can trigger it or use FutureProvider for data.
    // For now, let's just return initial state.
    return VacationState();
  }

  Future<void> loadVacations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = ref.read(userProfileProvider).user;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'User not logged in');
        return;
      }

      final api = ApiService(token: user.token);
      final data = await api.getMyVacations();
      
      final List<Map<String, dynamic>> requests = List<Map<String, dynamic>>.from(data['vacations'] ?? []);
      
      state = state.copyWith(requests: requests, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void addRequest(Map<String, dynamic> request) {
    state = state.copyWith(requests: [request, ...state.requests]);
  }
}

final vacationProvider = NotifierProvider<VacationNotifier, VacationState>(() {
  return VacationNotifier();
});
