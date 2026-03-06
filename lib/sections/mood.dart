import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/widgets/divider.dart';

class MoodSection extends StatelessWidget {
  const MoodSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> moods = [
      {"title": "DJ Nights", "image": "assets/images/dj.jpg"},
      {"title": "Comedy Shows", "image": "assets/images/comic.jpg"},
      {"title": "Bar Nights", "image": "assets/images/bar.jpg"},
      {"title": "Drinks & Chill", "image": "assets/images/drinks.jpg"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GradientDivider(title: "In the Mood for"),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: moods.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.90,
          ),
          itemBuilder: (context, index) {
            final mood = moods[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  // background image
                  Positioned.fill(
                    child: Image.asset(mood["image"]!, fit: BoxFit.cover),
                  ),
                  // gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  // title
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Text(
                      mood["title"]!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
