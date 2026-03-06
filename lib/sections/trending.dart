import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/classes/trending.dart';
import 'package:tixxo/supportive_pages/event_details.dart';

class TrendingEventsManager {
  static final TrendingEventsManager _instance =
      TrendingEventsManager._internal();
  factory TrendingEventsManager() => _instance;
  TrendingEventsManager._internal();

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

    print('🔥 INITIALIZING FIREBASE SINGLETON - ONCE ONLY!');
    _initialized = true;

    _subscription = FirebaseFirestore.instance
        .collection('Events')
        .where('status', isEqualTo: 'trending')
        .snapshots()
        .listen(
          (snapshot) {
            print('📡 FIREBASE UPDATE: ${snapshot.docs.length} events');

            _events = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'name': data['name'] ?? data['eventName'] ?? 'Unknown Event',
                'poster': data['poster'] ?? '',
                'videoUrl': data['videoUrl'],
                'location': data['location'] ?? 'Location TBA',
                'startTime': data['startTime'],
                'baseTicketPrice': data['baseTicketPrice'] ?? 0,
                'eventCategory': data['eventCategory'] ?? '',
                'eventSubCategory': data['eventSubCategory'] ?? '',
                'id': doc.id,
              };
            }).toList();

            print('🔄 NOTIFYING ${_listeners.length} LISTENERS');

            for (var listener in _listeners) {
              listener(_events);
            }
          },
          onError: (error) {
            print('❌ FIREBASE ERROR: $error');
          },
        );
  }

  void dispose() {
    print('🗑️ DISPOSING FIREBASE SINGLETON');
    _subscription?.cancel();
    _subscription = null;
    _events.clear();
    _listeners.clear();
    _initialized = false;
  }
}

class TrendingEvents extends StatefulWidget {
  final String? eventCategory;
  final String? eventSubCategory;

  const TrendingEvents({super.key, this.eventCategory, this.eventSubCategory});

  @override
  State<TrendingEvents> createState() => _TrendingEventsState();
}

class _TrendingEventsState extends State<TrendingEvents>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> trendingEvents = [];
  late PageController _pageController;
  late AnimationController _titleAnimationController;
  late AnimationController _cardAnimationController;

  int _currentPage = 0;
  bool _hasAnimated = false;
  Timer? _autoScrollTimer;
  bool _userInteracting = false;

  final TrendingEventsManager _manager = TrendingEventsManager();
  late Function(List<Map<String, dynamic>>) _dataListener;

  @override
  void initState() {
    super.initState();

    print('🚀 WIDGET INIT - Setting up controllers');

    _pageController = PageController(viewportFraction: 0.75, initialPage: 1000);

    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _dataListener = (events) {
      print('🔄 WIDGET RECEIVED DATA: ${events.length} events');
      if (mounted) {
        List<Map<String, dynamic>> filteredEvents = events;

        if (widget.eventCategory != null) {
          filteredEvents = filteredEvents
              .where((event) => event['eventCategory'] == widget.eventCategory)
              .toList();
        }

        if (widget.eventSubCategory != null) {
          filteredEvents = filteredEvents
              .where(
                (event) => event['eventSubCategory'] == widget.eventSubCategory,
              )
              .toList();
        }

        setState(() {
          trendingEvents = filteredEvents;
        });

        if (trendingEvents.isNotEmpty && _autoScrollTimer == null) {
          _startAutoScroll();
        } else if (trendingEvents.isEmpty) {
          _stopAutoScroll();
        }
      }
    };

    _manager.addListener(_dataListener);
    _manager.initialize();

    if (!_hasAnimated) {
      _hasAnimated = true;
      _titleAnimationController.forward();
      _cardAnimationController.forward();
    }
  }

  @override
  void didUpdateWidget(TrendingEvents oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventCategory != widget.eventCategory ||
        oldWidget.eventSubCategory != widget.eventSubCategory) {
      _dataListener(_manager.events);
    }
  }

  @override
  void dispose() {
    print('🔽 WIDGET DISPOSE');
    _manager.removeListener(_dataListener);
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _titleAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_userInteracting &&
          _pageController.hasClients &&
          trendingEvents.isNotEmpty) {
        final nextPage = (_pageController.page?.round() ?? 0) + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _onUserInteractionStart() {
    _userInteracting = true;
    _stopAutoScroll();
  }

  void _onUserInteractionEnd() {
    _userInteracting = false;
    Timer(const Duration(seconds: 3), () {
      if (!_userInteracting) {
        _startAutoScroll();
      }
    });
  }

  bool _isCardVisible(int index) {
    if (!_pageController.hasClients) return false;

    final currentPage = _pageController.page ?? 0.0;
    final eventIndex = index % trendingEvents.length;
    final currentEventIndex = (currentPage % trendingEvents.length).round();

    return eventIndex == currentEventIndex;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (trendingEvents.isEmpty) {
      if (widget.eventCategory != null || widget.eventSubCategory != null) {
        return const SizedBox.shrink();
      }
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),

          const _TrendingHeader(),

          const SizedBox(height: 15),

          // 🚀 HEIGHT FIX: Increased to 600px to solve Overflow/Yellow Strip issue
          // Calculation: Card Content (502px) + Vertical Padding (64px) + Buffer (~34px) = 600px
          SizedBox(
            height: 600,
            child: GestureDetector(
              onPanStart: (_) => _onUserInteractionStart(),
              onPanEnd: (_) => _onUserInteractionEnd(),
              onTapDown: (_) => _onUserInteractionStart(),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index % trendingEvents.length;
                  });
                },
                itemBuilder: (context, index) {
                  final eventIndex = index % trendingEvents.length;
                  final isVisible = _isCardVisible(index);
                  final event = trendingEvents[eventIndex];

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double scale = 1.0;
                      double opacity = 1.0;
                      double blur = 0.0;

                      if (_pageController.position.hasContentDimensions) {
                        final currentPage = _pageController.page ?? 0.0;
                        final distance = (index - currentPage).abs();

                        if (distance <= 1.0) {
                          scale = 1.12 - (distance * 0.24);
                          opacity = 1.0 - (distance * 0.4);
                          blur = distance * 2.0;
                        } else {
                          scale = 0.88;
                          opacity = 0.6;
                          blur = 2.0;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: ImageFiltered(
                              imageFilter: blur > 0
                                  ? ImageFilter.blur(sigmaX: blur, sigmaY: blur)
                                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                              child: EnhancedEventCard(
                                imagePath: event['poster'] ?? '',
                                videoUrl: event['videoUrl'],
                                description: event['name'] ?? 'Unknown Event',
                                eventId: event['id'] ?? '',
                                location: event['location'] ?? 'Location TBA',
                                startTime:
                                    event['startTime'] ?? Timestamp.now(),
                                baseTicketPrice: event['baseTicketPrice'] ?? 0,
                                animationController: _cardAnimationController,
                                isCenter: eventIndex == _currentPage,
                                isVisible: isVisible,
                                onTap: () {
                                  _onUserInteractionStart();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EventPage(eventId: event['id']!),
                                    ),
                                  ).then((_) {
                                    _onUserInteractionEnd();
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TrendingHeader extends StatelessWidget {
  const _TrendingHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Color(0xFF15612E),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 18,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
              children: const [
                TextSpan(
                  text: 'Trending ',
                  style: TextStyle(color: Color(0xFF181D27)),
                ),
                TextSpan(
                  text: 'this week',
                  style: TextStyle(color: Color(0xFF15612E)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.transparent,
                    Color(0xFF15612E),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
