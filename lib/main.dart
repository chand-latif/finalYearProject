import 'package:fix_easy/profile_page_seller.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'account_type.dart';
import 'forgot_password.dart';
import 'password_confirmation.dart';
import 'customer_home.dart';
import 'dart:io';
import 'seller_home.dart';
import 'splash_screen.dart';
import 'profile_page_Customer.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  // final prefs = await SharedPreferences.getInstance();
  // final token = prefs.getString('auth_token');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // final String initialRoute;

  // const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // initialRoute: initialRoute, // Default route
      routes: {
        '/home': (context) => MyHomePage(title: 'FYP'),
        '/accountType': (context) => ChooseAccountType(),
        // '/signUp': (context) => SignUp(),
        '/ForgotPassword': (context) => ForgotPassword(),
        '/PasswordConfirmation': (context) => PasswordConfirmation(),
        '/customerHome': (context) => CustomerHome(),
        '/sellerHome': (context) => ServiceProviderHome(),
        '/customerProfile': (context) => ProfilePage(),
        '/sellerProfile': (context) => ProfilePageSeller(),
      },
      title: 'FYP',

      // home: const MyHomePage(title: 'FYP'),
      home: StartupScreen(),
    );
  }
}
