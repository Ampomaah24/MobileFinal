
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/admin_notification_service.dart';
import '../../../core/models/admin_notification_model.dart';
import 'admin_app_bar.dart';
import 'admin_drawer.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({Key? key}) : super(key: key);

  @override
  _AdminNotificationScreenState createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    try {
      final service = Provider.of<AdminNotificationService>(context, listen: false);
      await service.fetchAdminNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _markAllAsRead() async {
    try {
      final service = Provider.of<AdminNotificationService>(context, listen: false);
      await service.markAllAsRead();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final service = Provider.of<AdminNotificationService>(context, listen: false);
        await service.deleteAllNotifications();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications cleared'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'Admin Notifications'),
      drawer: const AdminDrawer(currentIndex: -1),
      body: Consumer<AdminNotificationService>(
        builder: (context, notificationService, child) {
          if (notificationService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final notifications = notificationService.notifications;
          final hasUnread = notificationService.unreadCount > 0;
          
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          
          return Column(
            children: [
              // Action bar
              if (notifications.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${notifications.length} Notifications',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          if (hasUnread)
                            TextButton.icon(
                              icon: const Icon(Icons.done_all),
                              label: const Text('Mark All Read'),
                              onPressed: _markAllAsRead,
                            ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.delete_sweep),
                            label: const Text('Clear All'),
                            onPressed: _clearAllNotifications,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              
              // Notification list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(context, notifications[index]);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll receive notifications for important\nevents and updates here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, AdminNotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notification.id),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text('Are you sure you want to delete this notification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 8),
        color: notification.isRead ? null : Colors.blue.shade50,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: _buildNotificationIcon(notification.type),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.message),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => _markAsRead(notification),
          trailing: !notification.isRead
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AdminNotificationType type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case AdminNotificationType.newUser:
        icon = Icons.person_add;
        color = Colors.green;
        break;
      case AdminNotificationType.newBooking:
        icon = Icons.confirmation_number;
        color = Colors.blue;
        break;
      case AdminNotificationType.bookingCancellation:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case AdminNotificationType.systemAlert:
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case AdminNotificationType.revenueUpdate:
        icon = Icons.attach_money;
        color = Colors.purple;
        break;
      case AdminNotificationType.eventUpdate:
        icon = Icons.event;
        color = Colors.teal;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color),
    );
  }

  void _markAsRead(AdminNotificationModel notification) {
    if (!notification.isRead) {
      Provider.of<AdminNotificationService>(context, listen: false)
          .markAsRead(notification.id);
    }
    
    // Handle navigation or show details based on notification type
    _handleNotificationTap(notification);
  }

  void _deleteNotification(String notificationId) {
    Provider.of<AdminNotificationService>(context, listen: false)
        .deleteNotification(notificationId);
  }

  void _handleNotificationTap(AdminNotificationModel notification) {
    // Navigate to different screens based on notification type
    switch (notification.type) {
      case AdminNotificationType.newUser:
        if (notification.entityId != null) {
          // Navigate to user details
          Navigator.pushNamed(
            context,
            '/admin/users/details',
            arguments: notification.entityId,
          );
        }
        break;
      case AdminNotificationType.newBooking:
      case AdminNotificationType.bookingCancellation:
        if (notification.entityId != null) {
          // Navigate to booking details
          Navigator.pushNamed(
            context,
            '/admin/bookings/details',
            arguments: notification.entityId,
          );
        }
        break;
      case AdminNotificationType.eventUpdate:
        if (notification.entityId != null) {
          // Navigate to event details
          Navigator.pushNamed(
            context,
            '/admin/events/details',
            arguments: notification.entityId,
          );
        }
        break;
      case AdminNotificationType.revenueUpdate:
        // Navigate to analytics screen
        Navigator.pushNamed(context, '/admin/analytics');
        break;
      case AdminNotificationType.systemAlert:
      default:
        // For system alerts and other types, just show a detail dialog
        _showNotificationDetailsDialog(notification);
        break;
    }
  }

  void _showNotificationDetailsDialog(AdminNotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.message),
              const SizedBox(height: 16),
              Text(
                'Received: ${DateFormat('MMM d, yyyy \u2022 h:mm a').format(notification.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (notification.additionalData != null && notification.additionalData!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...notification.additionalData!.entries.map((entry) {
                  // Format the value based on its type
                  String value = '';
                  if (entry.value is int && entry.key.toLowerCase().contains('timestamp')) {
                    // Format as date if it's a timestamp
                    value = DateFormat('MMM d, yyyy \u2022 h:mm a')
                        .format(DateTime.fromMillisecondsSinceEpoch(entry.value));
                  } else if (entry.value is double) {
                    // Format as currency if it's a double
                    value = 'GHS ${entry.value.toStringAsFixed(2)}';
                  } else {
                    value = entry.value.toString();
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            _formatKey(entry.key),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(value),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  String _formatKey(String key) {
    // Convert camelCase or snake_case to Title Case with spaces
    String result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    
    result = result.replaceAll('_', ' ');
    
    // Capitalize first letter and trim spaces
    result = result.trim();
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }
    
    return result;
  }
}