import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/models/home_models.dart';
import 'package:tixxo/utils/responsive.dart';
import 'package:tixxo/widgets/section_header.dart';

class PlusBenefitsSection extends StatelessWidget {
  // Keeping the parameter to ensure home_screen.dart doesn't break,
  // but using a bespoke layout for the specific Figma cards.
  final List<dynamic> benefits;
  final bool isVisible;

  const PlusBenefitsSection({
    super.key,
    required this.benefits,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final r = Responsive(context);

    return Column(
      children: [
        const SectionHeader(title: 'Plus Benefits'),
        SizedBox(height: r.h(12)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: r.w(16)),
          child: Column(
            children: [
              // ─── Top Row: Two Square Cards ───
              Row(
                children: [
                  Expanded(child: _buildEarlyAccessCard(r)),
                  SizedBox(width: r.w(12)),
                  Expanded(child: _buildBonusCreditCard(r)),
                ],
              ),
              SizedBox(height: r.h(12)),
              // ─── Bottom Row: Wide Rectangular Card ───
              _buildZeroCommissionCard(r),
            ],
          ),
        ),
      ],
    );
  }

  /// Top Left Card (Dark Green)
  Widget _buildEarlyAccessCard(Responsive r) {
    return AspectRatio(
      aspectRatio: 1.0, // Forces perfect square
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r.radius(16)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF164726),
              Color(0xFF071F10),
            ], // Dark forest green gradient
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Placeholder for the 3D Tickets Asset
            // Replace this Positioned widget with your actual Image.asset when ready
            Positioned(
              bottom: -r.h(10),
              right: -r.w(10),
              child: Icon(
                Icons.local_activity_rounded,
                size: r.sp(80),
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(r.w(14)),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: r.sp(15),
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Early Access\n',
                      style: TextStyle(
                        color: Color(0xFF90FFAE),
                      ), // Bright neon green from Figma
                    ),
                    TextSpan(
                      text: 'Benefits',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Right Card (Warm Orange)
  Widget _buildBonusCreditCard(Responsive r) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r.radius(16)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFCE6645),
              Color(0xFFE59C69),
            ], // Warm peach/orange gradient
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Placeholder for the 3D Wallet Asset
            // Replace this Positioned widget with your actual Image.asset when ready
            Positioned(
              bottom: -r.h(10),
              right: -r.w(10),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: r.sp(80),
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(r.w(14)),
              child: Text(
                'Bonus\nCredit Cash',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.sp(15),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Full-Width Card (Dark Blue with Neon Border)
  Widget _buildZeroCommissionCard(Responsive r) {
    return Container(
      width: double.infinity,
      height: r.h(130),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.radius(16)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF030814),
            Color(0xFF0A183D),
          ], // Deep midnight blue gradient
        ),
        // The glowing blue border from the screenshot
        border: Border.all(color: const Color(0xFF1D66FF), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Placeholder for the large 3D "0%" Asset
          // Replace this Positioned widget with your actual Image.asset when ready
          Positioned(
            bottom: -r.h(20),
            right: -r.w(10),
            child: Icon(
              Icons.percent_rounded,
              size: r.sp(120),
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(r.w(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '0',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.sp(42),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      TextSpan(
                        text: '%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.sp(22),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: r.h(2)),
                Text(
                  'Commission Fees\nOn Tixoo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: r.sp(14),
                    fontWeight: FontWeight.w700,
                    color: const Color(
                      0xFFD0E0FF,
                    ), // Light frosty blue for subtitle
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
