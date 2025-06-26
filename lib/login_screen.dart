import 'package:fix_easy/customer_home.dart';
import 'package:fix_easy/theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'verfication_OTP.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_easy/create_company_profile.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  //fetch jwt token
  Future<void> fetchUserInfoAndNavigate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token not found. Please log in again.')),
      );
      return;
    }

    final response = await http.get(
      Uri.parse("https://fixease.pk/api/User/GetUserInformation"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userType = data['data']['userType'];

      if (userType == 'Customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerHome()),
        );
      } else if (userType == 'Seller') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    CreateCompanyProfileScreen(userID: data['data']['userId']),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch user info')));
    }
  }

  Future<void> sendOTP(String email) async {
    final url = Uri.parse(
      "https://fixease.pk/api/User/ResendVerificationOTP?Email=$email",
    );

    final body = {"email": email};

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        // Handle error if OTP sending fails
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to send OTP")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error sending OTP")));
    }
  }

  Future<void> signInUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var url = Uri.parse('https://fixease.pk/api/User/SignIn');

      var response = await http.post(
        url,
        headers: {'accept': '*/*', 'Content-Type': 'application/json'},
        body: jsonEncode({
          "userEmail": emailController.text.trim(),
          "password": passwordController.text.trim(),
        }),
      );

      // var responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        // Check if login failed with message
        if (response.statusCode == 200) {
          if (responseData['statusCode'] == 400) {
            final message = responseData['message'] ?? "Something went wrong";

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));

            // Check for unverified account
            if (message == "Account UnVerified !!") {
              await sendOTP(emailController.text.trim());

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          VerificationOTP(email: emailController.text.trim()),
                ),
              );
            }

            return;
          }

          //access token now
          final token =
              responseData['data']?['jwtAccessToken']?['access_Token'];

          if (token == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Login failed: token missing")),
            );
            return;
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);

          await fetchUserInfoAndNavigate(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server Error! Try again later.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email'),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      Text('Password'),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/ForgotPassword');
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                    if (_formKey.currentState!.validate()) {
                                      signInUser();
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Sign In',
                                    style: TextStyle(fontSize: 18),
                                  ),
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/customerHome');
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/google.png',
                                width: 20,
                                height: 20,
                              ),
                              SizedBox(width: 10),
                              Text('Login with Google'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/facebook.png',
                                width: 20,
                                height: 20,
                              ),
                              SizedBox(width: 10),
                              Text('Login with Facebook'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Don\'t have an account?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/accountType');
                            },
                            child: Text('Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
