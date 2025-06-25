import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'create_company_profile.dart';
import 'customer_home.dart';
// import 'dart:io';
// import 'package:http/io_client.dart';

class VerificationOTP extends StatefulWidget {
  final String email;

  const VerificationOTP({super.key, required this.email});

  @override
  State<VerificationOTP> createState() => _VerificationOTPState();
}

class _VerificationOTPState extends State<VerificationOTP> {
  // HttpClient _getHttpClient() {
  //   final httpClient =
  //       HttpClient()
  //         ..badCertificateCallback =
  //             (X509Certificate cert, String host, int port) => true;
  //   return httpClient;
  // }

  Future<void> sendOTP(String email) async {
    final url = Uri.parse(
      "https://fixease.pk/api/User/ResendVerificationOTP?Email=$email",
    );

    final body = {"email": email};

    try {
      // final IOClient ioClient = IOClient(_getHttpClient());
      // final response = await ioClient.post(
      //   url,
      //   headers: {"Content-Type": "application/json"},
      //   body: jsonEncode(body),
      // );
      //put call
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (responseData["statusCode"] == 200) {
          // Handle error if OTP sending fails
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("OTP sent successfully")));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to send OTP")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error sending OTP")));
    }
  }

  Future<void> verifyOTP(String email, int OTP) async {
    setState(() {
      isVerifying = true;
    });
    final url = Uri.parse(
      "https://fixease.pk/api/User/ConfirmEmail?Email=$email&OTP=$OTP",
    );
    final body = {"email": email, "otp": OTP};

    try {
      // final IOClient ioClient = IOClient(_getHttpClient());
      // final response = await ioClient.post(
      //   url,
      //   headers: {"Content-Type": "application/json"},
      //   // body: jsonEncode(body),
      // );

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (responseData["statusCode"] == 200) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('OTP verified successfully')));
          // Navigator.pushNamed(context, '/customerHome');
          Navigator.pushNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("failed to verify OTP")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server Error! Try again later.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("error verifying OTP: $e")));
    } finally {
      setState(() {
        isVerifying = false;
      });
    }
  }

  int? OTP;
  bool isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification OTP'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Text(
              'Check your Email',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            RichText(
              text: TextSpan(
                text: 'Please enter the OTP sent to',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: ' ${widget.email}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 7,
              children: [
                Text(
                  'OTP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 10),
                PinCodeTextField(
                  appContext: context,
                  length: 5, // Number of OTP digits
                  onChanged: (value) {
                    setState(() {
                      OTP = int.tryParse(value);
                    });
                  },
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(8),
                    fieldHeight: 50,
                    fieldWidth: 50,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey,
                    selectedColor: Colors.blueAccent,
                  ),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        sendOTP('${widget.email}');
                      },
                      child: Text(
                        'Send Code',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child:
                  isVerifying
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          verifyOTP('${widget.email}', OTP!);
                        },
                        child: Text('Verify', style: TextStyle(fontSize: 20)),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
