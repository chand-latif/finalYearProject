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

  // Add new state variables
  Map<String, Map<String, dynamic>?> latestNegotiations =
      {}; // Store negotiations by bookingId
  bool isLoadingNegotiation = false;

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
      padding: EdgeInsets.symmetric(vertical: 12),
      margin: EdgeInsets.only(top: 0),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
            selected: selectedStatus == 'finished',
            onSelected: (_) {
              setState(() => selectedStatus = 'finished');
              fetchBookings('finished');
            },
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.green.withOpacity(0.2),
            checkmarkColor: Colors.green,
            labelStyle: TextStyle(
              color:
                  selectedStatus == 'finished'
                      ? Colors.green
                      : Colors.grey[700],
              fontWeight:
                  selectedStatus == 'finished'
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
          SizedBox(width: 8),
        ],
      ),
    );
  }

  Future<void> _fetchLatestNegotiation(int bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/BookingNegotiation/getLatestNegotiation?BookingId=$bookingId',
        ),
        headers: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded'] == true) {
          setState(() {
            latestNegotiations = {
              ...latestNegotiations,
              bookingId.toString(): data['data'],
            };
          });
        }
      }
    } catch (e) {
      print('Error fetching negotiation: $e');
    }
  }

  Future<void> _makeOffer(int bookingId, double price) async {
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
          'BookingId': bookingId.toString(),
          'OfferedPrice': price.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Price offer submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchLatestNegotiation(bookingId);
        } else {
          throw Exception(data['message'] ?? 'Failed to submit offer');
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

  Future<void> _showPriceOfferDialog(int bookingId) async {
    final priceController = TextEditingController();
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Make Price Offer'),
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
                    _makeOffer(bookingId, price);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid price')),
                    );
                  }
                },
                child: Text('Send Offer'),
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

  // Replace the existing booking action buttons with this new method
  Widget _buildBookingActions(Map<String, dynamic> booking) {
    final bookingId = booking['bookingId'];
    final negotiation = latestNegotiations?[bookingId.toString()];

    // Initial load of negotiation if not already loaded
    if (negotiation == null && booking['status'] == 'Pending') {
      _fetchLatestNegotiation(bookingId);
    }

    if (booking['status'] == 'Completed') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Pending Customer Approval of Completion',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    if (booking['status'] == 'Pending') {
      // Show accept/reject for customer counter offer
      if (negotiation != null && negotiation['offeredByRole'] == 'Customer') {
        return Row(
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
                        : () => updateBookingStatus(bookingId, 'Reject'),
                child: Text('Reject', style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    isUpdatingStatus
                        ? null
                        : () => updateBookingStatus(bookingId, 'InProgress'),
                child: Text('Accept', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      }

      // Show waiting for customer approval if seller has made an offer
      if (negotiation != null && negotiation['offeredByRole'] == 'Seller') {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
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
        );
      }

      // Show make offer/reject buttons for initial state
      return Row(
        children: [
          SizedBox(height: 8),
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
                      : () => updateBookingStatus(bookingId, 'Reject'),
              child: Text('Reject', style: TextStyle(color: Colors.white)),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed:
                  isUpdatingStatus
                      ? null
                      : () => _showPriceOfferDialog(bookingId),
              child: Text('Make Offer', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    }

    // Show mark as completed button for in-progress bookings
    if (booking['status'] == 'InProgress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed:
              isUpdatingStatus ? null : () => markWorkCompleted(bookingId),
          child: Text(
            'Mark Work as Completed',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return _buildStatusButton(booking);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Bookings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
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
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BookingRequestDetailsScreen(
                                      booking: booking,
                                      onStatusChanged: fetchBookings,
                                    ),
                              ),
                            );
                            fetchBookings(
                              selectedStatus,
                            ); // Refresh after returning
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
                                      SizedBox(height: 8),
                                      // Add price display section
                                      if (booking['status'] == 'InProgress' ||
                                          booking['status'] == 'Completed' ||
                                          booking['status'] == 'finished') ...[
                                        SizedBox(height: 16),
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.green[200]!,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.payment,
                                                color: Colors.green,
                                              ),
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
                                      ] else if (booking['status'] ==
                                              'Pending' &&
                                          latestNegotiations[booking['bookingId']
                                                  .toString()] !=
                                              null) ...[
                                        SizedBox(height: 12),
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color:
                                                  latestNegotiations[booking['bookingId']
                                                              .toString()]!['offeredByRole'] ==
                                                          'Seller'
                                                      ? Colors.green[200]!
                                                      : Colors.blue[200]!,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.payment,
                                                color:
                                                    latestNegotiations[booking['bookingId']
                                                                .toString()]!['offeredByRole'] ==
                                                            'Seller'
                                                        ? Colors.green
                                                        : Colors.blue,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                latestNegotiations[booking['bookingId']
                                                            .toString()]!['offeredByRole'] ==
                                                        'Seller'
                                                    ? 'Your Offer: '
                                                    : 'Customer Offer: ',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Rs. ${latestNegotiations[booking['bookingId'].toString()]!['offeredPrice']?.toString() ?? 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color:
                                                      latestNegotiations[booking['bookingId']
                                                                  .toString()]!['offeredByRole'] ==
                                                              'Seller'
                                                          ? Colors.green[700]
                                                          : Colors.blue[700],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      SizedBox(height: 6),
                                      _buildBookingActions(booking),
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
