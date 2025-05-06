// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/admin/admin_dashboard_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/notifications/notification_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/booking/booking_confirmation_screen.dart';
import 'presentation/screens/booking/booking_history_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/home/discover_screen.dart';
import 'presentation/screens/event/event_details_screen.dart';
import 'presentation/screens/booking/booking_screen.dart';
import 'presentation/screens/booking/payment_screen.dart';  // Add this import
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/services/auth_service.dart';
import 'core/services/event_service.dart';
import 'core/services/booking_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/payment_service.dart';
import 'core/services/user_service.dart';
import 'core/providers/theme_provider.dart';

class EventlyApp extends StatelessWidget {
  const EventlyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access the theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Access the notification service
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    return MaterialApp(
      title: 'Evently',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode, // Use theme mode from provider
      initialRoute: '/', // Start with splash screen
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/discover': (context) => const DiscoverScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/booking-history': (context) => const BookingHistoryScreen(),
        // Other routes from AppRoutes
        ...AppRoutes.routes,
      },
      // Handle routes that need parameters
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/event-details':
            final eventId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (context) => EventDetailsScreen(eventId: eventId),
            );
          case '/booking':
            final eventId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (context) => BookingScreen(eventId: eventId),
            );
          case '/payment':  // Add this case
            final args = settings.arguments;
            return MaterialPageRoute(
              builder: (context) => PaymentScreen(),
            );
          case '/booking-confirmation':
            final bookingId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (context) => BookingConfirmationScreen(bookingId: bookingId),
            );
          default:
            // Use AppRoutes.generateRoute for other dynamic routes
            return AppRoutes.generateRoute(settings);
        }
      },
      navigatorKey: notificationService.navigatorKey,
    );
  }
}