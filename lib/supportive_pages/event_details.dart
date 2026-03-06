import 'dart:ui';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tixxo/supportive_pages/artist_detail.dart';
import 'package:tixxo/supportive_pages/promoter_detail.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/widgets/buttons/neopop_button/neopop_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tixxo/models/event.dart';
import 'package:tixxo/supportive_pages/ticket_selection.dart';
import 'package:tixxo/widgets/videoplayer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class EventPage extends StatefulWidget {
  final String eventId;

  const EventPage({super.key, required this.eventId});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> with TickerProviderStateMixin {
  late TabController _tabController;
  ScrollController? _nestedScrollController;
  bool _showTitleInAppBar = false;
  final GlobalKey _tabBarKey = GlobalKey();
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmittingReview = false;

  // Add favorite state variables
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  // Cache the event to prevent rebuilds
  Event? _cachedEvent;

  late ScrollController _scrollController;
  final List<GlobalKey> _sectionKeys = List.generate(6, (_) => GlobalKey());
  bool _isScrollingProgrammatically = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 6, vsync: this);
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  // Check if the event is already in user's favorites

  @override
  Widget build(BuildContext context) {
    if (widget.eventId.isEmpty) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: const Center(
          child: Text(
            "Invalid Event ID",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Events')
              .doc(widget.eventId)
              .snapshots(),
          builder: (context, snapshot) {
            // Show loading only on first load
            if (snapshot.connectionState == ConnectionState.waiting &&
                _cachedEvent == null) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB7FF1C)),
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  "Event not found",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            // Update cached event only when stream has new data
            if (snapshot.hasData && snapshot.data!.exists) {
              final eventData = snapshot.data!.data() as Map<String, dynamic>;
              eventData['id'] = widget.eventId;
              _cachedEvent = Event.fromJson(eventData);
            }

            // Use cached event for rendering
            final event = _cachedEvent!;
            final eventData = snapshot.data!.data() as Map<String, dynamic>;

            return Stack(
              children: [
                // Main scrollable content
                Column(
                  children: [
                    // Header with back button and conditional title
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        boxShadow: _showTitleInAppBar
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: _showTitleInAppBar
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            child: Text(
                                              event.name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: _isFavorite
                                    ? Stack(
                                        children: [
                                          // Green outline heart
                                          Icon(
                                            Icons.favorite,
                                            size: 24,
                                            color: Colors.green,
                                          ),
                                          // Black filled heart (smaller)
                                          Positioned.fill(
                                            child: Center(
                                              child: Icon(
                                                Icons.favorite,
                                                size: 20,
                                                color: Colors.black, // fill
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Icon(
                                        Icons.favorite_border,
                                        size: 24,
                                        color: Colors.green, // green outline
                                      ),
                                onPressed: _toggleFavorite,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main content
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo is ScrollUpdateNotification) {
                            _onScroll();
                            _updateActiveTab();
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Event media (video + poster swipe)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: Colors.white,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Hero(
                                          tag: widget.eventId,
                                          child:
                                              (event.videoUrl != null &&
                                                  event.videoUrl!.isNotEmpty)
                                              ? SizedBox(
                                                  height: 430,
                                                  width: double.infinity,
                                                  child: PageView(
                                                    children: [
                                                      AutoPlayVideo(
                                                        videoUrl:
                                                            event.videoUrl!,
                                                        borderRadius: 0,
                                                        fit: BoxFit.cover,
                                                      ),
                                                      CachedNetworkImage(
                                                        imageUrl: event.poster,
                                                        width: double.infinity,
                                                        height: 430,
                                                        fit: BoxFit.contain,
                                                        placeholder:
                                                            (
                                                              context,
                                                              url,
                                                            ) => Container(
                                                              height: 400,
                                                              color: Colors
                                                                  .grey[800],
                                                              child: const Center(
                                                                child: CircularProgressIndicator(
                                                                  valueColor:
                                                                      AlwaysStoppedAnimation<
                                                                        Color
                                                                      >(
                                                                        Color(
                                                                          0xFFB7FF1C,
                                                                        ),
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                        errorWidget:
                                                            (
                                                              context,
                                                              url,
                                                              error,
                                                            ) => Container(
                                                              height: 400,
                                                              color: Colors
                                                                  .grey[800],
                                                              child: const Icon(
                                                                Icons.error,
                                                                color: Colors
                                                                    .white,
                                                                size: 50,
                                                              ),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl: event.poster,
                                                  width: double.infinity,
                                                  height: 430,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                        height: 400,
                                                        color: Colors.grey[800],
                                                        child: const Center(
                                                          child: CircularProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                  Color
                                                                >(
                                                                  Color(
                                                                    0xFFB7FF1C,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                  errorWidget:
                                                      (
                                                        context,
                                                        url,
                                                        error,
                                                      ) => Container(
                                                        height: 400,
                                                        color: Colors.grey[800],
                                                        child: const Icon(
                                                          Icons.error,
                                                          color: Colors.black,
                                                          size: 50,
                                                        ),
                                                      ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Event title with gradient
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                            colors: [
                                              Color(0xFF202020),
                                              Color(0xFF15612E),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ).createShader(bounds),
                                      child: Text(
                                        event.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Gradient Divider
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black,
                                            Colors.grey,
                                            Colors.grey,
                                            Colors.white,
                                          ],
                                          stops: [0.0, 0.3, 0.7, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Date and Time
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[400],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.calendar_today_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Date and Time',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey[700],
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${DateFormat('EEE, dd MMM').format(event.startTime)}, ${DateFormat('h:mm a').format(event.startTime)}',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.black,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Transform.rotate(
                                          angle: -45 * 3.1415926535 / 180,
                                          child: Icon(
                                            Icons.arrow_forward,
                                            color: Color(0xFF15612E),
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Location
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[400],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.location_on_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Location',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                event.location,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Transform.rotate(
                                          angle: -45 * 3.1415926535 / 180,
                                          child: Icon(
                                            Icons.arrow_forward,
                                            color: Color(0xFF15612E),
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),

                            // Sticky Tab Bar
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _SliverTabBarDelegate(
                                TabBar(
                                  key: _tabBarKey,
                                  controller: _tabController,
                                  labelColor: Color(0xFF4EB152),
                                  unselectedLabelColor: Color(0xFF717680),
                                  indicatorColor: const Color(0xFF15612E),
                                  indicatorWeight: 2,
                                  isScrollable: true,
                                  tabAlignment: TabAlignment.start,
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onTap: (index) => _scrollToSection(index),
                                  tabs: [
                                    const Tab(text: 'About'),
                                    const Tab(text: 'Artist'),
                                    const Tab(text: 'Gallery'),
                                    const Tab(text: 'Organiser'),
                                    Tab(
                                      text: _hasEventEnded(event)
                                          ? 'Review'
                                          : 'Venue',
                                    ),
                                    if (snapshot.data!.data() != null &&
                                        (snapshot.data!.data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['moreInfo'] !=
                                            null &&
                                        ((snapshot.data!.data()
                                                    as Map<
                                                      String,
                                                      dynamic
                                                    >)['moreInfo']
                                                as String)
                                            .isNotEmpty)
                                      const Tab(text: 'More'),
                                  ],
                                ),
                              ),
                            ),
                            // All content sections vertically
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  // About Section
                                  Container(
                                    key: _sectionKeys[0],
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [_buildAboutTab(event)],
                                    ),
                                  ),

                                  // Artist Section
                                  Container(
                                    key: _sectionKeys[1],
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader('Artist'),
                                        _buildArtistTab(event),
                                      ],
                                    ),
                                  ),

                                  // Gallery Section
                                  Container(
                                    key: _sectionKeys[2],
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader('Gallery'),
                                        _buildGalleryTab(event),
                                      ],
                                    ),
                                  ),

                                  // Organiser Section
                                  Container(
                                    key: _sectionKeys[3],
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader('Organiser'),
                                        _buildOrganiserTab(event),
                                      ],
                                    ),
                                  ),

                                  // Venue/Review Section
                                  Container(
                                    key: _sectionKeys[4],
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader(
                                          _hasEventEnded(event)
                                              ? 'Review'
                                              : 'Venue',
                                        ),
                                        _hasEventEnded(event)
                                            ? _buildReviewTab(
                                                event,
                                                snapshot.data!.data()
                                                    as Map<String, dynamic>,
                                              )
                                            : _buildVenueTab(event),
                                      ],
                                    ),
                                  ),

                                  // More Section - Only show if moreInfo exists
                                  if (eventData['moreInfo'] != null &&
                                      (eventData['moreInfo'] as String)
                                          .isNotEmpty)
                                    Container(
                                      key: _sectionKeys[5],
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildSectionHeader('More'),
                                          _buildMoreTab(event, eventData),
                                        ],
                                      ),
                                    ),

                                  // Extra padding at bottom for bottom bar
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom section with price and book button - FIXED TO BOTTOM
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                      border: const Border(
                        top: BorderSide(color: Colors.grey, width: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Base Price',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                            Text(
                              _formatPrice(event.baseTicketPrice),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 35,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF245126), Color(0xFF4EB152)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TicketSelectionPage(
                                    eventId: widget.eventId,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Book Now',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  // NEW METHOD 1: Build Review Tab
  Widget _buildReviewTab(Event event, Map<String, dynamic> eventData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Review Form Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate Your Experience',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // Star Rating
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Color(0xFFFFD700),
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                if (_selectedRating > 0) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _getRatingText(_selectedRating),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Review Text Field
                Text(
                  'Write Your Review',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _reviewController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF15612E)),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),

                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmittingReview
                        ? null
                        : () => _submitReview(event, eventData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF15612E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmittingReview
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Submit Review',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Existing Reviews Section
          Text(
            'Reviews',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          _buildExistingReviews(event, eventData),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // NEW METHOD 2: Get Rating Text
  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  // NEW METHOD 3: Submit Review
  Future<void> _submitReview(
    Event event,
    Map<String, dynamic> eventData,
  ) async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please write a review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      // Get current user info
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Fetch user data from Users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'Anonymous';
      final userProfileUrl = userData['profileUrl'] ?? '';

      // Get promoterId from event
      final promoterId = eventData['promoterId'];
      if (promoterId == null) {
        throw Exception('Promoter ID not found');
      }

      // Create review document in promoters collection
      await FirebaseFirestore.instance
          .collection('promoters')
          .doc(promoterId)
          .collection('reviews')
          .add({
            'eventId': event.id,
            'eventName': event.name,
            'userId': currentUser.uid,

            'rating': _selectedRating,
            'comment': _reviewController.text.trim(),
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Clear form
      setState(() {
        _selectedRating = 0;
        _reviewController.clear();
        _isSubmittingReview = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Color(0xFF15612E),
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmittingReview = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NEW METHOD 4: Display Existing Reviews
  Widget _buildExistingReviews(Event event, Map<String, dynamic> eventData) {
    final promoterId = eventData['promoterId'];

    if (promoterId == null) {
      return Center(
        child: Text(
          'No reviews available',
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promoters')
          .doc(promoterId)
          .collection('reviews')
          .where('eventId', isEqualTo: event.id)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No reviews yet. Be the first to review!',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final reviewData = doc.data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info and rating
                  Row(
                    children: [
                      // User avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            reviewData['userProfileUrl'] != null &&
                                reviewData['userProfileUrl']
                                    .toString()
                                    .isNotEmpty
                            ? NetworkImage(reviewData['userProfileUrl'])
                            : null,
                        backgroundColor: Color(0xFF15612E).withOpacity(0.2),
                        child:
                            reviewData['userProfileUrl'] == null ||
                                reviewData['userProfileUrl'].toString().isEmpty
                            ? Icon(Icons.person, color: Color(0xFF15612E))
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // User name and stars
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reviewData['userName'] ?? 'Anonymous',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < (reviewData['rating'] ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Color(0xFFFFD700),
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),

                      // Timestamp
                      if (reviewData['timestamp'] != null)
                        Text(
                          _formatTimestamp(
                            reviewData['timestamp'] as Timestamp,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Review comment
                  Text(
                    reviewData['comment'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // NEW METHOD 5: Format Timestamp
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Add your other widget methods here (_buildSectionHeader, _buildAboutTab, etc.)

  // Add your other widget methods here (_buildSectionHeader, _buildAboutTab, etc.)
  Widget _buildVenueTab(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Google Map section
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    event.lat is String
                        ? double.parse(event.lat as String)
                        : event.lat,
                    event.long is String
                        ? double.parse(event.long as String)
                        : event.long,
                  ),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId("event_location"),
                    position: LatLng(
                      event.lat is String
                          ? double.parse(event.lat as String)
                          : event.lat,
                      event.long is String
                          ? double.parse(event.long as String)
                          : event.long,
                    ),
                    infoWindow: InfoWindow(title: event.location),
                  ),
                },
                zoomControlsEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Venue Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Venue Name
                if (event.venueInfo['name'] != null &&
                    event.venueInfo['name'].toString().isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Color(0xFF15612E),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.venueInfo['name'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Capacity
                if (event.venueInfo['capacity'] != null)
                  _buildVenueDetail(
                    Icons.people,
                    'Capacity',
                    '${event.venueInfo['capacity']} people',
                  ),
                if (event.venueInfo['capacity'] != null)
                  const SizedBox(height: 12),

                // Food & Beverages
                if (event.venueInfo['foodBeverages'] != null &&
                    event.venueInfo['foodBeverages'].toString().isNotEmpty)
                  _buildVenueDetail(
                    Icons.restaurant,
                    'Food & Beverages',
                    event.venueInfo['foodBeverages'].toString(),
                  ),
                if (event.venueInfo['foodBeverages'] != null &&
                    event.venueInfo['foodBeverages'].toString().isNotEmpty)
                  const SizedBox(height: 16),

                // Amenities Section
                if (event.venueInfo['amenities'] != null &&
                    event.venueInfo['amenities'] is Map) ...[
                  Text(
                    'Amenities',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (event.venueInfo['amenities']['wheelchairAccessible'] !=
                      null)
                    _buildVenueDetail(
                      Icons.accessible,
                      'Wheelchair Accessible',
                      event.venueInfo['amenities']['wheelchairAccessible'] ==
                              true
                          ? 'Available'
                          : 'Not Available',
                    ),
                  if (event.venueInfo['amenities']['wheelchairAccessible'] !=
                      null)
                    const SizedBox(height: 8),

                  if (event.venueInfo['amenities']['foodCourt'] != null)
                    _buildVenueDetail(
                      Icons.fastfood,
                      'Food Court',
                      event.venueInfo['amenities']['foodCourt'] == true
                          ? 'Available'
                          : 'Not Available',
                    ),
                  if (event.venueInfo['amenities']['foodCourt'] != null)
                    const SizedBox(height: 8),

                  if (event.venueInfo['amenities']['parking'] != null &&
                      event.venueInfo['amenities']['parking']
                          .toString()
                          .isNotEmpty)
                    _buildVenueDetail(
                      Icons.local_parking,
                      'Parking',
                      event.venueInfo['amenities']['parking'].toString(),
                    ),
                  if (event.venueInfo['amenities']['parking'] != null &&
                      event.venueInfo['amenities']['parking']
                          .toString()
                          .isNotEmpty)
                    const SizedBox(height: 8),

                  if (event.venueInfo['amenities']['security'] != null &&
                      event.venueInfo['amenities']['security']
                          .toString()
                          .isNotEmpty)
                    _buildVenueDetail(
                      Icons.security,
                      'Security',
                      event.venueInfo['amenities']['security'].toString(),
                    ),
                  if (event.venueInfo['amenities']['security'] != null &&
                      event.venueInfo['amenities']['security']
                          .toString()
                          .isNotEmpty)
                    const SizedBox(height: 8),

                  if (event.venueInfo['amenities']['smokingZone'] != null)
                    _buildVenueDetail(
                      Icons.smoking_rooms,
                      'Smoking Zone',
                      event.venueInfo['amenities']['smokingZone'] == true
                          ? 'Available'
                          : 'Not Available',
                    ),
                  if (event.venueInfo['amenities']['smokingZone'] != null)
                    const SizedBox(height: 8),

                  if (event.venueInfo['amenities']['washroomAvailable'] != null)
                    _buildVenueDetail(
                      Icons.wc,
                      'Washrooms',
                      event.venueInfo['amenities']['washroomAvailable'] == true
                          ? 'Available'
                          : 'Not Available',
                    ),
                  if (event.venueInfo['amenities']['washroomAvailable'] != null)
                    const SizedBox(height: 16),
                ],

                // Getting There Section
                if (event.venueInfo['gettingThere'] != null &&
                    event.venueInfo['gettingThere'] is Map) ...[
                  Text(
                    'Getting There',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (event.venueInfo['gettingThere']['metro'] != null &&
                      event.venueInfo['gettingThere']['metro']
                          .toString()
                          .isNotEmpty)
                    _buildVenueDetail(
                      Icons.subway,
                      'Metro',
                      event.venueInfo['gettingThere']['metro'].toString(),
                    ),
                  if (event.venueInfo['gettingThere']['metro'] != null &&
                      event.venueInfo['gettingThere']['metro']
                          .toString()
                          .isNotEmpty)
                    const SizedBox(height: 8),

                  if (event.venueInfo['gettingThere']['bus'] != null &&
                      event.venueInfo['gettingThere']['bus']
                          .toString()
                          .isNotEmpty)
                    _buildVenueDetail(
                      Icons.directions_bus,
                      'Bus',
                      event.venueInfo['gettingThere']['bus'].toString(),
                    ),
                  if (event.venueInfo['gettingThere']['bus'] != null &&
                      event.venueInfo['gettingThere']['bus']
                          .toString()
                          .isNotEmpty)
                    const SizedBox(height: 8),

                  if (event.venueInfo['gettingThere']['cab'] != null &&
                      event.venueInfo['gettingThere']['cab']
                          .toString()
                          .isNotEmpty)
                    _buildVenueDetail(
                      Icons.local_taxi,
                      'Cab',
                      event.venueInfo['gettingThere']['cab'].toString(),
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ticket Categories
          if (event.ticketCategories.isNotEmpty) ...[
            Text(
              'Ticket Categories',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...event.ticketCategories.map(
              (category) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFFB7FF1C).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.confirmation_number,
                        color: Color(0xFF15612E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category['name'] ?? 'Ticket',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '₹${category['price']} - ${category['description'] ?? ''}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Helper method for venue details
  Widget _buildVenueDetail(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Color(0xFF15612E), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    Colors.grey,
                    Colors.grey,
                    Colors.white,
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ), // <-- left & right padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Description first
          Text(
            event.description,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Event details with icons
          if (event.about['language'] != null &&
              event.about['language'].toString().isNotEmpty)
            _buildEventDetail(
              Icons.language,
              'Language',
              event.about['language'].toString(),
            ),
          if (event.about['language'] != null &&
              event.about['language'].toString().isNotEmpty)
            const SizedBox(height: 12),

          if (event.about['venueType'] != null &&
              event.about['venueType'].toString().isNotEmpty)
            _buildEventDetail(
              Icons.location_on,
              'Layout',
              event.about['venueType'].toString(),
            ),
          if (event.about['venueType'] != null &&
              event.about['venueType'].toString().isNotEmpty)
            const SizedBox(height: 12),

          if (event.about['duration'] != null &&
              event.about['duration'].toString().isNotEmpty)
            _buildEventDetail(
              Icons.schedule,
              'Duration',
              event.about['duration'].toString(),
            ),
          if (event.about['duration'] != null &&
              event.about['duration'].toString().isNotEmpty)
            const SizedBox(height: 12),

          if (event.about['ageLimit'] != null &&
              event.about['ageLimit'].toString().isNotEmpty)
            _buildEventDetail(
              Icons.person,
              'Age Limit',
              event.about['ageLimit'].toString(),
            ),
          if (event.about['ageLimit'] != null &&
              event.about['ageLimit'].toString().isNotEmpty)
            const SizedBox(height: 12),

          if (event.about['seating'] != null &&
              event.about['seating'].toString().isNotEmpty)
            _buildEventDetail(
              Icons.event_seat,
              'Seating',
              event.about['seating'].toString(),
            ),
          if (event.about['seating'] != null &&
              event.about['seating'].toString().isNotEmpty)
            const SizedBox(height: 12),

          // What to Expect section
          if (event.about['whatToExpect'] != null &&
              event.about['whatToExpect'] is List &&
              (event.about['whatToExpect'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildEventDetail(
              Icons.star,
              'What to Expect',
              (event.about['whatToExpect'] as List).join(', '),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFB3B3B3),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArtistTab(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.artistDetails.isNotEmpty) ...[
            ...event.artistDetails.map((artist) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildArtistCard(
                  artist['name'] ?? 'Unknown Artist',
                  artist['bio'] ?? 'No bio available',
                  artist['listeners'] ?? '',
                  artist['image'] ?? '',
                  artist['links'] as Map<String, dynamic>?, // Pass links
                  artist['artistId'] ??
                      '', // Pass artist ID (correct field name)
                ),
              );
            }).toList(),
          ] else ...[
            _buildArtistCard(
              'Artist Information',
              'Artist details will be updated soon. Stay tuned for exciting announcements!',
              'Coming Soon',
              '',
              null, // No links for placeholder
              '', // Empty artist ID for placeholder
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildArtistCard(
    String name,
    String description,
    String stats,
    String imageUrl,
    Map<String, dynamic>? links, // Add links parameter
    String artistId, // Add artist ID parameter
  ) {
    return GestureDetector(
      onTap: () {
        print('🎤 Tapping artist card: $name');
        print('🆔 Artist ID: $artistId');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistDetailPage(artistId: artistId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Artist Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // Artist Info and Icons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name and Arrow in same row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Color(0xFF000000), Color(0xFF4EB152)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: -45 * 3.1415926535 / 180,
                        child: Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF15612E),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Social Media Icons - Only show if links exist
                  if (links != null && links.isNotEmpty)
                    Row(
                      children: [
                        // Spotify Icon
                        if (links['spotify'] != null &&
                            links['spotify'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => _launchURL(links['spotify']),
                              child: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/images/spotify.svg',
                                    width: 34,
                                    height: 34,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // YouTube Music Icon
                        if (links['ytMusic'] != null &&
                            links['ytMusic'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => _launchURL(links['ytMusic']),
                              child: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/images/ytmusic.svg',
                                    width: 34,
                                    height: 34,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // YouTube Icon
                        if (links['yt'] != null && links['yt'].isNotEmpty)
                          GestureDetector(
                            onTap: () => _launchURL(links['yt']),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/images/yt.svg',
                                  width: 34,
                                  height: 34,
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

  Widget _buildGalleryTab(Event event) {
    String? selectedImage;

    return StatefulBuilder(
      builder: (context, setState) {
        return WillPopScope(
          onWillPop: () async {
            if (selectedImage != null) {
              setState(() {
                selectedImage = null;
              });
              return false; // Prevent page pop
            }
            return true;
          },
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  if (event.gallery.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ), // ADD HORIZONTAL PADDING
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.2,
                            ),
                        itemCount: event.gallery.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => setState(() {
                              selectedImage = event.gallery[index];
                            }),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                12,
                              ), // ROUNDED CORNERS
                              child: CachedNetworkImage(
                                imageUrl: event.gallery[index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFB7FF1C),
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[800],
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.grey[400],
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),

              // Enlarged image overlay
              if (selectedImage != null)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      selectedImage = null;
                    }),
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: selectedImage!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // New Organiser Tab
  Widget _buildOrganiserTab(Event event) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promoters')
          .where('uid', isEqualTo: event.promoterId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB7FF1C)),
              ),
            ),
          );
        }

        Map<String, dynamic>? promoter;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          promoter = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        }

        if (promoter == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Organiser information not available',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }

        final uid = promoter['uid'] ?? event.promoterId;
        final displayName = promoter['displayName'] ?? "Unknown Promoter";
        final email = promoter['email'] ?? "";

        // Get public data
        final publicData =
            promoter['publicdata'] as Map<String, dynamic>? ?? {};
        final photoURL = publicData['photoURL'] ?? promoter['photoURL'] ?? '';
        final businessName = publicData['businessName'] ?? displayName;
        final bio = publicData['bio'] ?? 'Verified promoter on Tixoo';
        final rating = (promoter['ratings'] ?? 0.0).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// --- Promoter Image ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: photoURL.isNotEmpty
                          ? Image.network(
                              photoURL,
                              width: 90,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 90,
                                    height: 120,
                                    color: const Color(0xFF2D2D2D),
                                    child: const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white54,
                                    ),
                                  ),
                            )
                          : Container(
                              width: 90,
                              height: 120,
                              color: const Color(0xFF2D2D2D),
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white54,
                              ),
                            ),
                    ),

                    const SizedBox(width: 14),

                    /// --- Info Column ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// --- Top Section: Business Name + Gradient Line ---
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Business Name with gradient text
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFF000000),
                                        Color(0xFF64CE68),
                                      ],
                                    ).createShader(bounds),
                                child: Text(
                                  businessName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(height: 4),

                              /// Gradient underline (black → grey)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black,
                                        Colors.grey,
                                        Colors.grey,
                                        Colors.white,
                                      ],
                                      stops: [0.0, 0.3, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          /// --- Middle Section: Bio ---
                          SizedBox(
                            height: 50,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                bio,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[700],
                                  height: 1.3,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          /// --- Bottom Section: Rating + Explore Button ---
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Color(0xFFFFC107),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),

                              /// Explore Button
                              SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PromoterDetailsPage(
                                              uid: uid,
                                              displayName: displayName,
                                              email: email,
                                              photoURL: photoURL,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF245126),
                                          Color(0xFF4EB152),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              8,
                                              0,
                                              0,
                                              0,
                                            ),
                                            child: Text(
                                              'Explore More',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              0,
                                              0,
                                              8,
                                              0,
                                            ),
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.arrow_forward,
                                                size: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Updated Venue Tab (removed organiser part)

  Widget _buildMoreTab(Event event, Map<String, dynamic> eventData) {
    // Access moreInfo directly from the map
    final String? moreInfo = eventData['moreInfo'] as String?;

    if (moreInfo == null || moreInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => _launchURL(moreInfo),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF15612E), size: 24),
              const SizedBox(width: 8),
              Text(
                "For more info click here",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15612E),
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, color: Color(0xFF15612E), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('favourites')
            .doc(widget.eventId)
            .get();

        if (mounted) {
          setState(() {
            _isFavorite = doc.exists;
          });
        }
      } catch (e) {
        debugPrint('Error checking favorite status: $e');
      }
    }
  }

  // Toggle favorite status with optimistic UI update
  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Show login prompt
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add favorites'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Optimistically update UI immediately (no loading state)
    final previousState = _isFavorite;
    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      final favoritesRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('favourites')
          .doc(widget.eventId);

      if (_isFavorite) {
        // Add to favorites
        await favoritesRef.set({
          'eventId': widget.eventId,
          'addedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              backgroundColor: Color(0xFFB7FF1C),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Remove from favorites
        await favoritesRef.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');

      // Revert to previous state on error
      if (mounted) {
        setState(() {
          _isFavorite = previousState;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasEventEnded(Event event) {
    if (event.endTime == null) return false;
    return DateTime.now().isAfter(event.endTime);
  }

  void _onScroll() {
    if (_nestedScrollController?.hasClients == true) {
      final showTitle = _nestedScrollController!.offset > 600;

      if (showTitle != _showTitleInAppBar) {
        setState(() {
          _showTitleInAppBar = showTitle;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  String _formatTime(DateTime startTime, DateTime endTime) {
    final start = DateFormat('h a').format(startTime);
    final end = DateFormat('h a').format(endTime);
    return '$start - $end';
  }

  String _formatPrice(int price) {
    return '₹${price.toString()}';
  }

  void _updateActiveTab() {
    if (_isScrollingProgrammatically) return;

    final scrollPosition = _scrollController.position.pixels;

    for (int i = _sectionKeys.length - 1; i >= 0; i--) {
      final key = _sectionKeys[i];
      final context = key.currentContext;

      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);

          if (position.dy <= 150) {
            if (_tabController.index != i) {
              _tabController.animateTo(i);
            }
            break;
          }
        }
      }
    }
  }

  Future<void> _scrollToSection(int index) async {
    _isScrollingProgrammatically = true;

    final key = _sectionKeys[index];
    final context = key.currentContext;

    if (context != null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final position = box.localToGlobal(Offset.zero);
        final currentScroll = _scrollController.position.pixels;

        final targetScroll = currentScroll + position.dy - 100;

        await _scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));
    _isScrollingProgrammatically = false;
  }

  // Helper method to launch URLs
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Handle error - you can show a snackbar or toast
      print('Could not launch $url');
    }
  }
}

// SliverTabBarDelegate (same as before)
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Color(0xFFF5F5F5), child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
