import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fix_easy/theme.dart';

class UpdateCompanyProfileScreen extends StatefulWidget {
  final int userID;
  final int companyID;
  const UpdateCompanyProfileScreen({
    super.key,
    required this.userID,
    required this.companyID,
  });

  @override
  _UpdateCompanyProfileScreenState createState() =>
      _UpdateCompanyProfileScreenState();
}

class _UpdateCompanyProfileScreenState
    extends State<UpdateCompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // Controllers
  final companyIdController = TextEditingController(text: '0');
  final companyNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final whatsappNumberController = TextEditingController();
  final companyAddressController = TextEditingController();

  // Change File? to String? for image URLs
  String? profilePictureUrl;
  String? companyLogoUrl;
  File? newProfilePicture;
  File? newCompanyLogo;
  bool isLoading = true;
  final Map<String, TimeOfDay?> _workingHoursStart = {};
  final Map<String, TimeOfDay?> _workingHoursEnd = {};
  final Map<String, bool> _dayOff = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': true,
  };

  @override
  void initState() {
    super.initState();
    fetchCompanyProfile();
    _fetchWorkingHours();
  }

  Future<void> _fetchWorkingHours() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/CompanyProfile/getWorkingHoursById?CompanyId=${widget.companyID}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _dayOff['Monday'] = data['isOffMonday'] ?? false;
          _dayOff['Tuesday'] = data['isOffTuesday'] ?? false;
          _dayOff['Wednesday'] = data['isOffWednesday'] ?? false;
          _dayOff['Thursday'] = data['isOffThursday'] ?? false;
          _dayOff['Friday'] = data['isOffFriday'] ?? false;
          _dayOff['Saturday'] = data['isOffSaturday'] ?? false;
          _dayOff['Sunday'] = data['isOffSunday'] ?? true;

          _workingHoursStart['Monday'] = _parseTime(data['mondayStartTime']);
          _workingHoursEnd['Monday'] = _parseTime(data['mondayEndTime']);
          _workingHoursStart['Tuesday'] = _parseTime(data['tuesdayStartTime']);
          _workingHoursEnd['Tuesday'] = _parseTime(data['tuesdayEndTime']);
          _workingHoursStart['Wednesday'] = _parseTime(
            data['wednesdayStartTime'],
          );
          _workingHoursEnd['Wednesday'] = _parseTime(data['wednesdayEndTime']);
          _workingHoursStart['Thursday'] = _parseTime(
            data['thursdayStartTime'],
          );
          _workingHoursEnd['Thursday'] = _parseTime(data['thursdayEndTime']);
          _workingHoursStart['Friday'] = _parseTime(data['fridayStartTime']);
          _workingHoursEnd['Friday'] = _parseTime(data['fridayEndTime']);
          _workingHoursStart['Saturday'] = _parseTime(
            data['saturdayStartTime'],
          );
          _workingHoursEnd['Saturday'] = _parseTime(data['saturdayEndTime']);
          _workingHoursStart['Sunday'] = _parseTime(data['sundayStartTime']);
          _workingHoursEnd['Sunday'] = _parseTime(data['sundayEndTime']);
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load working hours')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return null;
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  List<Widget> _buildWorkingHoursRows() {
    return _dayOff.keys.map((day) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(day, style: TextStyle(fontSize: 16)),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed:
                        _dayOff[day]! || !_dayOff[day]!
                            ? () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    _workingHoursStart[day] ??
                                    TimeOfDay(hour: 9, minute: 0),
                              );
                              if (picked != null &&
                                  picked != _workingHoursStart[day]) {
                                setState(() {
                                  _workingHoursStart[day] = picked;
                                });
                              }
                            }
                            : null,
                    child: Text(
                      style: TextStyle(fontSize: 12),

                      _workingHoursStart[day] == null
                          ? '--:--'
                          : '${_workingHoursStart[day]!.hour.toString().padLeft(2, '0')}:${_workingHoursStart[day]!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed:
                        _dayOff[day]! || !_dayOff[day]!
                            ? () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    _workingHoursEnd[day] ??
                                    TimeOfDay(hour: 17, minute: 0),
                              );
                              if (picked != null &&
                                  picked != _workingHoursEnd[day]) {
                                setState(() {
                                  _workingHoursEnd[day] = picked;
                                });
                              }
                            }
                            : null,
                    child: Text(
                      style: TextStyle(fontSize: 12),
                      _workingHoursEnd[day] == null
                          ? '--:--'
                          : '${_workingHoursEnd[day]!.hour.toString().padLeft(2, '0')}:${_workingHoursEnd[day]!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                Checkbox(
                  value: _dayOff[day],
                  onChanged: (value) {
                    setState(() {
                      _dayOff[day] = value ?? false;
                      if (value ?? false) {
                        _workingHoursStart[day] = null;
                        _workingHoursEnd[day] = null;
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _updateWorkingHours() async {
    setState(() {
      isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
          'https://fixease.pk/api/CompanyProfile/updateCompanyWorkingHours',
        ),
      );

      request.headers.addAll({
        'accept': '*/*',
        'Content-Type': 'multipart/form-data',
      });

      request.fields['CompanyId'] = widget.companyID.toString();
      request.fields['MondayStartTime'] = _formatTimeOfDay(
        _workingHoursStart['Monday'],
      );
      request.fields['MondayEndTime'] = _formatTimeOfDay(
        _workingHoursEnd['Monday'],
      );
      request.fields['IsOffMonday'] = _dayOff['Monday'].toString();
      request.fields['TuesdayStartTime'] = _formatTimeOfDay(
        _workingHoursStart['Tuesday'],
      );
      request.fields['TuesdayEndTime'] = _formatTimeOfDay(
        _workingHoursEnd['Tuesday'],
      );
      request.fields['IsOffTuesday'] = _dayOff['Tuesday'].toString();
      request.fields['WednesdayStartTime'] = _formatTimeOfDay(
        _workingHoursStart['Wednesday'],
      );
      request.fields['WednesdayEndTime'] = _formatTimeOfDay(
        _workingHoursEnd['Wednesday'],
      );
      request.fields['IsOffWednesday'] = _dayOff['Wednesday'].toString();
      request.fields['ThursdayStartTime'] = _formatTimeOfDay(
        _workingHoursStart['Thursday'],
      );
      request.fields['ThursdayEndTime'] = _formatTimeOfDay(
        _workingHoursEnd['Thursday'],
      );
      request.fields['IsOffThursday'] = _dayOff['Thursday'].toString();
      request.fields['FridayStartTime'] = _formatTimeOfDay(
        _workingHoursStart['Friday'],
      );
      request.fields['FridayEndTime'] = _formatTimeOfDay(
        _workingHoursEnd['Friday'],
      );
      request.fields['IsOffFriday'] = _dayOff['Friday'].toString();
      request.fields['SaturdayStartTime'] = _formatTimeOfDay(
        _workingHoursStart['Saturday'],
      );
      request.fields['SaturdayEndTime'] = _formatTimeOfDay(
        _workingHoursEnd['Saturday'],
      );
      request.fields['IsOffSaturday'] = _dayOff['Saturday'].toString();
      request.fields['SundayStartTime'] = _formatTimeOfDay(
        _workingHoursStart['Sunday'],
      );
      request.fields['SundayEndTime'] = _formatTimeOfDay(
        _workingHoursEnd['Sunday'],
      );
      request.fields['IsOffSunday'] = _dayOff['Sunday'].toString();

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Working Hours Updated Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode} - $responseBody'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> fetchCompanyProfile() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://fixease.pk/api/CompanyProfile/ListCompanyProfile?CompanyId=${widget.companyID}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          companyIdController.text = data['companyId'].toString();
          companyNameController.text = data['companyName'] ?? '';
          phoneNumberController.text = data['phoneNumber'] ?? '';
          whatsappNumberController.text = data['whatsappNumber'] ?? '';
          companyAddressController.text = data['companyAddress'] ?? '';
          // Assign image URLs from the response
          profilePictureUrl = data['profilePicture'] ?? '';
          companyLogoUrl = data['companyLogo'] ?? '';
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load company profile')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  Future<void> pickImage(String type) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (type == 'profile') {
          newProfilePicture = File(pickedFile.path);
        } else {
          newCompanyLogo = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('https://fixease.pk/api/CompanyProfile/UpdateCompanyProfile'),
      );

      request.headers.addAll({
        'accept': '*/*',
        'Content-Type': 'multipart/form-data',
      });

      // Add form fields
      request.fields['CompanyId'] = widget.companyID.toString();
      request.fields['UserId'] = widget.userID.toString();
      request.fields['CompanyName'] = companyNameController.text;
      request.fields['CompanyAddress'] = companyAddressController.text;
      request.fields['WhatsappNumber'] = whatsappNumberController.text;
      request.fields['PhoneNumber'] = phoneNumberController.text;

      // Add new images if selected
      if (newProfilePicture != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'ProfilePicture',
            newProfilePicture!.path,
          ),
        );
      }

      if (newCompanyLogo != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'CompanyLogo',
            newCompanyLogo!.path,
          ),
        );
      }

      var response = await request.send();
      // var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company Profile Updated Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Make sure to upload the pictures above '),
            backgroundColor: Colors.red,
          ),
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

  Widget buildImageWidget(String type) {
    String? imageUrl = type == 'profile' ? profilePictureUrl : companyLogoUrl;
    File? newImage = type == 'profile' ? newProfilePicture : newCompanyLogo;

    return Column(
      children: [
        GestureDetector(
          onTap: () => pickImage(type),
          child: CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey[300],
            backgroundImage:
                newImage != null
                    ? FileImage(newImage)
                    : (imageUrl != null && imageUrl.isNotEmpty
                        ? NetworkImage('https://fixease.pk/$imageUrl')
                        : null),
            child:
                (newImage == null && (imageUrl == null || imageUrl.isEmpty))
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600])
                    : null,
          ),
        ),
        SizedBox(height: 8),
        Text(
          newImage == null
              ? (imageUrl == null || imageUrl.isEmpty
                  ? 'Tap to add $type image'
                  : 'Tap to change $type image')
              : 'Tap to change $type image',
          style: TextStyle(color: Colors.grey[600], fontSize: 10),
        ),
        if (newImage != null)
          TextButton(
            onPressed:
                () => setState(() {
                  if (type == 'profile') {
                    newProfilePicture = null;
                  } else {
                    newCompanyLogo = null;
                  }
                }),
            child: Text("Remove Image", style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Company Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Center(child: buildImageWidget('profile')),
                          SizedBox(height: 20),
                          Center(child: buildImageWidget('company')),
                        ],
                      ),

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
                      Center(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Updating Profile...'),
                                    ],
                                  )
                                  : Text('Update Profile'),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
                      'Set your working hours for each day or mark days as off',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    ..._buildWorkingHoursRows(),
                    SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _updateWorkingHours,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Updating Working Hours...'),
                                  ],
                                )
                                : Text('Update Working Hours'),
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
