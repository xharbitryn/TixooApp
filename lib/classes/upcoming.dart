import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/widgets/buttons/neopop_button/neopop_button.dart';
import 'package:tixxo/models/event.dart';
import 'package:tixxo/supportive_pages/event_details.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final String title;
  final String venue;
  final String date;
  final String day;
  final String price;
  final String image;
  final bool isFavorite;
  final Future<void> Function() onFavoriteToggle;
  final String eventId;

  const EventCard({
    super.key,
    required this.event,
    required this.title,
    required this.venue,
    required this.date,
    required this.day,
    required this.price,
    required this.image,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.eventId,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isProcessing = false;

  Future<void> _handleFavoriteToggle() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.onFavoriteToggle();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 315,
      height: 380,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Date + Favorite
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    widget.day,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.date,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _isProcessing ? null : _handleFavoriteToggle,
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF15612E),
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          widget.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          key: ValueKey(widget.isFavorite),
                          color: widget.isFavorite
                              ? Colors.redAccent
                              : const Color(0xFF15612E),
                          size: 24,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          /// Event Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.image,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 50,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF15612E)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          /// Event Title (Gradient Text)
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.black, Colors.grey],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white, // Important for shader mask
              ),
            ),
          ),

          const SizedBox(height: 6),
          Text(
            widget.venue,
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 11),
          ),

          /// Gradient Divider (Black → Grey)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.grey],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          /// Price + Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Starts from\n${widget.price}',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87),
              ),
              NeoPopButton(
                color: Colors.transparent,
                animationDuration: const Duration(milliseconds: 500),
                onTapUp: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventPage(eventId: widget.eventId),
                    ),
                  );
                },
                onTapDown: () {},
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF15612E),
                        Color(0xFF202020),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
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
        ],
      ),
    );
  }
}
