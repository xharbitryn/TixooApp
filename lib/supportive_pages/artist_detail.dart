import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tixxo/sections/upcoming.dart';
import 'package:tixxo/supportive_pages/event_details.dart';
import 'package:tixxo/widgets/divider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/classes/upcoming.dart';
import 'package:tixxo/models/event.dart';

// Artist-specific events manager
class ArtistEventsManager {
  static final Map<String, ArtistEventsManager> _instances = {};

  factory ArtistEventsManager(String artistName) {
    if (!_instances.containsKey(artistName)) {
      _instances[artistName] = ArtistEventsManager._internal(artistName);
    }
    return _instances[artistName]!;
  }

  ArtistEventsManager._internal(this.artistName);

  final String artistName;
  StreamSubscription<QuerySnapshot>? _subscription;
  List<Map<String, dynamic>> _events = [];
  bool _initialized = false;
  final List<Function(List<Map<String, dynamic>>)> _listeners = [];

  List<Map<String, dynamic>> get events => List.from(_events);
  bool get hasData => _events.isNotEmpty;

  void addListener(Function(List<Map<String, dynamic>>) callback) {
    _listeners.add(callback);
    if (_events.isNotEmpty) {
      callback(_events);
    }
  }

  void removeListener(Function(List<Map<String, dynamic>>) callback) {
    _listeners.remove(callback);
  }

  void initialize() {
    if (_initialized) return;

    print('🔥 INITIALIZING ARTIST EVENTS FIREBASE SINGLETON FOR: $artistName');
    _initialized = true;

    _subscription = FirebaseFirestore.instance
        .collection('Events')
        .where('status', isEqualTo: 'upcoming')
        .snapshots()
        .listen(
          (snapshot) {
            print(
              '📡 ARTIST EVENTS FIREBASE UPDATE: ${snapshot.docs.length} events for $artistName',
            );

            final allEvents = snapshot.docs
                .where((doc) {
                  final eventData = doc.data() as Map<String, dynamic>;
                  final artistDetails =
                      eventData['artistDetails'] as List<dynamic>?;

                  if (artistDetails == null) return false;

                  return artistDetails.any((artistMap) {
                    if (artistMap is Map<String, dynamic>) {
                      final artistName = artistMap['name'] as String?;
                      return artistName == this.artistName;
                    }
                    return false;
                  });
                })
                .map((doc) {
                  final eventData = doc.data() as Map<String, dynamic>;
                  final event = Event.fromJson(eventData);
                  print(
                    '📝 Artist Event: ${event.name}, Document ID: ${doc.id}',
                  );
                  return {'event': event, 'docId': doc.id};
                })
                .where(
                  (item) => (item['event'] as Event).startTime.isAfter(
                    DateTime.now(),
                  ),
                )
                .toList();

            allEvents.sort(
              (a, b) => (a['event'] as Event).startTime.compareTo(
                (b['event'] as Event).startTime,
              ),
            );

            _events = allEvents;

            print(
              '🔄 NOTIFYING ${_listeners.length} ARTIST EVENTS LISTENERS FOR $artistName',
            );

            for (var listener in _listeners) {
              listener(_events);
            }
          },
          onError: (error) {
            print('❌ ARTIST EVENTS FIREBASE ERROR: $error');
          },
        );
  }

  void dispose() {
    print('🗑️ DISPOSING ARTIST EVENTS FIREBASE SINGLETON FOR: $artistName');
    _subscription?.cancel();
    _subscription = null;
    _events.clear();
    _listeners.clear();
    _initialized = false;
  }

  static void disposeAll() {
    for (var manager in _instances.values) {
      manager.dispose();
    }
    _instances.clear();
  }
}

class ArtistDetailPage extends StatefulWidget {
  final String? artistId;
  final DocumentSnapshot? artistDoc;

  const ArtistDetailPage({this.artistId, this.artistDoc, super.key})
    : assert(
        artistId != null || artistDoc != null,
        'Either artistId or artistDoc must be provided',
      );

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late String artistName;
  late PageController _pageController;
  int _currentPage = 0;

  // Cached data
  String? _posterUrl;
  String? _bio;
  List<String> _videoUrls = [];

