import 'dart:ui';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/classes/upcoming.dart';
import 'package:tixxo/models/event.dart';
import 'package:tixxo/sections/upcoming.dart';
import 'package:tixxo/supportive_pages/event_details.dart';
import 'package:tixxo/supportive_pages/review.dart';

class PromoterDetailsPage extends StatefulWidget {
  final String uid;
  final String displayName;
  final String email;
  final String photoURL;

  const PromoterDetailsPage({
    super.key,
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoURL,
  });

  @override
  State<PromoterDetailsPage> createState() => _PromoterDetailsPageState();
}

class _PromoterDetailsPageState extends State<PromoterDetailsPage> {
  Set<String> favoriteEventIds = {};
  bool isBioExpanded = false;
  Map<String, dynamic>? _cachedPromoterData;

  final FavoritesManager _favoritesManager = FavoritesManager();
  late Function(Set<String>) _favoritesListener;

  @override
  void initState() {
    super.initState();
    _favoritesListener = (favorites) {
      if (mounted) setState(() => favoriteEventIds = favorites);
    };
    _favoritesManager.addListener(_favoritesListener);
    _favoritesManager.initialize();
  }

  @override
  void dispose() {
    _favoritesManager.removeListener(_favoritesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promoters')
            .doc(widget.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _cachedPromoterData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "Promoter data not found",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }

          final promoterData = snapshot.data!.data() as Map<String, dynamic>?;
          if (promoterData == null) {
            return Center(
              child: Text(
                "No promoter data available",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }

          _cachedPromoterData = promoterData;

          // 🚀 FIX: The entire page is now inside a CustomScrollView with a SliverAppBar
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFFF5F5F5),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leadingWidth: 56,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(promoterData),
                    // Keep the other sections below as they were!
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> promoterData) {
    final publicData = promoterData['publicdata'] as Map<String, dynamic>?;
    final photoURL = publicData?['photoURL'] ?? '';
    final bio = publicData?['bio'] ?? '';
    final businessName = publicData?['businessName'] ?? widget.displayName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: photoURL.isNotEmpty
                ? Image.network(
                    photoURL,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220,
                  )
                : Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, size: 64),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  businessName,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bio.isNotEmpty)
            Text(
              bio,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
