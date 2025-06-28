import 'package:flutter/material.dart';
import 'nav_bar.dart';
import 'package:fix_easy/theme.dart';

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
      'name': 'Cleaning',
      'icon': Icons.cleaning_services,
      'color': Colors.purple,
      'route': '/cleaning',
    },
  ];

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

  void _onSearch(String query) {
    if (query.isNotEmpty) {
      // Handle search functionality
      print('Searching for: $query');
      // Implement search logic here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // Handle menu tap
          },
        ),
        title: Text(
          'Home/Customer',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'HELLO ABC ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text('👋', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'What you are looking\nfor today',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _onSearch,
                        decoration: InputDecoration(
                          hintText: 'Search what you need...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                          ),
                          suffixIcon: Container(
                            height: 22,
                            width: 20,
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed:
                                  () => _onSearch(_searchController.text),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // All Category Section
              Text(
                'All Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 20),

              // Services Grid
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
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

              SizedBox(height: 20),
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
      // onTap: () => _onServiceTap(title, route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 32, color: color),
            ),

            SizedBox(height: 12),

            // Service Name
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
