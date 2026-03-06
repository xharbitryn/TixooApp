import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tixxo/auth/lr.dart';
import 'package:tixxo/auth/phoneno.dart';
import 'package:tixxo/screens/navbar.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoginOrRegister();
          }

          final User user = snapshot.data!;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection("Users")
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const PhoneInputPage();
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>?;

              if (userData == null) {
                return const PhoneInputPage();
              }

              final otpVerified = userData["otpVerified"] ?? false;
              final profileCompleted = userData["profileCompleted"] ?? false;

              if (otpVerified == true && profileCompleted == true) {
                // 🚀 FIX: Changed to MainNavBar
                return const MainNavBar();
              } else {
                return const PhoneInputPage();
              }
            },
          );
        },
      ),
    );
  }
}
