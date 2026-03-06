import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CredButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isSecondary;

  const CredButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSecondary ? Colors.transparent : const Color(0xFFAFFF00),
          border: isSecondary
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
              : null,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 12)],
            Text(
              text,
              style: GoogleFonts.poppins(
                color: isSecondary ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
