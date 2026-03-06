import 'dart:ui';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/classes/upcoming.dart';
import 'package:tixxo/models/event.dart';
import 'package:tixxo/sections/upcoming.dart';
import 'package:tixxo/supportive_pages/event_details.dart';
import 'package:tixxo/supportive_pages/review.dart';

class PromoterDetailsPage extends StatefulWidget {
  final String uid;
  final String displayName;
  final String email;
  final String photoURL;

  const PromoterDetailsPage({
    super.key,
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoURL,
  });

  @override
  State<PromoterDetailsPage> createState() => _PromoterDetailsPageState();
}

class _PromoterDetailsPageState extends State<PromoterDetailsPage> {
  Set<String> favoriteEventIds = {};
  bool isBioExpanded = false;
  Map<String, dynamic>? _cachedPromoterData;

  final FavoritesManager _favoritesManager = FavoritesManager();
  late Function(Set<String>) _favoritesListener;

  @override
  void initState() {
    super.initState();

    _favoritesListener = (favorites) {
      if (mounted) {
        setState(() {
          favoriteEventIds = favorites;
        });
      }
    };

    _favoritesManager.addListener(_favoritesListener);
    _favoritesManager.initialize();
  }

  @override
  void dispose() {
    _favoritesManager.removeListener(_favoritesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 30,
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promoters')
            .doc(widget.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _cachedPromoterData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "Promoter data not found",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }

          final promoterData = snapshot.data!.data() as Map<String, dynamic>?;

          if (promoterData == null) {
            return Center(
              child: Text(
                "No promoter data available",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }

          // Cache the promoter data
          _cachedPromoterData = promoterData;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(promoterData),
                _buildUpcomingEventsOptimized(),
                _buildPastEvents(promoterData),
                _buildReviews(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingEventsOptimized() {
    if (_cachedPromoterData == null) {
      return const SizedBox.shrink();
    }

    final publicData =
        _cachedPromoterData!['publicdata'] as Map<String, dynamic>?;

    if (publicData == null || publicData['visibleEvents'] == null) {
      return const SizedBox.shrink();
    }

    final visibleEvents = publicData['visibleEvents'] as Map<String, dynamic>;
    final eventIds = visibleEvents.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (eventIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _getEventsStream(eventIds, 'Events'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final upcomingEvents =
            snapshot.data!
                .where((doc) {
                  if (!doc.exists) return false;
                  final data = doc.data() as Map<String, dynamic>?;
                  return data?['status'] == 'upcoming';
                })
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final startTime = (data['startTime'] as Timestamp).toDate();
                  final endTime = (data['endTime'] as Timestamp).toDate();

                  return {
                    'name': data['name'] ?? '',
                    'location': data['location'] ?? '',
                    'poster': data['poster'] ?? '',
                    'baseTicketPrice': data['baseTicketPrice'] ?? 0,
                    'startTime': startTime,
                    'endTime': endTime,
                    'docId': doc.id,
                    'description': data['description'] ?? '',
                    'eventCategory': data['eventCategory'] ?? '',
                    'eventSubCategory': data['eventSubCategory'] ?? '',
                  };
                })
                .toList()
              ..sort(
                (a, b) => (a['startTime'] as DateTime).compareTo(
                  b['startTime'] as DateTime,
                ),
              );

        if (upcomingEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Upcoming events",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF202020),
                        Color(0xFF202020),
                        Color(0xFF15612E),
                      ],
                      stops: [0.0, 0.2, 1.0],
                    ).createShader(Rect.fromLTWH(0, 0, 100, 50)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 135,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.90),
                itemCount: upcomingEvents.length,
                itemBuilder: (context, index) {
                  final event = upcomingEvents[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildUpcomingEventCard(event),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingEventCard(Map<String, dynamic> event) {
    final name = event['name'] as String;
    final location = event['location'] as String;
    final poster = event['poster'] as String;
    final basePrice = event['baseTicketPrice'] as num;
    final startTime = event['startTime'] as DateTime;
    final docId = event['docId'] as String;
    final isFavorite = favoriteEventIds.contains(docId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EventPage(eventId: docId)),
        );
      },
      child: Container(
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  poster,
                  width: 75,
                  height: 115,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 75,
                      height: 115,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                "${_weekdayName(startTime.weekday)}, "
                                "${startTime.day} ${_monthName(startTime.month)}, "
                                "${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF4A7C4A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await _favoritesManager.toggleFavorite(docId);
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
                        const SizedBox(height: 4),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "₹${basePrice.toStringAsFixed(0)} Onwards",
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2C3E2C), Color(0xFF4A7C4A)],
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
                                horizontal: 10,
                                vertical: 5,
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Book Now",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
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
      ),
    );
  }

  Widget _buildPastEvents(Map<String, dynamic> promoterData) {
    final publicData = promoterData['publicdata'] as Map<String, dynamic>?;

    if (publicData == null || publicData['visibleEvents'] == null) {
      return const SizedBox.shrink();
    }

    final visibleEvents = publicData['visibleEvents'] as Map<String, dynamic>;
    final eventIds = visibleEvents.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (eventIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _getEventsStream(eventIds, 'PastEvents'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final pastEvents =
            snapshot.data!.where((doc) => doc.exists).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final startTime = (data['startTime'] as Timestamp).toDate();
              final endTime = (data['endTime'] as Timestamp).toDate();

              return {
                'name': data['name'] ?? '',
                'location': data['location'] ?? '',
                'poster': data['poster'] ?? '',
                'baseTicketPrice': data['baseTicketPrice'] ?? 0,
                'startTime': startTime,
                'endTime': endTime,
                'docId': doc.id,
                'description': data['description'] ?? '',
                'eventCategory': data['eventCategory'] ?? '',
                'eventSubCategory': data['eventSubCategory'] ?? '',
              };
            }).toList()..sort(
              (a, b) => (b['startTime'] as DateTime).compareTo(
                a['startTime'] as DateTime,
              ),
            );

        if (pastEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Past events",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pastEvents.length,
                    separatorBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
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
                    itemBuilder: (context, index) {
                      final event = pastEvents[index];
                      return _buildPastEventCard(event);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Stream<List<DocumentSnapshot>> _getEventsStream(
    List<String> eventIds,
    String collection,
  ) {
    if (eventIds.isEmpty) {
      return Stream.value([]);
    }

    // Firebase has a limit of 10 items for 'whereIn', so we need to batch
    final batches = <List<String>>[];
    for (var i = 0; i < eventIds.length; i += 10) {
      batches.add(
        eventIds.sublist(
          i,
          i + 10 > eventIds.length ? eventIds.length : i + 10,
        ),
      );
    }

    final streams = batches.map((batch) {
      return FirebaseFirestore.instance
          .collection(collection)
          .where(FieldPath.documentId, whereIn: batch)
          .snapshots()
          .map((snapshot) => snapshot.docs);
    });

    // Combine all streams
    return streams.length == 1
        ? streams.first
        : streams.reduce((a, b) {
            return a.asyncMap((aList) async {
              final bList = await b.first;
              return [...aList, ...bList];
            });
          });
  }

  Widget _buildPastEventCard(Map<String, dynamic> event) {
    final name = event['name'] as String;
    final location = event['location'] as String;
    final poster = event['poster'] as String;
    final startTime = event['startTime'] as DateTime;
    final docId = event['docId'] as String;

    return GestureDetector(
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                poster,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${_weekdayName(startTime.weekday)}, ${startTime.day} ${_monthName(startTime.month)}, ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} ${startTime.hour >= 12 ? 'PM' : 'AM'}",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A7C4A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promoters')
          .doc(widget.uid)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final allReviews = snapshot.data!.docs;

        // Calculate average rating from all reviews
        double averageRating = 0.0;
        if (allReviews.isNotEmpty) {
          int totalRating = 0;
          for (var doc in allReviews) {
            final data = doc.data() as Map<String, dynamic>;
            totalRating += (data['rating'] ?? 0) as int;
          }
          averageRating = totalRating / allReviews.length;
        }

        // Get only first 3 reviews for display
        final displayReviews = allReviews.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "What People are Saying",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rating Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Rating bars
                    Expanded(
                      child: Column(
                        children: List.generate(5, (index) {
                          final starCount = 5 - index;
                          int count = allReviews.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return (data['rating'] ?? 0) == starCount;
                          }).length;

                          double percentage = allReviews.isNotEmpty
                              ? count / allReviews.length
                              : 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Text(
                                  "$starCount",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      // Background bar
                                      Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      // Filled bar based on percentage
                                      FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: percentage,
                                        child: Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF202020),
                                                Color(0xFF15612E),
                                              ],
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
                        }),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Average rating
                    Column(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              size: 20,
                              color: index < averageRating.round()
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${allReviews.length} Reviews",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Review List (only showing first 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayReviews.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
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
                itemBuilder: (context, index) {
                  final reviewData =
                      displayReviews[index].data() as Map<String, dynamic>;
                  final timestamp = reviewData['timestamp'] as Timestamp?;
                  final date = timestamp?.toDate();
                  final userId = reviewData['userId'] ?? '';
                  final comment = reviewData['comment'] ?? '';
                  final rating = reviewData['rating'] ?? 0;

                  String timeAgo = '';
                  if (date != null) {
                    final difference = DateTime.now().difference(date);
                    if (difference.inDays > 0) {
                      timeAgo = '${difference.inDays} days ago';
                    } else if (difference.inHours > 0) {
                      timeAgo = '${difference.inHours} hours ago';
                    } else {
                      timeAgo = 'Just now';
                    }
                  }

                  // Fetch user data from Users collection

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(userId)
                        .get(),
                    builder: (context, userSnapshot) {
                      String userName = 'Anonymous';
                      String userProfileUrl = '';

                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;
                        userName =
                            userData?['name'] ??
                            userData?['displayName'] ??
                            'Anonymous';
                        userProfileUrl = userData?['profileUrl'] ?? '';
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Image
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: userProfileUrl.isNotEmpty
                                    ? NetworkImage(userProfileUrl)
                                    : null,
                                child: userProfileUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                        size: 22,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),

                              // Name, Stars, Time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name
                                    Text(
                                      userName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    // Stars + Time
                                    Row(
                                      children: [
                                        Row(
                                          children: List.generate(5, (index) {
                                            return Icon(
                                              Icons.star,
                                              size: 16,
                                              color: index < rating
                                                  ? Colors.amber
                                                  : Colors.grey.shade300,
                                            );
                                          }),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeAgo,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // COMMENT BELOW EVERYTHING
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              comment,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Show All Reviews Button
            if (allReviews.length > 3)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Center(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllReviewsPage(
                            promoterUid: widget.uid,
                            promoterName: widget.displayName,
                            averageRating: averageRating,
                            totalReviews: allReviews.length,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "See All Reviews",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> promoterData) {
    final publicData = promoterData['publicdata'] as Map<String, dynamic>?;
    final photoURL = publicData?['photoURL'] ?? '';
    final bio = publicData?['bio'] ?? '';
    final businessName = publicData?['businessName'] ?? widget.displayName;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: photoURL.isNotEmpty
                ? Image.network(
                    photoURL,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, size: 64),
                      );
                    },
                  )
                : Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, size: 64),
                  ),
          ),
          const SizedBox(height: 16),

          // Business Name & Rating
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('promoters')
                .doc(widget.uid)
                .collection('reviews')
                .snapshots(),
            builder: (context, reviewSnapshot) {
              double averageRating = 0.0;

              if (reviewSnapshot.hasData &&
                  reviewSnapshot.data!.docs.isNotEmpty) {
                final reviews = reviewSnapshot.data!.docs;
                int totalRating = 0;
                for (var doc in reviews) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalRating += (data['rating'] ?? 0) as int;
                }
                averageRating = totalRating / reviews.length;
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      businessName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF202020),
                              Color(0xFF202020),
                              Color(0xFF15612E),
                            ],
                            stops: [0.0, 0.2, 1.0],
                          ).createShader(Rect.fromLTWH(0, 0, 100, 50)),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Bio (always full)
          if (bio.isNotEmpty)
            Text(
              bio,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _weekdayName(int weekday) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[weekday - 1];
  }
}
