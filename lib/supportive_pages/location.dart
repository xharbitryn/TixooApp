import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tixxo/widgets/search_bar.dart';
import '../services/location_service.dart';

class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  final List<String> cities = const [
    'Chandigarh',
    'Dehradun',
    'Noida',
    'Bareilly',
    'Ranchi',
    'Jaipur',
    'Pune',
    'Lucknow',
    'Haldwani',
  ];

  /// ✅ LOGIC: Save selected city to Firestore User Profile
  Future<void> _setManualLocation(BuildContext context, String city) async {
    final user = FirebaseAuth.instance.currentUser;

    // 1. Save to Firestore
    if (user != null) {
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'location': {'city': city, 'country': 'India'},
      }, SetOptions(merge: true));
    }

    // 2. Feedback & Navigation
    if (context.mounted) {
      Navigator.pop(context); // Go back to Home
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location set to $city'),
          backgroundColor: const Color(0xFF15612E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// ✅ LOGIC: Get GPS Location
  Future<void> _handleLocationAccess(BuildContext context) async {
    await LocationService.ensureInitialized();

    final user = FirebaseAuth.instance.currentUser;
    // Check if location is valid
    if (user != null &&
        LocationService.fullLocation != 'Location permission denied' &&
        LocationService.fullLocation != 'Location unavailable' &&
        LocationService.fullLocation != 'Location not found') {
      // Save GPS city to Firestore
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'location': {
          'city': LocationService.city,
          'country': LocationService.country,
        },
      }, SetOptions(merge: true));

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location set to ${LocationService.city}'),
            backgroundColor: const Color(0xFF15612E),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied or unavailable'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          "Location",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        titleSpacing: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            // ✅ SEARCH BAR (Location Mode)
            SizedBox(
              width: double.infinity,
              child: SearchBarSection(
                hintWords: const [
                  'Mumbai',
                  'Hyderabad',
                  'Kolkata',
                  'Chennai',
                  'Bangalore',
                ],
                searchType: SearchType.location, // 👈 Triggers Photon API
                onLocationSelected: (city) => _setManualLocation(context, city),
              ),
            ),

            const SizedBox(height: 16),

            // Location Access Button
            InkWell(
              onTap: () => _handleLocationAccess(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Allow Location Access",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Tap to use your current location",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tixoo's Presence
            Text(
              "Tixoo’s presence",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal Scroll
            SizedBox(
              height: 80,
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    ImageTile(imagePath: 'assets/images/mumbai.png'),
                    SizedBox(width: 12),
                    ImageTile(imagePath: 'assets/images/delhi.png'),
                    SizedBox(width: 12),
                    ImageTile(imagePath: 'assets/images/lucknow.png'),
                    SizedBox(width: 12),
                    ImageTile(imagePath: 'assets/images/haldwani.png'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "All Cities",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Manual City List
            ...cities.map(
              (city) => InkWell(
                onTap: () => _setManualLocation(context, city),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    city,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Center(
              child: Text(
                'Drix Entertainment Pvt. Ltd.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ImageTile extends StatelessWidget {
  final String imagePath;
  const ImageTile({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Image.asset(
          imagePath,
          height: 50,
          width: 50,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
