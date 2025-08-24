import 'package:fix_easy/customer_screens/customer_home.dart' as customer_home;
import 'package:fix_easy/theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../verfication_OTP.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_easy/seller_screens/create_company_profile.dart';
// import 'package:fix_easy/seller_screens/seller_home.dart' as seller_home;

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
      final companyCreated = data['data']['isCompanyProfileExist'];

      if (userType == 'Customer') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => customer_home.CustomerHome()),
          (route) => false, // This will remove all previous routes
        );
      } else if (userType == 'Seller') {
        if (companyCreated == false) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreateCompanyProfileScreen(
                    userID: data['data']['userId'],
                  ),
            ),
            (route) => false, // This will remove all previous routes
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/sellerHome',
            (route) => false, // This will remove all previous routes
          );
        }
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Welcome Card
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/FixEasy.png',
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 0),
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sign in to continue',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Login Form Card
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _buildInputDecoration(
                              'Enter your email',
                              Icons.email,
                            ),
                            validator:
                                (value) =>
                                    value?.isEmpty ?? true
                                        ? 'Email is required'
                                        : null,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Password',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _isObscure,
                            decoration: _buildInputDecoration(
                              'Enter your password',
                              Icons.lock,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed:
                                    () => setState(
                                      () => _isObscure = !_isObscure,
                                    ),
                              ),
                            ),
                            validator:
                                (value) =>
                                    value?.isEmpty ?? true
                                        ? 'Password is required'
                                        : null,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/ForgotPassword',
                                    ),
                                child: Text(
                                  'Forgot Password?',
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
                  SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
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
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text('Sign In', style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(height: 16),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Don\'t have an account?'),
                      TextButton(
                        onPressed:
                            () => Navigator.pushNamed(context, '/accountType'),
                        child: Text(
                          'Sign Up',
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
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String hint,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffixIcon,
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
