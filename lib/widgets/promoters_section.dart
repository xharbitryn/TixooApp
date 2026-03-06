import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/constants/app_colors.dart';
import 'package:tixxo/models/home_models.dart';
import 'package:tixxo/utils/responsive.dart';
import 'package:tixxo/widgets/section_header.dart';

class PromotersSection extends StatelessWidget {
  final List<PromoterData> promoters;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<PromoterData>? onPromoterTap;
  final ValueChanged<PromoterData>? onExploreTap;

  const PromotersSection({
    super.key,
    required this.promoters,
    this.onSeeAllTap,
    this.onPromoterTap,
    this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Column(
      children: [
        const SectionHeader(title: 'Promoters On Tixoo'),
        SizedBox(height: r.h(4)),
        SizedBox(
          height: r.h(180),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: r.w(16)),
            physics: const BouncingScrollPhysics(),
            itemCount: promoters.length,
            separatorBuilder: (_, __) => SizedBox(width: r.w(12)),
            itemBuilder: (context, index) {
              return _PromoterCard(
                promoter: promoters[index],
                onTap: () => onPromoterTap?.call(promoters[index]),
                onExplore: () => onExploreTap?.call(promoters[index]),
              );
            },
          ),
        ),
        SizedBox(height: r.h(14)),
        GestureDetector(
          onTap: onSeeAllTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'See All Promoters',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.sp(13),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: r.w(6)),
              Container(
                width: r.w(24),
                height: r.w(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textPrimary, width: 1.5),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: r.sp(14),
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromoterCard extends StatelessWidget {
  final PromoterData promoter;
  final VoidCallback? onTap;
  final VoidCallback? onExplore;

  const _PromoterCard({required this.promoter, this.onTap, this.onExplore});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: r.wp(82),
        padding: EdgeInsets.all(r.w(14)),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(r.radius(16)),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: r.radius(8),
              offset: Offset(0, r.h(3)),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: r.w(80),
              height: r.h(130),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r.radius(12)),
                color: AppColors.chipBg,
                image: DecorationImage(
                  image: NetworkImage(promoter.imageUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                ),
              ),
            ),
            SizedBox(width: r.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promoter.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: r.sp(15),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: r.h(6)),
                  Expanded(
                    child: Text(
                      promoter.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.sp(10),
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: r.h(6)),
                  Row(
                    children: [
                      Text(
                        promoter.rating.toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.sp(13),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: r.w(3)),
                      Icon(
                        Icons.star_rounded,
                        color: AppColors.ratingStarYellow,
                        size: r.sp(14),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onExplore,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.w(12),
                            vertical: r.h(6),
                          ),
                          decoration: BoxDecoration(
                            // Implementing the universal gradient here
                            gradient: const LinearGradient(
                              colors: [Color(0xFF245126), Color(0xFF4EB152)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(r.radius(8)),
                          ),
                          child: Text(
                            'Explore more',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: r.sp(10),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
