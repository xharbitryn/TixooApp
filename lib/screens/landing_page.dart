// lib/screens/landing_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import '../constants/design_constants.dart';
import 'home.dart'; // Existing production home page routing
import '../supportive_pages/location.dart'; // Assuming this maps to your location flow
import '../supportive_pages/profile.dart'; // Assuming this maps to your profile flow

// ============================================================
// SUGGESTION DATA
// ============================================================

enum _SuggType { artist, event, sports, club, venue }

class _SuggItem {
  final String query;
  final _SuggType type;
  const _SuggItem(this.query, this.type);
}

const List<_SuggItem> _kAllSuggestions = [
  _SuggItem('Arijit Singh Live Tour', _SuggType.artist),
  _SuggItem('Arijit Singh World Tour 2026', _SuggType.artist),
  _SuggItem('AP Dhillon Concert India', _SuggType.artist),
  _SuggItem('Diljit Dosanjh Live', _SuggType.artist),
  _SuggItem('Shreya Ghoshal Live', _SuggType.artist),
  _SuggItem('Nucleya Bass Camp', _SuggType.artist),
  _SuggItem('New Year Eve Party 2026', _SuggType.event),
  _SuggItem('Holi Festival Party 2026', _SuggType.event),
  _SuggItem('Stand Up Comedy Night', _SuggType.event),
  _SuggItem('Jazz Festival Mumbai', _SuggType.event),
  _SuggItem('Rock Night Bangalore', _SuggType.event),
  _SuggItem('Sunburn Festival 2026', _SuggType.event),
  _SuggItem('Lollapalooza India 2026', _SuggType.event),
  _SuggItem('IPL 2026 Tickets', _SuggType.sports),
  _SuggItem('India vs Pakistan T20', _SuggType.sports),
  _SuggItem('Pro Kabaddi League', _SuggType.sports),
  _SuggItem('ISL Football Matches', _SuggType.sports),
  _SuggItem('EDM Night Lucknow', _SuggType.club),
  _SuggItem('Bollywood Night Delhi', _SuggType.club),
  _SuggItem('Saturday Night Club', _SuggType.club),
  _SuggItem('Phoenix Palassio Events', _SuggType.venue),
  _SuggItem('Nucleus Mall Lucknow', _SuggType.venue),
  _SuggItem('DLF Cyberhub Shows', _SuggType.venue),
];

const List<_SuggItem> _kTrending = [
  _SuggItem('Sunburn Festival 2026', _SuggType.event),
  _SuggItem('Arijit Singh Live', _SuggType.artist),
  _SuggItem('IPL 2026 Tickets', _SuggType.sports),
  _SuggItem('Holi Party 2026', _SuggType.event),
  _SuggItem('EDM Night', _SuggType.club),
];

IconData _iconForType(_SuggType type) {
  switch (type) {
    case _SuggType.artist:
      return LucideIcons.mic2;
    case _SuggType.event:
      return LucideIcons.calendar;
    case _SuggType.sports:
      return LucideIcons.trophy;
    case _SuggType.club:
      return LucideIcons.disc;
    case _SuggType.venue:
      return LucideIcons.mapPin;
  }
}

Color _colorForType(_SuggType type) {
  switch (type) {
    case _SuggType.artist:
      return const Color(0xFF7C3AED);
    case _SuggType.event:
      return const Color(0xFF2563EB);
    case _SuggType.sports:
      return const Color(0xFFD97706);
    case _SuggType.club:
      return const Color(0xFF4EB152);
    case _SuggType.venue:
      return const Color(0xFF6B7280);
  }
}

// ============================================================
// STATE PROVIDERS (Integrated with Production Firebase)
// ============================================================

final isPremiumUserProvider = StateProvider<bool>((ref) => false);
final heroMediaUrlProvider = StateProvider<String?>(
  (ref) => 'assets/lottie/Loudspeaker.lottie',
);
final heroMediaTypeProvider = StateProvider<String>((ref) => 'lottie');

