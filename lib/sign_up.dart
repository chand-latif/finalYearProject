import 'package:flutter/material.dart';
import 'theme.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          
          children: [
            Text('Make your future bright with us!', style: TextStyle(fontSize:20, color: AppColors.primary),),
          ],
        ),
      ),
    );
  }
}