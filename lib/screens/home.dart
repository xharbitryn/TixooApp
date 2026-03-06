// lib/screens/home.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/home_models.dart';
import '../utils/responsive.dart';
import '../providers/home_provider.dart';

// Sandbox Widgets
import '../widgets/all_events_section.dart';
import '../widgets/artists_section.dart';
import '../widgets/hero_section.dart';
import '../widgets/offers_section.dart';
import '../widgets/plus_benefits_section.dart';
import '../widgets/promoters_section.dart';
import '../widgets/trending_section.dart';

class HomePage extends ConsumerStatefulWidget {
  final String? eventCategory;

  const HomePage({super.key, this.eventCategory});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedCategoryIndex = 0;
  int _selectedFilterIndex = -1;
  final bool _isPlusUser = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    if (widget.eventCategory != null) {
      if (widget.eventCategory == 'Sports') _selectedCategoryIndex = 2;
    }
  }

  void _onFilterSelected(int index) {
    setState(() {
      _selectedFilterIndex = _selectedFilterIndex == index ? -1 : index;
    });
  }

  bool get _isAllSelected => _selectedCategoryIndex == 0;

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final homeDataState = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        top: false,
        bottom: false,
        child: homeDataState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
          error: (err, stack) =>
              Center(child: Text('Error loading events: $err')),
          data: (data) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: HeroSection(
                    location: const LocationData(
                      city: 'Haldwani',
                      state: 'UK',
                      country: 'India',
                    ),
                    isPlusUser: _isPlusUser,
                    // FIX: Pointing to the correct animation file
                    lottieSource: 'assets/animations/happy_banner.json',
                    bgGradientStart: const Color(0xFFFFF5E1),
                    bgGradientEnd: const Color(0xFFFFB347),
                    onLocationTap: () {},
                    onGetPlusTap: () {},
                    onAvatarTap: () {},
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: r.h(32))),

                // If DB is totally empty, show a nice fallback message so we know it didn't crash
                if (data.allEvents.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(r.w(20)),
                      child: Center(
                        child: Text(
                          "No events found in the database yet!",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: r.sp(14),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_isAllSelected && data.trendingEvents.isNotEmpty)
                  SliverToBoxAdapter(
                    child: TrendingSection(events: data.trendingEvents),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: r.h(8))),

                if (_isAllSelected && data.artists.isNotEmpty)
                  SliverToBoxAdapter(
                    child: ArtistsSection(
                      artists: data.artists,
                      onSeeAllTap: () {},
                      onArtistTap: (artist) {},
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: r.h(8))),

                if (data.allEvents.isNotEmpty)
                  SliverToBoxAdapter(
                    child: AllEventsSection(
                      events: data.allEvents,
                      selectedFilterIndex: _selectedFilterIndex,
                      onFilterSelected: _onFilterSelected,
                      onEventTap: (event) {},
                      onBookNowTap: (event) {},
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: r.h(16))),

                SliverToBoxAdapter(
                  child: OffersSection(
                    offers: const [
                      OfferData(
                        id: 'o1',
                        title: '10% Cashback',
                        subtitle: 'on HDFC Bank Debit &\nCredit Cards',
                        imageUrl:
                            'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400',
                      ),
                      OfferData(
                        id: 'o2',
                        title: '15% Off',
                        subtitle: 'on First Booking\nwith Tixoo Plus',
                        imageUrl:
                            'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400',
                      ),
                    ],
                    onOfferTap: (offer) {},
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: r.h(16))),

                if (data.promoters.isNotEmpty)
                  SliverToBoxAdapter(
                    child: PromotersSection(
                      promoters: data.promoters,
                      onSeeAllTap: () {},
                      onPromoterTap: (promoter) {},
                      onExploreTap: (promoter) {},
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: r.h(16))),

                SliverToBoxAdapter(
                  child: PlusBenefitsSection(
                    benefits: const [],
                    isVisible: !_isPlusUser,
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: r.h(20))),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: r.h(30)),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Tixoo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: ' > ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextSpan(
                              text: 'District',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
