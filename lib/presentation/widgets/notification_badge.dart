// lib/presentation/widgets/notification_badge.dart
import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final double badgeSize;
  final double positionRight;
  final double positionTop;
  final int unreadCount;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.badgeColor,
    this.textStyle,
    this.padding = const EdgeInsets.all(4),
    this.badgeSize = 16,
    this.positionRight = 0,
    this.positionTop = 0,
    this.unreadCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (unreadCount == 0) {
      return child;
    }

    final badge = Container(
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
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: positionRight,
          top: positionTop,
          child: badge,
        ),
      ],
    );
  }
}