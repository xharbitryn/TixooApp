import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import '../constants/design_constants.dart';
import '../models/home_models.dart';
import '../widgets/top_bar.dart'; // 🚀 Imported TopBar
import '../widgets/search_bar_widget.dart'; // 🚀 Imported Global SearchBar
import 'home.dart';
import '../supportive_pages/location.dart';
import '../supportive_pages/profile.dart';

final isPremiumUserProvider = StateProvider<bool>((ref) => false);
final heroMediaUrlProvider = StateProvider<String?>(
  (ref) => 'assets/lottie/Loudspeaker.lottie',
);
final heroMediaTypeProvider = StateProvider<String>((ref) => 'lottie');
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _shimmerController;
  late AnimationController _gradientController;
  late AnimationController _heroFloatController;
  late AnimationController _footerGlowController;
  late AnimationController _breathingGlowController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: DesignConstants.durationEntranceMedium,
    )..forward();
    _shimmerController = AnimationController(
      vsync: this,
      duration: DesignConstants.durationShimmer,
    )..repeat();
    _gradientController = AnimationController(
      vsync: this,
      duration: DesignConstants.durationGradientShift,
    )..repeat(reverse: true);
    _heroFloatController = AnimationController(
      vsync: this,
      duration: DesignConstants.durationFloating,
    )..repeat(reverse: true);
    _footerGlowController = AnimationController(
      vsync: this,
      duration: DesignConstants.durationGlow,
    )..repeat(reverse: true);
    _breathingGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shimmerController.dispose();
    _gradientController.dispose();
    _heroFloatController.dispose();
    _footerGlowController.dispose();
    _breathingGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaInsets = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: DesignConstants.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _EnhancedFadeSlideTransition(
              controller: _entranceController,
              intervalStart: 0.0,
              intervalEnd: 0.4,
              anticipate: true,
              child: _HeaderSection(
                shimmerController: _shimmerController,
                heroFloatController: _heroFloatController,
                breathingController: _breathingGlowController,
              ),
            ),
            SizedBox(height: DesignConstants.spacingPromoToCategories.r),
            _EnhancedFadeSlideTransition(
              controller: _entranceController,
              intervalStart: 0.3,
              intervalEnd: 0.7,
              anticipate: true,
              child: _CategorySection(entranceController: _entranceController),
            ),
            _EnhancedFadeSlideTransition(
              controller: _entranceController,
              intervalStart: 0.5,
              intervalEnd: 0.9,
              anticipate: true,
              child: _FooterSection(
                gradientController: _gradientController,
                glowController: _footerGlowController,
              ),
            ),
            SizedBox(height: 24.r + safeAreaInsets.bottom),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends ConsumerWidget {
  final AnimationController shimmerController;
  final AnimationController heroFloatController;
  final AnimationController breathingController;

  const _HeaderSection({
    required this.shimmerController,
    required this.heroFloatController,
    required this.breathingController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = ScreenUtil().screenWidth;
    final safeAreaInsets = MediaQuery.of(context).padding;

    final heroMediaUrl = ref.watch(heroMediaUrlProvider);
    final heroMediaType = ref.watch(heroMediaTypeProvider);
    final isPremium = ref.watch(isPremiumUserProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8FCF1), Color(0xFFA3E4D7)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: safeAreaInsets.top + DesignConstants.appBarTopPadding.r,
          ),

          // 🚀 FIX: Replaced custom header with your beautiful global TopBar
          TopBar(
            location: const LocationData(
              city: 'Haldwani',
              state: 'UK',
              country: 'India',
            ),
            isPlusUser: isPremium,
            contentColor: Colors.black,
            onLocationTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationPage()),
            ),
            onGetPlusTap: () {},
            onAvatarTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),

          SizedBox(height: 16.r),

          // 🚀 FIX: Replaced custom search with global SearchBarWidget
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  DesignConstants.paddingHorizontalScreen.r +
                  math.max(safeAreaInsets.left, safeAreaInsets.right),
            ),
            child: const SearchBarWidget(),
          ),

          SizedBox(height: 16.r),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  DesignConstants.paddingHorizontalScreen.r +
                  math.max(safeAreaInsets.left, safeAreaInsets.right),
            ),
            child: AspectRatio(
              aspectRatio: 2.4 / 1,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: _HeroAnimationOrFallback(
                  heroMediaUrl: heroMediaUrl,
                  heroMediaType: heroMediaType,
                  shimmerController: shimmerController,
                  floatController: heroFloatController,
                  breathingController: breathingController,
                  screenWidth: screenWidth,
                  safeAreaInsets: safeAreaInsets,
                  availableHeight: screenWidth / 2.4,
                  contentSafeTop: 0,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.r),
        ],
      ),
    );
  }
}

