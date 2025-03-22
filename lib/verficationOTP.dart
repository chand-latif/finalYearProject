import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class verificationOTP extends StatefulWidget {
  final String email;
  const verificationOTP({super.key, required this.email});

  @override
  State<verificationOTP> createState() => _verificationOTPState();
}

class _verificationOTPState extends State<verificationOTP> {
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
            text:  TextSpan(
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
                Text('OTP', style: TextStyle(fontWeight: FontWeight.bold,color: AppColors.primary,fontSize: 18),),
                SizedBox(height: 10,),
                PinCodeTextField(
                  appContext: context,
                  length: 5, // Number of OTP digits
                  onChanged: (value) {
                    print("OTP Entered: $value");
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
              ],
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/newPassword');
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
