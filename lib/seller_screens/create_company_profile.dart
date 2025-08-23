import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fix_easy/theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

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
  File? companyProfile;
  bool isLoading = false;
  String? phoneError;
  String? whatsappNumberError;

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

  Future<void> pickImage(bool isProfile) async {
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
                      setState(() {
                        if (isProfile) {
                          companyProfile = File(pickedFile.path);
                        } else {
                          companyLogo = File(pickedFile.path);
                        }
                      });
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
                      setState(() {
                        if (isProfile) {
                          companyProfile = File(pickedFile.path);
                        } else {
                          companyLogo = File(pickedFile.path);
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
    );
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
      request.fields['CreatedBy'] = widget.userID.toString();
      request.fields['CompanyName'] = companyNameController.text;
      request.fields['PhoneNumber'] = phoneNumberController.text;
      request.fields['WhatsappNumber'] = whatsappNumberController.text;
      request.fields['CompanyAddress'] = companyAddressController.text;

      // Fix: Make sure Monday's state is being sent correctly
      request.fields.addAll({
        'WorkingHours.CompanyId': companyIdController.text,
        'WorkingHours.IsOffMonday': dayOff['Monday']!.toString().toLowerCase(),
        'WorkingHours.MondayStartTime': formatTimeOfDay(
          workingHoursStart['Monday'],
        ),
        'WorkingHours.MondayEndTime': formatTimeOfDay(
          workingHoursEnd['Monday'],
        ),
        // ...rest of the fields...
      });

      // Add company logo if selected
      if (companyLogo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('CompanyLogo', companyLogo!.path),
        );
        // request.files.add(
        //   await http.MultipartFile.fromPath(
        //     'ProfilePicture',
        //     companyLogo!.path,
        //   ),
        // );
      }

      if (companyProfile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'ProfilePicture',
            companyProfile!.path,
          ),
        );
        // request.files.add(
        //   await http.MultipartFile.fromPath(
        //     'ProfilePicture',
        //     companyProfile!.path,
        //   ),
        // );
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
        Navigator.pushReplacementNamed(context, '/sellerHome');
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

  void validatePhone(String phone) {
    setState(() {
      if (phone.isEmpty) {
        phoneError = 'Phone number is required';
      } else if (phone.length != 11) {
        phoneError = 'Phone number must be 11 digits';
      } else {
        phoneError = null;
      }
    });
  }

  void validateWhatsappNumber(String whatsappNumber) {
    setState(() {
      if (whatsappNumber.isEmpty) {
        whatsappNumberError = 'Whatsapp number is required';
      } else if (whatsappNumber.length != 11) {
        whatsappNumberError = 'Whatsapp number must be 11 digits';
      } else {
        whatsappNumberError = null;
      }
    });
  }

  Widget buildCompanyLogoWidget(bool isProfile) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => pickImage(isProfile),
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

  Widget buildCompanyProfileWidget(bool isProfile) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => pickImage(isProfile),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage:
                companyProfile != null ? FileImage(companyProfile!) : null,
            child:
                companyProfile == null
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600])
                    : null,
          ),
        ),
        SizedBox(height: 8),
        Text(
          companyProfile == null ? "Tap to add logo" : "Tap to change logo",
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        if (companyProfile != null)
          TextButton(
            onPressed: () => setState(() => companyProfile = null),
            child: Text("Remove Logo", style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
              // Profile Images Card
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Company Images',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildCompanyProfileWidget(true),
                          buildCompanyLogoWidget(false),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Company Information Form
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: companyNameController,
                        decoration: _buildInputDecoration(
                          'Company Name',
                          Icons.business,
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Please enter company name'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: phoneNumberController,

                        decoration: _buildInputDecoration(
                          'Phone Number',
                          Icons.phone,
                        ),

                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        onChanged: (value) {
                          validatePhone(value);
                        },
                        forceErrorText: phoneError,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return phoneError;
                          }
                          if (phoneError != null) {
                            return phoneError;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: whatsappNumberController,
                        decoration: _buildInputDecoration(
                          'WhatsApp Number',
                          FontAwesomeIcons.whatsapp,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        onChanged: (value) {
                          validateWhatsappNumber(value);
                        },
                        forceErrorText: whatsappNumberError,
                        keyboardType: TextInputType.phone,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Please enter WhatsApp number'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: companyAddressController,
                        decoration: _buildInputDecoration(
                          'Company Address',
                          Icons.location_on,
                        ),
                        maxLines: 2,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Please enter company address'
                                    : null,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Working Hours Card
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Working Hours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Set your working hours or mark days as off',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      SizedBox(height: 16),
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Day',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Center(child: Text('Start')),
                                      ),
                                      SizedBox(width: 40),
                                      Expanded(
                                        child: Center(child: Text('End')),
                                      ),
                                      SizedBox(width: 48),
                                      Text('Off'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(thickness: 1),
                          ...dayOff.keys
                              .map((day) => buildTimePickerRow(day))
                              .toList(),
                        ],
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating Profile...'),
                          ],
                        )
                        : Text('Create Profile'),
              ),
              SizedBox(height: 24),
            ],
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

  // Update the buildTimePickerRow method to match new design
  Widget buildTimePickerRow(String day) {
    bool isOff = dayOff[day] ?? false;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isOff ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isOff ? null : () => pickTime(context, day, true),
                        style: _timeButtonStyle(isOff),
                        child: Text(
                          workingHoursStart[day]?.format(context) ?? '--:--',
                          style: TextStyle(
                            color: isOff ? Colors.grey : AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('to', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isOff ? null : () => pickTime(context, day, false),
                        style: _timeButtonStyle(isOff),
                        child: Text(
                          workingHoursEnd[day]?.format(context) ?? '--:--',
                          style: TextStyle(
                            color: isOff ? Colors.grey : AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isOff,
                        onChanged: (value) {
                          setState(() {
                            dayOff[day] = value;
                            if (value) {
                              workingHoursStart[day] = null;
                              workingHoursEnd[day] = null;
                            }
                          });
                        },
                        activeColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (day != dayOff.keys.last) Divider(height: 1),
      ],
    );
  }

  ButtonStyle _timeButtonStyle(bool isOff) {
    return OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      side: BorderSide(color: isOff ? Colors.grey.shade300 : AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
