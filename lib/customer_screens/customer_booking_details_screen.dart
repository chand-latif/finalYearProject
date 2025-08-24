import 'package:flutter/material.dart';
import 'package:fix_easy/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_easy/widgets/image_viewer.dart';
import 'service_review_screen.dart';
import 'update_booking_screen.dart';

class CustomerBookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onStatusChanged;

  const CustomerBookingDetailsScreen({
    Key? key,
    required this.booking,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<CustomerBookingDetailsScreen> createState() =>
      _CustomerBookingDetailsScreenState();
}

class _CustomerBookingDetailsScreenState
    extends State<CustomerBookingDetailsScreen> {
  bool isUpdatingStatus = false;
  String? currentAction;

  String formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> confirmBooking(bool isAgree) async {
    setState(() {
      isUpdatingStatus = true;
      currentAction = isAgree ? 'agree' : 'cancel';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.put(
        Uri.parse(
          'https://fixease.pk/api/BookingService/ConfirmBooking?BookingId=${widget.booking['bookingId']}&isAgree=$isAgree',
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
          if (widget.onStatusChanged != null) widget.onStatusChanged!();
          Navigator.pop(context);
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
        currentAction = null;
      });
    }
  }

  Future<void> approveWorkCompletion() async {
    setState(() {
      isUpdatingStatus = true;
      currentAction = 'approve';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.put(
        Uri.parse(
          'https://fixease.pk/api/BookingService/FinishedBooking?BookingId=${widget.booking['bookingId']}',
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ServiceReviewScreen(
                    serviceId: widget.booking['serviceId'],
                  ),
            ),
          );
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to approve work completion');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isUpdatingStatus = false;
        currentAction = null;
      });
    }
  }

  Future<void> _openLocationOnMap() async {
    final lat = widget.booking['latitude'];
    final lng = widget.booking['longitude'];
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location not available')));
      return;
    }
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open Google Maps')));
    }
  }

  Future<void> deleteBooking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.delete(
        Uri.parse(
          'https://fixease.pk/api/BookingService/DeleteBookingById?BookingId=${widget.booking['bookingId']}',
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
        if (widget.onStatusChanged != null) widget.onStatusChanged!();
        Navigator.pop(context);
      } else {
        throw Exception('Failed to delete booking');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> showDeleteConfirmation() {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                  deleteBooking();
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Widget? _buildBottomButton(Map<String, dynamic> booking) {
    if (booking['status'] == 'Accept' || booking['status'] == 'Completed') {
      return null;
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch phone call')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Booking Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.edit_outlined),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder:
          //             (context) => UpdateBookingScreen(
          //               booking: widget.booking,
          //               onUpdate: () {
          //                 if (widget.onStatusChanged != null) {
          //                   widget.onStatusChanged!();
          //                 }
          //                 Navigator.pop(context);
          //               },
          //             ),
          //       ),
          //     );
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red),
            onPressed: showDeleteConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (booking['serviceImage'] != null)
              GestureDetector(
                onTap:
                    () => ImageViewer.showFullScreenImage(
                      context,
                      'https://fixease.pk${booking['serviceImage']}',
                    ),
                child: Hero(
                  tag: 'serviceImage${booking['serviceId']}',
                  child: Image.network(
                    'https://fixease.pk${booking['serviceImage']}',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['companyName'] ?? 'N/A',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),

                  // Service Provider Info Card
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
                          'Service Provider',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking['serviceProviderName'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      booking['category'] ?? 'N/A',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  if (booking['contactNumber'] != null)
                                    TextButton.icon(
                                      icon: Icon(
                                        Icons.phone,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                      label: Text(
                                        booking['contactNumber'],
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                      onPressed:
                                          () => _makePhoneCall(
                                            booking['contactNumber'],
                                          ),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        alignment: Alignment.centerLeft,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Booking Info Card
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
                          'Booking Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formatDateTime(booking['customerProposedTime']),
                                style: TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                booking['address'] ?? 'N/A',
                                style: TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.map),
                            label: Text('View on Map'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _openLocationOnMap,
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
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child:
            _buildBottomButton(booking) ??
            Row(
              children: [
                if (booking['status'] == 'Accept') ...[
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed:
                          isUpdatingStatus ? null : () => confirmBooking(false),
                      child:
                          isUpdatingStatus && currentAction == 'cancel'
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                              : Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed:
                          isUpdatingStatus ? null : () => confirmBooking(true),
                      child:
                          isUpdatingStatus && currentAction == 'agree'
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                              : Text('Confirm'),
                    ),
                  ),
                ] else if (booking['status'] == 'Completed') ...[
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed:
                          isUpdatingStatus ? null : approveWorkCompletion,
                      child:
                          isUpdatingStatus && currentAction == 'approve'
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                              : Text('Approve Work Completion'),
                    ),
                  ),
                ],
              ],
            ),
      ),
    );
  }
}
