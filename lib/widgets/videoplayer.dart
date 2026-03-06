import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AutoPlayVideo extends StatefulWidget {
  final String videoUrl;
  final double? borderRadius;
  final BoxFit fit;
  final bool autoplay;
  final bool muted;

  const AutoPlayVideo({
    super.key,
    required this.videoUrl,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.autoplay = true,
    this.muted = true,
  });

  @override
  State<AutoPlayVideo> createState() => _AutoPlayVideoState();
}

class _AutoPlayVideoState extends State<AutoPlayVideo>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..setVolume(widget.muted ? 0 : 1)
      ..initialize().then((_) {
        if (mounted && widget.autoplay && !_isDisposed) {
          _controller.play();
          setState(() {});
        }
      });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (widget.autoplay) _controller.play();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  bool get _isMuted => _controller.value.volume == 0;

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF4EB152),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
      child: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: widget.fit,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                size: 20,
              ),
              onPressed: () {
                if (_isDisposed) return;
                _controller.setVolume(_isMuted ? 1.0 : 0.0);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
