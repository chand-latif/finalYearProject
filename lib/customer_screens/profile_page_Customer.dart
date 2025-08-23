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

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Delete Account'),
            content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse('https://fixease.pk/api/User/DeleteUser?UserId=2'),
        headers: {'Authorization': 'Bearer $token', 'Accept': '*/*'},
      );

      if (response.statusCode == 200) {
        await prefs.remove('auth_token');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showLogoutConfirmationDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Logout'),
            content: Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.grey[50],
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      _logout(context);
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    // First confirmation
    final initialConfirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Account'),
            content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (initialConfirm != true) return;

    // Second confirmation
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Final Confirmation'),
            content: Text(
              'This will permanently delete your account and all associated data. Are you absolutely sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes, Delete My Account'),
              ),
            ],
          ),
    );

    if (finalConfirm == true) {
      _deleteAccount(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Text(
                    //   userEmail,
                    //   style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    // ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Account Information Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                      ),
                      title: Text('Member Since'),
                      subtitle: Text(joiningDate),
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                      leading: Icon(Icons.email, color: AppColors.primary),
                      title: Text('Email'),
                      subtitle: Text(userEmail),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Account Actions Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.orange),
                      title: Text('Logout'),
                      subtitle: Text('Sign out of your account'),
                      contentPadding: EdgeInsets.zero,
                      onTap: _showLogoutConfirmationDialog,
                    ),
                    ListTile(
                      leading: Icon(Icons.delete_forever, color: Colors.red),
                      title: Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: Text('Permanently delete your account'),
                      contentPadding: EdgeInsets.zero,
                      onTap: _showDeleteConfirmationDialog,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(currentIndex: 3),
    );
  }
}
