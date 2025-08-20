import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_easy/theme.dart';
import 'package:http/http.dart' as http;

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

    isLoading = false;
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => serviceImage = File(pickedFile.path));
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Update Service'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                        ),
                        child:
                            serviceImage != null
                                ? Image.file(serviceImage!, fit: BoxFit.cover)
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
              SizedBox(height: 16),

              // Service Details Card
              Card(
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

                      // Form Fields
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Service Category *',
                          border: OutlineInputBorder(),
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
                        validator: (value) => value == null ? 'Required' : null,
                      ),

                      SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: serviceType,
                        decoration: InputDecoration(
                          labelText: 'Service Type',
                          border: OutlineInputBorder(),
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

                      SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Service Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),

                      SizedBox(height: 16),
                      TextFormField(
                        controller: contactNumberController,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),

                      SizedBox(height: 16),
                      TextFormField(
                        controller: serviceTagsController,
                        decoration: InputDecoration(
                          labelText: 'Service Tags',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. #plumbing #repair',
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),

                      SizedBox(height: 16),
                      TextFormField(
                        controller: providerNameController,
                        decoration: InputDecoration(
                          labelText: 'Provider Name',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),

                      SizedBox(height: 16),
                      TextFormField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
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
    super.dispose();
  }
}
