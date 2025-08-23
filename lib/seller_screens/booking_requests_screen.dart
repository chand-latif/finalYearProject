import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_easy/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'nav_bar_seller.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fix_easy/widgets/image_viewer.dart';
import 'booking_request_details_screen.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({Key? key}) : super(key: key);

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> bookings = [];
  bool isUpdatingStatus = false;
  int? updatingBookingId;
  String? currentAction; // Track which action is being performed
  String? selectedStatus; // Add this state variable

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings([String? status]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception('No auth token found');

      final url = Uri.parse(
        'https://fixease.pk/api/BookingService/GetAllBookings${status != null ? '?status=$status' : ''}',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            bookings = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        } else {
          setState(() {
            bookings = [];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => isLoading = false);
      }
    }
  }

  String formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> updateBookingStatus(int bookingId, String status) async {
    setState(() {
      isUpdatingStatus = true;
      updatingBookingId = bookingId;
      currentAction = status;
    });

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
          fetchBookings(); // Refresh the list
        } else {
          throw Exception(data['message'] ?? 'Failed to update status');
        }
      } else {
        throw Exception('Failed to update booking status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isUpdatingStatus = false;
        updatingBookingId = null;
        currentAction = null;
      });
    }
  }

  Future<void> markWorkCompleted(int bookingId) async {
    setState(() {
      isUpdatingStatus = true;
      updatingBookingId = bookingId;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception('No auth token found');

      final response = await http.put(
        Uri.parse(
          'https://fixease.pk/api/BookingService/MarkWorkCompleted?BookingId=$bookingId',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Work marked as completed'),
              backgroundColor: Colors.green,
            ),
          );
          fetchBookings();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to mark work as completed',
          );
        }
      } else {
        throw Exception('Failed to update booking status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isUpdatingStatus = false;
        updatingBookingId = null;
      });
    }
  }

  Widget _buildBookingShimmer() {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 200, color: Colors.white),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 150, height: 24, color: Colors.white),
                      Container(width: 80, height: 24, color: Colors.white),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(height: 16, color: Colors.white),
                  SizedBox(height: 8),
                  Container(height: 16, width: 200, color: Colors.white),
                  SizedBox(height: 8),
                  Container(height: 16, width: 150, color: Colors.white),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 40, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(height: 40, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(Map<String, dynamic> booking) {
    if (booking['status'] == 'Pending' ||
        booking['status'] == 'InProgress' ||
        booking['status'] == 'Completed') {
      return Container(); // Return empty container for actionable statuses
    }

    String statusText = booking['status'] ?? 'Unknown';
    Color statusColor;

    switch (statusText.toLowerCase()) {
      case 'accept':
        statusColor = Colors.orange;
        statusText = 'Waiting for Customer Confirmation';
        break;
      case 'finished':
        statusColor = Colors.green;
        statusText = 'Service Completed';
        break;
      case 'reject':
        statusColor = Colors.red;
        statusText = 'Booking Rejected';
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16),
      margin: EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        statusText,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Booking Requests'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Add Status Filter Dropdown
          Padding(
            padding: EdgeInsets.fromLTRB(15, 15, 15, 7),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                hint: Text('Filter by status'),
                underline: SizedBox(),
                items: [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'InProgress',
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem(value: 'Accept', child: Text('Accepted')),
                  DropdownMenuItem(value: 'Reject', child: Text('Rejected')),
                ],
                onChanged: (value) {
                  setState(() => selectedStatus = value);
                  fetchBookings(value);
                },
              ),
            ),
          ),

          // Existing Bookings List
          Expanded(
            child:
                isLoading
                    ? ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: 3,
                      itemBuilder: (context, index) => _buildBookingShimmer(),
                    )
                    : bookings.isEmpty
                    ? Center(child: Text('No bookings found'))
                    : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: bookings.length,

                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BookingRequestDetailsScreen(
                                      booking: booking,
                                      onStatusChanged: fetchBookings,
                                    ),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.only(bottom: 16),
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (booking['issuedImages']?.isNotEmpty ??
                                    false)
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    child:
                                        booking['issuedImages'].length == 1
                                            ? GestureDetector(
                                              onTap:
                                                  () => ImageViewer.showFullScreenImage(
                                                    context,
                                                    'https://fixease.pk${booking['issuedImages'][0]}',
                                                  ),
                                              child: Image.network(
                                                'https://fixease.pk${booking['issuedImages'][0]}',
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder:
                                                    (_, __, ___) => Container(
                                                      width: double.infinity,
                                                      color: Colors.grey[300],
                                                      child: Icon(Icons.error),
                                                    ),
                                              ),
                                            )
                                            : ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  booking['issuedImages']
                                                      .length,
                                              itemBuilder: (
                                                context,
                                                imageIndex,
                                              ) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    right: 8,
                                                  ),
                                                  child: GestureDetector(
                                                    onTap:
                                                        () => ImageViewer.showFullScreenImage(
                                                          context,
                                                          'https://fixease.pk${booking['issuedImages'][imageIndex]}',
                                                        ),
                                                    child: Image.network(
                                                      'https://fixease.pk${booking['issuedImages'][imageIndex]}',
                                                      fit: BoxFit.cover,
                                                      width: 200,
                                                      errorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => Container(
                                                            width: 200,
                                                            color:
                                                                Colors
                                                                    .grey[300],
                                                            child: Icon(
                                                              Icons.error,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                  ),
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            booking['customerName'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          // Container(
                                          //   padding: EdgeInsets.symmetric(
                                          //     horizontal: 8,
                                          //     vertical: 4,
                                          //   ),
                                          //   decoration: BoxDecoration(
                                          //     color: AppColors.primary
                                          //         .withOpacity(0.1),
                                          //     borderRadius:
                                          //         BorderRadius.circular(4),
                                          //   ),
                                          //   child: Text(
                                          //     booking['status'] == 'Accept'
                                          //         ? 'Authorizing'
                                          //         : (booking['status'] ??
                                          //             'Pending'),
                                          //     style: TextStyle(
                                          //       color: AppColors.primary,
                                          //       fontWeight: FontWeight.bold,
                                          //     ),
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        booking['description'] ??
                                            'No description',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 20,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              booking['customerLocation'] ??
                                                  'N/A',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 20,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Proposed: ${formatDateTime(booking['customerProposedTime'])}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.category,
                                            size: 20,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            booking['category'] ?? 'N/A',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (booking['status'] == 'Pending')
                                        Padding(
                                          padding: EdgeInsets.only(top: 16),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed:
                                                      isUpdatingStatus &&
                                                              updatingBookingId ==
                                                                  booking['bookingId']
                                                          ? null
                                                          : () => updateBookingStatus(
                                                            booking['bookingId'],
                                                            'Reject',
                                                          ),
                                                  child:
                                                      isUpdatingStatus &&
                                                              updatingBookingId ==
                                                                  booking['bookingId'] &&
                                                              currentAction ==
                                                                  'Reject'
                                                          ? SizedBox(
                                                            height: 20,
                                                            width: 20,
                                                            child: CircularProgressIndicator(
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    Colors
                                                                        .white,
                                                                  ),
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                          : Text('Reject'),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed:
                                                      isUpdatingStatus &&
                                                              updatingBookingId ==
                                                                  booking['bookingId']
                                                          ? null
                                                          : () => updateBookingStatus(
                                                            booking['bookingId'],
                                                            'Accept',
                                                          ),
                                                  child:
                                                      isUpdatingStatus &&
                                                              updatingBookingId ==
                                                                  booking['bookingId'] &&
                                                              currentAction ==
                                                                  'Accept'
                                                          ? SizedBox(
                                                            height: 20,
                                                            width: 20,
                                                            child: CircularProgressIndicator(
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    Colors
                                                                        .white,
                                                                  ),
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                          : Text('Accept'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      if (booking['status'] == 'InProgress')
                                        Padding(
                                          padding: EdgeInsets.only(top: 16),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed:
                                                  isUpdatingStatus &&
                                                          updatingBookingId ==
                                                              booking['bookingId']
                                                      ? null
                                                      : () => markWorkCompleted(
                                                        booking['bookingId'],
                                                      ),
                                              child:
                                                  isUpdatingStatus &&
                                                          updatingBookingId ==
                                                              booking['bookingId']
                                                      ? SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.white),
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                      : Text(
                                                        'Mark Work as Completed',
                                                      ),
                                            ),
                                          ),
                                        ),

                                      if (booking['status'] == 'Completed')
                                        Padding(
                                          padding: EdgeInsets.only(top: 16),
                                          child: Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Waiting for Customer Approval',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),

                                      if (booking['status'] != 'Pending' &&
                                          booking['status'] != 'InProgress' &&
                                          booking['status'] != 'Completed')
                                        _buildStatusButton(booking),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: NavBarSeller(currentIndex: 1),
    );
  }
}
