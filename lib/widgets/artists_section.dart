import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/constants/app_colors.dart';
import 'package:tixxo/models/home_models.dart';
import 'package:tixxo/utils/responsive.dart';
import 'package:tixxo/widgets/section_header.dart';

class ArtistsSection extends StatelessWidget {
  final List<ArtistData> artists;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<ArtistData>? onArtistTap;

  const ArtistsSection({
    super.key,
    required this.artists,
    this.onSeeAllTap,
    this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Column(
      children: [
        const SectionHeader(title: 'Artists on Tixoo'),
        SizedBox(height: r.h(4)),
        SizedBox(
          height: r.h(100),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: r.w(20)),
            physics: const BouncingScrollPhysics(),
            itemCount: artists.length,
            separatorBuilder: (_, __) => SizedBox(width: r.w(16)),
            itemBuilder: (context, index) {
              return _ArtistAvatar(
                artist: artists[index],
                onTap: () => onArtistTap?.call(artists[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ArtistAvatar extends StatelessWidget {
  final ArtistData artist;
  final VoidCallback? onTap;

  const _ArtistAvatar({required this.artist, this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: r.w(68),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: r.w(58),
                  height: r.w(58),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.25),
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(artist.imageUrl),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    ),
                    color: AppColors.chipBg,
                  ),
                ),
                if (artist.isVerified)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: r.w(18),
                      height: r.w(18),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.add,
                        color: AppColors.textWhite,
                        size: r.sp(10),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: r.h(6)),
            Text(
              artist.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.sp(10),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
