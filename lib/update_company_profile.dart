// import 'dart:io';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:fix_easy/theme.dart';

// class UpdateCompanyProfileScreen extends StatefulWidget {
//   final int userID;
//   final int companyID;
//   const UpdateCompanyProfileScreen({
//     super.key,
//     required this.userID,
//     required this.companyID,
//   });

//   @override
//   _UpdateCompanyProfileScreenState createState() =>
//       _UpdateCompanyProfileScreenState();
// }

// class _UpdateCompanyProfileScreenState
//     extends State<UpdateCompanyProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final picker = ImagePicker();

//   // Controllers
//   final companyIdController = TextEditingController(text: '0');
//   final companyNameController = TextEditingController();
//   final phoneNumberController = TextEditingController();
//   final whatsappNumberController = TextEditingController();
//   final companyAddressController = TextEditingController();

//   File? profilePicture;
//   File? companyLogo;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchCompanyProfile();
//   }

//   Future<void> fetchCompanyProfile() async {
//     try {
//       final response = await http.get(
//         Uri.parse(
//           'https://fixease.pk/api/CompanyProfile/ListCompanyProfile?CompanyId=${widget.companyID}',
//         ),
//       );
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body)['data'];
//         setState(() {
//           companyIdController.text = data['companyId'].toString();
//           companyNameController.text = data['companyName'] ?? '';
//           phoneNumberController.text = data['phoneNumber'] ?? '';
//           whatsappNumberController.text = data['whatsappNumber'] ?? '';
//           companyAddressController.text = data['companyAddress'] ?? '';
//           // Note: Image fetching is not implemented as it requires file handling from URLs
//           isLoading = false;
//         });
//       } else {
//         // if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load company profile')),
//         );
//       }
//     } catch (e) {
//       // if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Network error: $e')));
//     }
//   }

//   Future<void> pickImage(String type) async {
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         if (type == 'profile') {
//           profilePicture = File(pickedFile.path);
//         } else {
//           companyLogo = File(pickedFile.path);
//         }
//       });
//     }
//   }

//   Future<void> submitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please fill all required fields')),
//       );
//       return;
//     }

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       var request = http.MultipartRequest(
//         'PUT',
//         Uri.parse(
//           'https://fixease.pk/api/CompanyProfile/UpdateCompanyProfile?CompanyId=${widget.companyID}&UserId=${widget.userID}&CompanyName=${Uri.encodeComponent(companyNameController.text)}&CompanyAddress=${Uri.encodeComponent(companyAddressController.text)}&WhatsappNumber=${Uri.encodeComponent(whatsappNumberController.text)}&PhoneNumber=${Uri.encodeComponent(phoneNumberController.text)}',
//         ),
//       );

//       request.headers.addAll({
//         'accept': '*/*',
//         'Content-Type': 'multipart/form-data',
//       });

//       if (profilePicture != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath(
//             'ProfilePicture',
//             profilePicture!.path,
//           ),
//         );
//       }
//       if (companyLogo != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath('CompanyLogo', companyLogo!.path),
//         );
//       }

//       var response = await request.send();
//       var responseBody = await response.stream.bytesToString();

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Company Profile Updated Successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${response.statusCode} - $responseBody'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       // ignore: use_build_context_synchronously
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Network error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Widget buildImageWidget(String type) {
//     File? image = type == 'profile' ? profilePicture : companyLogo;
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: () => pickImage(type),
//           child: CircleAvatar(
//             radius: 60,
//             backgroundColor: Colors.grey[300],
//             backgroundImage: image != null ? FileImage(image) : null,
//             child:
//                 image == null
//                     ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600])
//                     : null,
//           ),
//         ),
//         SizedBox(height: 8),
//         Text(
//           image == null
//               ? 'Tap to add $type image'
//               : 'Tap to change $type image',
//           style: TextStyle(color: Colors.grey[600], fontSize: 12),
//         ),
//         if (image != null)
//           TextButton(
//             onPressed:
//                 () => setState(() {
//                   if (type == 'profile') {
//                     profilePicture = null;
//                   } else {
//                     companyLogo = null;
//                   }
//                 }),
//             child: Text("Remove Image", style: TextStyle(color: Colors.red)),
//           ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Update Company Profile'),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//       ),
//       body:
//           isLoading
//               ? Center(child: CircularProgressIndicator())
//               : SingleChildScrollView(
//                 padding: EdgeInsets.all(16),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Center(child: buildImageWidget('profile')),
//                       SizedBox(height: 20),
//                       Center(child: buildImageWidget('company')),
//                       SizedBox(height: 20),
//                       TextFormField(
//                         controller: companyNameController,
//                         decoration: InputDecoration(
//                           labelText: 'Company Name *',
//                           border: OutlineInputBorder(),
//                           focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: AppColors.primary),
//                           ),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter company name';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 16),
//                       TextFormField(
//                         controller: phoneNumberController,
//                         decoration: InputDecoration(
//                           labelText: 'Phone Number *',
//                           border: OutlineInputBorder(),
//                           focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: AppColors.primary),
//                           ),
//                         ),
//                         keyboardType: TextInputType.phone,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter phone number';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 16),
//                       TextFormField(
//                         controller: whatsappNumberController,
//                         decoration: InputDecoration(
//                           labelText: 'WhatsApp Number *',
//                           border: OutlineInputBorder(),
//                           focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: AppColors.primary),
//                           ),
//                         ),
//                         keyboardType: TextInputType.phone,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter WhatsApp number';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 16),
//                       TextFormField(
//                         controller: companyAddressController,
//                         decoration: InputDecoration(
//                           labelText: 'Company Address *',
//                           border: OutlineInputBorder(),
//                           focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: AppColors.primary),
//                           ),
//                         ),
//                         maxLines: 2,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter company address';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 24),
//                       Center(
//                         child: ElevatedButton(
//                           onPressed: isLoading ? null : submitForm,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.primary,
//                             foregroundColor: Colors.white,
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 32,
//                               vertical: 16,
//                             ),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child:
//                               isLoading
//                                   ? Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       SizedBox(
//                                         width: 20,
//                                         height: 20,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           valueColor:
//                                               AlwaysStoppedAnimation<Color>(
//                                                 Colors.white,
//                                               ),
//                                         ),
//                                       ),
//                                       SizedBox(width: 12),
//                                       Text('Updating Profile...'),
//                                     ],
//                                   )
//                                   : Text('Update Profile'),
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//     );
//   }

//   @override
//   void dispose() {
//     companyIdController.dispose();
//     companyNameController.dispose();
//     phoneNumberController.dispose();
//     whatsappNumberController.dispose();
//     companyAddressController.dispose();
//     super.dispose();
//   }
// }

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

  @override
  void initState() {
    super.initState();
    fetchCompanyProfile();
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
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company Profile Updated Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
            radius: 60,
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
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: buildImageWidget('profile')),
                      SizedBox(height: 20),
                      Center(child: buildImageWidget('company')),
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
