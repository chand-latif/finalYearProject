import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_easy/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'service_review_screen.dart';
import 'package:fix_easy/widgets/image_viewer.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Filter Dropdown
          Padding(
            padding: EdgeInsets.all(16),
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
                  DropdownMenuItem(
                    value: 'Completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(value: 'Finished', child: Text('Finished')),
                ],
                onChanged: (value) {
                  setState(() => selectedStatus = value);
                  fetchBookings(value);
                },
              ),
            ),
          ),

          // Bookings List
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : bookings.isEmpty
                    ? Center(child: Text('No bookings found'))
                    : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Add service provider image
                              // Add service provider image
                              if (booking['profilePicture'] != null)
                                GestureDetector(
                                  onTap:
                                      () => ImageViewer.showFullScreenImage(
                                        context,
                                        'https://fixease.pk${booking['profilePicture']}',
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
                                          'https://fixease.pk${booking['profilePicture']}',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // Add a subtle indicator that the image is tappable
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                          colors: [
                                            Colors.black.withOpacity(0.1),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Align(
                                        alignment: Alignment.topRight,
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.zoom_in,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            size: 20,
                                          ),
                                        ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                booking['status'] ?? 'Pending',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              onPressed:
                                                  () => showDeleteConfirmation(
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
                                          color: Colors.grey,
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
                                            color: Colors.grey,
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
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          _formatDate(booking['createdDate']),
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
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
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
                                                                >(Colors.white),
                                                            strokeWidth: 2,
                                                          ),
                                                        )
                                                        : Text('Cancel'),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
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
                                                                >(Colors.white),
                                                            strokeWidth: 2,
                                                          ),
                                                        )
                                                        : Text('Confirm'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Approve work completion button
                                    if (booking['status'] == 'Completed')
                                      Padding(
                                        padding: EdgeInsets.only(top: 16),
                                        child: Row(
                                          children: [
                                            Expanded(
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
                                                                >(Colors.white),
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
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
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
