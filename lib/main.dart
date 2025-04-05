import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'account_type.dart';
import 'sign_up.dart';
import 'forgot_password.dart';
import 'new_password.dart';
import 'password_confirmation.dart';

void main() {
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
        '/forgotPassword': (context) => forgotPassword(),
        '/newPassword': (context) => newPassword(),
        '/passwordConfirmation': (context) => passwordConfirmation(),
      },
      title: 'FYP',

      home: const MyHomePage(title: 'FYP'),
    );
  }
}
