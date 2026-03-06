import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Changed to relative imports for production compatibility!
import '../constants/app_colors.dart';
import '../models/home_models.dart';
import '../utils/responsive.dart';
import '../utils/gradient_text.dart';
import '../widgets/section_header.dart';

class TrendingSection extends StatefulWidget {
  final List<TrendingEvent> events;
  final Function(TrendingEvent)? onEventTap; // 🚀 ADDED: Tap callback

  const TrendingSection({
    super.key,
    required this.events,
    this.onEventTap, // 🚀 ADDED: Tap callback
  });

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> {
  late final PageController _pageController;
  double _currentPage = 0;
  Timer? _autoSlideTimer;
  bool _isUserInteracting = false;

  // Infinite loop: multiply count so user can scroll endlessly
  int get _virtualCount => widget.events.length <= 3
      ? widget.events.length * 100
      : widget.events.length;

  int get _initialPage =>
      widget.events.length <= 3 ? widget.events.length * 50 : 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.68,
      initialPage: _initialPage,
    );
    _currentPage = _initialPage.toDouble();
    _pageController.addListener(_onPageScroll);
    _startAutoSlide();
  }

  void _onPageScroll() {
    if (mounted) {
      setState(() {
        _currentPage = _pageController.page ?? _currentPage;
      });
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_isUserInteracting && _pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _onUserInteractionStart() {
    _isUserInteracting = true;
    _autoSlideTimer?.cancel();
  }

  void _onUserInteractionEnd() {
    _isUserInteracting = false;
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isUserInteracting) {
        _startAutoSlide();
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Column(
      children: [
        const SectionHeader(title: 'Trending this week'),

        // Carousel — Figma card H 500 + vertical pop space
        SizedBox(
          height: r.h(520),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _onUserInteractionStart();
              } else if (notification is ScrollEndNotification) {
                _onUserInteractionEnd();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: _virtualCount,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final realIndex = index % widget.events.length;
                return _buildTrendingCard(context, index, realIndex, r);
              },
            ),
          ),
        ),

        SizedBox(height: r.h(10)),

        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.events.length,
            (index) => _buildDot(index, r),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCard(
    BuildContext context,
    int virtualIndex,
    int realIndex,
    Responsive r,
  ) {
    final event = widget.events[realIndex];
    final diff = (virtualIndex - _currentPage).abs();

    // Pop animation values
    final scale = math.max(0.88, 1.0 - diff * 0.1);
    final translateY = diff * r.h(18); // Center UP, sides DOWN
    final opacity = math.max(0.55, 1.0 - diff * 0.3);

    return Transform.translate(
      offset: Offset(0, translateY),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: GestureDetector(
            // 🚀 ADDED: Triggers the navigation to Event Details!
            onTap: () {
              if (widget.onEventTap != null) {
                widget.onEventTap!(event);
              }
            },
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: r.w(6),
                vertical: r.h(20), // Space for pop animation travel
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                // Figma: radius 30
                borderRadius: BorderRadius.circular(r.radius(30)),
                // Figma shadow: #000000 7%, blur 24.6, spread 7, X:0 Y:5
                boxShadow: [
                  BoxShadow(
                    color: AppColors.trendingCardShadow,
                    blurRadius: r.h(24.6),
                    spreadRadius: r.h(7),
                    offset: Offset(0, r.h(5)),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Event Image ────────────────────────────────
                  Expanded(
                    flex: 340,
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.all(r.w(9)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(r.radius(22)),
                        color: const Color(0xFFE8E8E8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ─── Event Details ──────────────────────────────
                  Expanded(
                    flex: 160,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.w(18),
                        vertical: r.h(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.dateTime,
                            style: GoogleFonts.poppins(
                              fontSize: r.sp(10),
                              fontWeight: FontWeight.w400,
                              height: 18 / 10,
                              letterSpacing: 0,
                              color: AppColors.trendingDateColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: r.h(4)),

                          Flexible(
                            child: GradientText(
                              text: event.title,
                              style: GoogleFonts.poppins(
                                fontSize: r.sp(16),
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                letterSpacing: 0,
                              ),
                              colors: AppColors.trendingTitleGradient,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          SizedBox(height: r.h(4)),

                          Container(
                            height: r.h(1),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFF535353), Color(0xFFFFFFFF)],
                              ),
                            ),
                          ),

                          SizedBox(height: r.h(4)),

                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: r.sp(12),
                                color: AppColors.trendingLocationColor
                                    .withOpacity(0.5),
                              ),
                              SizedBox(width: r.w(2)),
                              Expanded(
                                child: Text(
                                  '${event.venue}, ${event.city}',
                                  style: GoogleFonts.poppins(
                                    fontSize: r.sp(12),
                                    fontWeight: FontWeight.w400,
                                    height: 18 / 12,
                                    color: AppColors.trendingLocationColor
                                        .withOpacity(0.5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.near_me_rounded,
                                color: AppColors.trendingArrowColor,
                                size: r.sp(16),
                              ),
                            ],
                          ),

                          SizedBox(height: r.h(4)),

                          Text(
                            event.priceFormatted,
                            style: GoogleFonts.poppins(
                              fontSize: r.sp(12),
                              fontWeight: FontWeight.w600,
                              height: 18 / 12,
                              color: AppColors.trendingPriceColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index, Responsive r) {
    final realCurrentPage = _currentPage.round() % widget.events.length;
    final isActive = index == realCurrentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.symmetric(horizontal: r.w(3)),
      width: isActive ? r.w(20) : r.w(6),
      height: r.w(6),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(colors: AppColors.categorySelectedGradient)
            : null,
        color: isActive ? null : const Color(0xFFD0D0D0),
        borderRadius: BorderRadius.circular(r.w(3)),
      ),
    );
  }
}
