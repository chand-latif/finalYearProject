import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_easy/theme.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

class SearchResult {
  final Location location;
  final String formattedAddress;
  SearchResult(this.location, this.formattedAddress);
}

class UpdateServiceScreen extends StatefulWidget {
  final int serviceId;
  final int companyId;
  final Map<String, dynamic> initialData;

  const UpdateServiceScreen({
    super.key,
    required this.serviceId,
    required this.companyId,
    required this.initialData,
  });

  @override
  State<UpdateServiceScreen> createState() => _UpdateServiceScreenState();
}

class _UpdateServiceScreenState extends State<UpdateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // Controllers
  final descriptionController = TextEditingController();
  final contactNumberController = TextEditingController();
  final serviceTagsController = TextEditingController();
  final providerNameController = TextEditingController();
  final addressController = TextEditingController();
  final searchController = TextEditingController();

  final Map<String, int> serviceCategories = {
    'Plumber': 9,
    'Painter': 10,
    'Electrician': 11,
    'AC Fitter or Repair': 12,
    'Home Cleaner': 13,
    'Carpenter': 14,
  };

  String? selectedCategory;
  int? selectedCategoryId;
  File? serviceImage;
  String? existingImageUrl;
  String serviceType = 'Published';
  bool isLoading = true;

  // Add new state variables for location
  List<SearchResult> searchResults = [];
  bool showSearchResults = false;
  bool isSearching = false;
  double? pickedLat;
  double? pickedLng;
  String? selectedAddress;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with passed data
    descriptionController.text = widget.initialData['description'] ?? '';
    contactNumberController.text = widget.initialData['contactNumber'] ?? '';
    serviceTagsController.text = widget.initialData['serviceTags'] ?? '';
    providerNameController.text = widget.initialData['providerName'] ?? '';
    addressController.text = widget.initialData['address'] ?? '';

    // Set initial category
    final categoryName = widget.initialData['categoryName'];
    selectedCategory = categoryName;
    selectedCategoryId = serviceCategories[categoryName];

    // Set initial service type
    serviceType = widget.initialData['serviceType'] ?? 'Published';

    // Set initial image URL
    existingImageUrl = widget.initialData['serviceImage'];
    // pickedLat = widget.initialData['latitude'];
    // pickedLng = widget.initialData['longitude'];
    // selectedAddress = widget.initialData['address'];

    // Initialize location data with existing values
    if (widget.initialData['latitude'] != null &&
        widget.initialData['longitude'] != null &&
        widget.initialData['address'] != null) {
      setState(() {
        pickedLat = double.tryParse(widget.initialData['latitude'].toString());
        pickedLng = double.tryParse(widget.initialData['longitude'].toString());
        selectedAddress = widget.initialData['address'];
        addressController.text = widget.initialData['address'];
      });
    }

    isLoading = false;
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => serviceImage = File(pickedFile.path));
    }
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

      for (Location location in locations) {
        String displayAddress = query;

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
          displayAddress = query;
        }

        results.add(SearchResult(location, displayAddress));
      }

      setState(() {
        searchResults = results;
        showSearchResults = results.isNotEmpty;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not find location')));
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
  }

  Future<void> updateService() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
          'https://fixease.pk/api/CompanyServices/UpdateCompanyServices',
        ),
      );

      // Add headers
      request.headers.addAll({
        'accept': '*/*',
        'Content-Type': 'multipart/form-data',
      });

      // Add form fields
      request.fields.addAll({
        'ServiceId': widget.serviceId.toString(),
        'CompanyId': widget.companyId.toString(),
        'CategoryId': selectedCategoryId.toString(),
        'ServiceDescription': descriptionController.text,
        'ContactNumber': contactNumberController.text,
        'ServiceTags': serviceTagsController.text,
        'ServiceType': serviceType,
        'ProviderName': providerNameController.text,
        'Address': addressController.text,
        'Latitude': pickedLat?.toString() ?? '',
        'Longitude': pickedLng?.toString() ?? '',
      });

      // Add service image if selected
      if (serviceImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('ServiceImage', serviceImage!.path),
        );
      }

      print('Sending request with fields: ${request.fields}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to update service: ${response.body}');
      }
    } catch (e) {
      print('Error updating service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildAddressSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Update Service Location',
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
            'Search for new address',
            Icons.search,
          ).copyWith(
            suffixIcon:
                isSearching
                    ? Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
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
            Future.delayed(Duration(milliseconds: 500), () {
              if (searchController.text == value) {
                searchAddress(value);
              }
            });
          },
        ),

        // Current Address Display
        if (!showSearchResults && selectedAddress == null)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Address:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.initialData['address'] ?? 'No address available',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
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
                SearchResult result = searchResults[index];
                return ListTile(
                  title: Text(result.formattedAddress),
                  subtitle: Text(
                    '${result.location.latitude.toStringAsFixed(4)}, ${result.location.longitude.toStringAsFixed(4)}',
                  ),
                  onTap: () => selectLocation(result),
                );
              },
            ),
          ),

        SizedBox(height: 16),

        // Selected Location Display (only show after new selection)
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
                      'Current Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('Address: $selectedAddress'),
                Text(
                  'Coordinates: ${pickedLat!.toStringAsFixed(6)}, ${pickedLng!.toStringAsFixed(6)}',
                ),
                SizedBox(height: 8),
                TextButton.icon(
                  icon: Icon(Icons.edit_location, size: 16),
                  label: Text('Change Location'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    // Clear selection to allow new search
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Update Service'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () {
          if (showSearchResults) setState(() => showSearchResults = false);
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Card
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
                        GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child:
                                serviceImage != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        serviceImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : (existingImageUrl != null
                                        ? Image.network(
                                          'https://fixease.pk$existingImageUrl',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) =>
                                                  _buildImagePlaceholder(),
                                        )
                                        : _buildImagePlaceholder()),
                          ),
                        ),
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
                    child: buildAddressSearchSection(),
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
                            'Contact Number (11 digits)',
                            Icons.phone,
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 11,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Contact number is required';
                            if (!RegExp(r'^\d{11}$').hasMatch(value))
                              return 'Enter exactly 11 digits';
                            return null;
                          },
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
                  onPressed: isLoading ? null : updateService,
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
                              Text('Updating Service...'),
                            ],
                          )
                          : Text('Update Service'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
        SizedBox(height: 8),
        Text('Tap to change image'),
      ],
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
