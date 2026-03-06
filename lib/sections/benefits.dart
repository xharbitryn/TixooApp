import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/widgets/divider.dart';

class BenefitsSection extends StatelessWidget {
  const BenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Title
          GradientDivider(title: "Plus Benefits"),
          const SizedBox(height: 15),

          /// 🔹 Grid Layout for 3 Benefits
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBenefitCard(
                    image: "assets/images/benefit1.png",
                    title: "Early Access\nBenefits",
                    titleColor: Colors.white,
                    width: MediaQuery.of(context).size.width * 0.44,
                    height: 150,
                  ),
                  _buildBenefitCard(
                    image: "assets/images/benefit2.png",
                    title: "Bonus\nCredit Cash",
                    titleColor: Colors.white,
                    width: MediaQuery.of(context).size.width * 0.44,
                    height: 150,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBenefitCard(
                image: "assets/images/benefit3.png",
                title: "0%\nCommission Fees\nOn Tixoo",
                titleColor: Colors.white,
                width: double.infinity,
                height: 150,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔸 Helper widget for each benefit card
  Widget _buildBenefitCard({
    required String image,
    required String title,
    required Color titleColor,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
      alignment: Alignment.topLeft, // 🔹 Moved text to top-left
      padding: const EdgeInsets.all(12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: titleColor,
          height: 1.2,
          shadows: [
            const Shadow(
              color: Colors.black54,
              offset: Offset(1, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }
}
