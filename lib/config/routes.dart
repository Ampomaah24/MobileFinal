// lib/config/routes.dart
import 'package:flutter/material.dart';

// Screens
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/home/discover_screen.dart';
import '../presentation/screens/event/event_details_screen.dart';
import '../presentation/screens/event/event_map_screen.dart';
import '../presentation/screens/booking/booking_screen.dart';
import '../presentation/screens/booking/payment_screen.dart';  // Add this import
import '../presentation/screens/booking/booking_confirmation_screen.dart';
import '../presentation/screens/booking/booking_history_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/notifications/notification_screen.dart';
import '../presentation/screens/admin/admin_drawer.dart';
import '../presentation/screens/admin/admin_app_bar.dart';
import '../presentation/screens/admin/stat_card.dart';
import '../presentation/screens/admin/admin_analytics_screen.dart';
import '../presentation/screens/admin/admin_booking_details_screen.dart';
import '../presentation/screens/admin/admin_bookings_screen.dart';
import '../presentation/screens/admin/admin_dashboard_screen.dart';
import '../presentation/screens/admin/admin_events_screen.dart';
import '../presentation/screens/admin/admin_users_screen.dart';
import '../presentation/screens/admin/admin_settings_screen.dart';
import '../presentation/screens/admin/admin_user_details_screen.dart';
import '../presentation/screens/admin/event_form_screen.dart';

class AppRoutes {
  
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String eventDetails = '/event-details';
  static const String eventMap = '/event-map';
  static const String booking = '/booking';
  static const String payment = '/payment';  
  static const String bookingConfirmation = '/booking-confirmation';
  static const String bookingHistory = '/booking-history';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String admin = '/admin';
  static const String adminEvents = '/admin/events';
  static const String adminUsers = '/admin/users';
  static const String adminBookings = '/admin/bookings';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminSettings = '/admin/settings';
  
  
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomeScreen(),
    discover: (context) => const DiscoverScreen(),
    profile: (context) => const ProfileScreen(),
    bookingHistory: (context) => const BookingHistoryScreen(),
    notifications: (context) => const NotificationScreen(),
    admin: (context) => const AdminDashboardScreen(),
    adminEvents: (context) => const AdminEventsScreen(),
    adminUsers: (context) => const AdminUsersScreen(),
    adminBookings: (context) => const AdminBookingsScreen(),
    adminAnalytics: (context) => const AdminAnalyticsScreen(),
    adminSettings: (context) => const AdminSettingsScreen(),
  };
  
 
  static Route<dynamic> generateRoute(RouteSettings settings) {
    print("Generating route for: ${settings.name}");
    
    switch (settings.name) {
      case splash:
        return _buildPageTransition(const SplashScreen(), settings);
      
      case login:
        return _buildPageTransition(const LoginScreen(), settings);
      
      case register:
        return _buildPageTransition(const RegisterScreen(), settings);
      
      case forgotPassword:
        return _buildPageTransition(const ForgotPasswordScreen(), settings);
      
      case home:
        return _buildPageTransition(const HomeScreen(), settings);
      
      case discover:
        return _buildPageTransition(const DiscoverScreen(), settings);
      
      case notifications:
        return _buildPageTransition(const NotificationScreen(), settings);
      
      case eventDetails:
        final eventId = settings.arguments as String?;
        return _buildPageTransition(
          EventDetailsScreen(eventId: eventId),
          settings,
        );
      
      case eventMap:
        final eventId = settings.arguments as String?;
        return _buildPageTransition(
          EventMapScreen(eventId: eventId ?? ''),
          settings,
          fullscreenDialog: true,
        );
      
      case booking:
        final eventId = settings.arguments as String?;
        return _buildPageTransition(
          BookingScreen(eventId: eventId ?? ''),
          settings,
        );
      
      case payment:  // Add payment case
        return _buildPageTransition(
          const PaymentScreen(),
          settings,
        );
      
      case bookingConfirmation:
        final bookingId = settings.arguments as String?;
        return _buildPageTransition(
          BookingConfirmationScreen(bookingId: bookingId ?? ''),
          settings,
          fullscreenDialog: true,
        );
      
      case bookingHistory:
        return _buildPageTransition(const BookingHistoryScreen(), settings);
      
      case profile:
        return _buildPageTransition(const ProfileScreen(), settings);
      
      default:
        // 404 page
        print("Route not found: ${settings.name}");
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(
              child: Text('The requested page does not exist.'),
            ),
          ),
        );
    }
  }
  
  // Page transitioning
  static Route<dynamic> _buildPageTransition(
    Widget page, 
    RouteSettings settings, 
    {bool fullscreenDialog = false}
  ) {
    return MaterialPageRoute(
      builder: (context) => page,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }
  
  // Navigation helper methods
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      home, 
      (route) => false,
    );
  }
  
  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      login, 
      (route) => false,
    );
  }
  
  static Future<void> navigateToEventDetails(BuildContext context, String eventId) {
    return Navigator.pushNamed(
      context,
      eventDetails,
      arguments: eventId,
    ).then((_) {});
  }
  
  static Future<void> navigateToBooking(BuildContext context, String eventId) {
    return Navigator.pushNamed(
      context,
      booking,
      arguments: eventId,
    ).then((_) {});
  }
  
  static Future<void> navigateToPayment(BuildContext context, Map<String, dynamic> paymentData) {
    return Navigator.pushNamed(
      context,
      payment,
      arguments: paymentData,
    ).then((_) {});
  }
  
  static Future<void> navigateToBookingConfirmation(BuildContext context, String bookingId) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      bookingConfirmation,
      (route) => route.settings.name == home,
      arguments: bookingId,
    ).then((_) {});
  }
}