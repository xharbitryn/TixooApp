import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/constants/app_colors.dart';
import 'package:tixxo/models/home_models.dart';
import 'package:tixxo/utils/responsive.dart';

class CategoryStrip extends StatelessWidget {
  final List<CategoryItem> categories;
  final ValueChanged<int>? onCategorySelected;
  final VoidCallback? onMenuTap;

  const CategoryStrip({
    super.key,
    required this.categories,
    this.onCategorySelected,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: r.h(4)),
      height: r.h(70),
      child: Row(
        children: [
          // Hamburger / filter menu icon
          GestureDetector(
            onTap: onMenuTap,
            child: Container(
              width: r.w(44),
              margin: EdgeInsets.only(left: r.w(16)),
              alignment: Alignment.center,
              child: Container(
                width: r.w(40),
                height: r.w(40),
                decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.circular(r.radius(12)),
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: AppColors.textPrimary,
                  size: r.sp(20),
                ),
              ),
            ),
          ),

          SizedBox(width: r.w(6)),

          // Horizontal scrollable category chips
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: r.w(4), right: r.w(16)),
              itemCount: categories.length,
              separatorBuilder: (_, __) => SizedBox(width: r.w(10)),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return _CategoryChip(
                  category: cat,
                  onTap: () => onCategorySelected?.call(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback? onTap;

  const _CategoryChip({required this.category, this.onTap});

  IconData _getIconForCategory(String iconPath) {
    switch (iconPath) {
      case 'menu':
        return Icons.grid_view_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'mic':
        return Icons.mic_rounded;
      case 'book':
        return Icons.auto_stories_rounded;
      case 'theater':
        return Icons.theater_comedy_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final isSelected = category.isSelected;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: r.w(48),
            height: r.w(48),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.categorySelectedGreen
                  : AppColors.chipBg,
              borderRadius: BorderRadius.circular(r.radius(14)),
            ),
            child: Icon(
              _getIconForCategory(category.iconPath),
              color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
              size: r.sp(22),
            ),
          ),
          SizedBox(height: r.h(4)),
          Text(
            category.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: r.sp(10),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
