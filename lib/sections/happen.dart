import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tixxo/widgets/divider.dart';
import 'package:tixxo/widgets/videoplayer.dart';

class EventsThisWeekSection extends StatelessWidget {
  const EventsThisWeekSection({super.key});

  bool _isInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final beginningOfWeek = now.subtract(
      Duration(days: now.weekday - 1),
    ); // Monday
    final endOfWeek = beginningOfWeek.add(const Duration(days: 6)); // Sunday
    return date.isAfter(beginningOfWeek.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Events').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final events = snapshot.data!.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp? startTimeStamp = data['startTime'] as Timestamp?;
              if (startTimeStamp == null) return null;

              return {
                'id': doc.id,
                'title': data['name'] ?? 'Untitled Event',
                'startTime': startTimeStamp.toDate(),
                'venue': data['location'] ?? 'Unknown location',
                'poster': data['poster'] ?? '',
                'videoUrl': data['videoUrl'] ?? '',
              };
            })
            .where(
              (event) => event != null && _isInCurrentWeek(event['startTime']),
            )
            .cast<Map<String, dynamic>>()
            .toList();

        if (events.isEmpty)
          return const Center(child: Text('No events this week'));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GradientDivider(title: "Happening This Week"),
            SizedBox(
              height: 470,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: EventCard(
                      title: event['title'],
                      startTime: event['startTime'],
                      venue: event['venue'],
                      poster: event['poster'],
                      videoUrl: event['videoUrl'],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class EventCard extends StatelessWidget {
  final String title;
  final DateTime startTime;
  final String venue;
  final String poster;
  final String videoUrl;

  const EventCard({
    super.key,
    required this.title,
    required this.startTime,
    required this.venue,
    required this.poster,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight = 450.0;
    final mediaHeight = cardHeight * 0.8; // 80% height for video/image
    final infoHeight = cardHeight * 0.2; // 20% height for info

    return Center(
      child: Container(
        height: cardHeight,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Media ---
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
              child: SizedBox(
                height: mediaHeight,
                width: double.infinity,
                child: videoUrl.isNotEmpty
                    ? AutoPlayVideo(
                        videoUrl: videoUrl,
                        borderRadius: 3,
                        fit: BoxFit.fill,
                      )
                    : poster.isNotEmpty
                    ? Image.network(poster, fit: BoxFit.cover)
                    : Container(color: Colors.grey.shade300),
              ),
            ),

            // --- Info ---
            SizedBox(
              height: infoHeight,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('EEE, MMM d, h:mm a').format(startTime),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      venue,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
