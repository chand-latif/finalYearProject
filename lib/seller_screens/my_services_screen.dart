import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';
import 'update_service_screen.dart' as update_service;
import 'nav_bar_seller.dart';
import 'package:shimmer/shimmer.dart';
import 'seller_service_details_screen.dart';
import 'create_service.dart';

class MyServicesScreen extends StatefulWidget {
  final companyId;

  const MyServicesScreen({super.key, required this.companyId});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> services = [];

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/CompanyServices/getListOfPublishedCompanyServices?CompanyId=${widget.companyId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            services = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        }
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

  Future<void> deleteService(int serviceId) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'https://fixease.pk/api/CompanyServices/DeleteCompanyService?ServiceId=$serviceId',
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        fetchServices(); // Refresh the list
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

  Future<void> confirmDelete(int serviceId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this service?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                deleteService(serviceId);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildServiceShimmer() {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 150, color: Colors.white),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 100, height: 24, color: Colors.white),
                      Row(
                        children: [
                          Container(width: 32, height: 32, color: Colors.white),
                          SizedBox(width: 8),
                          Container(width: 32, height: 32, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(height: 16, color: Colors.white),
                  SizedBox(height: 8),
                  Container(height: 16, width: 200, color: Colors.white),
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
      backgroundColor: Colors.grey[50], // Add this line
      appBar: AppBar(
        title: Text('My Services'),
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
              ? Center(child: Text('No services found'))
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
                              (context) => SellerServiceDetailsScreen(
                                service: service,
                                companyId: widget.companyId,
                                onServiceUpdated: fetchServices,
                              ),
                        ),
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.only(bottom: 16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Image
                          if (service['serviceImage'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              child: Image.network(
                                'https://fixease.pk${service['serviceImage']}',
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      height: 150,
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
                                    // Category
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
                                        service['categoryName'] ?? 'N/A',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    // Edit and Delete Buttons
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      context,
                                                    ) => update_service.UpdateServiceScreen(
                                                      serviceId:
                                                          service['serviceId'],
                                                      companyId:
                                                          widget.companyId,
                                                      initialData: {
                                                        'description':
                                                            service['serviceDescription'],
                                                        'contactNumber':
                                                            service['contactNumber'],
                                                        'serviceTags':
                                                            service['serviceTags'],
                                                        'providerName':
                                                            service['providerName'],
                                                        'address':
                                                            service['address'],
                                                        'categoryName':
                                                            service['categoryName'],
                                                        'serviceType':
                                                            service['serviceType'],
                                                        'serviceImage':
                                                            service['serviceImage'],
                                                      },
                                                    ),
                                              ),
                                            ).then((value) {
                                              if (value == true) {
                                                // Refresh the services list if update was successful
                                                fetchServices();
                                              }
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => confirmDelete(
                                                service['serviceId'],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),

                                // Provider Name
                                Text(
                                  service['providerName'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),

                                // Description
                                Text(
                                  service['serviceDescription'] ??
                                      'No description',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                SizedBox(height: 12),

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
                                    Text(
                                      ' (${service['serviceRating']?['totalRatings'] ?? 0})',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),

                                // Contact and Address
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
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
                                SizedBox(height: 8),

                                // Tags
                                if (service['serviceTags'] != null)
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar: NavBarSeller(currentIndex: 2),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreateServiceScreen(companyID: widget.companyId),
            ),
          ).then(
            (_) => fetchServices(),
          ); // Refresh list after creating new service
        },
        label: Text('Add Service'),
        icon: Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
