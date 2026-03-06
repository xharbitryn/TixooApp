// lib/sections/allevents.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tixxo/models/event.dart';
import 'package:tixxo/supportive_pages/event_details.dart';

class AllEventsSection extends StatefulWidget {
  final String eventCategory;

  const AllEventsSection({super.key, required this.eventCategory});

  @override
  State<AllEventsSection> createState() => _AllEventsSectionState();
}

class _AllEventsSectionState extends State<AllEventsSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ValueNotifier<Set<String>> _favoriteEventIds = ValueNotifier({});

  int _visibleCount = 5;
  String? _selectedQuickFilter;
  DateTime? _selectedSpecificDate;
  String? _sortOrder;
  bool _filterByCity = false;

  final String _userCity = "Lucknow";

  // ✅ Static Category Map (Matches your horizontal strip exactly)
  final Map<String, List<String>> _categoryMap = {
    'basicEvent': ["Music", "Standup", "Poetry", "Theatre"],
    'Sports': ["Cricket", "Football", "Tennis", "Running"],
    'clubEvent': ["DJ Night", "Bollywood", "EDM", "Hip-Hop"],
  };

  List<String> get _currentCategoryFilters =>
      _categoryMap[widget.eventCategory] ??
      ["Music", "Standup", "Poetry", "Theatre"];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _favoriteEventIds.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['favorites'] != null) {
            _favoriteEventIds.value = Set<String>.from(data['favorites']);
          }
        }
      } catch (e) {
        debugPrint('Error loading favorites: $e');
      }
    }
  }

  Future<void> _toggleFavorite(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final currentFavorites = Set<String>.from(_favoriteEventIds.value);
    if (!currentFavorites.contains(eventId)) {
      currentFavorites.add(eventId);
    } else {
      currentFavorites.remove(eventId);
    }

    _favoriteEventIds.value = currentFavorites;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'favorites': currentFavorites.toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update favorite")),
        );
      }
    }
  }

  void _loadMoreEvents() {
    setState(() {
      _visibleCount += 5;
    });
  }

  List<Map<String, dynamic>> _processEvents(List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> processed = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      final event = Event.fromJson(data);
      final DateTime date = event.startTime;
      final String city = data['city'] ?? '';

      // ✅ READ SUB-CATEGORY FROM RAW DATA (Prevents 'getter not defined' error)
      final String subCategory = data['eventSubCategory'] ?? '';

      bool matches = true;

      // 1. Date Filter
      if (_selectedSpecificDate != null) {
        if (!_isSameDay(date, _selectedSpecificDate!)) matches = false;
      } else if (_selectedQuickFilter == 'Today') {
        if (!_isSameDay(date, DateTime.now())) matches = false;
      } else if (_selectedQuickFilter == 'Tomorrow') {
        if (!_isSameDay(date, DateTime.now().add(const Duration(days: 1))))
          matches = false;
      }
      // 2. Category Filter (Matches chip)
      else if (_selectedQuickFilter != null &&
          _selectedQuickFilter!.isNotEmpty) {
        // Strict case-insensitive comparison using local 'subCategory' variable
        if (subCategory.toLowerCase() != _selectedQuickFilter!.toLowerCase())
          matches = false;
      }

      // 3. City Filter
      if (_filterByCity) {
        if (!city.toLowerCase().contains(_userCity.toLowerCase()) &&
            !event.location.toLowerCase().contains(_userCity.toLowerCase())) {
          matches = false;
        }
      }

      if (matches) {
        processed.add({
          'event': event,
          'id': doc.id,
          'price': event.baseTicketPrice,
          'date': event.startTime,
        });
      }
    }

    // 4. Sorting
    if (_sortOrder == 'Low to High') {
      processed.sort(
        (a, b) => (a['price'] as int).compareTo(b['price'] as int),
      );
    } else if (_sortOrder == 'High to Low') {
      processed.sort(
        (a, b) => (b['price'] as int).compareTo(a['price'] as int),
      );
    } else {
      processed.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );
    }

    return processed;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filters",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Sort by Price",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildModalOption(
                        "Low to High",
                        _sortOrder == 'Low to High',
                        () {
                          setModalState(
                            () => _sortOrder = _sortOrder == 'Low to High'
                                ? null
                                : 'Low to High',
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildModalOption(
                        "High to Low",
                        _sortOrder == 'High to Low',
                        () {
                          setModalState(
                            () => _sortOrder = _sortOrder == 'High to Low'
                                ? null
                                : 'High to Low',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Location",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildModalOption("My City ($_userCity)", _filterByCity, () {
                    setModalState(() => _filterByCity = !_filterByCity);
                  }),
                  const SizedBox(height: 24),
                  Text(
                    "Specific Date",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF15612E),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          _selectedSpecificDate = picked;
                          _selectedQuickFilter = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedSpecificDate != null
                              ? const Color(0xFF15612E)
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedSpecificDate != null
                            ? const Color(0xFF15612E).withOpacity(0.05)
                            : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: _selectedSpecificDate != null
                                ? const Color(0xFF15612E)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedSpecificDate == null
                                ? "Select Date"
                                : DateFormat(
                                    "EEE, MMM d, yyyy",
                                  ).format(_selectedSpecificDate!),
                            style: GoogleFonts.poppins(
                              color: _selectedSpecificDate != null
                                  ? const Color(0xFF15612E)
                                  : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15612E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Apply Filters",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF15612E) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF15612E) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: _AllEventsHeader(title: "All Events"),
          ),

          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openFilters,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            (_sortOrder != null ||
                                _filterByCity ||
                                _selectedSpecificDate != null)
                            ? const Color(0xFF15612E)
                            : Colors.grey.shade300,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color:
                              (_sortOrder != null ||
                                  _filterByCity ||
                                  _selectedSpecificDate != null)
                              ? const Color(0xFF15612E)
                              : const Color(0xFF181D27),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Filters",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF181D27),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Color(0xFF181D27),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                _buildQuickChip("Today"),
                const SizedBox(width: 10),
                _buildQuickChip("Tomorrow"),

                if (_currentCategoryFilters.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  ..._currentCategoryFilters.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildQuickChip(cat),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('Events')
                .where('eventCategory', isEqualTo: widget.eventCategory)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Color(0xFF15612E)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Error loading events',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final processedEvents = _processEvents(snapshot.data!.docs);

              if (processedEvents.isEmpty) {
                return _buildEmptyState();
              }

              return _buildEventList(processedEvents);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> events) {
    final int totalCount = events.length;
    final int displayCount = (_visibleCount > totalCount)
        ? totalCount
        : _visibleCount;
    final bool hasMore = displayCount < totalCount;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayCount + 1,
      itemBuilder: (context, index) {
        if (index == displayCount) {
          if (hasMore) {
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

        final item = events[index];
        final Event event = item['event'];
        final String eventId = item['id'];

        return ValueListenableBuilder<Set<String>>(
          valueListenable: _favoriteEventIds,
          builder: (context, favorites, child) {
            return _PixelPerfectAllEventCard(
              key: ValueKey(eventId),
              event: event,
              docId: eventId,
              isFavorite: favorites.contains(eventId),
              onFavoriteToggle: () => _toggleFavorite(eventId),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickChip(String label) {
    final bool isSelected = _selectedQuickFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedQuickFilter = isSelected ? null : label;
          _selectedSpecificDate = null;
        });
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF15612E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF15612E) : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF181D27),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.filter_list_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No events match your filters',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PixelPerfectAllEventCard extends StatelessWidget {
  final Event event;
  final String docId;
  final bool isFavorite;
  final Future<void> Function() onFavoriteToggle;

  const _PixelPerfectAllEventCard({
    super.key,
    required this.event,
    required this.docId,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 122.0;
    const double cardRadius = 20.05;
    const double padding = 7.0;
    const double imageHeight = 108.0;
    const double imageRadius = 14.1;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventPage(eventId: docId)),
      ),
      child: Container(
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
              Hero(
                tag: 'allevents_$docId',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(imageRadius),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double imageWidth = (constraints.maxWidth * 0.45)
                          .clamp(130.0, 190.0);
                      return Image.network(
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
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4EB152),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF000000),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9E9E9E),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 3, right: 4),
                            child: Text(
                              "₹ ${event.baseTicketPrice} Onwards",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF767676),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 25,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4EB152), Color(0xFF245126)],
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
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _AllEventsHeader extends StatelessWidget {
  final String title;
  const _AllEventsHeader({required this.title});

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
                text: 'All ',
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
