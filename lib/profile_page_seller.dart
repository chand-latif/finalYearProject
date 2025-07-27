import 'package:fix_easy/theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'update_company_profile.dart';

enum AvailabilityStatus { Available, Busy, Away }

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
  String companyName = '';
  String companyPhoneNumber = '';
  String companyWhatsappNumber = '';
  String companyProfileURL = '';
  String companyLogoURL = '';
  final Map<String, TimeOfDay?> _workingHoursStart = {};
  final Map<String, TimeOfDay?> _workingHoursEnd = {};
  final Map<String, bool> _dayOff = {
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
    "Thursday": false,
    "Friday": false,
    "Saturday": false,
    "Sunday": false,
  };
  AvailabilityStatus? selectedStatus;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

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
      fetchWorkingHours();
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
        companyName = companyData['companyName'] ?? '';
        companyPhoneNumber =
            companyData['phoneNumber'] ??
            ''; // Fixed typo 'phoneNumer' to 'phoneNumber'
        companyWhatsappNumber = companyData['whatsappNumber'] ?? '';
        companyProfileURL = companyData['profilePicture'] ?? '';
        companyLogoURL = companyData['companyLogo'] ?? '';
      });
    }
  }

  Future<void> fetchWorkingHours() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/CompanyProfile/getWorkingHoursById?CompanyId=$companyId',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _dayOff['Monday'] = data['isOffMonday'] ?? false;
          _dayOff['Tuesday'] =
              data['isOffTuesday'] ??
              false; // Fixed typo 'isOfTuesday' to 'isOffTuesday'
          _dayOff['Wednesday'] =
              data['isOffWednesday'] ??
              false; // Fixed typo 'isOfWednesday' to 'isOffWednesday'
          _dayOff['Thursday'] =
              data['isOffThursday'] ??
              false; // Fixed typo 'isOfThursday' to 'isOffThursday'
          _dayOff['Friday'] =
              data['isOffFriday'] ??
              false; // Fixed typo 'isOfFriday' to 'isOffFriday'
          _dayOff['Saturday'] =
              data['isOffSaturday'] ??
              false; // Fixed typo 'isOfSaturday' to 'isOffSaturday'
          _dayOff['Sunday'] =
              data['isOffSunday'] ??
              false; // Fixed typo 'isOfSunday' to 'isOffSunday'

          _workingHoursStart['Monday'] = _parseTime(data['mondayStartTime']);
          _workingHoursEnd['Monday'] = _parseTime(data['mondayEndTime']);
          _workingHoursStart['Tuesday'] = _parseTime(data['tuesdayStartTime']);
          _workingHoursEnd['Tuesday'] = _parseTime(data['tuesdayEndTime']);
          _workingHoursStart['Wednesday'] = _parseTime(
            data['wednesdayStartTime'],
          );
          _workingHoursEnd['Wednesday'] = _parseTime(data['wednesdayEndTime']);
          _workingHoursStart['Thursday'] = _parseTime(
            data['thursdayStartTime'],
          );
          _workingHoursEnd['Thursday'] = _parseTime(data['thursdayEndTime']);
          _workingHoursStart['Friday'] = _parseTime(data['fridayStartTime']);
          _workingHoursEnd['Friday'] = _parseTime(data['fridayEndTime']);
          _workingHoursStart['Saturday'] = _parseTime(
            data['saturdayStartTime'],
          );
          _workingHoursEnd['Saturday'] = _parseTime(data['saturdayEndTime']);
          _workingHoursStart['Sunday'] = _parseTime(data['sundayStartTime']);
          _workingHoursEnd['Sunday'] = _parseTime(data['sundayEndTime']);
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load working hours')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return null;
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
    // Handle toggle functionality here
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
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // User Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "👤 Name: $userName",
                        style: TextStyle(fontSize: 18),
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
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Company Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Availability Status: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          DropdownButton<AvailabilityStatus>(
                            value: selectedStatus,
                            items:
                                AvailabilityStatus.values.map((
                                  AvailabilityStatus status,
                                ) {
                                  return DropdownMenuItem<AvailabilityStatus>(
                                    value: status,
                                    child: Text(status.name),
                                  );
                                }).toList(),
                            onChanged: (AvailabilityStatus? newValue) {
                              setState(() {
                                selectedStatus = newValue;
                              });
                            },
                          ),

                          // DropdownButton<AvailabilityStatus>(
                          //   value: selectedStatus,
                          //   items: [

                          // ], onChanged: onChanged)
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (companyProfileURL.isNotEmpty)
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      'https://fixease.pk/$companyProfileURL',
                                      height: 90,
                                      width: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                Text('Profile Photo'),
                              ],
                            ),

                          if (companyLogoURL.isNotEmpty)
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      'https://fixease.pk/$companyLogoURL',
                                      height: 90,
                                      width: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                Text('Company Logo'),
                              ],
                            ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "🏢 Company: $companyName",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        "📍 Address: $companyAddress",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "📞 Phone: $companyPhoneNumber",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "💬 WhatsApp: $companyWhatsappNumber",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Working Hours Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🕒 Working Hours",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Table(
                        border: TableBorder.all(color: Colors.grey),
                        columnWidths: {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                        },
                        children:
                            _dayOff.keys.map((day) {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      day,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _formatTimeOfDay(_workingHoursStart[day]),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _formatTimeOfDay(_workingHoursEnd[day]),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => navigate(),
                  icon: Icon(Icons.edit),
                  label: Text("Update Company Profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              SizedBox(height: 20),
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
      ),
    );
  }
}
