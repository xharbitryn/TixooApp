import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary Brand Colors ────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF1DB954);
  static const Color darkGreen = Color(0xFF0D5F2C);
  static const Color getPlusGreen = Color(0xFF1A3C28);
  static const Color lightGreen = Color(0xFFE8F8EE);
  static const Color categorySelectedGreen = Color(0xFF2EBD6B);
  static const Color wantBadgeGreen = Color(0xFF2EBD6B);

  // ─── Background Colors ───────────────────────────────────────────
  static const Color scaffoldBg = Color(0xFFF9F9F9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color searchBarBg = Color(0xFFFFFFFF);
  static const Color chipBg = Color(0xFFF2F2F2);
  static const Color filterChipBg = Color(0xFFF5F5F5);

  // ─── Text Colors ─────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGreen = Color(0xFF1DB954);
  static const Color textPrice = Color(0xFF1DB954);

  // ─── Border / Divider Colors ─────────────────────────────────────
  static const Color border = Color(0xFFE0E0E0);
  static const Color searchBorder = Color(0xFFD9D9D9);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color sectionLine = Color(0xFFD0D0D0);

  // ─── Shadow Colors ───────────────────────────────────────────────
  static const Color cardShadow = Color(0x14000000);
  static const Color elevatedShadow = Color(0x1F000000);

  // ─── Status / Badge Colors ───────────────────────────────────────
  static const Color ratingStarYellow = Color(0xFFFFB800);
  static const Color errorRed = Color(0xFFE53935);

  // ─── Benefit Card Colors ─────────────────────────────────────────
  static const Color benefitGreen = Color(0xFF1A6B37);
  static const Color benefitOrange = Color(0xFFE8923E);
  static const Color benefitBlue = Color(0xFF1B4B8A);

  // ─── Hero Section Colors ─────────────────────────────────────────
  static const Color heroGreenText = Color(0xFF2EBD6B);
  static const Color heroBgTint = Color(0xFFF5EDE3);

  // ─── Trending Card ───────────────────────────────────────────────
  static const Color trendingCardBg = Color(0xFF1E2A20);
  static const Color trendingCardOverlay = Color(0xB3000000);

  // ═══ Trending Section (Figma-accurate values) ════════════════════
  static const Color trendingCardShadow = Color(0x12000000); // #000000 7%
  static const Color trendingDateColor = Color(0xFF15612E);
  static const List<Color> trendingTitleGradient = [
    Color(0xFF000000),
    Color(0xFF848484),
  ];
  static const Color trendingLocationColor = Color(0xFF181D27);
  static const Color trendingPriceColor = Color(0xFF181D27);
  static const Color trendingArrowColor = Color(0xFF15612E);
  static const List<Color> trendingDividerGradient = [
    Color(0xFF535353),
    Color(0xFFFFFFFF),
  ];
  static const List<Color> categorySelectedGradient = [
    Color(0xFF4EB152),
    Color(0xFF245126),
  ];
  static const List<Color> sectionTitleGradient = [
    Color(0xFF000000),
    Color(0xFF15612E),
  ];
}
