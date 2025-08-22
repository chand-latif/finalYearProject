import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_easy/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

// Custom class to hold location and formatted address
class SearchResult {
  final Location location;
  final String formattedAddress;
  SearchResult(this.location, this.formattedAddress);
}

class BookServiceScreen extends StatefulWidget {
  final int serviceId;
  const BookServiceScreen({Key? key, required this.serviceId})
    : super(key: key);

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final searchController = TextEditingController();
  DateTime? proposedTime;
  List<File> issueImages = []; // Changed from single File to List<File>
  bool isLoading = false;
  bool showSearchResults = false;
  bool isSearching = false;
  double? pickedLat;
  double? pickedLng;
  String? selectedAddress;
  List<SearchResult> searchResults = [];
  final picker = ImagePicker();

  Future<void> pickImages() async {
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
                        issueImages.add(File(pickedFile.path));
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFiles = await picker.pickMultipleMedia();
                    if (pickedFiles.isNotEmpty) {
                      setState(() {
                        issueImages.addAll(
                          pickedFiles.map((file) => File(file.path)),
                        );
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera, color: AppColors.primary),
                  title: Text('Take Multiple Photos'),
                  onTap: () async {
                    Navigator.pop(context);
                    _showMultipleCameraDialog();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showMultipleCameraDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Take Multiple Photos'),
          content: Text('Keep taking photos. Press "Done" when finished.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pickedFile = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (pickedFile != null) {
                  setState(() {
                    issueImages.add(File(pickedFile.path));
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text('Take Photo', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void removeImage(int index) {
    setState(() {
      issueImages.removeAt(index);
    });
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
      locationController.text = searchResult.formattedAddress;
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
            Future.delayed(Duration(milliseconds: 500), () {
              if (searchController.text == value) {
                searchAddress(value);
              }
            });
          },
          onFieldSubmitted: searchAddress,
        ),
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
        TextFormField(
          controller: locationController,
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
                      locationController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Issue Images (${issueImages.length})',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        // Add Images Button
        GestureDetector(
          onTap: pickImages,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 40,
                  color: AppColors.primary,
                ),
                SizedBox(height: 8),
                Text(
                  'Add Images',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '(Optional)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // Display Selected Images
        if (issueImages.isNotEmpty) ...[
          SizedBox(height: 16),
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: issueImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          issueImages[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => removeImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: EdgeInsets.all(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> submitBooking() async {
    if (!_formKey.currentState!.validate() || proposedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No auth token found');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://fixease.pk/api/BookingService/CreateServiceBooking'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'accept': '*/*',
      });

      // Add form fields
      request.fields.addAll({
        'ServiceId': widget.serviceId.toString(),
        'Description': descriptionController.text,
        'Location': selectedAddress!,
        'Latitude': pickedLat.toString(),
        'Longitude': pickedLng.toString(),
        'ProposedTime': proposedTime!.toIso8601String(),
      });

      // Add multiple images if selected
      for (int i = 0; i < issueImages.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'IssuedImages',
            issueImages[i].path,
          ),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var responseData = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        Navigator.pushNamed(context, '/myBookings');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigator.pop(context, true);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to create booking');
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
        title: Text('Book Service'),
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
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 30)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
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
                                proposedTime?.toString() ??
                                    'Select date and time',
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

              // Submit Button
              ElevatedButton(
                onPressed: isLoading ? null : submitBooking,
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
                            Text('Booking Service...'),
                          ],
                        )
                        : Text('Book Service'),
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
}
