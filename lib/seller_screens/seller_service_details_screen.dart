import 'package:flutter/material.dart';
import 'package:fix_easy/theme.dart';
import 'update_service_screen.dart';
import 'package:http/http.dart' as http;
// import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_easy/customer_screens/service_reviews_screen.dart';
import 'package:fix_easy/widgets/image_viewer.dart';

class SellerServiceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> service;
  final int companyId;
  final VoidCallback? onServiceUpdated;

  const SellerServiceDetailsScreen({
    Key? key,
    required this.service,
    required this.companyId,
    this.onServiceUpdated,
  }) : super(key: key);

  Future<void> _deleteService(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Delete Service'),
            content: Text('Are you sure you want to delete this service?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse(
          'https://fixease.pk/api/CompanyServices/DeleteCompanyService?ServiceId=${service['serviceId']}',
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        if (onServiceUpdated != null) onServiceUpdated!();
      } else {
        throw Exception('Failed to delete service');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting service: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Service Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => UpdateServiceScreen(
                        serviceId: service['serviceId'],
                        companyId: companyId,
                        initialData: {
                          'description': service['serviceDescription'],
                          'contactNumber': service['contactNumber'],
                          'serviceTags': service['serviceTags'],
                          'providerName': service['providerName'],
                          'address': service['address'],
                          'categoryName': service['categoryName'],
                          'serviceType': service['serviceType'],
                          'serviceImage': service['serviceImage'],
                        },
                      ),
                ),
              ).then((value) {
                if (value == true && onServiceUpdated != null) {
                  onServiceUpdated!();
                  Navigator.pop(context);
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteService(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 12),
                            Text(
                              service['contactNumber'] ?? 'N/A',
                              style: TextStyle(fontSize: 15),
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
                        if (service['latitude'] != null &&
                            service['longitude'] != null) ...[
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
                              onPressed: () async {
                                final lat = service['latitude'];
                                final lng = service['longitude'];
                                final url = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                );
                                if (!await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                )) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not open Google Maps',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Service Tags Card
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
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Wrap(
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
                    ),
                  ],

                  // Ratings & Reviews Card
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

                  // Ratings & Reviews Section (optional for seller, can be added if needed)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
