
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/admin_notification_model.dart';

class AdminNotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<AdminNotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<AdminNotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Calculate unread count
  int get unreadCount => _notifications.where((notification) => !notification.isRead).length;
  
  // Fetch admin notifications
  Future<void> fetchAdminNotifications() async {
    _setLoading(true);
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('admin_notifications')
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit to the most recent 50 notifications
          .get();
      
      _notifications = snapshot.docs.map((doc) {
        return AdminNotificationModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      notifyListeners();
    } catch (e) {
      _error = 'Error fetching admin notifications: ${e.toString()}';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Create a new admin notification
  Future<void> createAdminNotification({
    required String title,
    required String message,
    required AdminNotificationType type,
    String? entityId,
    String? entityType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notification = AdminNotificationModel(
        id: '', // Will be set by Firestore
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        isRead: false,
        entityId: entityId,
        entityType: entityType,
        additionalData: additionalData,
      );
      
      // Add to Firestore
      final docRef = await _firestore
          .collection('admin_notifications')
          .add(notification.toMap());
      
      // Add to local list
      final newNotification = notification.copyWith(id: docRef.id);
      _notifications.insert(0, newNotification);
      
      notifyListeners();
    } catch (e) {
      _error = 'Error creating admin notification: ${e.toString()}';
      print(_error);
    }
  }
  
  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .update({'isRead': true});
      
      // Update in local list
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error marking notification as read: ${e.toString()}';
      print(_error);
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      // Get all unread notifications
      final batch = _firestore.batch();
      final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
      
      // Update in Firestore
      for (var notification in unreadNotifications) {
        final docRef = _firestore.collection('admin_notifications').doc(notification.id);
        batch.update(docRef, {'isRead': true});
      }
      
      await batch.commit();
      
      // Update local list
      _notifications = _notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();
      
      notifyListeners();
    } catch (e) {
      _error = 'Error marking all notifications as read: ${e.toString()}';
      print(_error);
    }
  }
  
  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .delete();
      
      // Remove from local list
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _error = 'Error deleting notification: ${e.toString()}';
      print(_error);
    }
  }
  
  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      // Get all notification IDs
      final batch = _firestore.batch();
      
      for (var notification in _notifications) {
        final docRef = _firestore.collection('admin_notifications').doc(notification.id);
        batch.delete(docRef);
      }
      
      await batch.commit();
      
      // Clear local list
      _notifications.clear();
      notifyListeners();
    } catch (e) {
      _error = 'Error deleting all notifications: ${e.toString()}';
      print(_error);
    }
  }
  
  // Generate notification for a new user
  Future<void> notifyNewUser(String userId, String userName, String userEmail) async {
    await createAdminNotification(
      title: 'New User Registration',
      message: '$userName ($userEmail) has registered',
      type: AdminNotificationType.newUser,
      entityId: userId,
      entityType: 'user',
      additionalData: {
        'name': userName,
        'email': userEmail,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  // Generate notification for a new booking
  Future<void> notifyNewBooking(String bookingId, String userId, String eventId, String eventTitle, double amount) async {
    await createAdminNotification(
      title: 'New Booking',
      message: 'A new booking worth GHS ${amount.toStringAsFixed(2)} for "$eventTitle"',
      type: AdminNotificationType.newBooking,
      entityId: bookingId,
      entityType: 'booking',
      additionalData: {
        'userId': userId,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'amount': amount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  // Generate notification for a booking cancellation
  Future<void> notifyBookingCancellation(String bookingId, String userId, String eventId, String eventTitle, double amount) async {
    await createAdminNotification(
      title: 'Booking Cancelled',
      message: 'A booking for "$eventTitle" worth GHS ${amount.toStringAsFixed(2)} was cancelled',
      type: AdminNotificationType.bookingCancellation,
      entityId: bookingId,
      entityType: 'booking',
      additionalData: {
        'userId': userId,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'amount': amount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  // Generate notification for daily revenue milestone
  Future<void> notifyRevenueMilestone(double amount, int bookingsCount) async {
    await createAdminNotification(
      title: 'Revenue Milestone',
      message: 'Daily revenue has reached GHS ${amount.toStringAsFixed(2)} from $bookingsCount bookings',
      type: AdminNotificationType.revenueUpdate,
      additionalData: {
        'amount': amount,
        'bookingsCount': bookingsCount,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  // Generate notification for system alerts
  Future<void> notifySystemAlert(String alertTitle, String alertMessage, {Map<String, dynamic>? data}) async {
    await createAdminNotification(
      title: alertTitle,
      message: alertMessage,
      type: AdminNotificationType.systemAlert,
      additionalData: data,
    );
  }
  
  // Helper method to update loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}