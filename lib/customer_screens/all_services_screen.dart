import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';
import 'service_details_screen.dart';
import 'nav_bar_customer.dart';
import 'package:fix_easy/widgets/image_viewer.dart';
import 'package:shimmer/shimmer.dart';

class AllServicesScreen extends StatefulWidget {
  const AllServicesScreen({super.key});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  bool isLoading = true;
  bool isSearching = false;
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> searchResults = [];
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchAllServices();
  }

  Future<void> fetchAllServices() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/CompanyServices/getListOfCompanyServices',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          services = List<Map<String, dynamic>>.from(data['data']);
          isLoading = false;
        });
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

  Future<void> searchServices(String tag) async {
    if (tag.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults.clear();
      });
      return;
    }

    setState(() => isSearching = true);
    try {
      final response = await http.get(
        Uri.parse('https://fixease.pk/api/CompanyServices/search?tag=$tag'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          searchResults = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching services: $e')));
      }
    } finally {
      setState(() => isLoading = false);
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
            Container(height: 120, color: Colors.white),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 120, height: 20, color: Colors.white),
                      Container(width: 80, height: 20, color: Colors.white),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('All Services'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Material(
              elevation: 4,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        searchController.text.isNotEmpty
                            ? AppColors.primary.withOpacity(0.5)
                            : Colors.transparent,
                  ),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search services by keywords...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color:
                          searchController.text.isNotEmpty
                              ? AppColors.primary
                              : Colors.grey[400],
                    ),
                    suffixIcon:
                        searchController.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.grey[400],
                              ),
                              splashRadius: 20,
                              onPressed: () {
                                searchController.clear();
                                searchServices('');
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color.fromARGB(
                          255,
                          175,
                          233,
                          230,
                        ).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color.fromARGB(
                          255,
                          175,
                          233,
                          230,
                        ).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: TextStyle(fontSize: 16),
                  onChanged: searchServices,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (context, index) => _buildServiceShimmer(),
                    )
                    : (isSearching ? searchResults : services).isEmpty
                    ? Center(
                      child: Text(
                        isSearching
                            ? 'No services found'
                            : 'No services available',
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount:
                          isSearching ? searchResults.length : services.length,
                      itemBuilder: (context, index) {
                        final service =
                            isSearching
                                ? searchResults[index]
                                : services[index];
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
                                  GestureDetector(
                                    onTap:
                                        () => ImageViewer.showFullScreenImage(
                                          context,
                                          'https://fixease.pk${service['serviceImage']}',
                                        ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                      child: Image.network(
                                        'https://fixease.pk${service['serviceImage']}',
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => Container(
                                              height: 120,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.error),
                                            ),
                                      ),
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
                                            service['providerName'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                                              service['categoryName'] ?? 'N/A',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        service['serviceDescription'] ??
                                            'No description',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 16),
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
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            service['contactNumber'] ?? 'N/A',
                                          ),
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
                                                      backgroundColor: AppColors
                                                          .primary
                                                          .withOpacity(0.1),
                                                      labelStyle: TextStyle(
                                                        color:
                                                            AppColors.primary,
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
          ),
        ],
      ),
      bottomNavigationBar: CustomNavBar(currentIndex: 2),
    );
  }
}
