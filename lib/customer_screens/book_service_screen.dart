import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_easy/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  final phoneController = TextEditingController();
  DateTime? proposedTime;
  List<File> issueImages = [];
  bool isLoading = false;
  bool showSearchResults = false;
  bool isSearching = false;
  double? pickedLat;
  double? pickedLng;
  String? selectedAddress;
  List<SearchResult> searchResults = [];
  final picker = ImagePicker();

  // Function to copy and save image to a permanent location
  Future<File> saveImagePermanently(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(imagePath);
      final savedImage = File('${directory.path}/$fileName');

      // Copy the file to permanent location
      final originalFile = File(imagePath);
      await originalFile.copy(savedImage.path);

      return savedImage;
    } catch (e) {
      print('Error saving image: $e');
      return File(imagePath);
    }
  }

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
                    await captureFromCamera();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await pickFromGallery();
                  },
                ),
                // ListTile(
                //   leading: Icon(Icons.photo_camera, color: AppColors.primary),
                //   title: Text('Take Multiple Photos'),
                //   onTap: () async {
                //     Navigator.pop(context);
                //     await captureMultiplePhotos();
                //   },
                // ),
              ],
            ),
          ),
    );
  }

  Future<void> captureFromCamera() async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress image to reduce size
        maxWidth: 1920, // Limit max width
        maxHeight: 1080, // Limit max height
      );

      if (pickedFile != null) {
        // Save image to permanent location
        final savedImage = await saveImagePermanently(pickedFile.path);

        setState(() {
          issueImages.add(savedImage);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo captured successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error capturing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        imageQuality: 85, // Compress images
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFiles.isNotEmpty) {
        List<File> newImages = [];
        for (XFile file in pickedFiles) {
          // Save each image to permanent location
          final savedImage = await saveImagePermanently(file.path);
          newImages.add(savedImage);
        }

        setState(() {
          issueImages.addAll(newImages);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pickedFiles.length} image(s) added'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Future<void> captureMultiplePhotos() async {
  //   int photosCount = 0;
  //   bool continueCapturing = true;

  //   while (continueCapturing) {
  //     try {
  //       final XFile? pickedFile = await picker.pickImage(
  //         source: ImageSource.camera,
  //         imageQuality: 85,
  //         maxWidth: 1920,
  //         maxHeight: 1080,
  //       );

  //       if (pickedFile != null) {
  //         // Save image to permanent location
  //         final savedImage = await saveImagePermanently(pickedFile.path);

  //         setState(() {
  //           issueImages.add(savedImage);
  //           photosCount++;
  //         });

  //         // Ask if user wants to capture more
  //         continueCapturing =
  //             await showDialog<bool>(
  //               context: context,
  //               builder: (BuildContext context) {
  //                 return AlertDialog(
  //                   title: Text('Photo Captured'),
  //                   content: Text(
  //                     '$photosCount photo(s) captured. Take another?',
  //                   ),
  //                   actions: [
  //                     TextButton(
  //                       onPressed: () => Navigator.pop(context, false),
  //                       child: Text('Done'),
  //                     ),
  //                     ElevatedButton(
  //                       onPressed: () => Navigator.pop(context, true),
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: AppColors.primary,
  //                       ),
  //                       child: Text(
  //                         'Take Another',
  //                         style: TextStyle(color: Colors.white),
  //                       ),
  //                     ),
  //                   ],
  //                 );
  //               },
  //             ) ??
  //             false;
  //       } else {
  //         continueCapturing = false;
  //       }
  //     } catch (e) {
  //       print('Error capturing photo: $e');
  //       continueCapturing = false;
  //     }
  //   }

  //   if (photosCount > 0) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('$photosCount photo(s) captured successfully'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   }
  // }

  void removeImage(int index) {
    setState(() {
      // Delete the file if it exists in app documents
      final file = issueImages[index];
      if (file.path.contains('Documents')) {
        file.deleteSync(recursive: false);
      }
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey[600],
                              ),
                            );
                          },
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
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
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

      // Create multipart request
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
        'PhoneNumber': phoneController.text,
      });

      // Add images with proper handling
      if (issueImages.isNotEmpty) {
        for (int i = 0; i < issueImages.length; i++) {
          try {
            final file = issueImages[i];

            // Check if file exists
            if (await file.exists()) {
              // Get file bytes
              final bytes = await file.readAsBytes();

              // Create multipart file from bytes
              final multipartFile = http.MultipartFile.fromBytes(
                'IssuedImages', // Field name matching API
                bytes,
                filename:
                    'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
              );

              request.files.add(multipartFile);

              print('Added image $i: ${multipartFile.filename}');
            } else {
              print('File does not exist: ${file.path}');
            }
          } catch (e) {
            print('Error adding image $i: $e');
          }
        }
      }

      // Send request
      print('Sending request with ${request.files.length} images');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear temporary images after successful upload
        for (var image in issueImages) {
          if (image.path.contains('Documents')) {
            try {
              await image.delete();
            } catch (e) {
              print('Error deleting temp file: $e');
            }
          }
        }

        Navigator.pushNamed(context, '/myBookings');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        var responseData = {};
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          print('Error parsing response: $e');
        }
        throw Exception(responseData['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      print('Error submitting booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    locationController.dispose();
    searchController.dispose();
    phoneController.dispose();
    super.dispose();
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
                      // Phone number field
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          'Phone Number (11 digits)',
                          Icons.phone,
                        ),
                        maxLength: 11,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number required';
                          }
                          if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                            return 'Enter exactly 11 digits';
                          }
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
                                proposedTime != null
                                    ? '${proposedTime!.day}/${proposedTime!.month}/${proposedTime!.year} ${proposedTime!.hour.toString().padLeft(2, '0')}:${proposedTime!.minute.toString().padLeft(2, '0')}'
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
