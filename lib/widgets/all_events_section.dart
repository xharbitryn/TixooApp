import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/constants/app_colors.dart';
import 'package:tixxo/models/home_models.dart';
import 'package:tixxo/utils/responsive.dart';
import 'package:tixxo/widgets/section_header.dart';

class AllEventsSection extends StatelessWidget {
  final List<EventData> events;
  final List<String> filters;
  final int selectedFilterIndex;
  final ValueChanged<int>? onFilterSelected;
  final ValueChanged<EventData>? onEventTap;
  final ValueChanged<EventData>? onBookNowTap;

  const AllEventsSection({
    super.key,
    required this.events,
    this.filters = const [
      'Filters',
      'Today',
      'Tomorrow',
      '10 km Far Away',
      'Music',
    ],
    this.selectedFilterIndex = -1,
    this.onFilterSelected,
    this.onEventTap,
    this.onBookNowTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Column(
      children: [
        const SectionHeader(title: 'All Events'),
        SizedBox(height: r.h(4)),
        _buildFilterChips(r),
        SizedBox(height: r.h(10)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: r.w(16)),
          child: _buildEventsGrid(r),
        ),
      ],
    );
  }

  Widget _buildFilterChips(Responsive r) {
    return SizedBox(
      height: r.h(36),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: r.w(16)),
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: r.w(8)),
        itemBuilder: (context, index) {
          final isFilter = index == 0;
          final isSelected = index == selectedFilterIndex;

          return GestureDetector(
            onTap: () => onFilterSelected?.call(index),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.w(12),
                vertical: r.h(6),
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : AppColors.white,
                borderRadius: BorderRadius.circular(r.radius(20)),
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFilter) ...[
                    Icon(
                      Icons.tune_rounded,
                      size: r.sp(14),
                      color: isSelected
                          ? AppColors.textWhite
                          : AppColors.textPrimary,
                    ),
                    SizedBox(width: r.w(4)),
                  ],
                  Text(
                    filters[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: r.sp(12),
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.textWhite
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsGrid(Responsive r) {
    final List<Widget> rows = [];
    for (int i = 0; i < events.length; i += 2) {
      final leftEvent = events[i];
      final rightEvent = i + 1 < events.length ? events[i + 1] : null;

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: r.h(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EventCard(
                  event: leftEvent,
                  onTap: () => onEventTap?.call(leftEvent),
                  onBookNow: () => onBookNowTap?.call(leftEvent),
                ),
              ),
              SizedBox(width: r.w(12)),
              Expanded(
                child: rightEvent != null
                    ? _EventCard(
                        event: rightEvent,
                        onTap: () => onEventTap?.call(rightEvent),
                        onBookNow: () => onBookNowTap?.call(rightEvent),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _EventCard extends StatelessWidget {
  final EventData event;
  final VoidCallback? onTap;
  final VoidCallback? onBookNow;

  const _EventCard({required this.event, this.onTap, this.onBookNow});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(r.radius(14)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: r.radius(10),
              offset: Offset(0, r.h(3)),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.chipBg,
                      child: Icon(
                        Icons.image_outlined,
                        size: r.sp(30),
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Positioned(
                    left: r.w(8),
                    bottom: r.h(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.w(10),
                        vertical: r.h(4),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.wantBadgeGreen,
                        borderRadius: BorderRadius.circular(r.radius(6)),
                      ),
                      child: Text(
                        'Want',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.sp(10),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: r.w(8),
                    top: r.h(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.w(6),
                        vertical: r.h(3),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(r.radius(6)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            event.dayLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: r.sp(9),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            event.monthLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: r.sp(7),
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(r.w(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: r.sp(11),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: r.h(2)),
                  Text(
                    '${event.venue}, ${event.city}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: r.sp(9),
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: r.h(6)),
                  Row(
                    children: [
                      Text(
                        event.priceFormatted,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textGreen,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onBookNow,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.w(10),
                            vertical: r.h(5),
                          ),
                          decoration: BoxDecoration(
                            // Implementing the universal gradient here
                            gradient: const LinearGradient(
                              colors: [Color(0xFF245126), Color(0xFF4EB152)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(r.radius(6)),
                          ),
                          child: Text(
                            'Book Now',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: r.sp(9),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