class _HeroAnimationOrFallback extends StatefulWidget {
  final String? heroMediaUrl;
  final String heroMediaType;
  final AnimationController shimmerController;
  final AnimationController floatController;
  final AnimationController breathingController;
  final double screenWidth;
  final EdgeInsets safeAreaInsets;
  final double availableHeight;
  final double contentSafeTop;

  const _HeroAnimationOrFallback({
    required this.heroMediaUrl,
    required this.heroMediaType,
    required this.shimmerController,
    required this.floatController,
    required this.breathingController,
    required this.screenWidth,
    required this.safeAreaInsets,
    required this.availableHeight,
    required this.contentSafeTop,
  });

  @override
  State<_HeroAnimationOrFallback> createState() =>
      _HeroAnimationOrFallbackState();
}

class _HeroAnimationOrFallbackState extends State<_HeroAnimationOrFallback> {
  bool _showMedia = true;

  @override
  void initState() {
    super.initState();
    if (widget.heroMediaUrl == null) _showMedia = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_showMedia && widget.heroMediaUrl != null) {
      return _DynamicHeroMedia(
        mediaUrl: widget.heroMediaUrl!,
        mediaType: widget.heroMediaType,
        floatController: widget.floatController,
        onLoadError: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _showMedia = false);
          });
        },
      );
    }
    return _StaticHeroContent(
      shimmerController: widget.shimmerController,
      floatController: widget.floatController,
      breathingController: widget.breathingController,
      screenWidth: widget.screenWidth,
      safeAreaInsets: widget.safeAreaInsets,
      availableHeight: widget.availableHeight,
      contentSafeTop: widget.contentSafeTop,
    );
  }
}

class _DynamicHeroMedia extends StatefulWidget {
  final String mediaUrl;
  final String mediaType;
  final AnimationController floatController;
  final VoidCallback onLoadError;

  const _DynamicHeroMedia({
    required this.mediaUrl,
    required this.mediaType,
    required this.floatController,
    required this.onLoadError,
  });

  @override
  State<_DynamicHeroMedia> createState() => _DynamicHeroMediaState();
}

class _DynamicHeroMediaState extends State<_DynamicHeroMedia> {
  bool _errorFired = false;

