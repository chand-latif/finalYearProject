import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_easy/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'service_review_screen.dart';
import 'package:fix_easy/widgets/image_viewer.dart';
import 'nav_bar_customer.dart';
import 'package:shimmer/shimmer.dart';
import 'customer_booking_details_screen.dart';
// import 'update_booking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> bookings = [];
  String? selectedStatus; // For filter dropdown
  bool isUpdatingStatus = false;
  int? updatingBookingId;
  String? currentAction;

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

      // Fix URL construction
      final url = Uri.parse(
        'https://fixease.pk/api/BookingService/ListOfBookingsForCustomer?status=${status ?? ''}',
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

  Future<void> confirmBooking(int bookingId, bool isAgree) async {
    setState(() {
      isUpdatingStatus = true;
      updatingBookingId = bookingId;
      currentAction = isAgree ? 'agree' : 'cancel';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception('No auth token found');

      final response = await http.put(
        Uri.parse(
          'https://fixease.pk/api/BookingService/ConfirmBooking?BookingId=$bookingId&isAgree=$isAgree',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAgree ? 'Booking accepted' : 'Booking cancelled'),
              backgroundColor: isAgree ? Colors.green : Colors.red,
            ),
          );
          fetchBookings(); // Refresh the list
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to update booking');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isUpdatingStatus = false;
        updatingBookingId = null;
        currentAction = null;
      });
    }
  }

  Future<void> approveWorkCompletion(Map<String, dynamic> booking) async {
    setState(() {
      isUpdatingStatus = true;
      updatingBookingId = booking['bookingId'];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception('No auth token found');

      final response = await http.put(
        Uri.parse(
          'https://fixease.pk/api/BookingService/FinishedBooking?BookingId=${booking['bookingId']}',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Work completion approved'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to review screen with correct serviceId
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ServiceReviewScreen(
                    serviceId:
                        booking['serviceId'], // Use serviceId instead of bookingId
                  ),
            ),
          );

          fetchBookings();
        } else {
          throw Exception(data['message']);
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

  Future<void> deleteBooking(int bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception('No auth token found');

      final response = await http.delete(
        Uri.parse(
          'https://fixease.pk/api/BookingService/DeleteBookingById?BookingId=$bookingId',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Pass the current filter status when refreshing
        fetchBookings(selectedStatus);
      } else {
        throw Exception('Failed to delete booking');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> showDeleteConfirmation(int bookingId) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Booking'),
          content: Text('Are you sure you want to delete this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteBooking(bookingId);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
            Container(height: 120, color: Colors.white),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(Map<String, dynamic> booking) {
    if (booking['status'] == 'Accept' || booking['status'] == 'Completed') {
      return Container(); // Return empty container for actionable statuses
    }

    String statusText = booking['status'] ?? 'Unknown';
    Color statusColor;

    switch (statusText.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending Seller Approval';
        break;
      case 'inprogress':
        statusColor = Colors.blue;
        statusText = 'Work In Progress';
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: Text('All'),
            selected: selectedStatus == null,
            onSelected: (_) {
              setState(() => selectedStatus = null);
              fetchBookings(null);
            },
            backgroundColor: Colors.grey[200],
            selectedColor: AppColors.primary.withOpacity(0.2),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color:
                  selectedStatus == null ? AppColors.primary : Colors.grey[700],
              fontWeight:
                  selectedStatus == null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Pending'),
            selected: selectedStatus == 'Pending',
            onSelected: (_) {
              setState(() => selectedStatus = 'Pending');
              fetchBookings('Pending');
            },
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.orange.withOpacity(0.2),
            checkmarkColor: Colors.orange,
            labelStyle: TextStyle(
              color:
                  selectedStatus == 'Pending'
                      ? Colors.orange
                      : Colors.grey[700],
              fontWeight:
                  selectedStatus == 'Pending'
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Accepted'),
            selected: selectedStatus == 'Accept',
            onSelected: (_) {
              setState(() => selectedStatus = 'Accept');
              fetchBookings('Accept');
            },
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.green.withOpacity(0.2),
            checkmarkColor: Colors.green,
            labelStyle: TextStyle(
              color:
                  selectedStatus == 'Accept' ? Colors.green : Colors.grey[700],
              fontWeight:
                  selectedStatus == 'Accept'
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('In Progress'),
            selected: selectedStatus == 'InProgress',
            onSelected: (_) {
              setState(() => selectedStatus = 'InProgress');
              fetchBookings('InProgress');
            },
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.blue.withOpacity(0.2),
            checkmarkColor: Colors.blue,
            labelStyle: TextStyle(
              color:
                  selectedStatus == 'InProgress'
                      ? Colors.blue
                      : Colors.grey[700],
              fontWeight:
                  selectedStatus == 'InProgress'
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),

          SizedBox(width: 8),
          FilterChip(
            label: Text('Completed'),
            selected: selectedStatus == 'Finished',
            onSelected: (_) {
              setState(() => selectedStatus = 'Finished');
              fetchBookings('Finished');
            },
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.green.withOpacity(0.2),
            checkmarkColor: Colors.green,
            labelStyle: TextStyle(
              color:
                  selectedStatus == 'Finished'
                      ? Colors.green
                      : Colors.grey[700],
              fontWeight:
                  selectedStatus == 'Finished'
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Rejected'),
            selected: selectedStatus == 'Reject',
            onSelected: (_) {
              setState(() => selectedStatus = 'Reject');
              fetchBookings('Reject');
            },
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.red.withOpacity(0.2),
            checkmarkColor: Colors.red,
            labelStyle: TextStyle(
              color: selectedStatus == 'Reject' ? Colors.red : Colors.grey[700],
              fontWeight:
                  selectedStatus == 'Reject'
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Add this line
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterChips(), // Replace old dropdown with new filter chips
          // Bookings List
          Expanded(
            child:
                isLoading
                    ? ListView.builder(
                      padding: EdgeInsets.all(16),

                      itemCount: 4,
                      itemBuilder: (context, index) => _buildBookingShimmer(),
                    )
                    : bookings.isEmpty
                    ? Center(child: Text('No bookings yet'))
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
                                    (context) => CustomerBookingDetailsScreen(
                                      booking: booking,
                                      onStatusChanged:
                                          () => fetchBookings(selectedStatus),
                                    ),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.white,
                            margin: EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Add service provider image
                                // Add service provider image
                                if (booking['serviceImage'] != null)
                                  GestureDetector(
                                    onTap:
                                        () => ImageViewer.showFullScreenImage(
                                          context,
                                          'https://fixease.pk${booking['serviceImage']}',
                                        ),
                                    child: Container(
                                      height: 120,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            'https://fixease.pk${booking['serviceImage']}',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                // if (booking['profilePicture'] != null)
                                //   Container(
                                //     height: 120,
                                //     width: double.infinity,
                                //     decoration: BoxDecoration(
                                //       borderRadius: BorderRadius.vertical(
                                //         top: Radius.circular(4),
                                //       ),
                                //       image: DecorationImage(
                                //         image: NetworkImage(
                                //           'https://fixease.pk${booking['profilePicture']}',
                                //         ),
                                //         fit: BoxFit.cover,
                                //       ),
                                //     ),
                                //   ),
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
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                booking['companyName'] ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                booking['serviceProviderName'] ??
                                                    'N/A',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              // Status container
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
                                              //     booking['status'] ??
                                              //         'Pending',
                                              //     style: TextStyle(
                                              //       color: AppColors.primary,
                                              //       fontWeight: FontWeight.bold,
                                              //     ),
                                              //   ),
                                              // ),
                                              // IconButton(
                                              //   icon: Icon(
                                              //     Icons.edit_outlined,
                                              //     color: AppColors.primary,
                                              //   ),
                                              //   onPressed: () {
                                              //     Navigator.push(
                                              //       context,
                                              //       MaterialPageRoute(
                                              //         builder:
                                              //             (
                                              //               context,
                                              //             ) => UpdateBookingScreen(
                                              //               booking: booking,
                                              //               onUpdate:
                                              //                   () => fetchBookings(
                                              //                     selectedStatus,
                                              //                   ),
                                              //             ),
                                              //       ),
                                              //     );
                                              //   },
                                              // ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                                onPressed:
                                                    () =>
                                                        showDeleteConfirmation(
                                                          booking['bookingId'],
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),

                                      // Category
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.category_outlined,
                                            size: 16,
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

                                      SizedBox(height: 8),

                                      // Contact Number
                                      if (booking['contactNumber'] != null &&
                                          booking['contactNumber'] != '0')
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              booking['contactNumber'],
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),

                                      SizedBox(height: 8),

                                      // Booking Date
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            _formatDate(
                                              booking['customerProposedTime'],
                                            ),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Customer confirmation buttons
                                      if (booking['status'] == 'Accept')
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
                                                          : () => confirmBooking(
                                                            booking['bookingId'],
                                                            false,
                                                          ),
                                                  child:
                                                      isUpdatingStatus &&
                                                              updatingBookingId ==
                                                                  booking['bookingId'] &&
                                                              currentAction ==
                                                                  'cancel'
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
                                                          : Text('Cancel'),
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
                                                          : () => confirmBooking(
                                                            booking['bookingId'],
                                                            true,
                                                          ),
                                                  child:
                                                      isUpdatingStatus &&
                                                              updatingBookingId ==
                                                                  booking['bookingId'] &&
                                                              currentAction ==
                                                                  'agree'
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
                                                          : Text('Confirm'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      // Approve work completion button
                                      else if (booking['status'] == 'Completed')
                                        Padding(
                                          padding: EdgeInsets.only(top: 16),
                                          child: Row(
                                            children: [
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
                                                          : () =>
                                                              approveWorkCompletion(
                                                                booking,
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
                                                                  >(
                                                                    Colors
                                                                        .white,
                                                                  ),
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                          : Text(
                                                            'Approve Work Completion',
                                                          ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      // Status button for other statuses
                                      else
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
      bottomNavigationBar: CustomNavBar(currentIndex: 1), // Add this line
    );
  }

  // Add this helper method to format the date
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}-${date.month}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
