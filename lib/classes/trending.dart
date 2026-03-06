import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EnhancedEventCard extends StatefulWidget {
  final String imagePath;
  final String? videoUrl;
  final String description;
  final String eventId;
  final String location;
  final Timestamp startTime;
  final int baseTicketPrice;
  final AnimationController animationController;
  final bool isCenter;
  final bool isVisible;
  final VoidCallback onTap;

  const EnhancedEventCard({
    super.key,
    required this.imagePath,
    this.videoUrl,
    required this.description,
    required this.eventId,
    required this.location,
    required this.startTime,
    required this.baseTicketPrice,
    required this.animationController,
    required this.onTap,
    this.isCenter = false,
    this.isVisible = false,
  });

  @override
  State<EnhancedEventCard> createState() => _EnhancedEventCardState();
}

class _EnhancedEventCardState extends State<EnhancedEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isMuted = true;
  bool _isVideoError = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _initializeVideo();
  }

  void _initializeVideo() {
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!))
            ..initialize()
                .then((_) {
                  if (mounted) {
                    setState(() => _isVideoInitialized = true);
                    _videoController!
                      ..setLooping(true)
                      ..setVolume(0.0);
                    if (widget.isVisible) _videoController!.play();
                  }
                })
                .catchError((_) {
                  if (mounted) setState(() => _isVideoError = true);
                });
    }
  }

  @override
  void didUpdateWidget(EnhancedEventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (_videoController != null && _isVideoInitialized && !_isVideoError) {
        widget.isVisible ? _videoController!.play() : _videoController!.pause();
      }
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _isVideoError = false;
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _disposeVideo();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${DateFormat('EEEE d MMMM').format(date)}, ${DateFormat('h:mma').format(date)} onwards";
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,##,###');
    return "₹ ${formatter.format(price)} Onwards";
  }

  @override
  Widget build(BuildContext context) {
    final dateTime = widget.startTime.toDate();
    final bool showVideo =
        widget.videoUrl != null &&
        widget.videoUrl!.isNotEmpty &&
        _isVideoInitialized &&
        !_isVideoError;

    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) {
        _hoverController.reverse();
        Future.delayed(const Duration(milliseconds: 100), widget.onTap);
      },
      onTapCancel: () => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            // Align prevents vertical stretching
            child: Align(
              alignment: Alignment.topCenter, // Pushes card to the top
              child: Container(
                width: 290,
                // 🛑 MARGIN FIX: Reduced Top to 4px.
                // Bottom is 24px to allow space for the heavy shadow.
                margin: const EdgeInsets.fromLTRB(10, 4, 10, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. IMAGE
                    Container(
                      height: 340,
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(9, 10, 9, 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            showVideo
                                ? VideoPlayer(_videoController!)
                                : Image.network(
                                    widget.imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (
                                          context,
                                          error,
                                          stackTrace,
                                        ) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.grey,
                                            size: 40,
                                          ),
                                        ),
                                  ),
                            if (showVideo)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      _isMuted = !_isMuted;
                                      _videoController!.setVolume(
                                        _isMuted ? 0.0 : 1.0,
                                      );
                                    });
                                  },
                                  onTapDown: (_) {},
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isMuted
                                          ? Icons.volume_off
                                          : Icons.volume_up,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // 2. TEXT CONTENT
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date
                          Text(
                            _formatDate(dateTime),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF15612E),
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // Title
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [Color(0xFF000000), Color(0xFF848484)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds);
                            },
                            child: Text(
                              widget.description,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Divider
                          Container(
                            height: 1,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF535353), Color(0x00FFFFFF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Location + Arrow
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.location,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF757575),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SvgPicture.asset(
                                'assets/icons/arrow.svg',
                                width: 14,
                                height: 14,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF15612E),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Price
                          Text(
                            _formatPrice(widget.baseTicketPrice),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181D27),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
