import 'dart:convert';

import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:http/http.dart' as http;
import 'verfication_otp.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

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
                          hintText: 'Enter your phone number',
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
                          ),
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
                            if (passwordController.text ==
                                confirmPasswordController.text) {
                              setState(() {
                                isLoading = true;
                              });

                              await signUpUser();

                              setState(() {
                                isLoading = false;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Passwords do not match"),
                                ),
                              );
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

  Future<void> signUpUser() async {
    final url = Uri.parse(
      "https://fixease20250417083804-e3gnb3ejfrbvames.eastasia-01.azurewebsites.net/api/User/SignUP",
    );

    final body = {
      "userEmail": emailController.text,
      "password": passwordController.text,
      "phoneNo": phoneController.text,
      "userType": 0,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (responseData["statusCode"] == 200) {
        // User registered
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User registered successfully")));
        // Now send OTP
        await sendOtp(emailController.text);

        // Navigate to VerificationOTP screen manually with email
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationOTP(email: emailController.text),
          ),
        );
      } else {
        // Already exists or error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData["message"] ?? "Error")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Something went wrong")));
    }
  }

  Future<void> sendOtp(String email) async {
    final url = Uri.parse(
      "https://fixease20250417083804-e3gnb3ejfrbvames.eastasia-01.azurewebsites.net/api/User/ResendVerificationOTP",
    );

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
