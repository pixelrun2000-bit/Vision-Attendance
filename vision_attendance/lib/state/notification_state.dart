// lib/state/notification_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'system',
      isRead: (json['is_read'] == 1 || json['is_read'] == true),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class NotificationState {
  final List<NotificationItem> notifications;
  final int unreadCount;
  final bool isLoading;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  late ApiService _api;

  @override
  NotificationState build() {
    _api = ref.watch(apiServiceProvider);
    // Trigger initial fetch
    Future.microtask(() => fetchNotifications());
    return NotificationState(isLoading: true);
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getNotifications();
      if (res['success'] == true) {
        final list = (res['notifications'] as List)
            .map((e) => NotificationItem.fromJson(e))
            .toList();
        state = state.copyWith(
          notifications: list,
          unreadCount: res['unread'] ?? 0,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void addNotification(NotificationItem item) {
    state = state.copyWith(
      notifications: [item, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    );
  }

  Future<void> markRead(int id) async {
    try {
      await _api.markNotificationRead(id);
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == id) return n.copyWith(isRead: true);
          return n;
        }).toList(),
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
        unreadCount: 0,
      );
    } catch (e) {
      // Handle error
    }
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
