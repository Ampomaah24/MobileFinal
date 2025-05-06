// lib/presentation/widgets/notification_icon.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import 'notification_badge.dart';

class NotificationIcon extends StatelessWidget {
  final double iconSize;
  final Color? iconColor;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;

  const NotificationIcon({
    Key? key,
    this.iconSize = 24.0,
    this.iconColor,
    this.onPressed,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    
    return Padding(
      padding: padding,
      child: IconButton(
        icon: NotificationBadge(
          positionRight: -2,
          positionTop: -2,
          badgeColor: Theme.of(context).colorScheme.error,
          child: Icon(
            Icons.notifications_outlined,
            size: iconSize,
            color: iconColor,
          ),
          unreadCount: notificationService.unreadCount,
        ),
        tooltip: 'Notifications',
        onPressed: onPressed ?? () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
    );
  }

  /// Factory method to create a standard notification icon for app bar
  factory NotificationIcon.appBar({
    Color? iconColor,
    VoidCallback? onPressed,
  }) {
    return NotificationIcon(
      iconColor: iconColor,
      onPressed: onPressed,
    );
  }

  /// Factory method to create a large notification icon for home screen
  factory NotificationIcon.large({
    Color? iconColor,
    VoidCallback? onPressed,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8.0),
  }) {
    return NotificationIcon(
      iconSize: 32.0,
      iconColor: iconColor,
      onPressed: onPressed,
      padding: padding,
    );
  }

  /// Factory method to create a small notification icon
  factory NotificationIcon.small({
    Color? iconColor,
    VoidCallback? onPressed,
  }) {
    return NotificationIcon(
      iconSize: 18.0,
      iconColor: iconColor,
      onPressed: onPressed,
    );
  }
}