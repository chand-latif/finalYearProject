import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fix_easy/theme.dart';

class CreateCompanyProfileScreen extends StatefulWidget {
  final int userID;
  const CreateCompanyProfileScreen({super.key, required this.userID});

  @override
  _CreateCompanyProfileScreenState createState() =>
      _CreateCompanyProfileScreenState();
}

class _CreateCompanyProfileScreenState
    extends State<CreateCompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // Controllers
  final companyIdController = TextEditingController(text: '0');
  final companyNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final whatsappNumberController = TextEditingController();
  final companyAddressController = TextEditingController();

  File? companyLogo;
  bool isLoading = false;

  Map<String, TimeOfDay?> workingHoursStart = {};
  Map<String, TimeOfDay?> workingHoursEnd = {};
  Map<String, bool> dayOff = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => companyLogo = File(pickedFile.path));
    }
  }

  Future<void> pickTime(BuildContext context, String day, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          workingHoursStart[day] = picked;
        } else {
          workingHoursEnd[day] = picked;
        }
      });
    }
  }

  String formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';
    // Format as HH:mm (24-hour format)
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Validate that working hours are set for non-off days
    for (String day in dayOff.keys) {
      if (!dayOff[day]!) {
        if (workingHoursStart[day] == null || workingHoursEnd[day] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please set working hours for $day or mark it as off',
              ),
            ),
          );
          return;
        }
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://fixease.pk/api/CompanyProfile/CreateCompanyProfile'),
      );

      request.headers.addAll({
        'accept': '*/*',
        'Content-Type': 'multipart/form-data',
      });

      // Add form fields
      request.fields['CompanyId'] = companyIdController.text;
      request.fields['UserId'] = widget.userID.toString();
      request.fields['CompanyName'] = companyNameController.text;
      request.fields['PhoneNumber'] = phoneNumberController.text;
      request.fields['WhatsappNumber'] = whatsappNumberController.text;
      request.fields['CompanyAddress'] = companyAddressController.text;

      // Use the actual CompanyId from the controller
      request.fields['WorkingHours.CompanyId'] = companyIdController.text;

      // Add company logo if selected
      if (companyLogo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('CompanyLogo', companyLogo!.path),
        );
        request.files.add(
          await http.MultipartFile.fromPath(
            'ProfilePicture',
            companyLogo!.path,
          ),
        );
      }

      // Add working hours for each day
      for (String day in dayOff.keys) {
        request.fields['WorkingHours.IsOff$day'] = dayOff[day].toString();

        if (!dayOff[day]!) {
          // Only add times if the day is not off
          request.fields['WorkingHours.${day}StartTime'] = formatTimeOfDay(
            workingHoursStart[day],
          );
          request.fields['WorkingHours.${day}EndTime'] = formatTimeOfDay(
            workingHoursEnd[day],
          );
        } else {
          // Set empty times for off days
          request.fields['WorkingHours.${day}StartTime'] = '';
          request.fields['WorkingHours.${day}EndTime'] = '';
        }
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company Profile Created Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamed(context, '/customerHome');
      } else {
        // Parse error response if possible
        String errorMessage = 'Error: ${response.statusCode}';
        try {
          var errorData = json.decode(responseBody);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else if (errorData is Map && errorData.containsKey('errors')) {
            errorMessage = errorData['errors'].toString();
          }
        } catch (e) {
          errorMessage =
              responseBody.isNotEmpty
                  ? responseBody
                  : 'Error: ${response.statusCode}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildTimePickerRow(String day) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: dayOff[day],
                  onChanged: (val) => setState(() => dayOff[day] = val!),
                  activeColor: AppColors.primary,
                ),
                Text(
                  "Day Off - $day",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (!dayOff[day]!)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Start Time:", style: TextStyle(fontSize: 12)),
                        TextButton(
                          onPressed: () => pickTime(context, day, true),
                          child: Text(
                            workingHoursStart[day]?.format(context) ??
                                'Pick Time',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("End Time:", style: TextStyle(fontSize: 12)),
                        TextButton(
                          onPressed: () => pickTime(context, day, false),
                          child: Text(
                            workingHoursEnd[day]?.format(context) ??
                                'Pick Time',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget buildCompanyLogoWidget() {
    return Column(
      children: [
        GestureDetector(
          onTap: pickImage,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage:
                companyLogo != null ? FileImage(companyLogo!) : null,
            child:
                companyLogo == null
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600])
                    : null,
          ),
        ),
        SizedBox(height: 8),
        Text(
          companyLogo == null ? "Tap to add logo" : "Tap to change logo",
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        if (companyLogo != null)
          TextButton(
            onPressed: () => setState(() => companyLogo = null),
            child: Text("Remove Logo", style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Company Profile'),
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
              Center(child: buildCompanyLogoWidget()),
              SizedBox(height: 20),
              TextFormField(
                controller: companyNameController,
                decoration: InputDecoration(
                  labelText: 'Company Name *',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter company name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: whatsappNumberController,
                decoration: InputDecoration(
                  labelText: 'WhatsApp Number *',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter WhatsApp number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: companyAddressController,
                decoration: InputDecoration(
                  labelText: 'Company Address *',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter company address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              Text(
                'Working Hours',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Set your working hours for each day or mark days as off',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 16),
              ...dayOff.keys.map((day) => buildTimePickerRow(day)).toList(),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      isLoading
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
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
                              Text('Creating Profile...'),
                            ],
                          )
                          : Text('Create Profile'),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    companyIdController.dispose();
    companyNameController.dispose();
    phoneNumberController.dispose();
    whatsappNumberController.dispose();
    companyAddressController.dispose();
    super.dispose();
  }
}
