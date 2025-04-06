import 'package:flutter/material.dart';
import 'nav_bar.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Home'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text(
          'Welcome to Customer Home!',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: CustomNavBar(),
    );
  }
}
