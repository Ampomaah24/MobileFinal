
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/auth_service.dart';
import 'notification_item.dart';
import '../../../core/models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    try {
      if (authService.user != null) {
        await notificationService.getNotifications(authService.user!.uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    try {
      if (authService.user != null) {
        await notificationService.markAllNotificationsAsRead(authService.user!.uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notifications as read: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _deleteAllNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (result == true && authService.user != null) {
      try {
        await notificationService.deleteAllNotifications(authService.user!.uid);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting notifications: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final hasUnread = notificationService.unreadCount > 0;
    final notifications = notificationService.notifications;
    final isLoading = notificationService.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all notifications',
              onPressed: _deleteAllNotifications,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildNotificationsList(notifications),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'We\'ll notify you about upcoming events and booking updates',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationItem(
            key: Key(notification.id),
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDismiss: () => _handleNotificationDismiss(notification),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    // Mark as read when tapped
    if (!notification.isRead) {
      await notificationService.markNotificationAsRead(notification.id);
    }
    
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.eventReminder:
        if (notification.eventId != null) {
          Navigator.pushNamed(
            context,
            '/event-details',
            arguments: notification.eventId,
          );
        }
        break;
      case NotificationType.bookingConfirmation:
        if (notification.bookingId != null) {
          Navigator.pushNamed(
            context,
            '/booking-confirmation',
            arguments: notification.bookingId,
          );
        }
        break;
      case NotificationType.systemUpdate:
        // Just display the message, no navigation
        break;
      case NotificationType.promotionalOffer:
        // Navigate to promotions screen or show promo details
        _showPromotionDetails(notification);
        break;
    }
  }
  
  void _showPromotionDetails(NotificationModel notification) {
    // Show a modal with promotion details
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final promoCode = notification.additionalData?['promoCode'] as String?;
        final discount = notification.additionalData?['discount'] as int?;
        final validUntil = notification.additionalData?['validUntil'] as int?;
        
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_offer,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (promoCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        promoCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          // Copy promo code to clipboard
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Promo code copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              if (discount != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Save ${discount}% on your next booking',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (validUntil != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Valid until ${DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(validUntil))}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/discover');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Discover Events'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleNotificationDismiss(NotificationModel notification) async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    try {
      await notificationService.deleteNotification(notification.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification dismissed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error dismissing notification: ${e.toString()}')),
        );
      }
    }
  }
}