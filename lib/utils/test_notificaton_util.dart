// lib/core/utils/test_notification_util.dart
import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/notification_model.dart';


class TestNotificationUtil {
  // Generate sample notifications for testing purposes
  static Future<void> generateSampleNotifications(
    NotificationService notificationService,
    String userId,
  ) async {
    try {
      // Event Reminder notification
      await notificationService.sendEventReminderNotification(
        userId,
        'sample_event_1',  // Event ID
        'Flutter Conference 2025',  // Event title
        DateTime.now().add(const Duration(days: 1)),  // Event time (tomorrow)
      );
      
      // Booking Confirmation notification
      await notificationService.sendEventBookingConfirmation(
        userId,
        'sample_event_2',  // Event ID
        'Live Music Festival',  // Event title
        DateTime.now().add(const Duration(days: 3)),  // Event time (3 days from now)
        2,  // Ticket count
        'sample_booking_1',  // Booking ID
        totalAmount: 120.00,  // Total amount
        eventImage: 'https://example.com/sample-event.jpg',  // Event image URL
      );
      
      // Send test notification (system update)
      await notificationService.sendTestNotification(userId);
      
      print('Successfully generated sample notifications for user $userId');
    } catch (e) {
      print('Error generating sample notifications: $e');
      rethrow;
    }
  }
}