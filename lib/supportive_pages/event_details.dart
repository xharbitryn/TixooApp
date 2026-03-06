import 'dart:ui';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tixxo/supportive_pages/artist_detail.dart';
import 'package:tixxo/supportive_pages/promoter_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tixxo/models/event.dart';
import 'package:tixxo/supportive_pages/ticket_selection.dart';
import 'package:tixxo/widgets/videoplayer.dart';
import 'package:url_launcher/url_launcher.dart';

class _AppColors {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color border = Color(0xFFE0E0E0);
  static const Color spotify = Color(0xFF1DB954);
  static const Color appleMusic = Color(0xFFFA243C);
  static const Color youtube = Color(0xFFFF0000);
  static const Color starYellow = Color(0xFFFFC107);
  static const Color iconPrimary = Color(0xFF1A1A1A);
}

class EventPage extends StatefulWidget {
  final String eventId;
  const EventPage({super.key, required this.eventId});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmittingReview = false;
  bool _isFavorite = false;

  Event? _cachedEvent;

  late final Stream<DocumentSnapshot> _eventStream;

  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _artistKey = GlobalKey();
  final GlobalKey _galleryKey = GlobalKey();
  final GlobalKey _venueKey = GlobalKey();
  final GlobalKey _organiserKey = GlobalKey();
  final GlobalKey _moreKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _eventStream = FirebaseFirestore.instance
        .collection('Events')
        .doc(widget.eventId)
        .snapshots();

