import 'package:flutter/material.dart';
import 'package:tixxo/screens/landing_page.dart';

class MainNavBar extends StatefulWidget {
  final int initialIndex;

  const MainNavBar({super.key, this.initialIndex = 0});

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      // 🚀 Removed BottomNavigationBar completely
      body: LandingPage(),
    );
  }
}
