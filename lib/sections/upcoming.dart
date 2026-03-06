import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tixxo/models/event.dart';
import 'package:tixxo/supportive_pages/event_details.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ✅ LOGIC: UpcomingEventsManager (PRESERVED)
// ─────────────────────────────────────────────────────────────────────────────
class UpcomingEventsManager {
  static final UpcomingEventsManager _instance =
      UpcomingEventsManager._internal();
  factory UpcomingEventsManager() => _instance;
  UpcomingEventsManager._internal();

  StreamSubscription<QuerySnapshot>? _subscription;
  List<Map<String, dynamic>> _events = [];
  bool _initialized = false;
  final List<Function(List<Map<String, dynamic>>)> _listeners = [];

  void addListener(Function(List<Map<String, dynamic>>) callback) {
    _listeners.add(callback);
    if (_events.isNotEmpty) callback(_events);
  }

  void removeListener(Function(List<Map<String, dynamic>>) callback) {
    _listeners.remove(callback);
  }

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _subscription = FirebaseFirestore.instance
        .collection('Events')
        .where('status', isEqualTo: 'upcoming')
        .snapshots()
        .listen((snapshot) {
          final allEvents = snapshot.docs
              .map((doc) {
                final eventData = doc.data() as Map<String, dynamic>;
                final event = Event.fromJson(eventData);
                return {
                  'event': event,
                  'docId': doc.id,
                  'eventCategory': eventData['eventCategory'] ?? '',
                  'eventSubCategory': eventData['eventSubCategory'] ?? '',
                  'location': eventData['location'] ?? '',
                  'city': eventData['city'] ?? '',
                };
              })
              .where(
                (item) =>
                    (item['event'] as Event).startTime.isAfter(DateTime.now()),
              )
              .toList();

          allEvents.sort(
            (a, b) => (a['event'] as Event).startTime.compareTo(
              (b['event'] as Event).startTime,
            ),
          );

          _events = allEvents;
          for (var listener in _listeners) listener(_events);
        });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _events.clear();
    _listeners.clear();
    _initialized = false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ LOGIC: FavoritesManager (PRESERVED)
// ─────────────────────────────────────────────────────────────────────────────
class FavoritesManager {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  StreamSubscription<QuerySnapshot>? _subscription;
  Set<String> _favoriteEventIds = {};
  bool _initialized = false;
  final List<Function(Set<String>)> _listeners = [];

  void addListener(Function(Set<String>) callback) {
    _listeners.add(callback);
    if (_favoriteEventIds.isNotEmpty) callback(_favoriteEventIds);
  }

  void removeListener(Function(Set<String>) callback) {
    _listeners.remove(callback);
  }