  // Bio expansion state
  bool _isBioExpanded = false;

  // YouTube player controllers
  List<YoutubePlayerController?> _youtubeControllers = [];
  List<bool> _isVideoPlaying = [];

  // Events management
  List<Map<String, dynamic>> artistEvents = [];
  Set<String> favoriteEventIds = {};
  late ArtistEventsManager _eventsManager;
  final FavoritesManager _favoritesManager = FavoritesManager();
  late Function(List<Map<String, dynamic>>) _eventsListener;
  late Function(Set<String>) _favoritesListener;

  // Loading state
  bool _isLoading = true;
  DocumentSnapshot? _artistDocument;

  // Cached month and weekday names
  static const List<String> _months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
  static const List<String> _weekdays = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadArtistData();
  }

  Future<void> _loadArtistData() async {
    try {
      print('🔍 LOADING ARTIST DATA');
      print('artistId: ${widget.artistId}');
      print('artistDoc: ${widget.artistDoc?.id}');

      // If artistDoc is provided, use it directly
      if (widget.artistDoc != null) {
        _artistDocument = widget.artistDoc;
        print('✅ Using provided artistDoc: ${_artistDocument!.id}');
      } else if (widget.artistId != null) {
        // Otherwise fetch from Firestore using artistId
        print('🔄 Fetching from Firestore with ID: ${widget.artistId}');
        _artistDocument = await FirebaseFirestore.instance
            .collection('Artists')
            .doc(widget.artistId)
            .get();
        print('📄 Document exists: ${_artistDocument!.exists}');
        print('📄 Document ID: ${_artistDocument!.id}');
      }

      if (_artistDocument != null && _artistDocument!.exists) {
        // Cache data immediately to avoid repeated data() calls
        final data = _artistDocument!.data() as Map<String, dynamic>;
        artistName = data['name'] ?? 'Unknown';
        _posterUrl = data['poster'] ?? '';
        _bio = data['bio'] ?? 'No bio available';

        // Get video URLs from array
        final videoUrlData = data['videoUrl'];
        if (videoUrlData is List) {
          _videoUrls = videoUrlData.map((url) => url.toString()).toList();
        } else if (videoUrlData is String && videoUrlData.isNotEmpty) {
          _videoUrls = [videoUrlData];
        }

        // Initialize YouTube controllers for each video
        _youtubeControllers = List.generate(_videoUrls.length, (_) => null);
        _isVideoPlaying = List.generate(_videoUrls.length, (_) => false);

        // Initialize events management
        _eventsManager = ArtistEventsManager(artistName);

        print('🚀 ARTIST DETAIL PAGE INIT FOR: $artistName');

        // Set up events listener
        _eventsListener = (events) {
          print(
            '🔄 ARTIST EVENTS RECEIVED: ${events.length} events for $artistName',
          );
          if (mounted) {
            setState(() {
              artistEvents = events;
            });
          }
        };

        // Set up favorites listener
        _favoritesListener = (favorites) {
          print(
            '❤️ ARTIST PAGE RECEIVED FAVORITES: ${favorites.length} favorites',
          );
          if (mounted) {
            setState(() {
              favoriteEventIds = favorites;
            });
          }
        };

        // Add listeners
        _eventsManager.addListener(_eventsListener);
        _favoritesManager.addListener(_favoritesListener);

        // Initialize managers
        _eventsManager.initialize();
        _favoritesManager.initialize();

        setState(() {
          _isLoading = false;
        });
      } else {
        // Artist not found
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading artist data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    print('🔽 ARTIST DETAIL PAGE DISPOSE FOR: $artistName');
    _pageController.dispose();

    // Dispose all YouTube controllers
    for (var controller in _youtubeControllers) {
      controller?.dispose();
    }

    _eventsManager.removeListener(_eventsListener);
    _favoritesManager.removeListener(_favoritesListener);
    super.dispose();
  }

  void _initializeYoutubePlayer(int index) {
    final videoId = YoutubePlayer.convertUrlToId(_videoUrls[index]);
    if (videoId == null) return;

    // Dispose previous controller if exists
    _youtubeControllers[index]?.dispose();

    _youtubeControllers[index] = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
      ),
    );

    setState(() {
      _isVideoPlaying[index] = true;
    });
  }

  String _monthName(int month) => _months[month - 1];
  String _weekdayName(int weekday) => _weekdays[weekday - 1];

  Widget _buildPosterSection() {
    if (_posterUrl?.isEmpty ?? true) return const SizedBox.shrink();

    // Check if the URL is an SVG file
    final isSvg = _posterUrl!.toLowerCase().endsWith('.svg');

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'artist-poster-$artistName',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: isSvg
                    ? Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2C3E2C), Color(0xFF4A7C4A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      )
                    : Image.network(
                        _posterUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                child: child,
                              );
                            },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistNameSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF2C3E2C), Color(0xFF4A7C4A)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              artistName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_bio != null && _bio!.isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _isBioExpanded = !_isBioExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _bio!,
                    maxLines: _isBioExpanded ? null : 3,
                    overflow: _isBioExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _isBioExpanded ? "Show less" : "Show more",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        _isBioExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFamousWorkSection() {
    if (_videoUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF2C3E2C), Color(0xFF4A7C4A)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              "Few famous work",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _videoUrls.length,
            itemBuilder: (context, index) {
              final videoId = YoutubePlayer.convertUrlToId(_videoUrls[index]);
              final thumbnailUrl = videoId != null
                  ? 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg'
                  : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      _isVideoPlaying[index] &&
                          _youtubeControllers[index] != null
                      ? YoutubePlayer(
                          controller: _youtubeControllers[index]!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: const Color(0xFF4A7C4A),
                          progressColors: const ProgressBarColors(
                            playedColor: Color(0xFF4A7C4A),
                            handleColor: Color(0xFF2C3E2C),
                          ),
                        )
                      : Stack(
                          children: [
                            // Blurred background image
                            if (thumbnailUrl.isNotEmpty)
                              ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Image.network(
                                  thumbnailUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                ),
                              )
                            else
                              Container(
                                height: 200,
                                color: Colors.grey.shade800,
                              ),
                            // Play button
                            Positioned.fill(
                              child: Center(
                                child: GestureDetector(
                                  onTap: () {
                                    _initializeYoutubePlayer(index);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 32,
                                    ),
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

  Widget _buildUpcomingEventsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF2C3E2C), Color(0xFF4A7C4A)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              "Upcoming events",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 14),

          /// No Events
          if (artistEvents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  "No upcoming events",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            /// Event List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: artistEvents.length,
              itemBuilder: (context, index) {
                final eventData = artistEvents[index];
                final event = eventData['event'] as Event;
                final docId = eventData['docId'] as String;
                final isFavorite = favoriteEventIds.contains(docId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🖼️ Event Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            event.poster,
                            width: 90,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 90,
                                height: 120,
                                color: Colors.grey.shade300,
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        /// 📄 Event Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Date & Time with Heart Icon
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${_weekdayName(event.startTime.weekday)}, "
                                      "${event.startTime.day} ${_monthName(event.startTime.month)}, "
                                      "${DateFormat('h:mm a').format(event.startTime)}",
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF4A7C4A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await _favoritesManager.toggleFavorite(
                                        docId,
                                      );
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Outer green outline heart (always visible)
                                        Icon(
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 24,
                                          color: Colors.green,
                                        ),

                                        // Inner black fill heart (ONLY when favorite)
                                        if (isFavorite)
                                          Icon(
                                            Icons.favorite,
                                            size: 20,
                                            color: Colors.black,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              /// Event Name
                              Text(
                                event.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),

                              const SizedBox(height: 3),

                              /// Venue
                              Text(
                                event.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontSize: 11.5,
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// 💰 Price + Book Now
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "₹ ${event.baseTicketPrice} Onwards",
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2C3E2C),
                                          Color(0xFF4A7C4A),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EventPage(eventId: docId),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        "Book Now",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A7C4A)),
        ),
      );
    }

    if (_artistDocument == null || !_artistDocument!.exists) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Artist not found',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          "Know About $artistName",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {},
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildPosterSection()),
          SliverToBoxAdapter(child: _buildArtistNameSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          SliverToBoxAdapter(child: _buildFamousWorkSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          SliverToBoxAdapter(child: _buildUpcomingEventsSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
