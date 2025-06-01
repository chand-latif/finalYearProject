import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'account_type.dart';
import 'sign_up.dart';
import 'forgot_password.dart';
import 'password_confirmation.dart';
import 'customer_home.dart';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/home', // Default route
      routes: {
        '/home': (context) => MyHomePage(title: 'FYP'),
        '/accountType': (context) => ChooseAccountType(),
        '/signUp': (context) => SignUp(),
        '/ForgotPassword': (context) => ForgotPassword(),

        '/PasswordConfirmation': (context) => PasswordConfirmation(),
        '/customerHome': (context) => CustomerHome(),
      },
      title: 'FYP',

      home: const MyHomePage(title: 'FYP'),
    );
  }
}
