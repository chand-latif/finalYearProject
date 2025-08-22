import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'package:http/http.dart' as http;
import '../verfication_otp.dart';
// import 'package:http/io_client.dart';
// import 'dart:io';

class SignUp extends StatefulWidget {
  final String accountType;
  const SignUp({super.key, required this.accountType});

  @override
  State<SignUp> createState() => _SignUpState();
}

final TextEditingController nameController = TextEditingController();
final TextEditingController emailController = TextEditingController();
final TextEditingController phoneController = TextEditingController();
final TextEditingController passwordController = TextEditingController();
final TextEditingController confirmPasswordController = TextEditingController();

class _SignUpState extends State<SignUp> {
  bool isLoading = false;
  bool isObscurePassword = true;
  bool isObscureConfirmPassword = true;

  // Add validation state variables
  String? emailError;
  String? phoneError;
  String? passwordError;
  String? nameError;

  // Email validation
  void validateEmail(String email) {
    RegExp emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    setState(() {
      if (email.isEmpty) {
        emailError = 'Email is required';
      } else if (!emailRegex.hasMatch(email)) {
        emailError = 'Enter a valid email';
      } else {
        emailError = null;
      }
    });
  }

  // Phone validation
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

  // Password validation
  void validatePassword(String password) {
    setState(() {
      if (password.isEmpty) {
        passwordError = 'Password is required';
      } else if (password.length < 6) {
        passwordError = 'Password must be at least 6 characters';
      } else {
        passwordError = null;
      }
    });
  }

  // Name validation
  void validateName(String name) {
    setState(() {
      if (name.isEmpty) {
        nameError = 'Name is required';
      } else {
        nameError = null;
      }
    });
  }

  bool isFormValid() {
    validateName(nameController.text);
    validateEmail(emailController.text);
    validatePhone(phoneController.text);
    validatePassword(passwordController.text);

    return nameError == null &&
        emailError == null &&
        phoneError == null &&
        passwordError == null &&
        passwordController.text == confirmPasswordController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Welcome Card
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Make your future bright with us!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create New Account',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Form Card
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
                      _buildInputField(
                        'Full Name',
                        nameController,
                        Icons.person,
                        validateName,
                        nameError,
                      ),
                      SizedBox(height: 16),
                      _buildInputField(
                        'Email Address',
                        emailController,
                        Icons.email,
                        validateEmail,
                        emailError,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),
                      _buildInputField(
                        'Phone Number',
                        phoneController,
                        Icons.phone,
                        validatePhone,
                        phoneError,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildPasswordField(
                        'Password',
                        passwordController,
                        isObscurePassword,
                        (value) {
                          setState(
                            () => isObscurePassword = !isObscurePassword,
                          );
                        },
                        validatePassword,
                        passwordError,
                      ),
                      SizedBox(height: 16),
                      _buildPasswordField(
                        'Confirm Password',
                        confirmPasswordController,
                        isObscureConfirmPassword,
                        (value) {
                          setState(
                            () =>
                                isObscureConfirmPassword =
                                    !isObscureConfirmPassword,
                          );
                        },
                        null,
                        null,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    isLoading
                        ? null
                        : () async {
                          if (isFormValid()) {
                            setState(() => isLoading = true);
                            await signUpUser();
                            setState(() => isLoading = false);
                          }
                        },
                child:
                    isLoading
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating Account...'),
                          ],
                        )
                        : Text('Sign Up', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(height: 16),

              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?'),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    Function(String)? onChanged,
    String? errorText, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: 'Enter your ${label.toLowerCase()}', // Add hint text
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
            errorText: errorText,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isObscure,
    Function(bool) onToggle,
    Function(String)? onChanged,
    String? errorText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText:
                label == 'Password'
                    ? 'Enter your password'
                    : 'Re-enter your password', // Add contextual hint text
            prefixIcon: Icon(Icons.lock, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () => onToggle(!isObscure),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            errorText: errorText,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // HttpClient _getHttpClient() {
  //   final httpClient =
  //       HttpClient()
  //         ..badCertificateCallback =
  //             (X509Certificate cert, String host, int port) => true;
  //   return httpClient;
  // }

  // void navigateBasedOnAccountType(String accountType) {
  //   if (accountType == 'seller') {
  //     Navigator.pushNamed(context, 'createCompanyProfile');

  //   } else if (accountType == 'customer') {
  //     Navigator.pushNamed(context, 'createCompanyProfile');
  //   } else {
  //     // Default or unknown type
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Invalid account type')));
  //   }
  // }

  Future<void> signUpUser() async {
    final url = Uri.parse("https://fixease.pk/api/User/SignUP");

    final body = {
      "userEmail": emailController.text,
      "password": passwordController.text,
      "username": nameController.text,
      "phoneNo": phoneController.text,
      "userType": widget.accountType.toString(),
    };

    try {
      // final IOClient ioClient = IOClient(_getHttpClient());
      // final response = await ioClient.post(
      //   url,
      //   headers: {"Content-Type": "application/json"},
      //   body: jsonEncode(body),
      // );
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData["statusCode"] == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User registered successfully")));

        await sendOtp(emailController.text);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationOTP(email: emailController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData["message"] ?? "Registration failed"),
          ),
        );
      }
    } catch (e) {
      print("Signup error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Something went wrong: $e")));
    }
  }

  // Future<void> signUpUser() async {
  //   final url = Uri.parse("https://fixease.pk/api/User/SignUP");

  //   final body = {
  //     "userEmail": emailController.text,
  //     "password": passwordController.text,
  //     "phoneNo": phoneController.text,
  //     "userType": "customer",
  //   };

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode(body),
  //     );

  //     final responseData = jsonDecode(response.body);
  //     if (response.statusCode == 200) {
  //       if (responseData["statusCode"] == 200) {
  //         // User registered
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text("User registered successfully")),
  //         );
  //         // Now send OTP
  //         await sendOtp(emailController.text);

  //         // Navigate to VerificationOTP screen manually with email
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder:
  //                 (context) => VerificationOTP(email: emailController.text),
  //           ),
  //         );
  //       } else {
  //         // Already exists or error
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text(responseData["message"] ?? "Error")),
  //         );
  //       }
  //     } else {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text("Server error")));
  //     }
  //   } catch (e) {
  //     print("Signup error: $e");
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Something went wrong: $e")));
  //   }
  // }

  Future<void> sendOtp(String email) async {
    final url = Uri.parse("https://fixease.pk/api/User/ResendVerificationOTP");

    final body = {"email": email};

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // OTP sent successfully
        print("OTP sent to $email");
      } else {
        print(
          "Failed to send OTP: ${responseData["message"] ?? "Unknown error"}",
        );
      }
    } catch (e) {
      print("Error sending OTP: $e");
    }
  }
}
// }

Future<void> sendOtp(String email) async {
  final url = Uri.parse("https://fixease.pk/api/User/ResendVerificationOTP");

  final body = {"email": email};

  try {
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // OTP sent successfully
      print("OTP sent to $email");
    } else {
      print(
        "Failed to send OTP: ${responseData["message"] ?? "Unknown error"}",
      );
    }
  } catch (e) {
    print("Error sending OTP: $e");
  }
}
