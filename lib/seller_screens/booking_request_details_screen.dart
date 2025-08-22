import 'package:flutter/material.dart';
import 'package:fix_easy/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_easy/widgets/image_viewer.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookingRequestDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onStatusChanged;

  const BookingRequestDetailsScreen({
    Key? key,
    required this.booking,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<BookingRequestDetailsScreen> createState() =>
      _BookingRequestDetailsScreenState();
}

class _BookingRequestDetailsScreenState
    extends State<BookingRequestDetailsScreen> {
  bool isUpdatingStatus = false;
  String? currentAction;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> updateBookingStatus(String status) async {
    setState(() {
      isUpdatingStatus = true;
      currentAction = status;
    });
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No auth token found');
      final response = await http.put(
        Uri.parse(
          'https://fixease.pk/api/BookingService/SetBookingStatus?BookingId=${widget.booking['bookingId']}&Status=$status',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Status updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          if (widget.onStatusChanged != null) widget.onStatusChanged!();
          Navigator.pop(context);
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
        currentAction = null;
      });
    }
  }

  Future<void> markWorkCompleted() async {
    setState(() {
      isUpdatingStatus = true;
      currentAction = 'Completed';
    });
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No auth token found');
      final response = await http.put(
        Uri.parse(
          'https://fixease.pk/api/BookingService/MarkWorkCompleted?BookingId=${widget.booking['bookingId']}',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Work marked as completed'),
              backgroundColor: Colors.green,
            ),
          );
          if (widget.onStatusChanged != null) widget.onStatusChanged!();
          Navigator.pop(context);
        } else {
          throw Exception(
            data['message'] ?? 'Failed to mark work as completed',
          );
        }
      } else {
        throw Exception('Failed to mark work as completed');
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

  String formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _openLocationOnMap() async {
    final lat = widget.booking['latitude'];
    final lng = widget.booking['longitude'];
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not available for this booking')),
      );
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

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Booking Request Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (booking['issuedImages']?.isNotEmpty ?? false)
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
                          itemCount: booking['issuedImages'].length,
                          itemBuilder: (context, imageIndex) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
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
                                      (_, __, ___) => Container(
                                        width: 200,
                                        color: Colors.grey[300],
                                        child: Icon(Icons.error),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        booking['customerName'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          booking['status'] == 'Accept'
                              ? 'Authorizing'
                              : (booking['status'] ?? 'Pending'),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Category
                  Row(
                    children: [
                      Icon(Icons.category, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        booking['category'] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Location
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
                          booking['customerLocation'] ?? 'N/A',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Proposed Time
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Proposed: ${formatDateTime(booking['customerProposedTime'])}',
                        style: TextStyle(color: Colors.grey[800], fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Contact Number
                  Row(
                    children: [
                      Icon(Icons.phone, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        booking['contactNumber'] ?? 'N/A',
                        style: TextStyle(color: Colors.grey[800], fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // View Location Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.map),
                      label: Text('View Location on Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _openLocationOnMap,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Description
                  Text(
                    'Issue Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    booking['description'] ?? 'No description',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 24),

                  // Status
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (booking['status'] == 'Pending') ...[
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      isUpdatingStatus
                          ? null
                          : () => updateBookingStatus('Reject'),
                  child:
                      isUpdatingStatus && currentAction == 'Reject'
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
                          : Text('Reject'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      isUpdatingStatus
                          ? null
                          : () => updateBookingStatus('Accept'),
                  child:
                      isUpdatingStatus && currentAction == 'Accept'
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
                          : Text('Accept'),
                ),
              ),
            ] else if (booking['status'] == 'InProgress') ...[
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isUpdatingStatus ? null : markWorkCompleted,
                  child:
                      isUpdatingStatus
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
                          : Text('Mark Work as Completed'),
                ),
              ),
            ] else if (booking['status'] == 'Completed') ...[
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Waiting for Customer Approval',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
