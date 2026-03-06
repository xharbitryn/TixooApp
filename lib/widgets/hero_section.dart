import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tixxo/models/home_models.dart';
import 'package:tixxo/utils/responsive.dart';
import 'package:tixxo/widgets/top_bar.dart';
import 'package:tixxo/widgets/search_bar_widget.dart';

class HeroSection extends StatelessWidget {
  final LocationData location;
  final bool isPlusUser;
  final String? avatarUrl;
  final String lottieSource;
  final Color bgGradientStart;
  final Color bgGradientEnd;
  final VoidCallback? onLocationTap;
  final VoidCallback? onGetPlusTap;
  final VoidCallback? onAvatarTap;

  const HeroSection({
    super.key,
    required this.location,
    required this.lottieSource,
    required this.bgGradientStart,
    required this.bgGradientEnd,
    this.isPlusUser = false,
    this.avatarUrl,
    this.onLocationTap,
    this.onGetPlusTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    // Dynamically calculate whether the background is dark or light
    final topBarContentColor =
        ThemeData.estimateBrightnessForColor(bgGradientStart) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgGradientStart, bgGradientEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(r.radius(24)),
          bottomRight: Radius.circular(r.radius(24)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: r.h(6)),

            TopBar(
              location: location,
              isPlusUser: isPlusUser,
              avatarUrl: avatarUrl,
              contentColor: topBarContentColor,
              onLocationTap: onLocationTap,
              onGetPlusTap: onGetPlusTap,
              onAvatarTap: onAvatarTap,
            ),

            SizedBox(height: r.h(12)),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(16)),
              child: const SearchBarWidget(),
            ),

            SizedBox(height: r.h(8)),

            // Main Banner
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(16)),
              child: AspectRatio(
                aspectRatio: 2.4 / 1,
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: _buildLottieAnimation(),
                ),
              ),
            ),

            SizedBox(height: r.h(16)),

            // Category Tiles Row
            _buildCategoryRow(r, topBarContentColor),

            SizedBox(height: r.h(24)),
          ],
        ),
      ),
    );
  }

  Widget _buildLottieAnimation() {
    final isNetworkUrl =
        lottieSource.startsWith('http://') ||
        lottieSource.startsWith('https://');

    if (isNetworkUrl) {
      return Lottie.network(
        lottieSource,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        backgroundLoading: false,
      );
    } else {
      return Lottie.asset(
        lottieSource,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        backgroundLoading: false,
      );
    }
  }

  Widget _buildCategoryRow(Responsive r, Color contentColor) {
    final cardHeight = r.h(100);
    final cardWidth = r.w(95);

    final List<Map<String, dynamic>> categoryData = [
      {
        "title": "Live\nMusic",
        "icon": Icons.music_note_rounded,
        "color": Colors.deepPurpleAccent,
      },
      {
        "title": "Comedy\nShows",
        "icon": Icons.theater_comedy_rounded,
        "color": Colors.orangeAccent,
      },
      {
        "title": "Sports &\nGames",
        "icon": Icons.sports_basketball_rounded,
        "color": Colors.greenAccent,
      },
      {
        "title": "Workshops\n& Arts",
        "icon": Icons.palette_rounded,
        "color": Colors.pinkAccent,
      },
    ];

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: r.w(16)),
        itemCount: categoryData.length,
        itemBuilder: (context, index) {
          final category = categoryData[index];

          return Container(
            width: cardWidth,
            margin: EdgeInsets.only(right: r.w(12)),
            decoration: BoxDecoration(
              // Glassmorphism implementation for seamless blending
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(r.radius(16)),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: r.radius(10),
                  offset: Offset(0, r.h(2)),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: -r.h(12),
                  right: -r.w(12),
                  child: Icon(
                    category["icon"],
                    color: category["color"].withOpacity(0.15),
                    size: r.sp(64),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(r.w(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        category["icon"],
                        color: category["color"],
                        size: r.sp(22),
                      ),
                      const Spacer(),
                      Text(
                        category["title"],
                        style: TextStyle(
                          color: Colors
                              .black87, // Dark text for contrast against white glass
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
