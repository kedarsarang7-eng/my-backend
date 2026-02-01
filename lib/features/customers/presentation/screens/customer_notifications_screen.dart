// ============================================================================
// CUSTOMER NOTIFICATIONS SCREEN
// ============================================================================
// Shows all notifications for a customer with read/unread filtering
//
// Author: DukanX Engineering
// Version: 1.0.0
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../customers/data/customer_notifications_repository.dart';

class CustomerNotificationsScreen extends ConsumerWidget {
  final String customerId;

  const CustomerNotificationsScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync =
        ref.watch(customerNotificationsProvider(customerId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(context, ref),
            child: Text(
              'Mark All Read',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmpty();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) =>
                _buildNotificationCard(context, ref, notifications[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    CustomerNotification notification,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = !notification.isRead;

    IconData icon;
    Color iconColor;
    switch (notification.notificationType) {
      case NotificationType.newInvoice:
        icon = Icons.receipt;
        iconColor = Colors.blue;
        break;
      case NotificationType.paymentReminder:
        icon = Icons.alarm;
        iconColor = Colors.orange;
        break;
      case NotificationType.paymentReceived:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.dueDateAlert:
        icon = Icons.warning;
        iconColor = Colors.red;
        break;
      case NotificationType.promotional:
        icon = Icons.local_offer;
        iconColor = Colors.purple;
        break;
      case NotificationType.systemAlert:
        icon = Icons.info;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            isUnread ? Border.all(color: Colors.blue.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _onNotificationTap(context, ref, notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontWeight:
                                  isUnread ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('dd MMM').format(time);
    }
  }

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    CustomerNotification notification,
  ) async {
    if (!notification.isRead) {
      final repo = ref.read(customerNotificationsRepositoryProvider);
      await repo.markAsRead(notification.id);
    }

    // Handle action based on notification type
    if (notification.actionType != null && notification.actionId != null) {
      // Navigate to appropriate screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Opening ${notification.actionType}: ${notification.actionId}'),
        ),
      );
    }
  }

  void _markAllAsRead(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(customerNotificationsRepositoryProvider);
    final result = await repo.markAllAsRead(customerId);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked ${result.data} as read')),
      );
    }
  }
}
