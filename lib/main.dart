// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'core/services/event_service.dart';
import 'core/services/booking_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/payment_service.dart';
import 'core/services/user_service.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print("Initializing Firebase...");
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // You should handle this error appropriately in a production app
  }
  
  // Run the app
  runApp(
    MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Auth service
        ChangeNotifierProvider(create: (_) => AuthService()),
        
        // Event service
        ChangeNotifierProvider(create: (_) => EventService()),
        
        // Location service
        ChangeNotifierProvider(create: (_) => LocationService()),
        
        // Notification service
        ChangeNotifierProvider(create: (_) => NotificationService()),
        
        // Payment service
        ChangeNotifierProvider(create: (_) => PaymentService()),
        
        // User service
        ChangeNotifierProvider(create: (_) => UserService()),
        
        // Booking service with dependencies
        ChangeNotifierProxyProvider4<EventService, NotificationService, UserService, PaymentService, BookingService>(
          create: (context) => BookingService(
            Provider.of<EventService>(context, listen: false),
            Provider.of<NotificationService>(context, listen: false),
            Provider.of<UserService>(context, listen: false),
          ),
          update: (context, eventService, notificationService, userService, paymentService, previous) =>
              previous ?? BookingService(
                eventService,
                notificationService,
                userService,
              ),
        ),
      ],
      child: const EventlyApp(),
    ),
  );
}