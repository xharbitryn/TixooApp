import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tixxo/auth/authgate.dart';
import 'package:tixxo/auth/authservice.dart';

class AccountSettingsPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  AccountSettingsPage({super.key});

  Future<void> _reauthenticateUser(User user, BuildContext context) async {
    try {
      if (user.providerData.any((info) => info.providerId == 'google.com')) {
        // Reauthenticate Google user
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) throw Exception("Google sign-in cancelled");
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      } else if (user.providerData.any(
        (info) => info.providerId == 'password',
      )) {
        // Reauthenticate Email/Password user
        final emailController = TextEditingController();
        final passwordController = TextEditingController();

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              "Re-enter your credentials",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(hintText: "Email"),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: "Password"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("Confirm"),
              ),
            ],
          ),
        );

        if (confirmed != true) throw Exception("Re-authentication cancelled");

        final credential = EmailAuthProvider.credential(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        throw Exception("Unsupported sign-in provider. Please log in again.");
      }
    } catch (e) {
      throw Exception("Re-authentication failed: $e");
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Delete Account",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmation != true) return;

    try {
      // Reauthenticate before deleting
      await _reauthenticateUser(user, context);

      // Delete user document from Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .delete();

      // Delete from Firebase Authentication
      await user.delete();

      // Sign out
      await _authService.signOut();

      // Navigate to login/welcome screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AuthGate()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting account: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          "Account Settings",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListTile(
          onTap: () => _deleteAccount(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          tileColor: const Color(0xFF1E1E1E),
          leading: const Icon(Icons.delete, color: Colors.red),
          title: Text(
            "Delete Account",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
