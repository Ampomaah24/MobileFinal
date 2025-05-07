import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'core/services/connectivity_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/firebase_connection_handler.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print("Initializing Cache Service...");
    // Initialize cache service first
    await CacheService.initialize();
    print("Cache initialized successfully");
    
    print("Initializing Firebase...");
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configure Firestore for offline persistence
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error during initialization: $e");
    
  }
  

  runApp(
    MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Connectivity service (should be initialized early)
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        
        // Firebase Connection Handler
        Provider(
          create: (context) => FirebaseConnectionHandler(
            connectivityService: Provider.of<ConnectivityService>(context, listen: false),
          ),
        ),
        
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
        
        // Sync service (depends on multiple services)
        ChangeNotifierProxyProvider5<ConnectivityService, FirebaseConnectionHandler, AuthService, EventService, BookingService, SyncService>(
          create: (context) => SyncService(
            connectivityService: Provider.of<ConnectivityService>(context, listen: false),
            firebaseHandler: Provider.of<FirebaseConnectionHandler>(context, listen: false),
            authService: Provider.of<AuthService>(context, listen: false),
            eventService: Provider.of<EventService>(context, listen: false),
            bookingService: Provider.of<BookingService>(context, listen: false),
          ),
          update: (context, connectivityService, firebaseHandler, authService, eventService, bookingService, previous) =>
              previous ?? SyncService(
                connectivityService: connectivityService,
                firebaseHandler: firebaseHandler,
                authService: authService,
                eventService: eventService,
                bookingService: bookingService,
              ),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Set build context for EventService
          final eventService = Provider.of<EventService>(context, listen: false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            eventService.setBuildContext(context);
          });
          
          return const EventlyApp();
        },
      ),
    ),
  );
}