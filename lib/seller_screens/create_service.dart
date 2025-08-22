import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_easy/theme.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

// Custom class to hold location and formatted address
class SearchResult {
  final Location location;
  final String formattedAddress;

  SearchResult(this.location, this.formattedAddress);
}

class CreateServiceScreen extends StatefulWidget {
  final companyID;
  const CreateServiceScreen({super.key, required this.companyID});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // Controllers
  final descriptionController = TextEditingController();
  final contactNumberController = TextEditingController();
  final serviceTagsController = TextEditingController();
  final providerNameController = TextEditingController();
  final addressController = TextEditingController();
  final searchController = TextEditingController();

  // Add these at class level
  final Map<String, int> serviceCategories = {
    'Plumber': 9,
    'Painter': 10,
    'Electrician': 11,
    'AC Fitter or Repair': 12,
    'Home Cleaner': 13,
    'Carpenter': 14,
  };
  String? selectedCategory = 'Plumber';
  int? selectedCategoryId = 9;

  File? serviceImage;
  String serviceType = 'Published';
  bool isLoading = false;
  bool isSearching = false;

  double? pickedLat;
  double? pickedLng;
  String? selectedAddress;

  List<SearchResult> searchResults = [];
  bool showSearchResults = false;

  Future<void> pickImage() async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (pickedFile != null) {
                      setState(() => serviceImage = File(pickedFile.path));
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (pickedFile != null) {
                      setState(() => serviceImage = File(pickedFile.path));
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget buildImagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child:
                serviceImage != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(serviceImage!, fit: BoxFit.cover),
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add Service Image',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
          ),
        ),
        if (serviceImage != null)
          TextButton(
            onPressed: () => setState(() => serviceImage = null),
            child: Text('Remove Image', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Future<void> searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults.clear();
        showSearchResults = false;
      });
      return;
    }

    setState(() => isSearching = true);

    try {
      List<Location> locations = await locationFromAddress(query);
      List<SearchResult> results = [];

      // Instead of reverse geocoding, use the original query with location details
      for (Location location in locations) {
        // You can optionally get additional context, but keep the original search term
        String displayAddress = query; // Keep the searched term

        // Optionally add area context from reverse geocoding
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String area = '';
            if (place.locality != null && place.locality!.isNotEmpty) {
              area += place.locality!;
            }
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty) {
              if (area.isNotEmpty) area += ', ';
              area += place.administrativeArea!;
            }
            if (area.isNotEmpty) {
              displayAddress = '$query, $area';
            }
          }
        } catch (e) {
          // If reverse geocoding fails, just use the search query
          displayAddress = query;
        }

        results.add(SearchResult(location, displayAddress));
      }

      setState(() {
        searchResults = results;
        showSearchResults = results.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        searchResults.clear();
        showSearchResults = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find location'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() => isSearching = false);
    }
  }

  Future<void> selectLocation(SearchResult searchResult) async {
    setState(() {
      pickedLat = searchResult.location.latitude;
      pickedLng = searchResult.location.longitude;
      selectedAddress = searchResult.formattedAddress;
      addressController.text = searchResult.formattedAddress;
      showSearchResults = false;
      searchController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location selected successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget buildAddressSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Service Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 12),

        // Search Field
        TextFormField(
          controller: searchController,
          decoration: _buildInputDecoration(
            'Search for address or location',
            Icons.search,
          ).copyWith(
            suffixIcon:
                isSearching
                    ? Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          showSearchResults = false;
                          searchResults.clear();
                        });
                      },
                    ),
          ),
          onChanged: (value) {
            // Add delay to avoid too many API calls
            Future.delayed(Duration(milliseconds: 500), () {
              if (searchController.text == value) {
                searchAddress(value);
              }
            });
          },
          onFieldSubmitted: searchAddress,
        ),

        // Search Results
        if (showSearchResults && searchResults.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                SearchResult searchResult = searchResults[index];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.location_on, color: AppColors.primary),
                  title: Text(
                    '${searchResult.location.latitude.toStringAsFixed(4)}, ${searchResult.location.longitude.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    searchResult.formattedAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  onTap: () => selectLocation(searchResult),
                );
              },
            ),
          ),

        SizedBox(height: 16),

        // Selected Address Display
        TextFormField(
          controller: addressController,
          decoration: _buildInputDecoration(
            'Selected Service Address',
            Icons.location_city,
          ),
          readOnly: true,
          maxLines: 2,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Please search and select an address'
                      : null,
        ),

        if (selectedAddress != null && pickedLat != null && pickedLng != null)
          Container(
            margin: EdgeInsets.only(top: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Location Selected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Address: $selectedAddress',
                  style: TextStyle(fontSize: 12, color: Colors.green[600]),
                ),
                SizedBox(height: 4),
                Text(
                  'Coordinates: ${pickedLat!.toStringAsFixed(6)}, ${pickedLng!.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 12, color: Colors.green[600]),
                ),
                SizedBox(height: 8),
                TextButton.icon(
                  icon: Icon(Icons.clear, size: 16),
                  label: Text('Clear Selection'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedAddress = null;
                      pickedLat = null;
                      pickedLng = null;
                      addressController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate() || serviceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and select an image')),
      );
      return;
    }

    if (selectedAddress == null || pickedLat == null || pickedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please search and select a service address')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://fixease.pk/api/CompanyServices/CreateCompanyServices',
        ),
      );

      // Add form fields
      request.fields.addAll({
        'ServiceId': '0', // Static as it's a new service
        'CompanyId': widget.companyID.toString(),
        'CategoryId': selectedCategoryId.toString(),
        'ServiceDescription': descriptionController.text,
        'ContactNumber': contactNumberController.text,
        'ServiceTags': serviceTagsController.text,
        'serviceType': serviceType,
        'ProviderName': providerNameController.text,
        'Address': selectedAddress!,
        'Latitude': pickedLat.toString(),
        'Longitude': pickedLng.toString(),
      });

      // Add service image
      if (serviceImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('ServiceImage', serviceImage!.path),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        if (responseData['statusCode'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('service of this category already exists!'),
              backgroundColor: const Color.fromARGB(255, 222, 84, 74),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create service: ${responseBody}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Create New Service'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () {
          // Hide search results when tapping outside
          if (showSearchResults) {
            setState(() => showSearchResults = false);
          }
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Upload Card
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Service Image',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '(Required)',
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        buildImagePicker(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Service Details Card
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Category Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: _buildInputDecoration(
                            'Service Category',
                            Icons.category,
                          ),
                          items:
                              serviceCategories.keys.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedCategory = newValue;
                              selectedCategoryId = serviceCategories[newValue];
                            });
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Please select a category'
                                      : null,
                        ),
                        SizedBox(height: 16),

                        // Service Type Dropdown
                        DropdownButtonFormField<String>(
                          value: serviceType,
                          decoration: _buildInputDecoration(
                            'Service Type',
                            Icons.work,
                          ),
                          items:
                              ['Published', 'Draft'].map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null)
                              setState(() => serviceType = newValue);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Location Card
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        buildAddressSearchSection(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Additional Information Card
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: _buildInputDecoration(
                            'Service Description',
                            Icons.description,
                          ),
                          maxLines: 3,
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: providerNameController,
                          decoration: _buildInputDecoration(
                            'Provider Name',
                            Icons.person,
                          ),
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: contactNumberController,
                          decoration: _buildInputDecoration(
                            'Contact Number',
                            Icons.phone,
                          ),
                          keyboardType: TextInputType.phone,
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: serviceTagsController,
                          decoration: _buildInputDecoration(
                            'Service Tags',
                            Icons.tag,
                          ).copyWith(hintText: 'e.g. #plumbing #repair'),
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      isLoading
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Creating Service...'),
                            ],
                          )
                          : Text('Create Service'),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    contactNumberController.dispose();
    serviceTagsController.dispose();
    providerNameController.dispose();
    addressController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
