import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tixxo/profile_pages/subscription.dart';
import 'package:tixxo/supportive_pages/location.dart';
import 'package:tixxo/supportive_pages/profile.dart';
// 👈 Import your SubscriptionPage

class LocationSection extends StatelessWidget {
  const LocationSection({super.key});

  String _formatLocation(Map<String, dynamic>? location) {
    if (location == null || location['city'] == null)
      return 'Set your location';
    return "${location['city']}";
  }

  String _getGuestLocation() => "Select your location";

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ──────────────────────────────
    // Guest Users
    // ──────────────────────────────
    if (user == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 📍 Google Maps–style Location Icon
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationPage()),
                );
              },
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF15612E),
                size: 28,
              ),
            ),
            const SizedBox(width: 6),

            // 🧭 Guest info
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationPage()),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guest User',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      _getGuestLocation(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.black.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 🟡 Get Plus Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF15612E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Get Plus",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 👤 Default Profile Picture for guest
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please login to access profile features',
                      style: GoogleFonts.poppins(color: Colors.black),
                    ),
                    backgroundColor: const Color(0xFFB7FF1C),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFB7FF1C), width: 2),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/profile.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ──────────────────────────────
    // Logged-in Users
    // ──────────────────────────────
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final userName = (data?['name'] ?? 'Guest User').toString();
        final location = data?['location'] as Map<String, dynamic>?;
        final profileImage =
            data?['profileUrl'] ?? 'assets/images/profile.jpeg';

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            0,
            8,
            0,
            16,
          ), // (left, top, right, bottom)
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 📍 Google Maps–style Location Icon
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationPage()),
                  );
                },
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF15612E),
                  size: 28,
                ),
              ),
              const SizedBox(width: 6),

              // 👤 User info
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LocationPage()),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        _formatLocation(location),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.black.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🟡 Get Plus Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15612E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Get Plus",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),

              // 👤 Profile Picture
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFB7FF1C),
                      width: 2,
                    ),
                    image: profileImage.toString().startsWith('http')
                        ? DecorationImage(
                            image: NetworkImage(profileImage),
                            fit: BoxFit.cover,
                          )
                        : DecorationImage(
                            image: AssetImage(profileImage),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
