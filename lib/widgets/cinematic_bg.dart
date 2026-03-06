import 'package:flutter/material.dart';
import 'dart:math' as math;

// Colors
const Color kTixooDarkGreen = Color(0xFF245126);
const Color kTixooLightGreen = Color(0xFF4EB152);

class CinematicBackground extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const CinematicBackground({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. ANIMATED CANVAS (Stays fixed in background)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _CinematicStardustPainter(
                  animationValue: controller.value,
                ),
              );
            },
          ),
        ),
        // 2. CONTENT (Scrollable on top)
        child,
      ],
    );
  }
}

class _CinematicStardustPainter extends CustomPainter {
  final double animationValue;
  final List<Offset> stars = List.generate(
    80,
    (index) => Offset(
      math.Random(index).nextDouble(),
      math.Random(index * 13).nextDouble(),
    ),
  );

  _CinematicStardustPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // 1. DEEP VOID BACKGROUND
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF000000),
          const Color(0xFF0A140A), // Deep Forest Black
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. AURORA CLOUDS (Breathing Animation)
    final Paint blobPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 150);

    double t = animationValue * 2 * math.pi;

    // Cloud 1
    double x1 = size.width * 0.9 + (size.width * 0.15 * math.cos(t));
    double y1 = size.height * 0.1 + (size.height * 0.15 * math.sin(t));
    blobPaint.color = kTixooDarkGreen.withOpacity(0.3);
    canvas.drawCircle(Offset(x1, y1), 300, blobPaint);

    // 3. STARDUST PARTICLES
    final Paint starPaint = Paint();
    for (int i = 0; i < stars.length; i++) {
      double speed = (i % 3) + 0.5;
      double dy = (stars[i].dy * size.height) + (math.sin(t * speed) * 15);
      double dx = (stars[i].dx * size.width) + (math.cos(t * speed) * 15);

      double rawOpacity = 0.1 + (0.2 * math.sin((t * 3) + i));
      starPaint.color = Colors.white.withOpacity(rawOpacity.clamp(0.0, 1.0));

      // Twinkle effect size
      double radius = (i % 5 == 0) ? 1.5 : 1.0;

      canvas.drawCircle(
        Offset(dx % size.width, dy % size.height),
        radius,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicStardustPainter oldDelegate) => true;
}
