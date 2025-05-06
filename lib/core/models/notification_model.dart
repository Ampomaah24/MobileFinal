// lib/core/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  eventReminder,
  bookingConfirmation,
  systemUpdate,
  promotionalOffer,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? eventId;
  final String? bookingId;
  final String? imageUrl;
  final Map<String, dynamic>? additionalData;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.eventId,
    this.bookingId,
    this.imageUrl,
    this.additionalData,
  });

  // Factory method to create a NotificationModel from a Firestore document
  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseNotificationType(data['type']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      eventId: data['eventId'],
      bookingId: data['bookingId'],
      imageUrl: data['imageUrl'],
      additionalData: data['additionalData'],
    );
  }

  // Convert NotificationModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'eventId': eventId,
      'bookingId': bookingId,
      'imageUrl': imageUrl,
      'additionalData': additionalData,
    };
  }

  // Helper method to parse notification type
  static NotificationType _parseNotificationType(String? typeStr) {
    if (typeStr == 'eventReminder') {
      return NotificationType.eventReminder;
    } else if (typeStr == 'bookingConfirmation') {
      return NotificationType.bookingConfirmation;
    } else if (typeStr == 'promotionalOffer') {
      return NotificationType.promotionalOffer;
    } else {
      return NotificationType.systemUpdate;
    }
  }

  // Create a copy of the notification with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? eventId,
    String? bookingId,
    String? imageUrl,
    Map<String, dynamic>? additionalData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      eventId: eventId ?? this.eventId,
      bookingId: bookingId ?? this.bookingId,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}