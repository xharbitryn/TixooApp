import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/models/home_models.dart';
import 'package:tixxo/utils/responsive.dart';

class TopBar extends StatelessWidget {
  final LocationData location;
  final bool isPlusUser;
  final String? avatarUrl;
  final Color contentColor;
  final VoidCallback? onLocationTap;
  final VoidCallback? onGetPlusTap;
  final VoidCallback? onAvatarTap;

  const TopBar({
    super.key,
    required this.location,
    this.isPlusUser = false,
    this.avatarUrl,
    this.contentColor = Colors.black,
    this.onLocationTap,
    this.onGetPlusTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    final elementBgColor = contentColor == Colors.black
        ? Colors.black.withOpacity(0.05)
        : Colors.white.withOpacity(0.2);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onLocationTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: r.w(28),
                    height: r.w(28),
                    decoration: BoxDecoration(
                      color: elementBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: contentColor,
                      size: r.sp(16),
                    ),
                  ),
                  SizedBox(width: r.w(6)),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                location.city,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: r.sp(14),
                                  fontWeight: FontWeight.w700,
                                  color: contentColor,
                                  height: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: contentColor,
                              size: r.sp(18),
                            ),
                          ],
                        ),
                        Text(
                          '${location.state}, ${location.country}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: r.sp(10),
                            fontWeight: FontWeight.w400,
                            color: contentColor.withOpacity(0.8),
                            height: 1.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: r.w(10)),
          if (!isPlusUser)
            GestureDetector(
              onTap: onGetPlusTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r.w(14),
                  vertical: r.h(7),
                ),
                decoration: BoxDecoration(
                  // Implementing the specific linear gradient requested
                  gradient: const LinearGradient(
                    colors: [Color(0xFF245126), Color(0xFF4EB152)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(r.radius(20)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF245126).withOpacity(0.3),
                      blurRadius: r.radius(6),
                      offset: Offset(0, r.h(2)),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: r.sp(14),
                    ),
                    SizedBox(width: r.w(4)),
                    Text(
                      'Get Plus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.sp(12),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(width: r.w(10)),
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: r.w(36),
              height: r.w(36),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: contentColor.withOpacity(0.2),
                  width: 1.5,
                ),
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: avatarUrl == null ? elementBgColor : null,
              ),
              child: avatarUrl == null
                  ? Icon(
                      Icons.person_rounded,
                      color: contentColor,
                      size: r.sp(20),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
