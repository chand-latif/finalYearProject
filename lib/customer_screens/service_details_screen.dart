import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import 'book_service_screen.dart';
import 'service_reviews_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            if (service['serviceImage'] != null)
              Image.network(
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

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      service['categoryName'] ?? 'N/A',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Provider Name
                  Text(
                    service['providerName'] ?? 'N/A',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    service['serviceDescription'] ?? 'No description available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Contact Information
                  Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  ListTile(
                    leading: Icon(Icons.phone, color: AppColors.primary),
                    title: Text(service['contactNumber'] ?? 'N/A'),
                    contentPadding: EdgeInsets.zero,
                    onTap:
                        () => _makePhoneCall(context, service['contactNumber']),
                  ),
                  ListTile(
                    leading: Icon(Icons.location_on, color: AppColors.primary),
                    title: Text(service['address'] ?? 'N/A'),
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Service Tags
                  if (service['serviceTags'] != null) ...[
                    SizedBox(height: 24),
                    Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          (service['serviceTags'] as String)
                              .split(' ')
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: Colors.grey[200],
                                ),
                              )
                              .toList(),
                    ),
                  ],

                  // Ratings & Reviews Section
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ratings & Reviews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                  SizedBox(height: 8),
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
                  if ((service['serviceReview'] as List).isNotEmpty) ...[
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(service['serviceReview'][0]['comment'] ?? ''),
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
