// lib/sections/promoter_section.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tixxo/screens/promo.dart';
import 'package:tixxo/supportive_pages/promoter_detail.dart';
import 'package:tixxo/widgets/divider.dart';

class PromotersSection extends StatefulWidget {
  const PromotersSection({super.key});

  @override
  State<PromotersSection> createState() => _PromotersSectionState();
}

class _PromotersSectionState extends State<PromotersSection> {
  // ✅ FIX 1: Increased viewportFraction to 0.95 to make the card "Huge" (Full Width)
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _autoScroll();
  }

  void _autoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage > 3) _currentPage = 0;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          /// --- Title Section ---
          const GradientDivider(title: "Promoters On Tixoo"),
          const SizedBox(height: 20),

          /// --- Promoters Carousel ---
          // ✅ FIX 2: Height set to 290px.
          // Card (200px) + Shadow Padding (Bottom 60px + Top 10px) + Buffer
          SizedBox(
            height: 290,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('promoters')
                  .where('verificationStatus', isEqualTo: 'approved')
                  .limit(4)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3E8B40)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No promoters found',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return PageView.builder(
                  controller: _pageController,
                  itemCount: docs.length,
                  padEnds: false, // Aligns first card to start
                  onPageChanged: (val) => _currentPage = val,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final uid = data['uid'] ?? docs[index].id;
                    final displayName = data['displayName'] ?? '';
                    final email = data['email'] ?? '';
                    final publicData =
                        data['publicdata'] as Map<String, dynamic>? ?? {};

                    final photoURL =
                        publicData['photoURL'] ?? data['photoURL'] ?? '';
                    final businessName =
                        publicData['businessName'] ?? 'Promoter';
                    final bio =
                        publicData['bio'] ?? 'Verified promoter on Tixoo';

                    return _buildPromoterCard(
                      uid: uid,
                      displayName: displayName,
                      email: email,
                      photoURL: photoURL,
                      businessName: businessName,
                      bio: bio,
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          /// --- See All Promoters Button ---
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PromoPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey[300]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All Promoters',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoterCard({
    required String uid,
    required String displayName,
    required String email,
    required String photoURL,
    required String businessName,
    required String bio,
  }) {
    return Padding(
      // ✅ FIX 3: Significant bottom padding ensures the deep shadow is never clipped
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 60),
      child: Container(
        height: 200, // ✅ EXACT FIGMA HEIGHT
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30), // ✅ EXACT RADIUS
          boxShadow: [
            // ✅ EXACT SHADOW: Opacity 7%, Blur 25, Spread 7, Y 7
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 25,
              spreadRadius: 7,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🖼️ Promoter Image
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                photoURL,
                width: 140, // Wide square-ish look
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 140,
                  height: double.infinity,
                  color: const Color(0xFF2D2D2D),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            /// 📝 Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Name & Gradient Divider
                  const SizedBox(height: 6),
                  Text(
                    businessName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 100,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3E8B40), Colors.transparent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),

                  // 2. Bio Text (Wrapped in Expanded to fix Pixel Overflow)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        bio,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF757575),
                          height: 1.4,
                        ),
                        // Automatically limits lines based on available space
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // 3. Rating & Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ⭐ Rating Pill
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('promoters')
                            .doc(uid)
                            .collection('reviews')
                            .snapshots(),
                        builder: (context, snapshot) {
                          double rating = 0.0;
                          if (snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty) {
                            final reviews = snapshot.data!.docs;
                            int totalRating = 0;
                            for (var doc in reviews) {
                              final rData = doc.data() as Map<String, dynamic>;
                              totalRating += (rData['rating'] ?? 0) as int;
                            }
                            rating = totalRating / reviews.length;
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  rating > 0
                                      ? rating.toStringAsFixed(1)
                                      : "New",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                ),
                                if (rating > 0) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Color(0xFFFFC107),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 8),

                      // 🟢 ✅ EXACT GRADIENT BUTTON (Replicated from your snippet)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PromoterDetailsPage(
                                  uid: uid,
                                  displayName: displayName,
                                  email: email,
                                  photoURL: photoURL,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF245126), // Dark Green
                                  Color(0xFF4EB152), // Light Green
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Explore More',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // ✅ Arrow with White Circle Border
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
