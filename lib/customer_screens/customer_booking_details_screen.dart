import 'package:flutter/material.dart';
import 'package:fix_easy/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_easy/widgets/image_viewer.dart';
import 'service_review_screen.dart';
// import 'update_booking_screen.dart';

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
  Map<String, dynamic>? latestNegotiation;
  bool isLoadingNegotiation = false;

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
  void initState() {
    super.initState();
    _fetchLatestNegotiation();
  }

  Future<void> _fetchLatestNegotiation() async {
    setState(() => isLoadingNegotiation = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/BookingNegotiation/getLatestNegotiation?BookingId=${widget.booking['bookingId']}',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded'] == true) {
          setState(() => latestNegotiation = data['data']);
        }
      }
    } catch (e) {
      print('Error fetching negotiation: $e');
    } finally {
      setState(() => isLoadingNegotiation = false);
    }
  }

  Future<void> _makeCounterOffer(double price) async {
    setState(() => isUpdatingStatus = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse(
          'https://fixease.pk/api/BookingNegotiation/CreateBookingNegotiation',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'BookingId': widget.booking['bookingId'].toString(),
          'OfferedPrice': price.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Counter offer submitted'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchLatestNegotiation();
        } else {
          throw Exception(data['message'] ?? 'Failed to submit counter offer');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isUpdatingStatus = false);
    }
  }

  Future<void> _showCounterOfferDialog() async {
    final priceController = TextEditingController();
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Make Counter Offer'),
            content: TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Price',
                prefixText: 'Rs. ',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final price = double.tryParse(priceController.text);
                  if (price != null && price > 0) {
                    Navigator.pop(context);
                    _makeCounterOffer(price);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid price')),
                    );
                  }
                },
                child: Text('Send Counter Offer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildPriceOfferCard() {
    if (latestNegotiation == null) return SizedBox.shrink();

    final isSellerOffer = latestNegotiation!['offeredByRole'] == 'Seller';
    final isCustomerOffer = latestNegotiation!['offeredByRole'] == 'Customer';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSellerOffer ? Colors.green[200]! : Colors.blue[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: isSellerOffer ? Colors.green : Colors.blue,
              ),
              SizedBox(width: 8),
              Text(
                isSellerOffer
                    ? 'Price Offered by Seller'
                    : 'Your Counter Offer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Rs. ${latestNegotiation!['offeredPrice'].toString()}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSellerOffer ? Colors.green[700] : Colors.blue[700],
            ),
          ),
        ],
      ),
    );
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
      body: SafeArea(
        child: SingleChildScrollView(
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
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
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
                                  formatDateTime(
                                    booking['customerProposedTime'],
                                  ),
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
                    SizedBox(height: 16),

                    // Price Offer Card
                    if (booking['status'] == 'Pending' &&
                        latestNegotiation != null)
                      _buildPriceOfferCard()
                    else if (booking['status'] == 'InProgress' ||
                        booking['status'] == 'Completed' ||
                        booking['status'] == 'finished')
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payment, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'Agreed Price',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Rs. ${booking['finalPrice']?.toString() ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
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
            booking['status'] == 'Pending' &&
                    latestNegotiation != null &&
                    latestNegotiation!['offeredByRole'] == 'Seller'
                ? Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed:
                                isUpdatingStatus
                                    ? null
                                    : () => confirmBooking(false),
                            child: Text(
                              'Reject',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed:
                                isUpdatingStatus
                                    ? null
                                    : _showCounterOfferDialog,
                            child: Text(
                              'Counter Offer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed:
                          isUpdatingStatus ? null : () => confirmBooking(true),
                      child: Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
                : booking['status'] == 'Pending' &&
                    latestNegotiation != null &&
                    latestNegotiation!['offeredByRole'] == 'Customer'
                ? Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    'Waiting for Seller Approval',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )
                : _buildBottomButton(booking) ??
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
                                  isUpdatingStatus
                                      ? null
                                      : () => confirmBooking(false),
                              child:
                                  isUpdatingStatus && currentAction == 'cancel'
                                      ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
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
                                  isUpdatingStatus
                                      ? null
                                      : () => confirmBooking(true),
                              child:
                                  isUpdatingStatus && currentAction == 'agree'
                                      ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
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
                                  isUpdatingStatus
                                      ? null
                                      : approveWorkCompletion,
                              child:
                                  isUpdatingStatus && currentAction == 'approve'
                                      ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
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
