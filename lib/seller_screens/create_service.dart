import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_easy/theme.dart';
import 'package:http/http.dart' as http;

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

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => serviceImage = File(pickedFile.path));
    }
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

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate() || serviceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and select an image')),
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
        'Address': addressController.text,
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

        // Go back to previous screen
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
      appBar: AppBar(
        title: Text('Create New Service'),
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
              buildImagePicker(),
              SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Service Category *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                items:
                    serviceCategories.keys.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue;
                    selectedCategoryId = serviceCategories[newValue];
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: serviceType,
                decoration: InputDecoration(
                  labelText: 'Service Type',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                items:
                    ['Published', 'Draft'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => serviceType = newValue);
                  }
                },
              ),

              SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Service Description',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                maxLines: 3,
                validator:
                    (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),

              SizedBox(height: 16),
              TextFormField(
                controller: contactNumberController,
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator:
                    (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),

              SizedBox(height: 16),
              TextFormField(
                controller: serviceTagsController,
                decoration: InputDecoration(
                  labelText: 'Service Tags',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  hintText: 'e.g. #Service #Provider',
                ),
                validator:
                    (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),

              SizedBox(height: 16),
              TextFormField(
                controller: providerNameController,
                decoration: InputDecoration(
                  labelText: 'Provider Name',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                validator:
                    (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),

              SizedBox(height: 16),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                validator:
                    (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),

              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text('Create Service'),
                ),
              ),
            ],
          ),
        ),
      ),
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
