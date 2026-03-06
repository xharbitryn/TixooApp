import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:tixxo/profile_pages/subscription.dart';
import 'package:tixxo/supportive_pages/location.dart';
import 'package:tixxo/supportive_pages/profile.dart';
import 'package:tixxo/widgets/search_bar.dart';

class HeroSectionSimplified extends StatelessWidget {
  const HeroSectionSimplified({super.key});

  /// Helper to get City
  String _getCity(Map<String, dynamic>? location) {
    if (location == null ||
        location['city'] == null ||
        location['city'].toString().isEmpty) {
      return 'Select Location';
    }
    return "${location['city']}";
  }

  /// Helper to get State and Country
  String _getStateCountry(Map<String, dynamic>? location) {
    if (location == null) {
      return 'India';
    }
    String state = location['state']?.toString() ?? '';
    String country = location['country']?.toString() ?? 'India';

    if (state.isNotEmpty && country.isNotEmpty) {
      return "$state, $country";
    } else if (state.isNotEmpty) {
      return state;
    } else {
      return country;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final double topPadding = MediaQuery.of(context).padding.top + 10;

    return Container(
      width: double.infinity,
      height: 380,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ───────────────── LOTTIE BACKGROUND ─────────────────
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Lottie.asset(
                // ✅ FIXED: Pointing to your new .json file
                'assets/animations/hero_banner.json',
                fit: BoxFit.cover,
                // ✅ REMOVED: 'decoder' line (JSON does not need decoding)
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      "Animation Error: ${error.toString()}",
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),

          // ───────────────── INTERACTIVE OVERLAY ─────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ───────────────── HEADER LOGIC ─────────────────
                if (user == null)
                  _buildGuestHeader(context)
                else
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return _buildGuestHeader(context, isLoading: true);
                      }
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      return _buildUserHeader(context, data);
                    },
                  ),

                const SizedBox(height: 24),

                // ───────────────── SEARCH BAR ─────────────────
                const SearchBarSection(
                  hintWords: [
                    "events",
                    "concerts",
                    "comedy shows",
                    "workshops",
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 WIDGET: Header for Logged-In User
  Widget _buildUserHeader(BuildContext context, Map<String, dynamic>? data) {
    final locationData = data?['location'] as Map<String, dynamic>?;
    final profileUrl = data?['profileUrl'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationPage()),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCity(locationData),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                      height: 1.1,
                    ),
                  ),
                  Text(
                    _getStateCountry(locationData),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Row(
          children: [
            _buildGetPlusButton(context),
            const SizedBox(width: 12),
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
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child:
                      (profileUrl != null &&
                          profileUrl.toString().startsWith('http'))
                      ? Image.network(profileUrl, fit: BoxFit.cover)
                      : Image.asset(
                          'assets/images/profile.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🔹 WIDGET: Header for Guest
  Widget _buildGuestHeader(BuildContext context, {bool isLoading = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationPage()),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? "Loading..." : "Select Location",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                      height: 1.1,
                    ),
                  ),
                  Text(
                    "India",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Row(
          children: [
            _buildGetPlusButton(context),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please login to access profile'),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  backgroundImage: AssetImage('assets/images/profile.png'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🔹 COMPONENT: Reusable "Get Plus" Button
  Widget _buildGetPlusButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPage()),
        );
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              "Get Plus",
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
