import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tixxo/widgets/divider.dart';
import 'package:tixxo/widgets/videoplayer.dart';
import 'package:video_player/video_player.dart';

class SpotlightSection extends StatelessWidget {
  const SpotlightSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Events')
          .where('spotlight', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'title': data['name'] ?? 'Untitled Event',
            'startTime': (data['startTime'] as Timestamp?)?.toDate(),
            'venue': data['location'] ?? 'Unknown location',
            'poster': data['poster'] ?? '',
            'videoUrl': data['videoUrl'] ?? '',
          };
        }).toList();

        if (events.isEmpty) {
          return const SizedBox(); // hide section if no spotlight
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GradientDivider(title: "Spotlight"),
            SizedBox(
              height: 470,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SpotlightCard(
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

class SpotlightCard extends StatelessWidget {
  final String title;
  final DateTime? startTime;
  final String venue;
  final String poster;
  final String videoUrl;

  const SpotlightCard({
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
    final mediaHeight = cardHeight * 0.8; // 80% for video/image
    final infoHeight = cardHeight * 0.2; // 20% for info

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Media ---
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            child: SizedBox(
              height: mediaHeight,
              width: double.infinity,
              child: videoUrl.isNotEmpty
                  ? AutoPlayVideo(
                      videoUrl: videoUrl,
                      borderRadius: 3,
                      fit: BoxFit.cover,
                    )
                  : poster.isNotEmpty
                  ? Image.network(poster, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade300),
            ),
          ),

          // --- Event Info ---
          SizedBox(
            height: infoHeight,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  if (startTime != null)
                    Text(
                      DateFormat('EEE, MMM d, h:mm a').format(startTime!),
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
    );
  }
}
