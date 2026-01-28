/// App-wide constants for the FixEasy app.

class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// App name
  static const String appName = 'FixEasy';

  /// App tagline
  static const String appTagline = 'Your Home Service Partner';

  /// Shared preferences keys
  static const String authTokenKey = 'auth_token';
  static const String userTypeKey = 'user_type';
  static const String userIdKey = 'user_id';
  static const String companyIdKey = 'company_id';

  /// User types
  static const String customerType = 'Customer';
  static const String sellerType = 'Seller';

  /// Booking statuses
  static const String statusPending = 'Pending';
  static const String statusAccepted = 'Accepted';
  static const String statusInProgress = 'InProgress';
  static const String statusCompleted = 'Completed';
  static const String statusCancelled = 'Cancelled';
  static const String statusRejected = 'Rejected';

  /// Service categories (matching backend IDs)
  static const Map<String, int> categoryIds = {
    'Plumber': 9,
    'Painter': 10,
    'Electrician': 11,
    'AC Repair': 12,
    'Cleaner': 13,
    'Carpenter': 14,
  };

  /// Animation durations
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration snackBarDuration = Duration(seconds: 3);
}
