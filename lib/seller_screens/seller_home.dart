import 'package:fix_easy/seller_screens/create_service.dart';
import 'package:fix_easy/seller_screens/my_services_screen.dart';
import 'package:fix_easy/theme.dart';
import 'package:flutter/material.dart';
import 'nav_bar_seller.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'booking_request_details_screen.dart';
import 'package:shimmer/shimmer.dart';

class ServiceProviderHome extends StatefulWidget {
  const ServiceProviderHome({super.key});

  @override
  State<ServiceProviderHome> createState() => _ServiceProviderHomeState();
}

class _ServiceProviderHomeState extends State<ServiceProviderHome> {
  // Stats variables from API
  int pendingBookings = 0;
  int acceptedBookings = 0;
  int inProgressBookings = 0;
  int finishedBookings = 0;
  double averageRating = 0.0;
  int totalRatings = 0;
  int? companyId;
  bool isLoading = true;
  List<Map<String, dynamic>> recentBookings = [];

  // Company info
  String? companyName;
  String? companyLogo;
  bool isLoadingCompanyInfo = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    fetchStats();
    fetchRecentBookings();
  }

  Future<void> fetchStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/BookingService/getServiceProviderStats',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded'] && data['data'] != null) {
          setState(() {
            pendingBookings = data['data']['pending'] ?? 0;
            acceptedBookings = data['data']['accepted'] ?? 0;
            inProgressBookings = data['data']['inProgress'] ?? 0;
            finishedBookings = data['data']['finished'] ?? 0;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching stats: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> fetchRecentBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('https://fixease.pk/api/BookingService/GetAllBookings'),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            // Take only the first 3 bookings
            recentBookings = List<Map<String, dynamic>>.from(
              (data['data'] as List).take(3),
            );
          });
        }
      }
    } catch (e) {
      print('Error fetching recent bookings: $e');
    }
  }

  Future<void> updateBookingStatus(int bookingId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.put(
        Uri.parse(
          'https://fixease.pk/api/BookingService/SetBookingStatus?BookingId=$bookingId&Status=$status',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Status updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh data
          fetchStats();
          fetchRecentBookings();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
        // After getting companyId, fetch company profile
        fetchCompanyProfile();
      });

      // Then fetch company services to calculate rating
      final servicesResponse = await http.get(
        Uri.parse(
          'https://fixease.pk/api/CompanyServices/getListOfPublishedCompanyServices?CompanyId=$companyId',
        ),
      );

      if (servicesResponse.statusCode == 200) {
        final servicesData = json.decode(servicesResponse.body);
        final services = List<Map<String, dynamic>>.from(servicesData['data']);

        int totalRatings = 0;
        double totalRatingSum = 0;

        for (var service in services) {
          final serviceRating = service['serviceRating'];
          if (serviceRating != null) {
            totalRatings += serviceRating['totalRatings'] as int;
            totalRatingSum +=
                (serviceRating['averageRating'] as num) *
                serviceRating['totalRatings'];
          }
        }

        if (mounted) {
          setState(() {
            this.totalRatings = totalRatings;
            this.averageRating =
                totalRatings > 0 ? totalRatingSum / totalRatings : 0.0;
          });
        }
      }
    } else {
      print('api call error');
    }
  }

  // Add this new method
  Future<void> fetchCompanyProfile() async {
    try {
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
            companyName = companyData['companyName'];
            companyLogo = companyData['companyLogo'];
            isLoadingCompanyInfo = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching company profile: $e');
      if (mounted) {
        setState(() {
          isLoadingCompanyInfo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        centerTitle: true, // Add this
        title: Image.asset(
          'assets/FixEasy.png',
          height: 100, // Adjust height as needed
          fit: BoxFit.contain,
        ),
        actions: [
          // Profile icon that navigates to profile
          IconButton(
            icon: Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/sellerProfile'),
          ),
        ],
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
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyName ?? 'Loading...',
                              style: TextStyle(
                                fontSize: 22,
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
                      ),
                      if (!isLoadingCompanyInfo)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            image:
                                companyLogo != null
                                    ? DecorationImage(
                                      image: NetworkImage(
                                        'https://fixease.pk$companyLogo',
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              companyLogo == null
                                  ? Icon(
                                    Icons.business,
                                    color: Colors.grey,
                                    size: 30,
                                  )
                                  : null,
                        )
                      else
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

            // Updated booking overview section
            if (isLoading)
              _buildBookingOverviewShimmer()
            else
              _buildBookingOverview(),

            SizedBox(height: 24),

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

            _buildRecentBookingsList(),

            SizedBox(height: 24),
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

  Widget _buildBookingOverview() {
    return Container(
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5, // Changed from 1.5 to 1.3 to make cards taller
        physics: NeverScrollableScrollPhysics(),
        children: [
          _buildBookingOverviewCard(
            'Pending Requests',
            pendingBookings.toString(),
            Icons.schedule,
            Colors.orange,
            () => Navigator.pushNamed(context, '/sellerBookingRequests'),
          ),
          _buildBookingOverviewCard(
            'In Progress',
            inProgressBookings.toString(),
            Icons.engineering,
            Colors.blue,
            () => Navigator.pushNamed(context, '/sellerBookingRequests'),
          ),
          _buildBookingOverviewCard(
            'Completed Jobs',
            finishedBookings.toString(),
            Icons.check_circle_outline,
            Colors.green,
            () => Navigator.pushNamed(context, '/sellerBookingRequests'),
          ),
          _buildRatingCard(
            'Rating',
            '$totalRatings Reviews',
            averageRating.toStringAsFixed(1),
            Icons.star,
            Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingOverviewCard(
    String title,
    String count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(
    String title,
    String subtitle,
    String rating,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                rating,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingOverviewShimmer() {
    return Row(
      children:
          List.generate(
            3,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: index == 1 ? 12 : 0),
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
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(width: 40, height: 24, color: Colors.white),
                      SizedBox(height: 4),
                      Container(width: 60, height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ).toList(),
    );
  }

  Widget _buildRecentBookingsList() {
    if (recentBookings.isEmpty) {
      return Center(child: Text('No recent bookings'));
    }

    return Column(
      children:
          recentBookings.map((booking) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BookingRequestDetailsScreen(
                          booking: booking,
                          onStatusChanged: () {
                            fetchStats();
                            fetchRecentBookings();
                          },
                        ),
                  ),
                );
              },
              child: Card(
                margin: EdgeInsets.only(bottom: 12),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            booking['customerName'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        booking['description'] ?? 'No description',
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Proposed: ${formatDateTime(booking['customerProposedTime'])}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            booking['category'] ?? 'N/A',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      // Price display section
                      if (booking['status'] == 'InProgress' ||
                          booking['status'] == 'Completed' ||
                          booking['status'] == 'finished') ...[
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.payment, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Agreed Price: ',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rs. ${booking['finalPrice']?.toString() ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 12),
                      // Status indicator - similar to booking requests
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            booking['status'],
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getStatusIcon(booking['status']),
                              color: _getStatusColor(booking['status']),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              _getStatusText(booking['status']),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _getStatusColor(booking['status']),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending Approval';
      case 'accept':
        return 'Waiting for Customer Confirmation';
      case 'inprogress':
        return 'Work in Progress';
      case 'completed':
        return 'Waiting for Customer Approval';
      case 'finished':
        return 'Service Completed';
      case 'reject':
        return 'Booking Rejected';
      default:
        return status?.toUpperCase() ?? 'N/A';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'inprogress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'reject':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'inprogress':
        return Icons.engineering;
      case 'completed':
        return Icons.check_circle;
      case 'reject':
        return Icons.cancel;
      default:
        return Icons.circle;
    }
  }

  String formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      DateTime dt;
      if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        return dateTime.toString();
      }
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTime.toString();
    }
  }
}
