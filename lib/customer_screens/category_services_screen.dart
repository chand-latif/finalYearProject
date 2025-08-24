import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import '../theme.dart';
import 'service_details_screen.dart';

class CategoryServicesScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryServicesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> services = [];

  @override
  void initState() {
    super.initState();
    fetchCategoryServices();
  }

  Future<void> fetchCategoryServices() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/CompanyServices/getListOfPublishedServicesByServiceCategory?CategoryId=${widget.categoryId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          services = List<Map<String, dynamic>>.from(data['data']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load services');
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading services: $e')));
      }
    }
  }

  Widget _buildServiceShimmer() {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 200, width: double.infinity, color: Colors.white),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 150, height: 24, color: Colors.white),
                      Container(width: 50, height: 24, color: Colors.white),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Container(height: 16, width: 200, color: Colors.white),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Container(width: 100, height: 16, color: Colors.white),
                      SizedBox(width: 16),
                      Expanded(
                        child: Container(height: 16, color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (context, index) => _buildServiceShimmer(),
              )
              : services.isEmpty
              ? Center(child: Text('No services available'))
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ServiceDetailsScreen(service: service),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.white,
                      margin: EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (service['serviceImage'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              child: Image.network(
                                'https://fixease.pk${service['serviceImage']}',
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      height: 200,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.error),
                                    ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      service['providerName'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                        Text(
                                          ' ${(service['serviceRating']?['averageRating'] ?? 0).toStringAsFixed(1)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  service['serviceDescription'] ??
                                      'No description',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(service['contactNumber'] ?? 'N/A'),
                                    SizedBox(width: 16),
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        service['address'] ?? 'N/A',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (service['serviceTags'] != null) ...[
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    children:
                                        (service['serviceTags'] as String)
                                            .split(' ')
                                            .map(
                                              (tag) => Chip(
                                                label: Text(
                                                  tag,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
