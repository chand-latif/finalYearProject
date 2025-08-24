import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';
import 'service_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fix_easy/widgets/image_viewer.dart';
import 'package:shimmer/shimmer.dart'; // Add this import

class CompanyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> company;

  const CompanyDetailsScreen({Key? key, required this.company})
    : super(key: key);

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> services = [];

  @override
  void initState() {
    super.initState();
    fetchCompanyServices();
  }

  Future<void> fetchCompanyServices() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/CompanyServices/getListOfPublishedCompanyServices?CompanyId=${widget.company['companyId']}',
        ),
      );

      if (mounted) {
        // Check if widget is still mounted
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['data'] != null) {
            setState(() {
              services = List<Map<String, dynamic>>.from(data['data']);
              isLoading = false;
            });
          } else {
            setState(() {
              services = [];
              isLoading = false;
            });
          }
        } else {
          setState(() {
            services = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          services = [];
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading services: $e')));
      }
    }
  }

  Future<void> _launchPhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch phone call')));
    }
  }

  Future<void> _launchWhatsApp(String whatsappNumber) async {
    var url = "whatsapp://send?phone=$whatsappNumber";
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch WhatsApp')));
    }
  }

  Widget _buildServiceShimmer() {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 120, width: double.infinity, color: Colors.white),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Container(width: 200, height: 16, color: Colors.white),
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
    // final mediaQuery = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: AppColors.primary, // Change background color
      body: SafeArea(
        child: Container(
          // Add Container to handle background colors
          color: Colors.white, // Content area remains white
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: GestureDetector(
                    onTap:
                        () => ImageViewer.showFullScreenImage(
                          context,
                          'https://fixease.pk${widget.company['companyLogo'] ?? ''}',
                        ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://fixease.pk${widget.company['companyLogo'] ?? ''}',
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.error),
                              ),
                        ),
                        // Add gradient overlay for better text visibility
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    widget.company['companyName'] ?? 'Company',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Company Info Card
                          Card(
                            elevation: 2,
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Company Information',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  ListTile(
                                    leading: Icon(Icons.location_on),
                                    title: Text(
                                      widget.company['companyAddress'] ?? 'N/A',
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              widget.company['phoneNumber'] !=
                                                      null
                                                  ? () => _launchPhoneCall(
                                                    widget
                                                        .company['phoneNumber'],
                                                  )
                                                  : null,
                                          icon: Icon(Icons.phone),
                                          label: Text(
                                            'Call',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              widget.company['whatsappNumber'] !=
                                                      null
                                                  ? () => _launchWhatsApp(
                                                    widget
                                                        .company['whatsappNumber'],
                                                  )
                                                  : null,
                                          icon: Icon(
                                            FontAwesomeIcons.whatsapp,
                                            color: Colors.green,
                                            size: 22,
                                          ), // Changed from phone to whatsapp
                                          label: Text(
                                            'WhatsApp',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  144,
                                                  221,
                                                  147,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 20),
                          Text(
                            'Available Services',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                    if (isLoading)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 3,
                        itemBuilder: (context, index) => _buildServiceShimmer(),
                      )
                    else if (services.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.engineering_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No services available at the moment',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final service = services[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ServiceDetailsScreen(
                                        service: service,
                                      ),
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
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            service['categoryName'] ?? 'N/A',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          service['serviceDescription'] ??
                                              'No description',
                                          style: TextStyle(fontSize: 16),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
