import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_easy/customer_home.dart';
import 'seller_home.dart';
import 'theme.dart';
import 'dart:async';

class StartupScreen extends StatefulWidget {
  @override
  _StartupScreenState createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    Future.delayed(Duration.zero, () async {
      await _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // ✅ This line fixes the Ticker issue
    super.dispose();
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
      // final userId = data['data']['userId'];

      if (userType == 'Customer') {
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (context) => CustomerHome()),
        //   (Route<dynamic> route) => false,
        // );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CustomerHome()),
        );
      } else if (userType == 'Seller') {
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (context) => ServiceProviderHome()),
        //   (Route<dynamic> route) => false,
        // );

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
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Image.asset(
                'assets/logo.png', // Ensure you have a logo in assets folder
                width: 120,
              ),
              SizedBox(height: 20),
              // App Tagline
              Text(
                'Your Home Service Partner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
