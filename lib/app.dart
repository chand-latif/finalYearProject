import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';

// Import existing screens (these will work with the new architecture)
import 'splash_screen.dart';
import 'auth/login_screen.dart';
import 'auth/account_type.dart';
import 'auth/forgot_password.dart';
import 'auth/password_confirmation.dart';
import 'customer_screens/customer_home.dart';
import 'customer_screens/profile_page_Customer.dart';
import 'customer_screens/my_bookings_screen.dart';
import 'customer_screens/all_services_screen.dart';
import 'seller_screens/seller_home.dart';
import 'seller_screens/profile_page_seller.dart';
import 'seller_screens/booking_requests_screen.dart';

/// Main app widget with theme and routing configuration.
class FixEasyApp extends StatelessWidget {
  const FixEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixEasy',
      debugShowCheckedModeBanner: false,
      
      // Apply the app theme
      theme: AppTheme.lightTheme,

      // Define app routes
      routes: {
        '/home': (context) => const MyHomePage(title: 'FYP'),
        '/accountType': (context) => const ChooseAccountType(),
        '/ForgotPassword': (context) => const ForgotPassword(),
        '/PasswordConfirmation': (context) => const PasswordConfirmation(),
        '/customerHome': (context) => const CustomerHome(),
        '/sellerHome': (context) => const ServiceProviderHome(),
        '/customerProfile': (context) => const ProfilePage(),
        '/sellerProfile': (context) => const ProfilePageSeller(),
        '/myBookings': (context) => const MyBookingsScreen(),
        '/sellerBookingRequests': (context) => const BookingRequestsScreen(),
        '/allServices': (context) => const AllServicesScreen(),
      },

      // Start with splash screen
      home: const StartupScreen(),
    );
  }
}