  void initialize() {
    if (_initialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _initialized = true;
    _subscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('favourites')
        .snapshots()
        .listen((snapshot) {
          _favoriteEventIds = snapshot.docs.map((doc) => doc.id).toSet();
          for (var listener in _listeners) listener(_favoriteEventIds);
        });
  }

  Future<void> toggleFavorite(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('favourites')
        .doc(eventId);
    if (_favoriteEventIds.contains(eventId))
      await ref.delete();
    else
      await ref.set({'eventId': eventId});
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _favoriteEventIds.clear();
    _listeners.clear();
    _initialized = false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ UI: UpcomingEventsSection (LOGIC FIXED + PIXEL PERFECT)
// ─────────────────────────────────────────────────────────────────────────────
class UpcomingEventsSection extends StatefulWidget {
  final String? eventCategory;
  final String? eventSubCategory;

  const UpcomingEventsSection({
    super.key,
    this.eventCategory,
    this.eventSubCategory,
  });

  @override
  State<UpcomingEventsSection> createState() => _UpcomingEventsSectionState();
}

class _UpcomingEventsSectionState extends State<UpcomingEventsSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _allEvents = []; // Total database events
  List<Map<String, dynamic>> _filteredEvents =
      []; // ✅ NEW: Total events matching current filter
  List<Map<String, dynamic>> _displayedEvents =
      []; // Events currently on screen
  Set<String> favoriteEventIds = {};
  int _visibleCount = 5;

  final UpcomingEventsManager _eventsManager = UpcomingEventsManager();
  final FavoritesManager _favoritesManager = FavoritesManager();

  @override
  void initState() {
    super.initState();
    _eventsManager.addListener((events) {
      if (mounted) {
        setState(() {
          _allEvents = events;
          _filterAndPaginate();
        });
      }
    });
    _favoritesManager.addListener((favorites) {
      if (mounted) setState(() => favoriteEventIds = favorites);
    });
    _eventsManager.initialize();
    _favoritesManager.initialize();
  }

  // ✅ LOGIC FIX: Accurately tracks the filtered list
  void _filterAndPaginate() {
    // 1. Attempt Strict Filter
    List<Map<String, dynamic>> currentFilter = _allEvents.where((e) {
      bool cat =
          widget.eventCategory == null ||
          e['eventCategory'] == widget.eventCategory;
      bool sub =
          widget.eventSubCategory == null ||
          e['eventSubCategory'] == widget.eventSubCategory;
      return cat && sub;
    }).toList();

    // 2. Fallback: Category only
    if (currentFilter.isEmpty) {
      currentFilter = _allEvents.where((e) {
        bool cat =
            widget.eventCategory == null ||
            e['eventCategory'] == widget.eventCategory;
        return cat;
      }).toList();
    }

    // 3. Fallback: Show All
    if (currentFilter.isEmpty) {
      currentFilter = _allEvents;
    }

    setState(() {
      _filteredEvents = currentFilter; // ✅ Store the true filtered list
      _displayedEvents = _filteredEvents.take(_visibleCount).toList();
    });
  }

  void _loadMoreEvents() {
    setState(() {
      _visibleCount += 5;
      _filterAndPaginate();
    });
  }

  @override
  void didUpdateWidget(UpcomingEventsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventCategory != widget.eventCategory ||
        oldWidget.eventSubCategory != widget.eventSubCategory) {
      // Reset pagination on category change
      _visibleCount = 5;
      _filterAndPaginate();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_displayedEvents.isEmpty) {
      if (_allEvents.isEmpty)
        return const SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF15612E)),
          ),
        );
      return const SizedBox.shrink();
    }

    // ✅ FIXED LOGIC: Compare displayed count vs filtered count
    bool hasMore = _displayedEvents.length < _filteredEvents.length;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: _UpcomingHeader(title: "Upcoming Events"),
        ),
        const SizedBox(height: 10),

        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Always +1 for the footer
          itemCount: _displayedEvents.length + 1,
          itemBuilder: (context, index) {
            // 🔹 FOOTER RENDER
            if (index == _displayedEvents.length) {
              if (hasMore) {
                // Button
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: GestureDetector(
                      onTap: _loadMoreEvents,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF15612E),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Load More Events",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF15612E),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF15612E),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                // End of List Message (Icon + Text)
                return Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 30.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: Color(0xFF9E9E9E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "You've reached the end of the list",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }

            final event = _displayedEvents[index]['event'] as Event;
            final docId = _displayedEvents[index]['docId'] as String;
            return _PixelPerfectEventCard(
              event: event,
              docId: docId,
              isFavorite: favoriteEventIds.contains(docId),
              onFavoriteToggle: () async =>
                  _favoritesManager.toggleFavorite(docId),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔹 PIXEL-PERFECT CARD (Exact Dimensions & Text Properties)
// ─────────────────────────────────────────────────────────────────────────────
class _PixelPerfectEventCard extends StatelessWidget {
  final Event event;
  final String docId;
  final bool isFavorite;
  final Future<void> Function() onFavoriteToggle;

  const _PixelPerfectEventCard({
    required this.event,
    required this.docId,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    // 📏 FIGMA SPECS
    const double cardHeight = 122.0;
    const double cardRadius = 20.0;
    const double padding = 7.0;
    const double imageHeight = 108.0;
    const double imageRadius = 14.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventPage(eventId: docId)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive Image (47% width)
          final double imageWidth = (constraints.maxWidth * 0.47).clamp(
            130.0,
            188.0,
          );

          return Container(
            height: cardHeight,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 18.1,
                  spreadRadius: 5.07,
                  offset: const Offset(0, 3.62),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(padding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖼️ LEFT IMAGE
                  Hero(
                    tag: 'upcoming_$docId',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(imageRadius),
                      child: Image.network(
                        event.poster,
                        height: imageHeight,
                        width: imageWidth,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: imageWidth,
                          height: imageHeight,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 📝 RIGHT CONTENT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ROW 1: Date + Heart
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'EEE, d MMM, h:mm a',
                              ).format(event.startTime),
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w500, // Medium
                                color: const Color(0xFF4EB152), // Green
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Heart Icon
                            GestureDetector(
                              onTap: () async => await onFavoriteToggle(),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16,
                                  color: isFavorite ? Colors.red : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ROW 2: Title & Location
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700, // Bold
                                color: const Color(0xFF000000),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2), // Tiny gap
                            Text(
                              event.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600, // SemiBold
                                color: const Color(0xFF9E9E9E),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),

                        // ROW 3: Price + Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  "₹ ${event.baseTicketPrice} Onwards",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600, // SemiBold
                                    color: const Color(0xFF767676),
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // BUTTON (Fixed Dimensions)
                            Container(
                              width: 80,
                              height: 25,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4EB152),
                                    Color(0xFF245126),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(7.2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Book Now",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600, // SemiBold
                                  color: Colors.white,
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
    );
  }
}

// 🔹 Header Widget
class _UpcomingHeader extends StatelessWidget {
  final String title;
  const _UpcomingHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
                stops: [0.0, 0.5, 1.0],
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
                text: 'Upcoming ',
                style: TextStyle(color: Color(0xFF181D27)),
              ),
              TextSpan(
                text: 'Events',
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
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
