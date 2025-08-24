import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';
import 'book_service_screen.dart';
import 'service_reviews_screen.dart';
import 'package:fix_easy/widgets/image_viewer.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> service;

  const ServiceDetailsScreen({Key? key, required this.service})
    : super(key: key);

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    // Clean the phone number by removing spaces and any special characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');

    // Create the URI with the cleaned number
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (!await launchUrl(launchUri)) {
        throw 'Could not launch phone dialer';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open phone dialer: $e')),
      );
    }
  }

  // Add: open WhatsApp with given number (same approach used in company_details_screen)
  Future<void> _launchWhatsApp(
    BuildContext context,
    String whatsappNumber,
  ) async {
    final cleanNumber = whatsappNumber.replaceAll(RegExp(r'\s+'), '');
    final url = "whatsapp://send?phone=$cleanNumber";
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch WhatsApp')));
    }
  }

  Future<void> _openLocationOnMap(BuildContext context) async {
    final lat = service['latitude'];
    final lng = service['longitude'];
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not available for this service')),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Service Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Image
              if (service['serviceImage'] != null)
                GestureDetector(
                  onTap:
                      () => ImageViewer.showFullScreenImage(
                        context,
                        'https://fixease.pk${service['serviceImage']}',
                      ),
                  child: Image.network(
                    'https://fixease.pk${service['serviceImage']}',
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: Icon(Icons.error, size: 50),
                        ),
                  ),
                ),

              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['providerName'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        service['categoryName'] ?? 'N/A',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Description Card
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
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            service['serviceDescription'] ??
                                'No description available',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Contact Information Card
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
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 12),

                          // REPLACED ROW: show phone + whatsapp icon
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 12),

                              // phone as expandable TextButton (same as before)
                              Expanded(
                                child: TextButton(
                                  onPressed:
                                      () => _makePhoneCall(
                                        context,
                                        service['contactNumber'],
                                      ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.centerLeft,
                                  ),
                                  child: Text(
                                    service['contactNumber'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: 8),

                              // WhatsApp icon button (only enabled if number exists)
                              if (service['contactNumber'] != null &&
                                  (service['contactNumber'] as String)
                                      .trim()
                                      .isNotEmpty)
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      76,
                                      216,
                                      78,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: FaIcon(
                                      FontAwesomeIcons.whatsapp,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    onPressed:
                                        () => _launchWhatsApp(
                                          context,
                                          service['contactNumber'],
                                        ),
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
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  service['address'] ?? 'N/A',
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
                              label: Text('View Location on Map'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _openLocationOnMap(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Service Tags Card
                    if (service['serviceTags'] != null) ...[
                      SizedBox(height: 16),
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
                              'Tags',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  (service['serviceTags'] as String)
                                      .split(' ')
                                      .map(
                                        (tag) => Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(tag),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Ratings & Reviews Card
                    SizedBox(height: 16),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ratings & Reviews',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if ((service['serviceReview'] as List).length > 1)
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ServiceReviewsScreen(
                                              reviews: service['serviceReview'],
                                              averageRating:
                                                  service['serviceRating']['averageRating'] ??
                                                  0,
                                              totalRatings:
                                                  service['serviceRating']['totalRatings'] ??
                                                  0,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Text('See all'),
                                ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Rating Summary
                          Row(
                            children: [
                              Text(
                                '${(service['serviceRating']?['averageRating'] ?? 0).toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index <
                                                (service['serviceRating']?['averageRating'] ??
                                                    0)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 20,
                                      );
                                    }),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${service['serviceRating']?['totalRatings'] ?? 0} ratings',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Show first review if exists
                          if ((service['serviceReview'] as List)
                              .isNotEmpty) ...[
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service['serviceReview'][0]['userName'] ??
                                        'Anonymous',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    service['serviceReview'][0]['comment'] ??
                                        '',
                                  ),
                                ],
                              ),
                            ),
                          ],
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
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Navigator.push(context, route)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BookServiceScreen(
                            serviceId: service['serviceId'],
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Book Service',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed:
                    () => _makePhoneCall(context, service['contactNumber']),
                icon: Icon(Icons.phone, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
