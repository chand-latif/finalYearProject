import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fix_easy/theme.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchResult {
  final Location location;
  final String formattedAddress;
  SearchResult(this.location, this.formattedAddress);
}

class UpdateBookingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onUpdate;

  const UpdateBookingScreen({Key? key, required this.booking, this.onUpdate})
    : super(key: key);

  @override
  State<UpdateBookingScreen> createState() => _UpdateBookingScreenState();
}

class _UpdateBookingScreenState extends State<UpdateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final searchController = TextEditingController();
  final phoneController = TextEditingController();

  DateTime? proposedTime;
  List<File> issueImages = [];
  List<String> existingImages = [];
  bool isLoading = false;
  bool showSearchResults = false;
  bool isSearching = false;
  double? pickedLat;
  double? pickedLng;
  String? selectedAddress;
  List<SearchResult> searchResults = [];
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize with existing booking data
    descriptionController.text = widget.booking['description'] ?? '';
    phoneController.text = widget.booking['contactNumber'] ?? '';
    locationController.text = widget.booking['address'] ?? '';
    selectedAddress = widget.booking['address'];

    // Initialize location data
    if (widget.booking['latitude'] != null &&
        widget.booking['longitude'] != null) {
      pickedLat = double.tryParse(widget.booking['latitude'].toString());
      pickedLng = double.tryParse(widget.booking['longitude'].toString());
    }

    // Initialize proposed time
    if (widget.booking['customerProposedTime'] != null) {
      proposedTime = DateTime.parse(widget.booking['customerProposedTime']);
    }

    // Initialize existing images
    if (widget.booking['issuedImages'] != null) {
      existingImages = List<String>.from(widget.booking['serviceImage']);
    }
  }

  Future<void> updateBooking() async {
    if (!_formKey.currentState!.validate() || proposedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token found');

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('https://fixease.pk/api/BookingService/updateServiceBooking'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'accept': '*/*',
      });

      // Update field names to match API requirements
      request.fields.addAll({
        'BookingId': widget.booking['bookingId'].toString(),
        'ServiceId': widget.booking['serviceId'].toString(),
        'Description': descriptionController.text,
        'Location': selectedAddress ?? widget.booking['address'],
        'Latitude': (pickedLat ?? widget.booking['latitude'])?.toString() ?? '',
        'Longitude':
            (pickedLng ?? widget.booking['longitude'])?.toString() ?? '',
        'ProposedTime': proposedTime!.toIso8601String(),
        'PhoneNumber': phoneController.text,
      });

      // Add new images if any
      for (var image in issueImages) {
        request.files.add(
          await http.MultipartFile.fromPath('IssuedImages', image.path),
        );
      }

      print('Sending update request with fields: ${request.fields}');

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (widget.onUpdate != null) widget.onUpdate!();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
          jsonDecode(responseBody)['message'] ?? 'Failed to update booking',
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

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        issueImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> removeImage(int index) {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remove Image'),
            content: Text('Are you sure you want to remove this image?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    issueImages.removeAt(index);
                  });
                  Navigator.pop(context);
                },
                child: Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> searchLocation(String query) async {
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
            displayAddress =
                '${place.street}, ${place.locality}, ${place.administrativeArea}';
          }
        } catch (e) {
          print('Error getting place details: $e');
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

  Future<void> selectLocation(SearchResult result) async {
    setState(() {
      pickedLat = result.location.latitude;
      pickedLng = result.location.longitude;
      selectedAddress = result.formattedAddress;
      locationController.text = result.formattedAddress;
      showSearchResults = false;
      searchController.clear();
    });
  }

  // Update the buildAddressSearchSection to match BookServiceScreen
  Widget buildAddressSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: 'Search Location',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) => searchLocation(value),
        ),
        SizedBox(height: 8),
        if (showSearchResults)
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final result = searchResults[index];
                return ListTile(
                  title: Text(result.formattedAddress),
                  onTap: () => selectLocation(result),
                );
              },
            ),
          ),
        if (selectedAddress != null && !showSearchResults)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Selected Location: $selectedAddress',
              style: TextStyle(color: Colors.green),
            ),
          ),
      ],
    );
  }

  // Update the buildImageSection to show both existing and new images
  Widget buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Issue Images',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        // Existing Images
        if (existingImages.isNotEmpty) ...[
          Text(
            'Current Images:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: existingImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Image.network(
                    'https://fixease.pk${existingImages[index]}',
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
        ],
        // New Images
        Text(
          'Add New Images:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add Image Button
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, color: Colors.grey),
                      Text('Add Image', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),
              // New Images
              ...issueImages.asMap().entries.map((entry) {
                int idx = entry.key;
                File image = entry.value;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Image.file(
                        image,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => removeImage(idx),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Update Booking'),
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
              // Booking Details Card
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
                        'Booking Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: _buildInputDecoration(
                          'Issue Description',
                          Icons.description,
                        ),
                        maxLines: 3,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          'Phone Number (11 digits)',
                          Icons.phone,
                        ),
                        maxLength: 11,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Phone number required';
                          if (!RegExp(r'^\d{11}$').hasMatch(value))
                            return 'Enter exactly 11 digits';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      buildAddressSearchSection(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Date & Time Card
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
                        'Preferred Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: proposedTime ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 30)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                proposedTime ?? DateTime.now(),
                              ),
                            );
                            if (time != null) {
                              setState(() {
                                proposedTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                proposedTime != null
                                    ? '${proposedTime!.day}/${proposedTime!.month}/${proposedTime!.year} ${proposedTime!.hour}:${proposedTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Select date and time',
                                style: TextStyle(
                                  color:
                                      proposedTime == null
                                          ? Colors.grey
                                          : Colors.black,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Image Upload Card
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: buildImageSection(),
                ),
              ),
              SizedBox(height: 24),

              // Update Button
              ElevatedButton(
                onPressed: isLoading ? null : updateBooking,
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
                            Text('Updating Booking...'),
                          ],
                        )
                        : Text('Update Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.black54),
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    locationController.dispose();
    searchController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
