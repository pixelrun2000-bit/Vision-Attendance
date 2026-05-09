// lib/screens/home/notification_center_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notification Center'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n.isRead = true;
                }
              });
            },
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _NotificationList(notifications: _notifications),
          _NotificationList(
              notifications: _notifications
                  .where((n) => n.type == 'attendance')
                  .toList()),
          _NotificationList(
              notifications: _notifications
                  .where((n) => n.type == 'leave')
                  .toList()),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<_Notification> notifications;

  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context) {
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (_, i) => _NotificationCard(notification: notifications[i]),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _Notification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: notification.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(notification.icon,
                color: notification.color, size: 22),
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
                Text(notification.time,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notification {
  final String title;
  final String body;
  final String time;
  final String type;
  final IconData icon;
  final Color color;
  bool isRead;

  _Notification({
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

final _notifications = [
  _Notification(
    title: 'Check-In Confirmed',
    body: 'Your check-in at HQ North Wing was recorded at 08:42 AM.',
    time: '2 mins ago',
    type: 'attendance',
    icon: Icons.login_rounded,
    color: AppColors.success,
    isRead: false,
  ),
  _Notification(
    title: 'Leave Request Update',
    body: 'Your "Summer Break 2024" request is pending manager approval.',
    time: '1 hour ago',
    type: 'leave',
    icon: Icons.beach_access_rounded,
    color: AppColors.warning,
    isRead: false,
  ),
  _Notification(
    title: 'Overtime Alert',
    body: 'You worked 12h 15m on Tuesday — 4h 15m overtime logged.',
    time: 'Yesterday',
    type: 'attendance',
    icon: Icons.access_time_rounded,
    color: AppColors.primary,
    isRead: true,
  ),
  _Notification(
    title: 'Leave Approved',
    body: 'Personal Leave (Apr 02–03) has been approved by HR.',
    time: '2 days ago',
    type: 'leave',
    icon: Icons.check_circle_rounded,
    color: AppColors.success,
    isRead: true,
  ),
  _Notification(
    title: 'AI Insight',
    body: 'Your attendance rate this month is 98% — top 5% in your team!',
    time: '3 days ago',
    type: 'ai',
    icon: Icons.auto_awesome_rounded,
    color: AppColors.info,
    isRead: true,
  ),
  _Notification(
    title: 'Reminder: Check-Out',
    body: 'It\'s 6:00 PM — don\'t forget to check out before leaving.',
    time: '4 days ago',
    type: 'attendance',
    icon: Icons.logout_rounded,
    color: AppColors.error,
    isRead: true,
  ),
];
