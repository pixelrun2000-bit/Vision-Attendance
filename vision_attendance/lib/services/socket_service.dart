// lib/services/socket_service.dart
import 'dart:developer' as dev;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import '../state/user_profile_state.dart';
import '../state/notification_state.dart';
import '../state/vacation_state.dart';
import '../state/attendance_refresh_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final user = ref.watch(userProfileProvider).user;
  final notifier = ref.read(notificationProvider.notifier);
  
  final service = SocketService(
    baseUrl: ApiConfig.baseUrl,
    userId: user?.id,
    notificationNotifier: notifier,
    ref: ref,
  );
  
  ref.onDispose(() => service.dispose());
  
  return service;
});

class SocketService {
  final String baseUrl;
  final int? userId;
  final NotificationNotifier notificationNotifier;
  final Ref ref;
  
  late io.Socket _socket;

  SocketService({
    required this.baseUrl,
    required this.userId,
    required this.notificationNotifier,
    required this.ref,
  }) {
    _init();
  }

  void _init() {
    dev.log('[Socket] Initializing for $baseUrl', name: 'SocketService');
    
    _socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      dev.log('[Socket] Connected: ${_socket.id}', name: 'SocketService');
      if (userId != null) {
        _socket.emit('user:join', userId);
      }
    });

    _socket.onDisconnect((_) {
      dev.log('[Socket] Disconnected', name: 'SocketService');
    });

    // Listen for new notifications
    _socket.on('notification:new', (data) {
      dev.log('[Socket] New notification received: $data', name: 'SocketService');
      final item = NotificationItem.fromJson(data);
      notificationNotifier.addNotification(item);
    });

    // Real-time Vacation updates
    _socket.on('vacation:new', (data) {
      dev.log('[Socket] New vacation request', name: 'SocketService');
      ref.read(vacationProvider.notifier).loadVacations();
    });

    _socket.on('vacation:update', (data) {
      dev.log('[Socket] Vacation status updated', name: 'SocketService');
      ref.read(vacationProvider.notifier).loadVacations();
    });

    // Real-time Attendance updates
    _socket.on('attendance:refresh', (data) {
      dev.log('[Socket] Attendance refresh requested', name: 'SocketService');
      // This is a bit tricky since AttendanceLogScreen is a StatefulWidget with its own state.
      // But we can emit a global refresh event or use a provider if we had one.
      // For now, let's just log it. If AttendanceLogScreen is open, we can use a refresh provider.
      ref.read(attendanceRefreshProvider.notifier).triggerRefresh();
    });

    _socket.on('attendance:update', (data) {
       dev.log('[Socket] Attendance global update: $data', name: 'SocketService');
       // This can be used for the admin dashboard or global stats
       ref.read(attendanceRefreshProvider.notifier).triggerRefresh();
    });

    _socket.onConnectError((err) => dev.log('[Socket] Connect Error: $err', name: 'SocketService'));
    _socket.onError((err) => dev.log('[Socket] Error: $err', name: 'SocketService'));
  }

  void joinRoom(int roomId) {
    _socket.emit('room:join', roomId);
  }

  void leaveRoom(int roomId) {
    _socket.emit('room:leave', roomId);
  }

  void dispose() {
    _socket.disconnect();
    _socket.dispose();
  }
}
