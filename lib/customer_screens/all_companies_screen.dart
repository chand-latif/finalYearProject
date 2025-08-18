import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';
import 'company_details_screen.dart';

class AllCompaniesScreen extends StatefulWidget {
  const AllCompaniesScreen({super.key});

  @override
  State<AllCompaniesScreen> createState() => _AllCompaniesScreenState();
}

class _AllCompaniesScreenState extends State<AllCompaniesScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> companies = [];

  @override
  void initState() {
    super.initState();
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/CompanyProfile/ListOfAllCompanyProfile',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          companies = List<Map<String, dynamic>>.from(data['data']);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading companies: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Companies'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : companies.isEmpty
              ? Center(child: Text('No companies available'))
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final company = companies[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  CompanyDetailsScreen(company: company),
                        ),
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Company Logo
                              Container(
                                width: 100,
                                height: 100,
                                margin: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      'https://fixease.pk${company['companyLogo']}',
                                    ),
                                    fit: BoxFit.cover,
                                    onError: (_, __) {},
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        company['companyName'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              company['companyAddress'] ??
                                                  'N/A',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            company['phoneNumber'] ?? 'N/A',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
