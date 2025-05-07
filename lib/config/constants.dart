
class AppConstants {
  // App info
  static const String appName = 'Evently';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Discover and book local events';
  
  // Firebase collections
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String bookingsCollection = 'bookings';
  static const String reviewsCollection = 'reviews';
  static const String categoriesCollection = 'categories';
  
  // Storage paths
  static const String userProfilesPath = 'user_profiles';
  static const String eventImagesPath = 'event_images';
  static const String ticketsPath = 'tickets';
  
  // Default values
  static const int defaultSearchRadius = 25; 
  static const int maxSearchResults = 50;
  static const int defaultCacheTime = 15; 
  
  // API keys 
  static const String googleMapsApiKey = 'AIzaSyCPHQDG-WWZvehWnrpSlQAssPAHPUw2pmM';
  
  
  // Pagination
  static const int eventsPerPage = 10;
  static const int bookingsPerPage = 15;
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Regular expressions
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$',
  );
  
  // Event categories
  static const List<String> eventCategories = [
    'Music',
    'Sports',
    'Arts',
    'Food & Drink',
    'Networking',
    'Tech',
    'Education',
    'Outdoors',
    'Health & Wellness',
    'Entertainment',
    'Nightlife',
    'Family',
    'Business',
    'Charity',
    'Other',
  ];
  
  // Date formats
  static const String dateFormatFull = 'EEEE, MMMM d, yyyy';
  static const String dateFormatShort = 'MMM d, yyyy';
  static const String dateFormatDay = 'E, MMM d';
  static const String timeFormat = 'h:mm a';
  
  // Error messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNoInternet = 'No internet connection. Please check your connection and try again.';
  static const String errorServerTimeout = 'Server is taking too long to respond. Please try again later.';
  static const String errorAuthentication = 'Authentication failed. Please sign in again.';
  static const String errorPermissionDenied = 'You don\'t have permission to perform this action.';
  
  // Success messages
  static const String successProfileUpdate = 'Profile updated successfully';
  static const String successBooking = 'Booking confirmed successfully';
  static const String successEventCreation = 'Event created successfully';
  
  // App routes (consider moving to routes.dart if growing too large)
  static const String routeHome = '/home';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeEventDetails = '/event-details';
  static const String routeBooking = '/booking';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';
  static const String routeSplash = '/splash';
  static const String routeForgotPassword = '/forgot-password';
  
  // Shared preferences keys
  static const String prefUserId = 'user_id';
  static const String prefUserEmail = 'user_email';
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefThemeMode = 'theme_mode';
  static const String prefUserLocation = 'user_location';
  static const String prefSearchRadius = 'search_radius';
  static const String prefNotifications = 'notifications_enabled';
  
  // Notification channels
  static const String notificationChannelEvents = 'event_notifications';
  static const String notificationChannelBookings = 'booking_notifications';
  static const String notificationChannelPromos = 'promotional_notifications';
  
  // Feature flags
  static const bool enablePayments = true;
  static const bool enableReviews = true;
  static const bool enableChat = false;
  static const bool enableLocationSharing = true;
}