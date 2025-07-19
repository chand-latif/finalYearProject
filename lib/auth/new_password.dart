import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewPassword extends StatefulWidget {
  final String email;
  const NewPassword({super.key, required this.email});

  @override
  State<NewPassword> createState() => _NewPasswordState();
}

final TextEditingController newPasswordController = TextEditingController();
final TextEditingController oldPasswordController = TextEditingController();

class _NewPasswordState extends State<NewPassword> {
  bool isVerifying = false;

  Future<void> changePassword() async {
    setState(() {
      isVerifying = true;
    });

    final url = Uri.parse('https://fixease.pk/api/User/ChangePassword');

    final body = {
      "email": "${widget.email}",
      "currentPassword": oldPasswordController.text.trim(),
      "newPassword": newPasswordController.text.trim(),
    };
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['statusCode'] == 200) {
          Navigator.pushNamed(context, '/PasswordConfirmation');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Password changed successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Password change failed"),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }

      // Navigator.pushNamed(context, '/PasswordConfirmation');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Password changed successfully")),
      // );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error changing password: $e")));
    } finally {
      setState(() {
        isVerifying = false;
      });
    }
  }

  bool isObscureOld = true;
  bool isObscureNew = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set New Password'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 30,
            children: [
              Text(
                'Create a new password. Ensure it differs from the previous one for the security',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Text(
                        'Current Password',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        obscureText: isObscureOld,
                        controller: oldPasswordController,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              isObscureOld
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                isObscureOld = !isObscureOld;
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
                          hintText: 'Enter your current password',
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
                    spacing: 10,
                    children: [
                      Text(
                        'New Password',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        obscureText: isObscureNew,
                        controller: newPasswordController,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              isObscureNew
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                isObscureNew = !isObscureNew;
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
                          hintText: 'Enter your new password',
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
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
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            changePassword();
                          },
                          child: Text('Update Password'),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
