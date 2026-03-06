import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/utils/responsive.dart';

class SearchBarWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const SearchBarWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: r.h(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.radius(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: r.radius(10),
              offset: Offset(0, r.h(2)),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(12)),
              child: Icon(
                Icons.search_rounded,
                color: Colors
                    .deepPurpleAccent, // Swapped from food-red to an event-purple
                size: r.sp(20),
              ),
            ),
            Expanded(
              child: Text(
                "Search for events, artists, venues...",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.sp(13),
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Container(width: 1, height: r.h(24), color: Colors.grey.shade300),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(12)),
              child: Icon(
                Icons.mic,
                color: Colors.deepPurpleAccent,
                size: r.sp(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