    _scrollController.addListener(_onScroll);
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showTitle = _scrollController.offset > 300;
    if (showTitle != _showAppBarTitle) {
      setState(() => _showAppBarTitle = showTitle);
    }
  }

  void _scrollToSection(int index) {
    GlobalKey? targetKey;
    switch (index) {
      case 0:
        targetKey = _aboutKey;
        break;
      case 1:
        targetKey = _artistKey;
        break;
      case 2:
        targetKey = _galleryKey;
        break;
      case 3:
        targetKey = _venueKey;
        break;
      case 4:
        targetKey = _organiserKey;
        break;
      case 5:
        targetKey = _moreKey;
        break;
    }

    if (targetKey?.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
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
        if (mounted) setState(() => _isFavorite = doc.exists);
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add favorites'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final previousState = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);

    try {
      final favoritesRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('favourites')
          .doc(widget.eventId);
      if (_isFavorite) {
        await favoritesRef.set({
          'eventId': widget.eventId,
          'addedAt': FieldValue.serverTimestamp(),
        });
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              backgroundColor: Color(0xFFB7FF1C),
            ),
          );
      } else {
        await favoritesRef.delete();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              backgroundColor: Colors.grey,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavorite = previousState);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _hasEventEnded(Event event) {
    if (event.endTime == null) return false;
    return DateTime.now().isAfter(event.endTime);
  }

  void _openGalleryView(List<dynamic> gallery, int initialIndex) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: gallery.length,
                controller: PageController(initialPage: initialIndex),
                itemBuilder: (context, idx) {
                  return InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: gallery[idx],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: _AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 50,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventId.isEmpty) {
      return const Scaffold(
        backgroundColor: _AppColors.background,
        body: Center(child: Text("Invalid Event ID")),
      );
    }

    return Scaffold(
      backgroundColor: _AppColors.background,
      bottomNavigationBar: _cachedEvent != null
          ? _buildBottomBar(_cachedEvent!)
          : null,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _eventStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _cachedEvent == null) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB7FF1C)),
                ),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists)
              return const Center(child: Text("Event not found"));

            final eventData = snapshot.data!.data() as Map<String, dynamic>;
            eventData['id'] = widget.eventId;
            _cachedEvent = Event.fromJson(eventData);
            final event = _cachedEvent!;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: 0,
                  pinned: true,
                  backgroundColor: _AppColors.background,
                  surfaceTintColor: Colors.transparent,
                  leading: _buildAppBarButton(
                    Icons.arrow_back,
                    () => Navigator.pop(context),
                  ),
                  title: AnimatedOpacity(
                    opacity: _showAppBarTitle ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      event.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  actions: [
                    _buildAppBarButton(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      _toggleFavorite,
                      iconColor: _isFavorite ? Colors.red : null,
                    ),
                    const SizedBox(width: 12),
                    _buildAppBarButton(Icons.ios_share, _shareEvent),
                    const SizedBox(width: 16),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBannerSection(event),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          event.name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDateTimeCard(event),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    child: Container(
                      color: _AppColors.background,
                      child: _EventTabBar(
                        hasEnded: _hasEventEnded(event),
                        onTabSelected: _scrollToSection,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        key: _aboutKey,
                        child: _EventAboutSection(
                          description: event.description,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoSection(event),
                      const SizedBox(height: 24),
                      Container(
                        key: _venueKey,
                        child: _hasEventEnded(event)
                            ? _buildReviewTab(event, eventData)
                            : _buildVenueSection(event),
                      ),
                      const SizedBox(height: 24),
                      if (event.artistDetails.isNotEmpty)
                        Container(
                          key: _artistKey,
                          child: _buildArtistSection(event),
                        ),
                      if (event.artistDetails.isNotEmpty)
                        const SizedBox(height: 24),
                      Container(
                        key: _galleryKey,
                        child: _buildGallerySection(event),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        key: _organiserKey,
                        child: _buildOrganizerSection(event),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        key: _moreKey,
                        child: _buildTermsSection(event, eventData),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBarButton(
    IconData icon,
    VoidCallback onPressed, {
    Color? iconColor,
  }) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _AppColors.background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, size: 18),
          color: iconColor ?? _AppColors.iconPrimary,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildBannerSection(Event event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 0.75,
          child: event.videoUrl != null && event.videoUrl!.isNotEmpty
              ? PageView(
                  children: [
                    AutoPlayVideo(
                      videoUrl: event.videoUrl!,
                      borderRadius: 0,
                      fit: BoxFit.cover,
                    ),
                    _buildImage(event.poster),
                  ],
                )
              : _buildImage(event.poster),
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: _AppColors.backgroundSecondary,
          child: const Center(
            child: CircularProgressIndicator(color: _AppColors.primaryGreen),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: _AppColors.backgroundSecondary,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: _AppColors.textTertiary,
            ),
          ),
        ),
      );
    }
    return Container(color: _AppColors.backgroundSecondary);
  }

  Widget _buildDateTimeCard(Event event) {
    final formattedDate = DateFormat(
      'EEE, dd MMM yyyy',
    ).format(event.startTime);
    final formattedTime =
        '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: _AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date and Time',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$formattedDate, $formattedTime',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _AppColors.textPrimary,
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

  Widget _buildInfoSection(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.translate,
            'Language',
            event.about['language']?.toString() ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.crop_free,
            'Layout',
            event.about['venueType']?.toString() ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time_outlined,
            'Duration',
            event.about['duration']?.toString() ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.people_outline,
            'Age Limit',
            event.about['ageLimit']?.toString() ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.event_seat_outlined,
            'Seating',
            event.about['seating']?.toString() ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _AppColors.primaryGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVenueSection(Event event) {
    final venueName = event.venueInfo['name']?.toString() ?? event.location;
    final address = event.venueInfo['address']?.toString() ?? event.location;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Venue',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _AppColors.border),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _buildActionButton(Icons.copy_outlined, () {
                    Clipboard.setData(ClipboardData(text: address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied')),
                    );
                  }),
                  const SizedBox(width: 8),
                  _buildActionButton(Icons.share_outlined, _shareEvent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              _launchURL(
                'https://www.google.com/maps/search/?api=1&query=${event.lat},${event.long}',
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _AppColors.textPrimary,
              side: const BorderSide(color: _AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get Direction',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: _AppColors.backgroundSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: _AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: _AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: _AppColors.textSecondary),
      ),
    );
  }

  Widget _buildArtistSection(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Artist',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...event.artistDetails.map((artist) {
            final links = artist['links'] as Map<String, dynamic>? ?? {};
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  if (artist['artistId'] != null)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ArtistDetailPage(artistId: artist['artistId']),
                      ),
                    );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 110,
                          height: 110,
                          color: _AppColors.backgroundSecondary,
                          child:
                              artist['image'] != null &&
                                  artist['image'].toString().isNotEmpty
                              ? Image.network(
                                  artist['image'],
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        artist['name'] ?? 'Unknown',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: _AppColors.backgroundSecondary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_outward,
                                        size: 14,
                                        color: _AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  artist['bio'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: _AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (links['spotify'] != null &&
                                    links['spotify'].toString().isNotEmpty)
                                  _buildSocialButton(
                                    Icons.music_note,
                                    _AppColors.spotify,
                                    links['spotify'],
                                  ),
                                if (links['spotify'] != null &&
                                    links['spotify'].toString().isNotEmpty)
                                  const SizedBox(width: 8),
                                if (links['appleMusic'] != null &&
                                    links['appleMusic'].toString().isNotEmpty)
                                  _buildSocialButton(
                                    Icons.play_circle_filled,
                                    _AppColors.appleMusic,
                                    links['appleMusic'],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: Icon(icon, size: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildGallerySection(Event event) {
    if (event.gallery.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gallery',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: event.gallery.length > 4 ? 4 : event.gallery.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final isLastVisible = index == 3 && event.gallery.length > 4;
              return GestureDetector(
                onTap: () => _openGalleryView(event.gallery, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: event.gallery[index],
                        fit: BoxFit.cover,
                      ),
                      if (isLastVisible)
                        Container(
                          color: Colors.black.withOpacity(0.55),
                          child: Center(
                            child: Text(
                              '+${event.gallery.length - 4}',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerSection(Event event) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promoters')
          .where('uid', isEqualTo: event.promoterId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SizedBox.shrink();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox.shrink();

        final promoter =
            snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final publicData =
            promoter['publicdata'] as Map<String, dynamic>? ?? {};
        final name =
            publicData['businessName'] ??
            promoter['displayName'] ??
            "Organizer";
        final description = publicData['bio'] ?? 'Verified promoter on Tixoo';
        final logoUrl = publicData['photoURL'] ?? promoter['photoURL'] ?? '';
        final rating = (promoter['ratings'] ?? 0.0).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organizer',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: _AppColors.border),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 100,
                        height: 100,
                        color: _AppColors.backgroundSecondary,
                        child: logoUrl.isNotEmpty
                            ? Image.network(logoUrl, fit: BoxFit.cover)
                            : const Icon(
                                Icons.business,
                                size: 40,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: _AppColors.textSecondary,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _AppColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: _AppColors.starYellow,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PromoterDetailsPage(
                                      uid: promoter['uid'] ?? event.promoterId,
                                      displayName: name,
                                      email: promoter['email'] ?? "",
                                      photoURL: logoUrl,
                                    ),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(100),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF245126),
                                        Color(0xFF4EB152),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Explore more',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildTermsSection(Event event, Map<String, dynamic> eventData) {
    final moreInfo = eventData['moreInfo']?.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _AppColors.border),
          const SizedBox(height: 8),
          const _ExpandableTermsItem(
            title: 'Terms and Conditions',
            content:
                'Tickets once booked cannot be exchanged or refunded.\nPlease carry a valid ID proof.\nThe organizers reserve the right to admission.',
          ),
          if (moreInfo != null && moreInfo.isNotEmpty) ...[
            Container(height: 1, color: _AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: GestureDetector(
                onTap: () => _launchURL(moreInfo),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: _AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "For more info click here",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.primaryGreen,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTab(Event event, Map<String, dynamic> eventData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _AppColors.border),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate Your Experience',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (index) => GestureDetector(
                        onTap: () =>
                            setState(() => _selectedRating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFFFD700),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: _AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmittingReview
                        ? null
                        : () => _submitReview(event, eventData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmittingReview
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Submit Review',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview(
    Event event,
    Map<String, dynamic> eventData,
  ) async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSubmittingReview = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');
      final promoterId = eventData['promoterId'];
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
      setState(() {
        _selectedRating = 0;
        _reviewController.clear();
        _isSubmittingReview = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: _AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      setState(() => _isSubmittingReview = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBottomBar(Event event) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: _AppColors.background,
        border: Border(top: BorderSide(color: _AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Base Price',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${_formatPrice(event.baseTicketPrice)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TicketSelectionPage(eventId: widget.eventId),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF245126), Color(0xFF4EB152)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Book Now',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000)
      return price
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    return price.toStringAsFixed(0);
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication))
      debugPrint('Could not launch $url');
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyTabBarDelegate({required this.child});
  @override
  double get minExtent => 45.0;
  @override
  double get maxExtent => 45.0;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => true;
}

class _EventTabBar extends StatefulWidget {
  final Function(int) onTabSelected;
  final bool hasEnded;
  const _EventTabBar({required this.onTabSelected, required this.hasEnded});
  @override
  State<_EventTabBar> createState() => _EventTabBarState();
}

class _EventTabBarState extends State<_EventTabBar> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  late List<String> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      'About',
      'Artist',
      'Gallery',
      widget.hasEnded ? 'Review' : 'Venue',
      'Organiser',
      'More',
    ];
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
    widget.onTabSelected(index);
    final targetOffset =
        (index * 90.0) - (MediaQuery.of(context).size.width / 2) + 45.0;
    if (_scrollController.hasClients)
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _AppColors.border.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(
            _tabs.length,
            (index) => GestureDetector(
              onTap: () => _selectTab(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedIndex == index
                          ? _AppColors.primaryGreen
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[index],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: _selectedIndex == index
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _selectedIndex == index
                        ? _AppColors.textPrimary
                        : _AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventAboutSection extends StatefulWidget {
  final String description;
  const _EventAboutSection({required this.description});
  @override
  State<_EventAboutSection> createState() => _EventAboutSectionState();
}

class _EventAboutSectionState extends State<_EventAboutSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚀 THE FIX: Replaced AnimatedCrossFade entirely.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: Text(
              widget.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _AppColors.textSecondary,
                height: 1.6,
              ),
              maxLines: _isExpanded ? null : 6,
              overflow: _isExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Text(
              _isExpanded ? 'Read Less' : 'Read More',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _AppColors.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableTermsItem extends StatefulWidget {
  final String title, content;
  const _ExpandableTermsItem({required this.title, required this.content});
  @override
  State<_ExpandableTermsItem> createState() => _ExpandableTermsItemState();
}

class _ExpandableTermsItemState extends State<_ExpandableTermsItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
            _isExpanded
                ? _animationController.forward()
                : _animationController.reverse();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: _AppColors.border),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: _AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.content,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
