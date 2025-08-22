import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fix_easy/theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  // Add these variables
  String currentAvailabilityStatus = 'Available';
  bool isUpdatingStatus = false;

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
      bool isOff = _dayOff[day] ?? false;
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
                              isOff
                                  ? null
                                  : () async {
                                    final TimeOfDay? picked =
                                        await showTimePicker(
                                          context: context,
                                          initialTime:
                                              _workingHoursStart[day] ??
                                              TimeOfDay(hour: 9, minute: 0),
                                        );
                                    if (picked != null &&
                                        picked != _workingHoursStart[day]) {
                                      setState(
                                        () => _workingHoursStart[day] = picked,
                                      );
                                    }
                                  },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            side: BorderSide(
                              color:
                                  isOff
                                      ? Colors.grey.shade300
                                      : AppColors.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _workingHoursStart[day] == null
                                ? '--:--'
                                : '${_workingHoursStart[day]!.hour.toString().padLeft(2, '0')}:${_workingHoursStart[day]!.minute.toString().padLeft(2, '0')}',
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
                              isOff
                                  ? null
                                  : () async {
                                    final TimeOfDay? picked =
                                        await showTimePicker(
                                          context: context,
                                          initialTime:
                                              _workingHoursEnd[day] ??
                                              TimeOfDay(hour: 17, minute: 0),
                                        );
                                    if (picked != null &&
                                        picked != _workingHoursEnd[day]) {
                                      setState(
                                        () => _workingHoursEnd[day] = picked,
                                      );
                                    }
                                  },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            side: BorderSide(
                              color:
                                  isOff
                                      ? Colors.grey.shade300
                                      : AppColors.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _workingHoursEnd[day] == null
                                ? '--:--'
                                : '${_workingHoursEnd[day]!.hour.toString().padLeft(2, '0')}:${_workingHoursEnd[day]!.minute.toString().padLeft(2, '0')}',
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
                              _dayOff[day] = value;
                              if (value) {
                                _workingHoursStart[day] = null;
                                _workingHoursEnd[day] = null;
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
          if (day != _dayOff.keys.last) Divider(height: 1),
        ],
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

      // Fix: Make sure Monday's state is being sent correctly
      request.fields.addAll({
        'CompanyId': widget.companyID.toString(),
        'IsOffMonday':
            _dayOff['Monday']!
                .toString()
                .toLowerCase(), // Fix: Add .toLowerCase()
        'MondayStartTime': _formatTimeOfDay(_workingHoursStart['Monday']),
        'MondayEndTime': _formatTimeOfDay(_workingHoursEnd['Monday']),
        'IsOffTuesday': _dayOff['Tuesday'].toString(),
        'TuesdayStartTime': _formatTimeOfDay(_workingHoursStart['Tuesday']),
        'TuesdayEndTime': _formatTimeOfDay(_workingHoursEnd['Tuesday']),
        'IsOffWednesday': _dayOff['Wednesday'].toString(),
        'WednesdayStartTime': _formatTimeOfDay(_workingHoursStart['Wednesday']),
        'WednesdayEndTime': _formatTimeOfDay(_workingHoursEnd['Wednesday']),
        'IsOffThursday': _dayOff['Thursday'].toString(),
        'ThursdayStartTime': _formatTimeOfDay(_workingHoursStart['Thursday']),
        'ThursdayEndTime': _formatTimeOfDay(_workingHoursEnd['Thursday']),
        'IsOffFriday': _dayOff['Friday'].toString(),
        'FridayStartTime': _formatTimeOfDay(_workingHoursStart['Friday']),
        'FridayEndTime': _formatTimeOfDay(_workingHoursEnd['Friday']),
        'IsOffSaturday': _dayOff['Saturday'].toString(),
        'SaturdayStartTime': _formatTimeOfDay(_workingHoursStart['Saturday']),
        'SaturdayEndTime': _formatTimeOfDay(_workingHoursEnd['Saturday']),
        'IsOffSunday': _dayOff['Sunday'].toString(),
        'SundayStartTime': _formatTimeOfDay(_workingHoursStart['Sunday']),
        'SundayEndTime': _formatTimeOfDay(_workingHoursEnd['Sunday']),
      });

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Working Hours Updated Successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Add: Notify the profile page to refresh
        Navigator.pop(context, true);
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
          // Set initial status
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

  Future<void> updateAvailabilityStatus(String status) async {
    setState(() {
      isUpdatingStatus = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
          'https://fixease.pk/api/CompanyProfile/UpdateAvailabilityStatus',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'companyId': widget.companyID}),
      );

      if (response.statusCode == 200) {
        setState(() {
          currentAvailabilityStatus = status;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated successfully')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    } finally {
      setState(() {
        isUpdatingStatus = false;
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Update Company Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
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
                        Column(children: [buildImageWidget('profile')]),
                        Column(children: [buildImageWidget('company')]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Company Information Form
            Form(
              key: _formKey,
              child: Card(
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
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Please enter phone number'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: whatsappNumberController,
                        decoration: _buildInputDecoration(
                          'WhatsApp Number',
                          FontAwesomeIcons.whatsapp,
                        ),
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
            ),
            SizedBox(height: 16),

            // Working Hours Card with Update Button
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
                          'Working Hours',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _updateWorkingHours,
                          icon: Icon(Icons.save, size: 18),
                          label: Text('Save Hours'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Set working hours or mark days as off',
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
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Center(child: Text('Start')),
                                    ),
                                    SizedBox(width: 40),
                                    Expanded(child: Center(child: Text('End'))),
                                    SizedBox(width: 48),
                                    Text('Off'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(thickness: 1),
                        ..._buildWorkingHoursRows(),
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
                          Text('Updating Profile...'),
                        ],
                      )
                      : Text('Update Profile Information'),
            ),
          ],
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
    companyIdController.dispose();
    companyNameController.dispose();
    phoneNumberController.dispose();
    whatsappNumberController.dispose();
    companyAddressController.dispose();
    super.dispose();
  }
}
