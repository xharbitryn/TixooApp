import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GradientDivider extends StatelessWidget {
  final String title;

  const GradientDivider({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Common gradient colors
    const lineGradientColors = [
      Color(0xFF2C3E2C), // dark green
      Color(0xFF4A7C4A), // light green
      Colors.white, // fade to white
    ];

    const textGradientColors = [
      Color(0xFF2C3E2C), // dark green
      Color(0xFF4A7C4A), // light green (no white fade here)
    ];

    return Container(
      color: const Color(0xFFF7F7F7), // light background
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left gradient line
          Container(
            width: 50,
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: lineGradientColors,
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Gradient text (dark → light green)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: textGradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(Rect.fromLTWH(0, 0, 200, 0)),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white, // needed for ShaderMask
                ),
              ),
            ),
          ),

          // Right gradient line
          Container(
            width: 50,
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: lineGradientColors,
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
