import 'package:fix_easy/theme.dart';
import 'package:flutter/material.dart';

class passwordConfirmation extends StatefulWidget {
  const passwordConfirmation({super.key});

  @override
  State<passwordConfirmation> createState() => _passwordConfirmationState();
}

class _passwordConfirmationState extends State<passwordConfirmation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 30,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/confirmationLogo.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
              Text(
                'Success',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                'Congratulations! Your password has been changed.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/home');
                },
                
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Continue Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
