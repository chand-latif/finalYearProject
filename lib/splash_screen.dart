import 'dart:convert';

import 'package:fix_easy/login_screen.dart';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_easy/customer_home.dart';
import 'create_company_profile.dart';
import 'seller_home.dart';

class StartupScreen extends StatefulWidget {
  @override
  _StartupScreenState createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      // No token found, navigate to login/home
      Navigator.pushNamed(context, '/home');
      return;
    }

    // Token exists — get user info
    final response = await http.get(
      Uri.parse("https://fixease.pk/api/User/GetUserInformation"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userType = data['data']['userType'];
      final userId = data['data']['userId'];

      if (userType == 'Customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CustomerHome()),
        );
      } else if (userType == 'Seller') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ServiceProviderHome()),
        );
      }
    } else {
      Navigator.pushNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()), // splash/loading UI
    );
  }
}
