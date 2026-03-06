import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:tixxo/widgets/cinematic_bg.dart';

/// **Responsive Scaling Engine**
/// Centralized logic to scale UI elements elegantly across devices.
class Responsive {
  /// Scales a value based on screen width, with dampening for larger screens.
  static double s(BuildContext c, double val) {
    final double width = MediaQuery.of(c).size.width;
    const double baseWidth = 390.0; // iPhone reference

    // Tablet/Desktop Logic (Dampened Scaling)
    if (width > 600) {
      double scaleFactor = width / baseWidth;
      // Dampen the scale so elements don't get cartoonishly huge
      // 0.45 factor means we only take 45% of the extra growth
      double dampenedScale = 1.0 + ((scaleFactor - 1.0) * 0.45);
      return val * dampenedScale;
    }

    // Mobile Logic (Linear Scaling)
    return val * (width / baseWidth);
  }

  /// Returns constraints to keep forms readable on wide screens (iPad/Web)
  static BoxConstraints formConstraints(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return BoxConstraints(maxWidth: width > 600 ? 520 : double.infinity);
  }
}

// --- 1. PREMIUM INPUT FIELD ---
class PremiumAuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final Widget? suffixWidget;
  final AnimationController shimmerController;
  final bool isValid;
  final bool showValidation;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final TextInputType keyboardType;

  const PremiumAuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.shimmerController,
    this.isPassword = false,
    this.suffixWidget,
    this.isValid = false,
    this.showValidation = false,
    this.textInputAction,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<PremiumAuthField> createState() => _PremiumAuthFieldState();
}

class _PremiumAuthFieldState extends State<PremiumAuthField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic sizing via Responsive Engine
    final double borderRadius = Responsive.s(context, 14);
    final double iconSize = Responsive.s(context, 20);
    final double fontSize = Responsive.s(context, 15);
    final double verticalPadding = Responsive.s(context, 18);

    Color borderColor = Colors.white.withOpacity(0.1);
    if (widget.showValidation && widget.isValid) {
      borderColor = kTixooLightGreen.withOpacity(0.5);
    }

    return Stack(
      children: [
        // 1. ROTATING GLOW (Only visible when focused)
        if (_isFocused)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: widget.shimmerController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        kTixooLightGreen.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.4, 0.5, 0.6],
                      transform: GradientRotation(
                        widget.shimmerController.value * 2 * math.pi,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // 2. ACTUAL INPUT CONTAINER
        Container(
          margin: const EdgeInsets.all(1.7),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(borderRadius - 2),
            border: Border.all(
              color: _isFocused ? Colors.transparent : borderColor,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: fontSize),
            cursorColor: kTixooLightGreen,
            decoration: InputDecoration(
              prefixIcon: Icon(
                widget.icon,
                color: (widget.showValidation && widget.isValid)
                    ? kTixooLightGreen
                    : (_isFocused ? Colors.white : Colors.white38),
                size: iconSize,
              ),
              suffixIcon: widget.suffixWidget != null
                  ? Padding(
                      padding: EdgeInsets.all(Responsive.s(context, 12.0)),
                      child: widget.suffixWidget,
                    )
                  : null,
              hintText: widget.label,
              hintStyle: GoogleFonts.poppins(
                color: Colors.white24,
                fontSize: fontSize,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: verticalPadding),
            ),
          ),
        ),
      ],
    );
  }
}

// --- 2. CYBER EYE (Show/Hide Password) ---
class CyberEyeButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onTap;

  const CyberEyeButton({
    super.key,
    required this.isVisible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double size = Responsive.s(context, 20);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isVisible
            ? Icon(
                Icons.visibility_outlined,
                key: const ValueKey('open'),
                color: kTixooLightGreen,
                size: size,
              )
            : Icon(
                Icons.visibility_off_outlined,
                key: const ValueKey('closed'),
                color: Colors.white38,
                size: size,
              ),
      ),
    );
  }
}

// --- 3. SCALE BUTTON (Click Animation) ---
class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const ScaleButton({super.key, required this.child, required this.onTap});

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

// --- 4. ROTATING BORDER BUTTON (Skip Login) ---
class RotatingBorderButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final AnimationController controller;

  const RotatingBorderButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final double height = Responsive.s(context, 34);
    final double width = Responsive.s(context, 100);
    final double fontSize = Responsive.s(context, 12);
    final double radius = Responsive.s(context, 20);

    return ScaleButton(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The rotating gradient border
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      kTixooLightGreen,
                      Colors.transparent,
                    ],
                    stops: const [0.2, 0.5, 0.8],
                    transform: GradientRotation(controller.value * 2 * math.pi),
                  ),
                ),
              );
            },
          ),
          // The button center
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.s(context, 16),
              vertical: Responsive.s(context, 8),
            ),
            margin: const EdgeInsets.all(1.7),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: kTixooLightGreen,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
