import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/constants/app_colors.dart';
import 'package:tixxo/models/home_models.dart';
import 'package:tixxo/utils/responsive.dart';
import 'package:tixxo/widgets/section_header.dart';

class OffersSection extends StatelessWidget {
  final List<OfferData> offers;
  final ValueChanged<OfferData>? onOfferTap;

  const OffersSection({super.key, required this.offers, this.onOfferTap});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Column(
      children: [
        const SectionHeader(title: 'Offers On Tixoo'),
        SizedBox(height: r.h(4)),
        SizedBox(
          height: r.h(130),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: r.w(16)),
            physics: const BouncingScrollPhysics(),
            itemCount: offers.length,
            separatorBuilder: (_, __) => SizedBox(width: r.w(12)),
            itemBuilder: (context, index) {
              return _OfferCard(
                offer: offers[index],
                onTap: () => onOfferTap?.call(offers[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferData offer;
  final VoidCallback? onTap;

  const _OfferCard({required this.offer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: r.wp(65),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2E1F), Color(0xFF0D1E12)],
          ),
          borderRadius: BorderRadius.circular(r.radius(16)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: r.radius(10),
              offset: Offset(0, r.h(4)),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -r.w(20),
              bottom: -r.h(20),
              child: Container(
                width: r.w(120),
                height: r.w(120),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(r.w(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    offer.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: r.sp(22),
                      fontWeight: FontWeight.w800,
                      color: AppColors.textWhite,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: r.h(6)),
                  Text(
                    offer.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: r.sp(11),
                      fontWeight: FontWeight.w400,
                      color: AppColors.textWhite.withOpacity(0.75),
                      height: 1.3,
                    ),
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
