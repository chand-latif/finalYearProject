import 'package:fix_easy/theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'update_company_profile.dart';
import 'nav_bar_seller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  String currentAvailabilityStatus = 'Available';
  bool isUpdatingStatus = false;

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

      if (mounted) {
        setState(() {
          userName = userData['userName'] ?? '';
          userEmail = userData['userEmail'] ?? '';
          joiningDate = userData['createdDate']?.split('T')[0] ?? '';
          companyId = userData['companyId'];
          userId = userData['userId'];
        });
        fetchCompanyInfo();
        fetchWorkingHours();
      }
    } else {
      print("Failed to fetch user info.");
    }
  }

  Future<void> updateAvailabilityStatus(String status) async {
    if (!mounted) return;

    setState(() {
      isUpdatingStatus = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
          'https://fixease.pk/api/CompanyProfile/SetAvailabilityStatus?Status=$status&CompanyId=$companyId',
        ),
        headers: {'accept': '*/*'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          currentAvailabilityStatus = status;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated successfully')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingStatus = false;
        });
      }
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

      if (mounted) {
        setState(() {
          companyAddress = companyData['companyAddress'] ?? '';
          companyName = companyData['companyName'] ?? '';
          companyPhoneNumber = companyData['phoneNumber'] ?? '';
          companyWhatsappNumber = companyData['whatsappNumber'] ?? '';
          companyProfileURL = companyData['profilePicture'] ?? '';
          companyLogoURL = companyData['companyLogo'] ?? '';
          currentAvailabilityStatus = companyData['status'] ?? 'Available';
        });
      }
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
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load working hours')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
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
    ).then((value) {
      // Refresh data when returning from update screen
      if (value == true) {
        fetchCompanyInfo();
        fetchWorkingHours();
      }
    });
  }

  Future<void> deleteUserAndCompany() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.delete(
        Uri.parse('https://fixease.pk/api/User/DeleteUser?UserId=$userId'),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        await prefs.remove('auth_token'); // Clear token
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> deleteCompanyProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.delete(
        Uri.parse(
          'https://fixease.pk/api/CompanyProfile/DeleteCompanyProfile?CompanyId=$companyId',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        await prefs.remove('auth_token'); // Clear token
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        throw Exception('Failed to delete company profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> showDeleteConfirmationDialog(String type) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text(
            type == 'both'
                ? 'Are you sure you want to delete your user account and company profile? This action cannot be undone.'
                : 'Are you sure you want to delete your company profile? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (type == 'both') {
                  deleteUserAndCompany();
                } else {
                  deleteCompanyProfile();
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'deleteAll') {
                    showDeleteConfirmationDialog('both');
                  } else if (value == 'deleteCompany') {
                    showDeleteConfirmationDialog('company');
                  }
                },
                itemBuilder:
                    (BuildContext context) => [
                      PopupMenuItem(
                        value: 'deleteAll',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          title: Text('Delete Account & Company'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'deleteCompany',
                        child: ListTile(
                          leading: Icon(Icons.business, color: Colors.red),
                          title: Text('Delete Company Only'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Colors.cyan, Colors.teal],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          companyProfileURL.isNotEmpty
                              ? NetworkImage(
                                'https://fixease.pk/$companyProfileURL',
                              )
                              : null,
                      child:
                          companyProfileURL.isEmpty
                              ? Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                    ),
                    SizedBox(height: 10),
                    Text(
                      userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    color: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                currentAvailabilityStatus,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      currentAvailabilityStatus == 'Available'
                                          ? Colors.green
                                          : currentAvailabilityStatus == 'Busy'
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          isUpdatingStatus
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : DropdownButton<String>(
                                value: currentAvailabilityStatus,
                                items:
                                    ['Available', 'Busy', 'Away'].map((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    updateAvailabilityStatus(newValue);
                                  }
                                },
                              ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Company Info Card
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(height: 24),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                Icons.business,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text('Company Name'),
                            subtitle: Text(companyName),
                            contentPadding: EdgeInsets.zero,
                          ),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text('Address'),
                            subtitle: Text(companyAddress),
                            contentPadding: EdgeInsets.zero,
                          ),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                Icons.phone,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text('Phone'),
                            subtitle: Text(companyPhoneNumber),
                            contentPadding: EdgeInsets.zero,
                          ),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: Icon(
                                FontAwesomeIcons.whatsapp,
                                color: Colors.green,
                                size: 30,
                              ),
                            ),
                            title: Text('WhatsApp'),
                            subtitle: Text(companyWhatsappNumber),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Working Hours Card
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Working Hours',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(height: 24),
                          ..._dayOff.keys.map((day) {
                            final isOff = _dayOff[day] ?? false;
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      day,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isOff
                                                ? Colors.grey
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (!isOff) ...[
                                    Expanded(
                                      child: Text(
                                        '${_formatTimeOfDay(_workingHoursStart[day])} - ${_formatTimeOfDay(_workingHoursEnd[day])}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ] else
                                    Expanded(
                                      child: Text(
                                        'Off Day',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Action Buttons
                  ElevatedButton.icon(
                    onPressed: () => navigate(),
                    icon: Icon(Icons.edit),
                    label: Text("Update Company Profile"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: Icon(Icons.logout),
                    label: Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 0),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBarSeller(currentIndex: 3),
    );
  }
}
