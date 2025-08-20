import 'package:fix_easy/theme.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'nav_bar_customer.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';

  String userEmail = '';

  String joiningDate = '';

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  // final DateTime joiningDate = DateTime.now();
  Future<void> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final response = await http.get(
      Uri.parse("https://fixease.pk/api/User/GetUserInformation"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    // final data = jsonDecode(response.body);
    // final userEmail = data['data']['userEmail'];
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userData = data['data'];

      if (mounted) {
        setState(() {
          userName = userData['userName'] ?? '';
          userEmail = userData['userEmail'] ?? '';
          joiningDate = userData['createdDate']?.split('T')[0] ?? '';
        });
      }
    } else {
      print("Failed to fetch user info.");
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Remove JWT token

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home', // Replace with your login route
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Add this line
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            // fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    Text("👤 Name: $userName", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text(
                      "📧 Email: $userEmail",
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "📅 Joining Date: $joiningDate",
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: Icon(Icons.logout),
                label: Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(currentIndex: 3),
    );
  }
}
