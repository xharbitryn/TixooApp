import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategorySection extends StatefulWidget {
  final String eventCategory;
  final Function(String?) onCategorySelected;

  const CategorySection({
    super.key,
    required this.eventCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  String? selectedSubCategory;

  // ✅ LOGIC PRESERVED
  final Map<String, String> subCategoryIcons = {
    "Music": "assets/images/music.png",
    "Standup": "assets/images/comedy.png",
    "Poetry": "assets/images/poetry.png",
    "Theatre": "assets/images/play.png",
  };

  // ✅ LOGIC PRESERVED
  List<String> getSubCategories(String mainCategory) {
    switch (mainCategory) {
      case "basicEvent":
        return ["Music", "Standup", "Poetry", "Theatre"];
      case "Sports":
        return ["Cricket", "Football", "Tennis", "Running"];
      case "clubEvent":
        return ["DJ Night", "Bollywood", "EDM", "Hip-Hop"];
      default:
        return ["Music", "Standup", "Poetry", "Theatre"];
    }
  }

  @override
  void initState() {
    super.initState();
    final subCategories = getSubCategories(widget.eventCategory);
    if (subCategories.isNotEmpty) {
      selectedSubCategory = subCategories[0];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCategorySelected(selectedSubCategory);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subCategories = getSubCategories(widget.eventCategory);

    // 🎨 GRADIENT DEFINITION (Extracted from your screenshot)
    const Gradient selectedGradient = LinearGradient(
      colors: [
        Color(0xFF28E230), // Bright Neon Green (Top)
        Color(0xFF245126), // Dark Forest Green (Bottom)
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // Dark Background
        borderRadius: BorderRadius.circular(30), // Pill Shape
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: subCategories.asMap().entries.map((entry) {
          int index = entry.key;
          String sub = entry.value;
          final isSelected = selectedSubCategory == sub;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedSubCategory = sub;
                });
                widget.onCategorySelected(selectedSubCategory);
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🔹 ICON (With Gradient Mask if Selected)
                        if (isSelected)
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                selectedGradient.createShader(bounds),
                            blendMode: BlendMode
                                .srcIn, // Applies gradient to icon shape
                            child: Image.asset(
                              subCategoryIcons[sub] ??
                                  "assets/images/music.png",
                              height: 24,
                              width: 24,
                              fit: BoxFit.contain,
                            ),
                          )
                        else
                          Image.asset(
                            subCategoryIcons[sub] ?? "assets/images/music.png",
                            height: 24,
                            width: 24,
                            fit: BoxFit.contain,
                            color: Colors.white, // Pure White for unselected
                          ),

                        const SizedBox(height: 6),

                        // 🔹 TEXT (With Gradient Mask if Selected)
                        if (isSelected)
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                selectedGradient.createShader(bounds),
                            child: Text(
                              sub,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors
                                    .white, // Base color required for ShaderMask
                              ),
                            ),
                          )
                        else
                          Text(
                            sub,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 🔹 Vertical Divider
                  if (index != subCategories.length - 1)
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
