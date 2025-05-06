// lib/presentation/widgets/admin/admin_notification_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/admin_notification_service.dart';

class AdminNotificationBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final double badgeSize;
  final double positionRight;
  final double positionTop;

  const AdminNotificationBadge({
    Key? key,
    required this.child,
    this.badgeColor,
    this.textStyle,
    this.padding = const EdgeInsets.all(4),
    this.badgeSize = 16,
    this.positionRight = 0,
    this.positionTop = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminNotificationService>(
      builder: (context, service, _) {
        final unreadCount = service.unreadCount;
        
        if (unreadCount == 0) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: positionRight,
              top: positionTop,
              child: Container(
                padding: padding,
                constraints: BoxConstraints(minWidth: badgeSize, minHeight: badgeSize),
                decoration: BoxDecoration(
                  color: badgeColor ?? Theme.of(context).colorScheme.error,
                  shape: unreadCount < 10 ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: unreadCount < 10 ? null : BorderRadius.circular(badgeSize / 2),
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: textStyle ?? const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Factory method to create a standard admin notification icon for app bar
  factory AdminNotificationBadge.appBar({
    required Widget child,
    Color? badgeColor,
  }) {
    return AdminNotificationBadge(
      child: child,
      badgeColor: badgeColor,
      positionRight: -2,
      positionTop: -2,
    );
  }
}