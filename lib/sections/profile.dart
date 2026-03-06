import 'package:flutter/material.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.only(top: 12, right: 20),
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFB7FF1C), width: 2),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/pfp.jpg', // Ensure this is in pubspec.yaml
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
