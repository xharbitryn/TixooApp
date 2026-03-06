import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/neopop.dart';
import 'package:tixxo/profile_pages/drawer1.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Upgrade yourself",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        titleSpacing: 0,
      ),

      // 👇 Scrollable content
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price container
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFB7FF1C)),
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: Text(
                      "Get 10% off on every ticket you buy",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      text: "₹69",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                      children: [
                        TextSpan(
                          text: " for 3 months",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // NeoPopButton
                  NeoPopButton(
                    color: const Color(0xFFB7FF1C),
                    animationDuration: const Duration(milliseconds: 500),
                    onTapUp: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Subscribed to Plus!'),
                          backgroundColor: const Color(0xFFB7FF1C),
                        ),
                      );
                    },
                    onTapDown: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text(
                        'Get Plus',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    "Get exclusive benefits every time you book a ticket on Tixoo.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Plus Benefits
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🌟 Plus Benefits",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Benefit 1
                  _buildBenefitWithIcon(
                    "10% off on every ticket you buy — save every single time.",
                    "assets/images/off.png",
                  ),
                  Divider(color: Colors.white.withOpacity(0.3)),

                  // Benefit 2
                  _buildBenefitWithIcon(
                    "Early access to events before they go live for everyone else.",
                    "assets/images/early.png",
                  ),
                  Divider(color: Colors.white.withOpacity(0.3)),

                  // Benefit 3
                  _buildBenefitWithIcon(
                    "Free Tixoo Cash with every booking — your loyalty rewarded.",
                    "assets/images/coin.png",
                  ),

                  const SizedBox(height: 80),
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
                ],
              ),
            ),
            const SizedBox(height: 80), // extra space so content not hidden
          ],
        ),
      ),

      // 👇 Fixed bottom section inside SafeArea
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Base Price\n₹69 / 3 months",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              NeoPopButton(
                color: const Color(0xFFB7FF1C),
                animationDuration: const Duration(milliseconds: 500),
                onTapUp: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Subscribed to Plus!'),
                      backgroundColor: const Color(0xFFB7FF1C),
                    ),
                  );
                },
                onTapDown: () {
                  showPlusMembershipDrawer(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    'Get Plus',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitWithIcon(String text, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imagePath, width: 38, height: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
