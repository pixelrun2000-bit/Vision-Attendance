// lib/screens/home/notification_center_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../state/notification_state.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Refresh notifications when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notification Center'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllRead(),
              child: const Text('Mark All Read',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Attendance'),
            Tab(text: 'Leave'),
          ],
        ),
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _NotificationList(notifications: state.notifications),
                _NotificationList(
                    notifications: state.notifications
                        .where((n) => n.type == 'attendance')
                        .toList()),
                _NotificationList(
                    notifications: state.notifications
                        .where((n) => n.type == 'vacation' || n.type == 'leave')
                        .toList()),
              ],
            ),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  final List<NotificationItem> notifications;

  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64, color: AppColors.border),
            SizedBox(height: 16),
            Text('No notifications', style: AppTextStyles.headlineMedium),
            SizedBox(height: 6),
            Text('You\'re all caught up!', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, i) => _NotificationCard(notification: notifications[i]),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationItem notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final IconData icon;
    final Color color;

    switch (notification.type) {
      case 'attendance':
        icon = notification.title.contains('Failed') ? Icons.error_outline : Icons.login_rounded;
        color = notification.title.contains('Failed') ? AppColors.error : AppColors.success;
        break;
      case 'vacation':
      case 'leave':
        icon = Icons.beach_access_rounded;
        color = AppColors.warning;
        break;
      case 'ai':
        icon = Icons.auto_awesome_rounded;
        color = AppColors.info;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppColors.primary;
    }

    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationProvider.notifier).markRead(notification.id);
        }
      },
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : AppColors.primary.withOpacity(0.03),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: AppTextStyles.titleLarge),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(notification.body, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 6),
                  Text(
                    _getTimeAgo(notification.createdAt),
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dateTime);
  }
}
