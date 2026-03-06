// lib/constants/design_constants.dart

import 'package:flutter/material.dart';

/// Design System Constants - CORRECTED with exact Figma measurements
/// Frame: 440x956
class DesignConstants {
  // ==================== FRAME DIMENSIONS ====================
  static const Size designSize = Size(440, 956);

  // ==================== COLORS ====================
  static const LinearGradient primaryGreenGradient = LinearGradient(
    colors: [Color(0xFF245126), Color(0xFF4EB152)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient textDarkGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF949494)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cashbackTitleGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF15612E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient footerBackgroundGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF15612E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient footerTextGradient = LinearGradient(
    colors: [Color(0xFF4EB152), Color(0xFF245126)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient assuredBadgeGradient = LinearGradient(
    colors: [Color(0xFF241526), Color(0xFF4EB152)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color searchPlaceholder = Color(0xFFB3B3B3);
  static const Color searchBorder = Color(0xFFBBBDBB);
  static const Color categorySubtitle = Color(0xFF6B6B6B);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ==================== TYPOGRAPHY - EXACT FROM FIGMA ====================
  static const String fontFamily = 'Poppins';

  static const double fontSizeLocationCity = 10.0;
  static const double fontSizeLocationState = 8.0;
  static const double fontSizeGetPlus = 12.0;
  static const double fontSizeSearchPlaceholder = 12.0;
  static const double fontSizeAssuredBadge = 10.29;
  static const double fontSizeCashbackTitle = 20.0;
  static const double fontSizeCashbackSubtitle = 14.0;
  static const double fontSizeCategoryTitle = 20.0;
  static const double fontSizeCategorySubtitle = 8.0;
  static const double fontSizeFooterTitle = 36.0;
  static const double fontSizeFooterCredit = 8.57;

  static const double lineHeightLocation = 1.3;
  static const double lineHeightButton = 0.968;
  static const double lineHeightDefault = 1.2;

  static const double letterSpacingTight = -0.33;
  static const double letterSpacingNormal = 0.0;

  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightRegular = FontWeight.w400;

  // ==================== SPACING - FROM FIGMA SCREENSHOTS ====================
  static const double paddingHorizontalScreen = 20.0;
  static const double appBarTopPadding = 12.0;
  static const double appBarHeight = 44.0;
  static const double locationToSearchGap = 12.0;
  static const double searchBarTopOffset = 68.0;
  static const double spacingSearchToPromo = 16.0;
  static const double spacingPromoToCategories = 24.0;
  static const double spacingBetweenCategoryRows = 16.0;
  static const double spacingBetweenCategoryCards = 16.0;

  // ==================== DIMENSIONS ====================
  static const double heightGetPlusButton = 32.0;
  static const double sizeProfileAvatar = 36.0;
  static const double widthProfileBorder = 2.0;
  static const double iconSizeLocation = 16.0;
  static const double iconSizeBolt = 12.0;
  static const double heightSearchBar = 48.0;
  static const double searchBarBorderWidth = 1.0;
  static const double headerHeightRatio = 0.91;
  static const double uShapeCurveDepthRatio = 0.10;
  static const double promoCardHeightRatio = 0.37;

  // ==================== BORDER RADIUS ====================
  static const double radiusSearchBar = 16.0;
  static const double radiusAssuredBadge = 20.0;
  static const double radiusCategoryCard = 20.0;
  static const double radiusFooter = 24.0;
  static const double radiusGetPlusButton = 30.0;

  // ==================== SHADOWS ====================
  static List<BoxShadow> searchBarShadow({bool focused = false}) => [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(focused ? 0.08 : 0.04),
      blurRadius: focused ? 16 : 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> getPlusShadow(double breathingValue) => [
    BoxShadow(
      color: const Color(
        0xFF245126,
      ).withOpacity(0.25 + (breathingValue * 0.15)),
      blurRadius: 10 + (breathingValue * 6),
      offset: const Offset(0, 3),
      spreadRadius: breathingValue * 1.5,
    ),
  ];

  static List<BoxShadow> categoryShadow({bool hovered = false}) => [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(hovered ? 0.06 : 0.03),
      blurRadius: hovered ? 16 : 12,
      offset: Offset(0, hovered ? 6 : 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> assuredBadgeShadow(double glowValue) => [
    BoxShadow(
      color: const Color(0xFF245126).withOpacity(0.25 + (glowValue * 0.2)),
      blurRadius: 10 + (glowValue * 6),
      spreadRadius: glowValue * 2,
    ),
  ];

  static List<BoxShadow> footerShadow(double glowValue) => [
    BoxShadow(
      color: const Color(0xFF0D3D1A).withOpacity(0.5),
      blurRadius: 20,
      offset: const Offset(0, 10),
      spreadRadius: 1,
    ),
    BoxShadow(
      color: const Color(0xFF245126).withOpacity(0.15 + (glowValue * 0.25)),
      blurRadius: 30 + (glowValue * 15),
      spreadRadius: glowValue * 3,
    ),
  ];

  // ==================== ANIMATION DURATIONS ====================
  static const Duration durationEntranceFast = Duration(milliseconds: 350);
  static const Duration durationEntranceMedium = Duration(milliseconds: 500);
  static const Duration durationShimmer = Duration(milliseconds: 2000);
  static const Duration durationGradientShift = Duration(milliseconds: 3000);
  static const Duration durationFloating = Duration(milliseconds: 2500);
  static const Duration durationGlow = Duration(milliseconds: 4000);
  static const Duration durationButtonScale = Duration(milliseconds: 150);
  static const Duration durationCardHover = Duration(milliseconds: 300);
  static const Duration durationSearchPlaceholder = Duration(
    milliseconds: 3000,
  );

  // ==================== CATEGORY CARDS ====================
  static const double aspectRatioEventsCard = 0.85;
  static const double aspectRatioSportsCard = 0.85;
  static const double aspectRatioClubCard = 2.4;
  static const double imageScaleEvents = 0.85;
  static const double imageScaleSports = 0.80;
  static const double imageScaleClub = 0.85;

  static const Alignment imageAlignmentEvents = Alignment.bottomRight;
  static const Alignment imageAlignmentSports = Alignment.bottomCenter;
  static const Alignment imageAlignmentClub = Alignment.bottomRight;

  static const LinearGradient eventsCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0FDF4), Color(0xFFF9FCFA)],
  );

  static const LinearGradient sportsCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEFF6FF), Color(0xFFF4F8FC)],
  );

  static const LinearGradient clubCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAF5FF), Color(0xFFFCF4F8)],
  );

  // ==================== ASSET PATHS ====================
  static const String iconLocationPin = 'assets/icons/ic_location_pin.svg';
  static const String iconBolt = 'assets/icons/ic_bolt.svg';
  static const String iconArrowUpRight = 'assets/icons/ic_arrow_up_right.svg';
  static const String imagePromoMachine =
      'assets/images/img_cashback_machine_3d.png';
  static const String imageEventsCard = 'assets/images/img_card_events_bg.png';
  static const String imageSportsCard =
      'assets/images/img_sports_equipment_3d.png';
  static const String imageClubCard = 'assets/images/img_club_passes_3d.png';
  static const String fallbackPromo = 'assets/lottie/fallback_promo.json';

  // ==================== SEARCH PLACEHOLDER ANIMATION ====================
  static const List<String> searchPlaceholders = [
    'Search for events',
    'Search for artists',
    'Search for promoters',
    'Search for venues',
  ];
}
