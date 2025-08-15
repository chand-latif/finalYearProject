import 'package:flutter/material.dart';

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({super.key});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int seclectedIndex = 0;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  void onItemTapped(int index) {
    setState(() {
      seclectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, "/customerHome");
        break;
      case 1:
        Navigator.pushNamed(context, "/myBookings");
        break;
      case 2:
        Navigator.pushNamed(context, "/customerProfile");
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // return Row(
    //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //   children: [
    //     Column(children: [Icon(Icons.home), Text('Home')]),
    //   ],
    // );
    return BottomNavigationBar(
      currentIndex: seclectedIndex,
      onTap: onItemTapped,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Profile'),
      ],
    );
  }
}
