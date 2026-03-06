import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/supportive_pages/event_details.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({Key? key}) : super(key: key);

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  List<Map<String, dynamic>> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavourites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavourites() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final favSnapshot = await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('favourites')
        .get();

    if (favSnapshot.docs.isEmpty) {
      setState(() {
        _allEvents = [];
        _isLoading = false;
      });
      return;
    }

    List<Map<String, dynamic>> events = [];
    for (var favDoc in favSnapshot.docs) {
      final eventId = favDoc['eventId'];

      if (eventId != null && eventId.toString().isNotEmpty) {
        final eventDoc = await _firestore
            .collection('Events')
            .doc(eventId)
            .get();

        if (eventDoc.exists) {
          events.add({'id': eventDoc.id, ...eventDoc.data()!});
        }
      }
    }

    setState(() {
      _allEvents = events;
      _isLoading = false;
    });
  }

  Future<void> _removeFromFavourites(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Remove from UI immediately
      setState(() {
        _allEvents.removeWhere((event) => event['id'] == eventId);
      });

      // Then remove from database
      final favSnapshot = await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('favourites')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (var doc in favSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error removing from favourites: $e');
      // Reload if there's an error
      _loadFavourites();
    }
  }

  String _getEventStatus(Map<String, dynamic> event) {
    final now = DateTime.now();
    final startTime =
        (event['startTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final endTime =
        (event['endTime'] as Timestamp?)?.toDate() ?? DateTime.now();

    if (now.isBefore(startTime)) {
      return 'Upcoming';
    } else if (now.isAfter(endTime)) {
      return 'Finished';
    } else {
      return 'Ongoing';
    }
  }

  // Updated to return gradient or color
  dynamic _getStatusDecoration(String status) {
    switch (status) {
      case 'Finished':
        return Colors.grey.shade800;
      case 'Cancelled':
        return const Color(0xFFB71C1C);
      case 'Ongoing':
        return Colors.red;
      case 'Upcoming':
      default:
        return const LinearGradient(
          colors: [Color(0xFF245126), Color(0xFF4EB152)],
        );
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Finished':
        return 'Hope you enjoyed alot!';
      case 'Cancelled':
        return 'We will initiate your refund soon';
      case 'Ongoing':
        return 'Event is live now!';
      case 'Upcoming':
      default:
        return 'Get ready for the event!';
    }
  }

  List<Map<String, dynamic>> _filterEventsByCategory(
    List<Map<String, dynamic>> events,
    String category,
  ) {
    if (category == 'Events') {
      return events
          .where(
            (e) => e['eventCategory']?.toString().toLowerCase() == 'basicevent',
          )
          .toList();
    } else if (category == 'Sports') {
      return events
          .where(
            (e) => e['eventCategory']?.toString().toLowerCase() == 'sports',
          )
          .toList();
    } else if (category == 'Club Events') {
      return events
          .where(
            (e) => e['eventCategory']?.toString().toLowerCase() == 'clubevent',
          )
          .toList();
    }
    return events;
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final startTime =
        (event['startTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final eventDate = DateFormat('EEE, dd MMM, h:mm a').format(startTime);
    final status = _getEventStatus(event);
    final statusDecoration = _getStatusDecoration(status);
    final statusMessage = _getStatusMessage(status);
    final subCategory = event['eventSubCategory']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventPage(eventId: event['id']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with image and details side by side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 90,
                    height: 125,
                    child:
                        event['poster'] != null &&
                            event['poster'].toString().isNotEmpty
                        ? Image.network(
                            event['poster'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.event,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Event Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sub Category and Heart Icon Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (subCategory.isNotEmpty)
                                  Text(
                                    subCategory,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF4CAF50),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                // Date and Time
                                Text(
                                  eventDate,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _removeFromFavourites(event['id']),
                            child: Stack(
                              alignment: Alignment.center,
                              children: const [
                                Icon(
                                  Icons.favorite_border,
                                  color: Color(0xFF4CAF50), // green outline
                                  size: 26,
                                ),
                                Icon(
                                  Icons.favorite,
                                  color: Colors.black, // filled black heart
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Event Name
                      Text(
                        event['name'] ?? 'No name',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Location
                      Text(
                        event['location'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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

            const SizedBox(height: 16),

            // Bottom section with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusDecoration is Color ? statusDecoration : null,
                    gradient: statusDecoration is LinearGradient
                        ? statusDecoration
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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

  Widget _buildCategoryTab(String category) {
    final filteredEvents = _filterEventsByCategory(_allEvents, category);

    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              'You have no more favourites',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        return _buildEventCard(filteredEvents[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            'Favourites',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF4CAF50),
                indicatorWeight: 3,
                labelColor: const Color(0xFF4CAF50),
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Events'),
                  Tab(text: 'Sports'),
                  Tab(text: 'Club Events'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : _allEvents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    color: Colors.grey,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favourites yet',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryTab('Events'),
                _buildCategoryTab('Sports'),
                _buildCategoryTab('Club Events'),
              ],
            ),
    );
  }
}
