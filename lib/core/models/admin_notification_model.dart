import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminNotificationType {
  newUser,
  newBooking,
  bookingCancellation,
  systemAlert,
  revenueUpdate,
  eventUpdate,
  other
}

class AdminNotificationModel {
  final String id;
  final String title;
  final String message;
  final AdminNotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? entityId; 
  final String? entityType; 
  final Map<String, dynamic>? additionalData;

  AdminNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.entityId,
    this.entityType,
    this.additionalData,
  });

  // Factory method to create an AdminNotificationModel from Firestore
  factory AdminNotificationModel.fromMap(String id, Map<String, dynamic> data) {
    return AdminNotificationModel(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseNotificationType(data['type']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      entityId: data['entityId'],
      entityType: data['entityType'],
      additionalData: data['additionalData'],
    );
  }

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'entityId': entityId,
      'entityType': entityType,
      'additionalData': additionalData,
    };
  }

  // Create a copy with updated fields
  AdminNotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    AdminNotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? entityId,
    String? entityType,
    Map<String, dynamic>? additionalData,
  }) {
    return AdminNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Helper method to parse notification type
  static AdminNotificationType _parseNotificationType(String? typeStr) {
    switch (typeStr) {
      case 'newUser':
        return AdminNotificationType.newUser;
      case 'newBooking':
        return AdminNotificationType.newBooking;
      case 'bookingCancellation':
        return AdminNotificationType.bookingCancellation;
      case 'systemAlert':
        return AdminNotificationType.systemAlert;
      case 'revenueUpdate':
        return AdminNotificationType.revenueUpdate;
      case 'eventUpdate':
        return AdminNotificationType.eventUpdate;
      default:
        return AdminNotificationType.other;
    }
  }
}