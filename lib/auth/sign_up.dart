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
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0), //test
          child: Column(
            spacing: 20,
            children: [
              Text(
                'Make your future bright with us!',
                style: TextStyle(fontSize: 20, color: AppColors.primary),
              ),
              Column(
                spacing: 10,
                children: [
                  Text(
                    'Create New Account',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 7,
                    children: [
                      Text('Full Name'),
                      TextField(
                        controller: nameController,
                        onChanged: validateName,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          hintText: 'Enter your full name',
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
                          ),
                          errorText: nameError,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 7,
                    children: [
                      Text('Email Address'),
                      TextField(
                        controller: emailController,
                        onChanged: validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          hintText: 'Enter your Email',
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
                          ),
                          errorText: emailError,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 7,
                    children: [
                      Text('Phone Number'),
                      TextField(
                        controller: phoneController,
                        onChanged: validatePhone,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          hintText: 'Enter your 11-digit number',
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
                          ),
                          errorText: phoneError,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 7,
                    children: [
                      Text('Password'),
                      TextField(
                        controller: passwordController,
                        onChanged: validatePassword,
                        obscureText: isObscurePassword,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              isObscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                isObscurePassword = !isObscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
                          ),
                          hintText: 'Enter your password',
                          errorText: passwordError,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 7,
                    children: [
                      Text('Confirm Password'),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: isObscureConfirmPassword,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              isObscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                isObscureConfirmPassword =
                                    !isObscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
                          ),
                          hintText: 'Confirm your password',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            if (isFormValid()) {
                              setState(() {
                                isLoading = true;
                              });

                              await signUpUser();

                              setState(() {
                                isLoading = false;
                              });
                            }
                          },
                  child:
                      isLoading
                          ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text('Sign Up', style: TextStyle(fontSize: 20)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/home');
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(color: AppColors.primary, fontSize: 15),
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