// Production Auth Hook
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ============================================================
// BASE SCREEN -> LANDING PAGE
// ============================================================

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

// ============================================================
// HEADER SECTION
// ============================================================

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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8FCF1), Color(0xFFA3E4D7)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: safeAreaInsets.top + DesignConstants.appBarTopPadding.r,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  DesignConstants.paddingHorizontalScreen.r +
                  math.max(safeAreaInsets.left, safeAreaInsets.right),
            ),
            child: _PerfectlyAlignedAppBar(
              breathingController: breathingController,
            ),
          ),
          SizedBox(height: 16.r),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  DesignConstants.paddingHorizontalScreen.r +
                  math.max(safeAreaInsets.left, safeAreaInsets.right),
            ),
            child: const _PerfectSearchBar(),
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

// ============================================================
// APP BAR
// ============================================================

class _PerfectlyAlignedAppBar extends ConsumerWidget {
  final AnimationController breathingController;

  const _PerfectlyAlignedAppBar({required this.breathingController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: DesignConstants.appBarHeight.r,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              label:
                  'Current location: Haldwani, Uttarakhand, India. Tap to change.',
              button: true,
              child: _ScaleOnTap(
                // Production navigation
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationPage()),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          DesignConstants.iconLocationPin,
                          height: DesignConstants.iconSizeLocation.sp,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF000000),
                            BlendMode.srcIn,
                          ),
                          placeholderBuilder: (_) => Icon(
                            Icons.location_on,
                            size: DesignConstants.iconSizeLocation.sp,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        SizedBox(width: 5.r),
                        Flexible(
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) =>
                                DesignConstants.textDarkGradient.createShader(
                                  Rect.fromLTWH(
                                    0,
                                    0,
                                    bounds.width,
                                    bounds.height,
                                  ),
                                ),
                            child: Text(
                              'Haldwani',
                              style: GoogleFonts.poppins(
                                fontSize:
                                    DesignConstants.fontSizeLocationCity.sp,
                                fontWeight: DesignConstants.fontWeightBold,
                                height: 1.0,
                                letterSpacing:
                                    DesignConstants.letterSpacingTight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 21.r),
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) =>
                            DesignConstants.textDarkGradient.createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                        child: Text(
                          'Uttarakhand, India',
                          style: GoogleFonts.poppins(
                            fontSize: DesignConstants.fontSizeLocationState.sp,
                            fontWeight: DesignConstants.fontWeightRegular,
                            height: 1.0,
                            letterSpacing: DesignConstants.letterSpacingTight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 10.r),
          Consumer(
            builder: (context, ref, _) {
              final isPremium = ref.watch(isPremiumUserProvider);
              if (isPremium) return const SizedBox.shrink();

              return Semantics(
                label: 'Get Tixoo Plus subscription',
                button: true,
                child: AnimatedBuilder(
                  animation: breathingController,
                  builder: (context, child) => _ScaleOnTap(
                    onTap: () {},
                    child: Container(
                      height: DesignConstants.heightGetPlusButton.r,
                      padding: EdgeInsets.symmetric(horizontal: 12.r),
                      decoration: BoxDecoration(
                        gradient: DesignConstants.primaryGreenGradient,
                        borderRadius: BorderRadius.circular(
                          DesignConstants.radiusGetPlusButton.r,
                        ),
                        boxShadow: DesignConstants.getPlusShadow(
                          breathingController.value,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              DesignConstants.iconBolt,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              height: DesignConstants.iconSizeBolt.sp,
                              placeholderBuilder: (_) => Icon(
                                Icons.flash_on,
                                color: Colors.white,
                                size: DesignConstants.iconSizeBolt.sp,
                              ),
                            ),
                            SizedBox(width: 5.r),
                            Text(
                              'Get Plus',
                              style: GoogleFonts.poppins(
                                color: DesignConstants.white,
                                fontSize: DesignConstants.fontSizeGetPlus.sp,
                                fontWeight: DesignConstants.fontWeightBold,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 10.r),
          Consumer(
            builder: (context, ref, _) {
              // Linked directly to production Firebase Auth
              final authState = ref.watch(authStateProvider);
              final isLoggedIn = authState.value != null;

              return Semantics(
                label: isLoggedIn ? 'View profile' : 'Sign up or login',
                button: true,
                child: _ScaleOnTap(
                  // Production Navigation
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ),
                  child: Container(
                    height: DesignConstants.sizeProfileAvatar.r,
                    width: DesignConstants.sizeProfileAvatar.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLoggedIn
                            ? const Color(0xFF4EB152)
                            : const Color(0xFFE0E0E0),
                        width: DesignConstants.widthProfileBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      color: isLoggedIn
                          ? Colors.white
                          : const Color(0xFFF5F5F5),
                    ),
                    child: isLoggedIn
                        ? ClipOval(
                            child: Image.network(
                              'https://i.pravatar.cc/150?img=11',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                LucideIcons.user,
                                color: Colors.grey[800],
                                size: 16.sp,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              LucideIcons.userPlus,
                              color: const Color(0xFF9E9E9E),
                              size: 15.sp,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SEARCH BAR
// ============================================================

class _PerfectSearchBar extends StatefulWidget {
  const _PerfectSearchBar();

  @override
  State<_PerfectSearchBar> createState() => _PerfectSearchBarState();
}

class _PerfectSearchBarState extends State<_PerfectSearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final ValueNotifier<String> _queryNotifier = ValueNotifier('');

  OverlayEntry? _overlayEntry;
  late AnimationController _overlayAnim;

  bool _isActive = false;
  List<String> _recentSearches = ['Arijit Singh', 'IPL Tickets'];

  @override
  void initState() {
    super.initState();
    _overlayAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _focusNode.addListener(_onFocusChanged);
    _textController.addListener(() {
      _queryNotifier.value = _textController.text;
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (!_isActive) setState(() => _isActive = true);
      _showOverlay();
    } else {
      if (_isActive) setState(() => _isActive = false);
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _overlayAnim.forward();
  }

  void _hideOverlay() {
    _overlayAnim.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (ctx) {
        return _SearchOverlayScaffold(
          layerLink: _layerLink,
          queryNotifier: _queryNotifier,
          animController: _overlayAnim,
          recentSearches: List.unmodifiable(_recentSearches),
          onSuggestionTap: _onSuggestionSelected,
          onFillQuery: _fillQuery,
          onClearRecent: _removeRecentSearch,
          onDismiss: _dismissSearch,
        );
      },
    );
  }

  void _onSuggestionSelected(String suggestion) {
    _textController.text = suggestion;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() {
      _recentSearches = [
        suggestion,
        ..._recentSearches.where((s) => s != suggestion),
      ].take(5).toList();
    });
    _focusNode.unfocus();
  }

  void _fillQuery(String suggestion) {
    _textController.text = suggestion;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _queryNotifier.value = suggestion;
    _overlayEntry?.markNeedsBuild();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _removeRecentSearch(String search) {
    setState(() {
      _recentSearches = _recentSearches.where((s) => s != search).toList();
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _dismissSearch() {
    _textController.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        label: 'Search for events, artists, promoters and venues',
        textField: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: DesignConstants.heightSearchBar.r,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              DesignConstants.radiusSearchBar.r,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isActive ? 0.10 : 0.05),
                blurRadius: _isActive ? 22 : 14,
                offset: Offset(0, _isActive ? 6 : 4),
              ),
              if (_isActive)
                BoxShadow(
                  color: const Color(0xFF4EB152).withOpacity(0.12),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
            ],
            border: Border.all(
              width: _isActive ? 1.5 : 1.0,
              color: _isActive
                  ? const Color(0xFF4EB152).withOpacity(0.6)
                  : const Color(0xFFE0E0E0).withOpacity(0.6),
            ),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: _isActive
                    ? GestureDetector(
                        key: const ValueKey('back'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_textController.text.isNotEmpty) {
                            _textController.clear();
                          } else {
                            _dismissSearch();
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.r),
                          child: Icon(
                            LucideIcons.arrowLeft,
                            color: const Color(0xFF4EB152),
                            size: 20.sp,
                          ),
                        ),
                      )
                    : GestureDetector(
                        key: const ValueKey('search'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _focusNode.requestFocus(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.r),
                          child: Icon(
                            LucideIcons.search,
                            color: const Color(0xFF9E9E9E),
                            size: 20.sp,
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: _isActive
                    ? TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF212121),
                          fontSize:
                              DesignConstants.fontSizeSearchPlaceholder.sp,
                          fontWeight: FontWeight.w400,
                          height: 1.0,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search events, artists, venues…',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFFBDBDBD),
                            fontSize:
                                DesignConstants.fontSizeSearchPlaceholder.sp,
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _onSuggestionSelected(value.trim());
                          }
                        },
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _focusNode.requestFocus(),
                        child: const _SmoothRotatingPlaceholder(),
                      ),
              ),
              if (_isActive)
                ValueListenableBuilder<String>(
                  valueListenable: _queryNotifier,
                  builder: (_, q, __) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: q.isNotEmpty
                        ? GestureDetector(
                            key: const ValueKey('clear'),
                            behavior: HitTestBehavior.opaque,
                            onTap: _textController.clear,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14.r),
                              child: Icon(
                                LucideIcons.x,
                                color: const Color(0xFF9E9E9E),
                                size: 18.sp,
                              ),
                            ),
                          )
                        : Padding(
                            key: const ValueKey('mic-active'),
                            padding: EdgeInsets.only(right: 14.r),
                            child: Icon(
                              LucideIcons.mic,
                              color: const Color(0xFFBDBDBD),
                              size: 18.sp,
                            ),
                          ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.only(right: 14.r),
                  child: Icon(
                    LucideIcons.mic,
                    color: const Color(0xFFBDBDBD),
                    size: 18.sp,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    _queryNotifier.dispose();
    _overlayAnim.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }
}

class _SearchOverlayScaffold extends StatelessWidget {
  final LayerLink layerLink;
  final ValueNotifier<String> queryNotifier;
  final AnimationController animController;
  final List<String> recentSearches;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<String> onFillQuery;
  final ValueChanged<String> onClearRecent;
  final VoidCallback onDismiss;

  const _SearchOverlayScaffold({
    required this.layerLink,
    required this.queryNotifier,
    required this.animController,
    required this.recentSearches,
    required this.onSuggestionTap,
    required this.onFillQuery,
    required this.onClearRecent,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: Offset(0, 8.r),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: AnimatedBuilder(
              animation: animController,
              builder: (_, child) => FadeTransition(
                opacity: CurvedAnimation(
                  parent: animController,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -0.06),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: queryNotifier,
                builder: (_, query, __) => _SuggestionPanel(
                  query: query,
                  recentSearches: recentSearches,
                  onSuggestionTap: onSuggestionTap,
                  onFillQuery: onFillQuery,
                  onClearRecent: onClearRecent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  final String query;
  final List<String> recentSearches;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<String> onFillQuery;
  final ValueChanged<String> onClearRecent;

  const _SuggestionPanel({
    required this.query,
    required this.recentSearches,
    required this.onSuggestionTap,
    required this.onFillQuery,
    required this.onClearRecent,
  });

  List<_SuggItem> get _filtered {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return _kAllSuggestions
        .where((s) => s.query.toLowerCase().contains(q))
        .take(7)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.isNotEmpty;
    final filtered = _filtered;
    final hasRecent = recentSearches.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignConstants.radiusSearchBar.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.97),
              borderRadius: BorderRadius.circular(
                DesignConstants.radiusSearchBar.r,
              ),
              border: Border.all(
                color: const Color(0xFF4EB152).withOpacity(0.18),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.11),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: const Color(0xFF4EB152).withOpacity(0.07),
                  blurRadius: 32,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasQuery) ...[
                  if (filtered.isNotEmpty) ...[
                    SizedBox(height: 6.r),
                    ...filtered.asMap().entries.map((e) {
                      final isLast = e.key == filtered.length - 1;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SuggestionRow(
                            item: e.value,
                            query: query,
                            onTap: () => onSuggestionTap(e.value.query),
                            onFill: () => onFillQuery(e.value.query),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: const Color(0xFFF0F0F0),
                              indent: 16.r,
                              endIndent: 16.r,
                            ),
                        ],
                      );
                    }),
                    SizedBox(height: 6.r),
                  ] else ...[
                    Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.searchX,
                            size: 16.sp,
                            color: const Color(0xFFBDBDBD),
                          ),
                          SizedBox(width: 10.r),
                          Flexible(
                            child: Text(
                              'No results for "$query"',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF9E9E9E),
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  if (hasRecent) ...[
                    _SectionHeader(
                      title: 'Recent Searches',
                      icon: LucideIcons.clock,
                      iconColor: const Color(0xFF9CA3AF),
                    ),
                    ...recentSearches.asMap().entries.map((e) {
                      final isLast = e.key == recentSearches.length - 1;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RecentRow(
                            text: e.value,
                            onTap: () => onSuggestionTap(e.value),
                            onFill: () => onFillQuery(e.value),
                            onRemove: () => onClearRecent(e.value),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: const Color(0xFFF0F0F0),
                              indent: 16.r,
                              endIndent: 16.r,
                            ),
                        ],
                      );
                    }),
                    Container(
                      height: 1,
                      margin: EdgeInsets.symmetric(vertical: 6.r),
                      color: const Color(0xFFF0F0F0),
                    ),
                  ],
                  _SectionHeader(
                    title: 'Trending Now',
                    icon: LucideIcons.trendingUp,
                    iconColor: const Color(0xFF4EB152),
                  ),
                  ..._kTrending.asMap().entries.map((e) {
                    final isLast = e.key == _kTrending.length - 1;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SuggestionRow(
                          item: e.value,
                          query: '',
                          onTap: () => onSuggestionTap(e.value.query),
                          onFill: () => onFillQuery(e.value.query),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: const Color(0xFFF0F0F0),
                            indent: 16.r,
                            endIndent: 16.r,
                          ),
                      ],
                    );
                  }),
                  SizedBox(height: 6.r),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 10.r),
      child: Row(
        children: [
          Icon(icon, size: 13.sp, color: iconColor),
          SizedBox(width: 6.r),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatefulWidget {
  final _SuggItem item;
  final String query;
  final VoidCallback onTap;
  final VoidCallback onFill;

  const _SuggestionRow({
    required this.item,
    required this.query,
    required this.onTap,
    required this.onFill,
  });

  @override
  State<_SuggestionRow> createState() => _SuggestionRowState();
}

class _SuggestionRowState extends State<_SuggestionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final typeColor = _colorForType(widget.item.type);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) {
        setState(() => _hovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered
            ? const Color(0xFF4EB152).withOpacity(0.05)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 11.r),
        child: Row(
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Icon(
                  _iconForType(widget.item.type),
                  size: 14.sp,
                  color: typeColor,
                ),
              ),
            ),
            SizedBox(width: 12.r),
            Expanded(
              child: _HighlightedText(
                text: widget.item.query,
                query: widget.query,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onFill,
              child: Padding(
                padding: EdgeInsets.only(left: 10.r),
                child: Icon(
                  LucideIcons.arrowUpRight,
                  size: 16.sp,
                  color: const Color(0xFF4EB152),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRow extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final VoidCallback onFill;
  final VoidCallback onRemove;

  const _RecentRow({
    required this.text,
    required this.onTap,
    required this.onFill,
    required this.onRemove,
  });

  @override
  State<_RecentRow> createState() => _RecentRowState();
}

class _RecentRowState extends State<_RecentRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) {
        setState(() => _hovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered
            ? const Color(0xFF4EB152).withOpacity(0.04)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 11.r),
        child: Row(
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                color: const Color(0xFF9CA3AF).withOpacity(0.10),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.clock,
                  size: 14.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),
            SizedBox(width: 12.r),
            Expanded(
              child: Text(
                widget.text,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF374151),
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onFill,
              child: Padding(
                padding: EdgeInsets.only(left: 6.r, right: 4.r),
                child: Icon(
                  LucideIcons.arrowUpRight,
                  size: 15.sp,
                  color: const Color(0xFF4EB152),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onRemove,
              child: Padding(
                padding: EdgeInsets.only(left: 4.r),
                child: Icon(
                  LucideIcons.x,
                  size: 14.sp,
                  color: const Color(0xFFD1D5DB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.poppins(
      fontSize: 12.sp,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF374151),
      height: 1.2,
    );

    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);

    if (idx == -1) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final highlightStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF4EB152),
    );

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: highlightStyle,
          ),
          if (idx + query.length < text.length)
            TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}

class _SmoothRotatingPlaceholder extends StatefulWidget {
  const _SmoothRotatingPlaceholder();

  @override
  State<_SmoothRotatingPlaceholder> createState() =>
      _SmoothRotatingPlaceholderState();
}

class _SmoothRotatingPlaceholderState extends State<_SmoothRotatingPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  static const _types = ['events', 'artists', 'promoters', 'venues'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _currentIndex = (_currentIndex + 1) % _types.length);
        _controller.forward(from: 0);
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'Search for ',
          style: GoogleFonts.poppins(
            color: const Color(0xFF9E9E9E),
            fontSize: DesignConstants.fontSizeSearchPlaceholder.sp,
            fontWeight: DesignConstants.fontWeightRegular,
            height: 1.0,
          ),
        ),
        Flexible(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final v = _controller.value;
              final opacity = v < 0.15
                  ? 0.3 + (v / 0.15) * 0.7
                  : v > 0.85
                  ? 1.0 - ((v - 0.85) / 0.15) * 0.7
                  : 1.0;
              final dy = math.sin(v * math.pi) * 2.0;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Text(
                    _types[_currentIndex],
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF4EB152),
                      fontSize: DesignConstants.fontSizeSearchPlaceholder.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HERO ANIMATION OR FALLBACK
// ============================================================

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

// ============================================================
// CATEGORY SECTION
// ============================================================

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
                    // Production routing injected here!
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
                    // Production routing injected here!
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
              // Production routing injected here!
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
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final double aspectRatio;
  final String bgImage;
  final Alignment imageAlignment;
  final bool isFullWidth;
  final String semanticLabel;
  final double imageScaleFactor;
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

// ============================================================
// FOOTER SECTION
// ============================================================

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

// ============================================================
// SHIMMERING GRADIENT TEXT (FIXED RENDER BUG)
// ============================================================

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
              gradient.colors[1], // EXACTLY 4 COLORS
            ],
            stops: [
              math.max(0, v - 0.3),
              v,
              math.min(1, v + 0.3),
              math.min(1, v + 0.6), // EXACTLY 4 STOPS
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
        },
        // We add color: Colors.white so the ShaderMask has a solid alpha channel to paint onto
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
  final double intervalStart;
  final double intervalEnd;
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
        if (animation.value > 0.8) {
          final overshoot = math.sin((animation.value - 0.8) * math.pi * 5) * 2;
          slideOffset -= overshoot;
        }
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
