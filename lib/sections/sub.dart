import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/profile_pages/subscription.dart';
import 'package:tixxo/widgets/divider.dart';
// 👈 import your existing page

class SubscriptionSection extends StatelessWidget {
  const SubscriptionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Section Title
        const GradientDivider(title: "Subscription"),

        // 🔹 Square Image Card
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionPage()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            height: 330, // square size
            width: 450,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              image: const DecorationImage(
                image: AssetImage("assets/images/sub.jpg"), // 👈 your image
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