  void _fireError() {
    if (_errorFired) return;
    _errorFired = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoadError();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.floatController,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          0,
          math.sin(widget.floatController.value * 2 * math.pi) * 6,
        ),
        child: child,
      ),
      child: _buildMedia(),
    );
  }

  Widget _buildMedia() {
    switch (widget.mediaType) {
      case 'lottie':
        if (widget.mediaUrl.startsWith('http')) {
          return Lottie.network(
            widget.mediaUrl,
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
            errorBuilder: (_, __, ___) {
              _fireError();
              return const SizedBox.shrink();
            },
          );
        }
        return Lottie.asset(
          widget.mediaUrl,
          fit: BoxFit.contain,
          repeat: true,
          animate: true,
          errorBuilder: (_, __, ___) {
            _fireError();
            return const SizedBox.shrink();
          },
        );
      case 'svg':
        return SvgPicture.network(
          widget.mediaUrl,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const SizedBox.shrink(),
        );
      case 'image':
        return Image.network(
          widget.mediaUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            _fireError();
            return const SizedBox.shrink();
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StaticHeroContent extends StatelessWidget {
  final AnimationController shimmerController;
  final AnimationController floatController;
  final AnimationController breathingController;
  final double screenWidth;
  final EdgeInsets safeAreaInsets;
  final double availableHeight;
  final double contentSafeTop;

  const _StaticHeroContent({
    required this.shimmerController,
    required this.floatController,
    required this.breathingController,
    required this.screenWidth,
    required this.safeAreaInsets,
    required this.availableHeight,
    required this.contentSafeTop,
  });

  @override
  Widget build(BuildContext context) {
    final belowSearchBarHeight = availableHeight - contentSafeTop;

    return Stack(
      fit: StackFit.expand,
      children: [
        ...List.generate(8, (i) {
          final angle = i * math.pi * 2 / 8;
          final rPct = 0.20 + (i % 2) * 0.08;
          final cx = screenWidth * 0.5;
          final cy = contentSafeTop + belowSearchBarHeight * 0.40;
          return _FloatingParticle(
            controller: floatController,
            position: Offset(
              cx + (screenWidth * rPct * math.cos(angle)),
              cy + (belowSearchBarHeight * rPct * 0.6 * math.sin(angle)),
            ),
            delay: i * 0.125,
          );
        }),
        Positioned(
          top: contentSafeTop + 16.r,
          left: DesignConstants.paddingHorizontalScreen.r + safeAreaInsets.left,
          right: screenWidth * 0.42,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([
                  shimmerController,
                  breathingController,
                ]),
                builder: (_, __) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.r,
                    vertical: 5.r,
                  ),
                  decoration: BoxDecoration(
                    gradient: DesignConstants.assuredBadgeGradient,
                    borderRadius: BorderRadius.circular(
                      DesignConstants.radiusAssuredBadge.r,
                    ),
                    boxShadow: DesignConstants.assuredBadgeShadow(
                      shimmerController.value * breathingController.value,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        color: DesignConstants.white,
                        size: 10.sp,
                      ),
                      SizedBox(width: 4.r),
                      Text(
                        'Assured',
                        style: GoogleFonts.poppins(
                          color: DesignConstants.white,
                          fontSize: DesignConstants.fontSizeAssuredBadge.sp,
                          fontWeight: DesignConstants.fontWeightBold,
                          height: DesignConstants.lineHeightButton,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10.r),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => DesignConstants.cashbackTitleGradient
                    .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                child: Text(
                  '10% cashback',
                  style: GoogleFonts.poppins(
                    fontSize: DesignConstants.fontSizeCashbackTitle.sp,
                    fontWeight: DesignConstants.fontWeightBold,
                    height: DesignConstants.lineHeightDefault,
                  ),
                ),
              ),
              SizedBox(height: 4.r),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => DesignConstants.textDarkGradient
                    .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                child: Text(
                  'On every purchase\nwith Tixoo+',
                  style: GoogleFonts.poppins(
                    fontSize: DesignConstants.fontSizeCashbackSubtitle.sp,
                    fontWeight: DesignConstants.fontWeightRegular,
                    height: DesignConstants.lineHeightDefault,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: floatController,
          builder: (_, child) => Positioned(
            left: screenWidth * 0.35,
            right: 0,
            top:
                contentSafeTop +
                8.r +
                math.sin(floatController.value * 2 * math.pi) * 8,
            child: child!,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.48,
              maxHeight: belowSearchBarHeight * 0.75,
            ),
            child: Image.asset(
              DesignConstants.imagePromoMachine,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[200]!, Colors.grey[100]!],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[400],
                  size: 40.sp,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingParticle extends StatelessWidget {
  final AnimationController controller;
  final Offset position;
  final double delay;

  const _FloatingParticle({
    required this.controller,
    required this.position,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final v = (controller.value + delay) % 1.0;
        final dy = math.sin(v * 2 * math.pi) * 12;
        final dx = math.cos(v * 2 * math.pi) * 3;
        final opacity = 0.35 + math.sin(v * 2 * math.pi) * 0.25;
        final size = 7.r + math.sin(v * 2 * math.pi) * 2.r;
        return Positioned(
          left: position.dx + dx,
          top: position.dy + dy,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategorySection extends StatelessWidget {
  final AnimationController entranceController;

  const _CategorySection({required this.entranceController});

  @override
  Widget build(BuildContext context) {
    final safeAreaInsets = MediaQuery.of(context).padding;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal:
            DesignConstants.paddingHorizontalScreen.r +
            math.max(safeAreaInsets.left, safeAreaInsets.right),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EnhancedFadeSlideTransition(
                  controller: entranceController,
                  intervalStart: 0.4,
                  intervalEnd: 0.7,
                  anticipate: true,
                  child: _CategoryCard(
                    title: 'Events',
                    subtitle: 'Browse all events',
                    gradientColors: DesignConstants.eventsCardGradient.colors,
                    aspectRatio: DesignConstants.aspectRatioEventsCard,
                    bgImage: DesignConstants.imageEventsCard,
                    imageAlignment: DesignConstants.imageAlignmentEvents,
                    semanticLabel: 'Browse Events category',
                    imageScaleFactor: DesignConstants.imageScaleEvents,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const HomePage(eventCategory: 'basicEvent'),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: DesignConstants.spacingBetweenCategoryCards.r),
              Expanded(
                child: _EnhancedFadeSlideTransition(
                  controller: entranceController,
                  intervalStart: 0.45,
                  intervalEnd: 0.75,
                  anticipate: true,
                  child: _CategoryCard(
                    title: 'Sports',
                    subtitle: 'Browse all Sports events',
                    gradientColors: DesignConstants.sportsCardGradient.colors,
                    aspectRatio: DesignConstants.aspectRatioSportsCard,
                    bgImage: DesignConstants.imageSportsCard,
                    imageAlignment: DesignConstants.imageAlignmentSports,
                    semanticLabel: 'Browse Sports category',
                    imageScaleFactor: DesignConstants.imageScaleSports,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomePage(eventCategory: 'Sports'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignConstants.spacingBetweenCategoryRows.r),
          _EnhancedFadeSlideTransition(
            controller: entranceController,
            intervalStart: 0.5,
            intervalEnd: 0.8,
            anticipate: true,
            child: _CategoryCard(
              title: 'Club Events',
              subtitle: 'Browse all Club events',
              gradientColors: DesignConstants.clubCardGradient.colors,
              aspectRatio: DesignConstants.aspectRatioClubCard,
              bgImage: DesignConstants.imageClubCard,
              imageAlignment: DesignConstants.imageAlignmentClub,
              isFullWidth: true,
              semanticLabel: 'Browse Club Events category',
              imageScaleFactor: DesignConstants.imageScaleClub,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomePage(eventCategory: 'clubEvent'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title, subtitle, bgImage, semanticLabel;
  final List<Color> gradientColors;
  final double aspectRatio, imageScaleFactor;
  final Alignment imageAlignment;
  final bool isFullWidth;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.aspectRatio,
    required this.bgImage,
    required this.semanticLabel,
    required this.onTap,
    this.imageAlignment = Alignment.bottomRight,
    this.isFullWidth = false,
    this.imageScaleFactor = 0.85,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: DesignConstants.durationCardHover,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _hoverController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _hoverController.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _hoverController.reverse();
        },
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (_, child) => Transform.scale(
            scale: 1.0 - (_hoverController.value * 0.02),
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final cw = constraints.maxWidth;
                  final ch = constraints.maxHeight;
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(
                        DesignConstants.radiusCategoryCard.r,
                      ),
                      boxShadow: DesignConstants.categoryShadow(
                        hovered: _isPressed,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              DesignConstants.radiusCategoryCard.r,
                            ),
                            child: Align(
                              alignment: widget.imageAlignment,
                              child: SizedBox(
                                width: cw * widget.imageScaleFactor,
                                height: ch * widget.imageScaleFactor,
                                child: Image.asset(
                                  widget.bgImage,
                                  fit: BoxFit.contain,
                                  alignment: widget.imageAlignment,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(18.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (b) => DesignConstants
                                          .cashbackTitleGradient
                                          .createShader(
                                            Rect.fromLTWH(
                                              0,
                                              0,
                                              b.width,
                                              b.height,
                                            ),
                                          ),
                                      child: Text(
                                        widget.title,
                                        style: GoogleFonts.poppins(
                                          fontSize: DesignConstants
                                              .fontSizeCategoryTitle
                                              .sp,
                                          fontWeight:
                                              DesignConstants.fontWeightBold,
                                          height:
                                              DesignConstants.lineHeightDefault,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.r),
                                  SvgPicture.asset(
                                    DesignConstants.iconArrowUpRight,
                                    height: 14.sp,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF000000),
                                      BlendMode.srcIn,
                                    ),
                                    placeholderBuilder: (_) => Icon(
                                      Icons.arrow_outward,
                                      size: 14.sp,
                                      color: const Color(0xFF000000),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.r),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: cw * 0.65,
                                ),
                                child: Text(
                                  widget.subtitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: DesignConstants
                                        .fontSizeCategorySubtitle
                                        .sp,
                                    color: DesignConstants.categorySubtitle,
                                    fontWeight:
                                        DesignConstants.fontWeightRegular,
                                    height: DesignConstants.lineHeightDefault,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  final AnimationController gradientController;
  final AnimationController glowController;

  const _FooterSection({
    required this.gradientController,
    required this.glowController,
  });

  @override
  Widget build(BuildContext context) {
    final safeAreaInsets = MediaQuery.of(context).padding;

    return AnimatedBuilder(
      animation: Listenable.merge([gradientController, glowController]),
      builder: (_, child) => Container(
        width: double.infinity,
        margin: EdgeInsets.only(
          left:
              DesignConstants.paddingHorizontalScreen.r +
              math.max(safeAreaInsets.left, safeAreaInsets.right),
          right:
              DesignConstants.paddingHorizontalScreen.r +
              math.max(safeAreaInsets.left, safeAreaInsets.right),
          top: 12.r,
          bottom: math.max(16.r, safeAreaInsets.bottom + 8.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 36.r, horizontal: 20.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.lerp(
                DesignConstants.footerBackgroundGradient.colors[0],
                DesignConstants.footerBackgroundGradient.colors[1],
                gradientController.value * 0.4,
              )!,
              DesignConstants.footerBackgroundGradient.colors[1],
              DesignConstants.footerBackgroundGradient.colors[0],
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(DesignConstants.radiusFooter.r),
          boxShadow: DesignConstants.footerShadow(glowController.value),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ShimmeringGradientText(
              'Live Everyday!',
              style: GoogleFonts.poppins(
                fontSize: DesignConstants.fontSizeFooterTitle.sp,
                fontWeight: DesignConstants.fontWeightBold,
                height: DesignConstants.lineHeightDefault,
                shadows: [
                  Shadow(
                    color: const Color(0xFF4EB152).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              gradient: DesignConstants.footerTextGradient,
              shimmerController: gradientController,
            ),
            SizedBox(height: 12.r),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Created with ',
                    style: GoogleFonts.poppins(
                      color: DesignConstants.white.withOpacity(0.85),
                      fontSize: DesignConstants.fontSizeFooterCredit.sp,
                      height: DesignConstants.lineHeightDefault,
                    ),
                    maxLines: 1,
                  ),
                ),
                AnimatedBuilder(
                  animation: glowController,
                  builder: (_, child) => Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4EB152,
                          ).withOpacity(0.3 + glowController.value * 0.4),
                          blurRadius: 10 + glowController.value * 6,
                          spreadRadius: glowController.value * 2,
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      scale: 1.0 + glowController.value * 0.12,
                      child: Icon(
                        LucideIcons.heart,
                        color: const Color(0xFF4EB152),
                        size: 12.sp,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    ' in Lucknow, India',
                    style: GoogleFonts.poppins(
                      color: DesignConstants.white.withOpacity(0.85),
                      fontSize: DesignConstants.fontSizeFooterCredit.sp,
                      height: DesignConstants.lineHeightDefault,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmeringGradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  final AnimationController shimmerController;

  const _ShimmeringGradientText(
    this.text, {
    required this.style,
    required this.gradient,
    required this.shimmerController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (_, __) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
          final v = shimmerController.value;
          return LinearGradient(
            colors: [
              gradient.colors[0],
              gradient.colors[1],
              gradient.colors[0],
              gradient.colors[1],
            ],
            stops: [
              math.max(0, v - 0.3),
              v,
              math.min(1, v + 0.3),
              math.min(1, v + 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
        },
        child: Text(
          text,
          style: style.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EnhancedFadeSlideTransition extends StatelessWidget {
  final AnimationController controller;
  final double intervalStart, intervalEnd;
  final Widget child;
  final bool anticipate;

  const _EnhancedFadeSlideTransition({
    required this.controller,
    required this.intervalStart,
    required this.intervalEnd,
    required this.child,
    this.anticipate = false,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        intervalStart,
        intervalEnd,
        curve: anticipate
            ? const Cubic(0.36, 0, 0.66, -0.56)
            : Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        double slideOffset;
        if (anticipate && animation.value < 0.2) {
          slideOffset = 30 * (1 - animation.value) + (animation.value * 5);
        } else {
          slideOffset = 30 * (1 - animation.value);
        }
        if (animation.value > 0.8)
          slideOffset -= math.sin((animation.value - 0.8) * math.pi * 5) * 2;
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, slideOffset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleOnTap({required this.child, required this.onTap});

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DesignConstants.durationButtonScale,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
