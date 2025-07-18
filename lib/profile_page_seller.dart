import 'package:fix_easy/theme.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'update_company_profile.dart';

class ProfilePageSeller extends StatefulWidget {
  ProfilePageSeller({super.key});

  @override
  State<ProfilePageSeller> createState() => _ProfilePageSellerState();
}

class _ProfilePageSellerState extends State<ProfilePageSeller> {
  String userName = '';

  String userEmail = '';

  String joiningDate = '';
  int companyId = 0;
  int userId = 0;
  bool switchValue = false;

  String companyAddress = '';
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

      setState(() {
        userName = userData['userName'] ?? '';
        userEmail = userData['userEmail'] ?? '';
        joiningDate = userData['createdDate']?.split('T')[0] ?? '';
        companyId = userData['companyId'];
        userId = userData['userId'];
      });
      fetchCompanyInfo();
    } else {
      print("Failed to fetch user info.");
    }
  }

  Future<void> fetchCompanyInfo() async {
    final response = await http.get(
      Uri.parse(
        "https://fixease.pk/api/CompanyProfile/ListCompanyProfile?CompanyId=$companyId",
      ),
      headers: {'accept': '*/*'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final companyData = data['data'];

      setState(() {
        companyAddress = companyData['companyAddress'] ?? '';
      });
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

  void toggleSwitch(bool value) {
    setState(() {
      switchValue = value;
    });
  }

  void navigate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => UpdateCompanyProfileScreen(
              userID: userId,
              companyID: companyId,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "👤 Name: $userName",
                          style: TextStyle(fontSize: 18),
                        ),
                        Switch(
                          value: switchValue,
                          activeColor: AppColors.primary,
                          onChanged: toggleSwitch,
                        ),
                      ],
                    ),
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
                    Text(
                      "📅 Joining Date: $companyAddress",
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            Card(child: BackButton(onPressed: navigate)),
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
    );
  }
}
