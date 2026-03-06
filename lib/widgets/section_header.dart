import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/utils/responsive.dart';
import 'package:tixxo/utils/gradient_text.dart';

/// Reusable section header with gradient decorative lines on both sides.
/// Pattern: ——— Title ———
class SectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;

  const SectionHeader({super.key, required this.title, this.padding});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Padding(
      padding:
          padding ??
          EdgeInsets.symmetric(horizontal: r.w(20), vertical: r.h(12)),
      // Using MainAxisAlignment.center ensures the fixed-width assembly stays centered
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLine(r, isLeft: true),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.w(12)),
            child: GradientText(
              text: title,
              style: GoogleFonts.poppins(
                fontSize: r.sp(18), // Reduced size to match Figma
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              // Exact gradient specified from Figma
              colors: const [Color(0xFF000000), Color(0xFF15612E)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          _buildLine(r, isLeft: false),
        ],
      ),
    );
  }

  Widget _buildLine(Responsive r, {required bool isLeft}) {
    // Left line starts black (to match the 0% gradient text),
    // Right line starts dark green (to match the 100% gradient text).
    final startColor = isLeft
        ? const Color(0xFF000000)
        : const Color(0xFF15612E);

    return Container(
      width: r.w(
        45,
      ), // Replaced 'Expanded' with a strict width to prevent stretching
      height: r.h(2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          colors: [startColor, startColor.withOpacity(0.0)],
        ),
      ),
    );
  }
}
