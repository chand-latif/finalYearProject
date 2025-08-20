// import 'dart:nativewrappers/_internal/vm_shared/lib/compact_hash.dart';

import 'package:fix_easy/seller_screens/create_service.dart';
import 'package:fix_easy/seller_screens/my_services_screen.dart';
import 'package:fix_easy/theme.dart';
import 'package:flutter/material.dart';
import 'nav_bar_seller.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ServiceProviderHome extends StatefulWidget {
  const ServiceProviderHome({super.key});

  @override
  State<ServiceProviderHome> createState() => _ServiceProviderHomeState();
}

class _ServiceProviderHomeState extends State<ServiceProviderHome> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchUserInfo();
  }

  // Sample data - Replace with actual data from your API
  int requestedBookings = 5;
  int acceptedBookings = 12;
  int cancelledBookings = 2;
  int completedJobs = 28;
  double rating = 4.8;
  int? companyId;

  final List<Map<String, dynamic>> recentBookings = [
    {
      'customerName': 'Ahmad Ali',
      'service': 'Plumbing',
      'time': '10:00 AM',
      'date': 'Today',
      'status': 'pending',
      'amount': 1500.0,
    },
    {
      'customerName': 'Sarah Khan',
      'service': 'Electrical Work',
      'time': '2:00 PM',
      'date': 'Today',
      'status': 'accepted',
      'amount': 2200.0,
    },
    {
      'customerName': 'Usman Sheikh',
      'service': 'AC Repair',
      'time': '11:00 AM',
      'date': 'Tomorrow',
      'status': 'pending',
      'amount': 3000.0,
    },
  ];

  Future<void> fetchUserInfo() async {
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
      if (!mounted) return;
      setState(() {
        companyId = data['data']['companyId'];
      });
    } else {
      print('api call error');
    }
  }

  void _onBookingAction(String action, int index) {
    setState(() {
      if (action == 'accept') {
        recentBookings[index]['status'] = 'accepted';
        acceptedBookings++;
        requestedBookings--;
      } else if (action == 'reject') {
        recentBookings[index]['status'] = 'cancelled';
        cancelledBookings++;
        requestedBookings--;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking ${action}ed successfully'),
        backgroundColor: action == 'accept' ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: Text(
          'Service Provider Home',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            // fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15),

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.cyan, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 10.0,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Provider Dashboard',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Welcome back! 👋',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 15, 0, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 20,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 60, // Added fixed width
                            height: 60, // Added fixed height
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add_circle_outline, size: 28),
                              onPressed: () {
                                // Navigate to create new service
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => CreateServiceScreen(
                                          companyID: companyId,
                                        ),
                                  ),
                                );
                              },
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create New\nService',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            width: 60, // Added fixed width
                            height: 60, // Added fixed height
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.teal,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.build_circle_outlined, size: 28),
                              onPressed: () {
                                // Navigate to my services
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MyServicesScreen(
                                          companyId: companyId,
                                        ),
                                  ),
                                );
                              },
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'My\nServices',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Booking Status Cards
            Text(
              'Booking Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildBookingCard(
                    'Requested Bookings',
                    requestedBookings.toString(),
                    Icons.schedule,
                    Colors.orange,
                    () => _navigateToBookings('requested'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildBookingCard(
                    'Accepted Bookings',
                    acceptedBookings.toString(),
                    Icons.check_circle,
                    Colors.green,
                    () => _navigateToBookings('accepted'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildBookingCard(
                    'Cancelled Bookings',
                    cancelledBookings.toString(),
                    Icons.cancel,
                    Colors.red,
                    () => _navigateToBookings('cancelled'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Completed Jobs',
                    completedJobs.toString(),
                    Icons.task_alt,
                    Colors.teal,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Rating',
                    rating.toString(),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),

            SizedBox(width: 24),

            // Recent Bookings
            Text(
              'Recent Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 16),

            ...recentBookings.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> booking = entry.value;
              return _buildBookingItem(booking, index);
            }).toList(),

            SizedBox(height: 24),

            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: NavBarSeller(),
    );
  }

  Widget _buildBookingCard(
    String title,
    String count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildBookingItem(Map<String, dynamic> booking, int index) {
    Color statusColor =
        booking['status'] == 'pending'
            ? Colors.orange
            : booking['status'] == 'accepted'
            ? Colors.green
            : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.15),
                child: Icon(
                  booking['status'] == 'pending'
                      ? Icons.schedule
                      : booking['status'] == 'accepted'
                      ? Icons.check
                      : Icons.close,
                  color: statusColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['customerName'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${booking['service']} • ${booking['date']} ${booking['time']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                'PKR ${booking['amount'].toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (booking['status'] == 'pending') ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onBookingAction('reject', index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Reject'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onBookingAction('accept', index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToBookings(String type) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navigate to $type bookings')));
  }
}
