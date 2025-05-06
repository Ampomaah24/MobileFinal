import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;
  String? _fcmToken;
  tz.Location? _local;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationService() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      _local = tz.local;

      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _fcmToken = await _firebaseMessaging.getToken();

        FirebaseMessaging.onMessage.listen(_handleMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);

        const initializationSettings = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        );

        await _localNotifications.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: _onSelectNotification,
        );

        await _setupNotificationChannels();

        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        _initialized = true;
        notifyListeners();
      }
    } catch (e) {
      print('Initialization error: $e');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Background message: ${message.messageId}');
  }

  void _handleMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(message);
    }
    if (message.data['userId'] != null) {
      _saveNotificationToFirestore(message);
    }
  }

  void _handleInitialMessage(RemoteMessage? message) {
    if (message != null) _navigateBasedOnMessage(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _navigateBasedOnMessage(message);
  }

  void _navigateBasedOnMessage(RemoteMessage message) {
    final data = message.data;
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if (data['type'] == 'event' && data['eventId'] != null) {
      nav.pushNamed('/event-details', arguments: data['eventId']);
    } else if (data['type'] == 'booking' && data['bookingId'] != null) {
      nav.pushNamed('/booking-confirmation', arguments: data['bookingId']);
    } else if (data['notificationId'] != null) {
      markNotificationAsRead(data['notificationId']);
    }
  }

  void _onSelectNotification(NotificationResponse response) {
    final nav = navigatorKey.currentState;
    final payload = response.payload;
    if (nav == null || payload == null) return;

    if (payload.startsWith('/event-details')) {
      final eventId = Uri.parse(payload).queryParameters['id'];
      nav.pushNamed('/event-details', arguments: eventId);
    } else if (payload.startsWith('/booking-confirmation')) {
      final bookingId = Uri.parse(payload).queryParameters['id'];
      nav.pushNamed('/booking-confirmation', arguments: bookingId);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    String channelId = _getChannelIdForType(message.data['type']);

    final android = AndroidNotificationDetails(
      channelId,
      channelId.replaceAll('_', ' ').toUpperCase(),
      channelDescription: 'Channel for $channelId',
      importance: Importance.high,
      priority: Priority.high,
    );

    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);

    await _localNotifications.show(
      message.hashCode,
      notif.title ?? 'Evently',
      notif.body ?? '',
      details,
      payload: message.data['route'],
    );
  }

  String _getChannelIdForType(String? type) {
    switch (type) {
      case 'event_reminder':
        return 'event_reminders';
      case 'booking_confirmation':
        return 'booking_confirmations';
      case 'system_update':
        return 'system_updates';
      default:
        return 'event_reminders';
    }
  }

  Future<void> _setupNotificationChannels() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.createNotificationChannel(AndroidNotificationChannel(
        'event_reminders',
        'Event Reminders',
        description: 'Notifications for upcoming events',
        importance: Importance.high,
      ));
      await android.createNotificationChannel(AndroidNotificationChannel(
        'booking_confirmations',
        'Booking Confirmations',
        description: 'Notifications for confirmed bookings',
        importance: Importance.high,
      ));
      await android.createNotificationChannel(AndroidNotificationChannel(
        'system_updates',
        'System Updates',
        description: 'General system messages and alerts',
        importance: Importance.low,
      ));
    }
  }

  Future<void> cancelEventReminder(String eventId) async {
    try {
      await _localNotifications.cancel(eventId.hashCode);
      final reminders = await _firestore
          .collection('event_reminders')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (final doc in reminders.docs) {
        await doc.reference.update({'status': 'cancelled'});
      }

      print('Reminder for event $eventId cancelled.');
    } catch (e) {
      print('Error cancelling reminder: $e');
    }
  }

  Future<void> sendEventBookingConfirmation(
    String userId,
    String eventId,
    String eventTitle,
    DateTime eventTime,
    int ticketCount,
    String bookingId, {
    double? totalAmount,
    String? eventImage,
  }) async {
    try {
      final notif = NotificationModel(
        id: 'booking_$bookingId',
        userId: userId,
        title: 'Booking Confirmed',
        message: 'Your booking for "$eventTitle" ($ticketCount tickets) is confirmed!',
        type: NotificationType.bookingConfirmation,
        createdAt: DateTime.now(),
        isRead: false,
        eventId: eventId,
        bookingId: bookingId,
        imageUrl: eventImage,
        additionalData: {
          'totalAmount': totalAmount,
        },
      );

      await _firestore.collection('notifications').doc(notif.id).set(notif.toMap());

      const android = AndroidNotificationDetails(
        'booking_confirmations',
        'Booking Confirmations',
        importance: Importance.high,
        priority: Priority.high,
      );
      const ios = DarwinNotificationDetails();
      final details = NotificationDetails(android: android, iOS: ios);

      await _localNotifications.show(
        bookingId.hashCode,
        notif.title,
        notif.message,
        details,
        payload: '/booking-confirmation?id=$bookingId',
      );
    } catch (e) {
      print('Error sending confirmation: $e');
    }
  }

  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final userId = message.data['userId'];
    if (userId == null) return;

    final notif = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: message.notification?.title ?? 'Evently',
      message: message.notification?.body ?? '',
      type: NotificationType.eventReminder,
      createdAt: DateTime.now(),
      isRead: false,
      eventId: message.data['eventId'],
      bookingId: message.data['bookingId'],
      imageUrl: message.data['imageUrl'],
      additionalData: message.data,
    );

    await _firestore.collection('notifications').doc(notif.id).set(notif.toMap());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // ADDED METHODS BELOW

  // Method to schedule event reminders
  Future<void> scheduleEventReminder(
    String eventId, 
    String eventTitle, 
    DateTime eventTime,
  ) async {
    try {
      // Skip if the event is in the past
      if (eventTime.isBefore(DateTime.now())) {
        print('Event date is in the past, skipping reminder');
        return;
      }
      
      // First check if a reminder already exists
      final existing = await _firestore
          .collection('event_reminders')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'active')
          .get();
      
      if (existing.docs.isNotEmpty) {
        print('Reminder for event $eventId already scheduled');
        return;
      }

      // We'll schedule three reminders:
      // 1. One day before the event
      // 2. Three hours before the event
      // 3. Thirty minutes before the event
    
      final oneDayBefore = eventTime.subtract(const Duration(days: 1));
      final threeHoursBefore = eventTime.subtract(const Duration(hours: 3));
      final thirtyMinsBefore = eventTime.subtract(const Duration(minutes: 30));
      
      final now = DateTime.now();
      
      // Only schedule reminders that are in the future
      if (oneDayBefore.isAfter(now)) {
        _scheduleLocalNotification(
          id: 'day_$eventId'.hashCode,
          title: 'Event Tomorrow: $eventTitle',
          body: 'Don\'t forget your event "$eventTitle" tomorrow at ${_formatTime(eventTime)}',
          scheduledDate: oneDayBefore,
          payload: '/event-details?id=$eventId',
        );
      }
      
      if (threeHoursBefore.isAfter(now)) {
        _scheduleLocalNotification(
          id: 'hours_$eventId'.hashCode,
          title: 'Event in 3 Hours: $eventTitle',
          body: 'Your event "$eventTitle" starts in 3 hours at ${_formatTime(eventTime)}',
          scheduledDate: threeHoursBefore,
          payload: '/event-details?id=$eventId',
        );
      }
      
      if (thirtyMinsBefore.isAfter(now)) {
        _scheduleLocalNotification(
          id: 'mins_$eventId'.hashCode,
          title: 'Event Soon: $eventTitle',
          body: 'Your event "$eventTitle" starts in 30 minutes!',
          scheduledDate: thirtyMinsBefore,
          payload: '/event-details?id=$eventId',
        );
      }
      
      // Save reminder record to Firestore
      await _firestore.collection('event_reminders').add({
        'eventId': eventId,
        'eventTitle': eventTitle,
        'eventTime': Timestamp.fromDate(eventTime),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('Reminders scheduled for event $eventId');
    } catch (e) {
      print('Error scheduling event reminder: $e');
    }
  }
  
  Future<void> _scheduleLocalNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  String? payload,
}) async {
  final androidDetails = AndroidNotificationDetails(
    'event_reminders',
    'Event Reminders',
    channelDescription: 'Notifications for upcoming events',
    importance: Importance.high,
    priority: Priority.high,
  );

  final iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

await _localNotifications.zonedSchedule(
  id,
  title,
  body,
  tz.TZDateTime.from(scheduledDate, _local ?? tz.local),
  details,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  payload: payload,
  matchDateTimeComponents: null, 
);

}

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
  
  // Method to fetch a user's notifications
  Future<void> getNotifications(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      _notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load notifications: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print('Error loading notifications: $e');
    }
  }
  
  // Method to mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get all unread notifications for the user
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      // Update all documents in a batch
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      // Commit the batch
      await batch.commit();
      
      // Update local state
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark notifications as read: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print('Error marking all notifications as read: $e');
    }
  }
  
  // Method to delete a specific notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('notifications').doc(notificationId).delete();
      
      // Update local state
      _notifications.removeWhere((notification) => notification.id == notificationId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete notification: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print('Error deleting notification: $e');
    }
  }
  
  // Method to delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get all notifications for the user
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      
      // Delete all documents in a batch
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch
      await batch.commit();
      
      // Update local state
      _notifications = [];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete notifications: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print('Error deleting all notifications: $e');
    }
  }
}