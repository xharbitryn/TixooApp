// lib/sections/offers_section.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:tixxo/widgets/divider.dart';

class OfferSection extends StatefulWidget {
  const OfferSection({super.key});

  @override
  State<OfferSection> createState() => _OfferSectionState();
}

class _OfferSectionState extends State<OfferSection> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> offers = [
    {
      "image": "assets/images/hdfc.png", // Full card asset
      "title": "10% Cashback",
      "subtitle": "on HDFC Bank Debit &\nCredit Cards",
    },
    {
      "image": "assets/images/hdfc.png",
      "title": "Flat ₹500 Off",
      "subtitle": "On your first booking\nwith Tixoo Plus",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        const GradientDivider(title: "Offers On Tixoo"),
        const SizedBox(height: 16),

        /// 🔹 Carousel Slider
        CarouselSlider.builder(
          itemCount: offers.length,
          itemBuilder: (context, index, realIndex) {
            final offer = offers[index];

            return Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    /// 🖼️ 1. Background Asset (Full Card)
                    Positioned.fill(
                      child: Image.asset(
                        offer['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),

                    /// 📝 2. Text Overlay with Figma Styles
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        top: 8,
                        bottom: 8,
                        right: 110,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ✅ Gradient Text for Title (White -> #84AFFF)
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Colors.white,
                                Color(0xFF84AFFF),
                              ], // Extracted from Figma
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: Text(
                              offer['title'],
                              style: GoogleFonts.poppins(
                                color: Colors
                                    .white, // Required for ShaderMask base
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // ✅ Solid Color for Subtitle (#96D7FF)
                          Text(
                            offer['subtitle'],
                            style: GoogleFonts.poppins(
                              color: const Color(
                                0xFF96D7FF,
                              ), // Extracted from Figma
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 96,
            // ✅ Auto-Swipe / Scroll Animation Logic
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: true,
            viewportFraction: 0.92,
            padEnds: false,
            disableCenter: true,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
        ),
      ],
    );
  }
}
