import 'package:fix_easy/customer_screens/all_companies_screen.dart';
import 'package:fix_easy/customer_screens/company_details_screen.dart';
import 'package:flutter/material.dart';
import 'nav_bar_customer.dart';
import 'package:fix_easy/theme.dart';
import 'category_services_screen.dart';
import 'all_services_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final TextEditingController _searchController = TextEditingController();

  // Service categories data
  final List<Map<String, dynamic>> serviceCategories = [
    {
      'name': 'Carpenter',
      'icon': Icons.carpenter,
      'color': Colors.orange,
      'route': '/carpenter',
    },
    {
      'name': 'Painter',
      'icon': Icons.format_paint,
      'color': Colors.blue,
      'route': '/painter',
    },
    {
      'name': 'Plumber',
      'icon': Icons.plumbing,
      'color': Colors.lightBlue,
      'route': '/plumber',
    },
    {
      'name': 'Electrician',
      'icon': Icons.electrical_services,
      'color': Colors.amber,
      'route': '/electrician',
    },
    {
      'name': 'AC Repair',
      'icon': Icons.ac_unit,
      'color': Colors.teal,
      'route': '/ac_repair',
    },
    {
      'name': 'Cleaner',
      'icon': Icons.cleaning_services,
      'color': Colors.purple,
      'route': '/cleaning',
    },
  ];

  bool isLoadingCompanies = true;
  List<Map<String, dynamic>> featuredCompanies = [];

  @override
  void initState() {
    super.initState();
    fetchFeaturedCompanies();
  }

  Future<void> fetchFeaturedCompanies() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/CompanyProfile/ListOfAllCompanyProfile',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> companies = List<Map<String, dynamic>>.from(
          data['data'],
        );

        // Fetch services for all companies in parallel
        final futures = companies.map((company) async {
          try {
            final servicesResponse = await http.get(
              Uri.parse(
                'https://fixease.pk/api/CompanyServices/getListOfPublishedCompanyServices?CompanyId=${company['companyId']}',
              ),
            );

            if (servicesResponse.statusCode == 200) {
              final servicesData = json.decode(servicesResponse.body);
              final services = List<Map<String, dynamic>>.from(
                servicesData['data'],
              );

              int totalRatings = 0;
              double totalRatingSum = 0;

              for (var service in services) {
                final serviceRating = service['serviceRating'];
                if (serviceRating != null) {
                  totalRatings += serviceRating['totalRatings'] as int;
                  totalRatingSum +=
                      (serviceRating['averageRating'] as num) *
                      serviceRating['totalRatings'];
                }
              }

              return {
                ...company,
                'totalRatings': totalRatings,
                'averageRating':
                    totalRatings > 0 ? totalRatingSum / totalRatings : 0.0,
                'servicesCount': services.length,
              };
            }
          } catch (e) {
            print(
              'Error fetching services for company ${company['companyId']}: $e',
            );
          }
          return null;
        });

        // Wait for all requests to complete
        final results = await Future.wait(futures);

        if (!mounted) return;

        // Filter out null results and sort by total ratings
        final companiesWithRatings =
            results
                .where((company) => company != null)
                .toList()
                .cast<Map<String, dynamic>>();

        companiesWithRatings.sort(
          (a, b) =>
              (b['totalRatings'] as int).compareTo(a['totalRatings'] as int),
        );

        setState(() {
          featuredCompanies = companiesWithRatings.take(3).toList();
          isLoadingCompanies = false;
        });
      } else {
        if (mounted) {
          setState(() {
            featuredCompanies = [];
            isLoadingCompanies = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching companies: $e');
      if (mounted) {
        setState(() {
          featuredCompanies = [];
          isLoadingCompanies = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // void _onServiceTap(String serviceName, String route) {
  //   // Handle service selection
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('$serviceName service selected'),
  //       duration: Duration(seconds: 1),
  //     ),
  //   );
  //   // Navigate to service page
  //   // Navigator.pushNamed(context, route);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        centerTitle: true, // Add this
        title: Image.asset(
          'assets/FixEasy.png',
          height: 100, // Adjust height as needed
          fit: BoxFit.contain,
        ),
        actions: [
          // Profile icon that navigates to profile
          IconButton(
            icon: Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/customerProfile'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section with Gradient Background
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back! 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Find your perfect service provider',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Browse by Category Section
              Text(
                'Browse by Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: serviceCategories.length,
                itemBuilder: (context, index) {
                  final service = serviceCategories[index];
                  return _buildServiceCard(
                    service['name'],
                    service['icon'],
                    service['color'],
                    service['route'],
                  );
                },
              ),

              SizedBox(height: 30),

              // Companies Section
              Text(
                'Featured Companies',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              _buildFeaturedCompaniesSection(),

              //   // Add View All Services button at the bottom
              //   SizedBox(height: 10),
              //   SizedBox(
              //     width: double.infinity,
              //     child: ElevatedButton(
              //       onPressed: () {
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) => AllServicesScreen(),
              //           ),
              //         );
              //       },
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: AppColors.primary,
              //         padding: EdgeInsets.symmetric(vertical: 16),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(8),
              //         ),
              //       ),
              //       child: Text(
              //         'Browse All Services',
              //         style: TextStyle(fontSize: 16, color: Colors.white),
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(),
    );
  }

  Widget _buildServiceCard(
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () {
        // Get category ID from name
        int? categoryId;
        switch (title) {
          case 'Plumber':
            categoryId = 9;
            break;
          case 'Painter':
            categoryId = 10;
            break;
          case 'Electrician':
            categoryId = 11;
            break;
          case 'AC Repair':
            categoryId = 12;
            break;
          case 'Cleaner':
            categoryId = 13;
            break;
          case 'Carpenter':
            categoryId = 14;
            break;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CategoryServicesScreen(
                  categoryId: categoryId!,
                  categoryName: title,
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10), // Reduced from 12
              margin: EdgeInsets.only(top: 4), // Added top margin
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: EdgeInsets.all(6), // Reduced from 8
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24, // Reduced from 28
                  color: color,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCompaniesSection() {
    if (isLoadingCompanies) {
      return SizedBox(
        height: 160,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: NeverScrollableScrollPhysics(),
          children: List.generate(3, (index) => _buildCompanyShimmer()),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          children: [
            ...featuredCompanies.map(
              (company) => _buildCompanyCard(
                company['companyName'] ?? 'N/A',
                'https://fixease.pk${company['companyLogo']}',
                '⭐ ${company['averageRating']?.toStringAsFixed(1) ?? '0.0'}',
                '${company['servicesCount']} Services',
                company: company,
              ),
            ),
            // See All Card
            GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllCompaniesScreen(),
                    ),
                  ),
              child: Container(
                width: 140,
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'See All\nCompanies',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyShimmer() {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(height: 12),
            Container(width: 80, height: 12, color: Colors.white),
            SizedBox(height: 8),
            Container(width: 60, height: 10, color: Colors.white),
            SizedBox(height: 8),
            Container(width: 70, height: 10, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyCard(
    String name,
    String logoUrl,
    String rating,
    String services, {
    Map<String, dynamic>? company,
  }) {
    return GestureDetector(
      onTap:
          company != null
              ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompanyDetailsScreen(company: company),
                ),
              )
              : null,
      child: Container(
        width: 140,
        margin: EdgeInsets.fromLTRB(0, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(logoUrl),
              onBackgroundImageError: (_, __) {},
            ),
            SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(rating, style: TextStyle(color: Colors.amber, fontSize: 12)),
            SizedBox(height: 4),
            Text(
              services,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
