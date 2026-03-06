import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:tixxo/utils/responsive.dart';
import 'dart:math' as math;

enum SuggType { artist, event, sports, club, venue }

class SuggItem {
  final String query;
  final SuggType type;
  const SuggItem(this.query, this.type);
}

const List<SuggItem> _kAllSuggestions = [
  SuggItem('Arijit Singh Live Tour', SuggType.artist),
  SuggItem('Arijit Singh World Tour 2026', SuggType.artist),
  SuggItem('AP Dhillon Concert India', SuggType.artist),
  SuggItem('Diljit Dosanjh Live', SuggType.artist),
  SuggItem('New Year Eve Party 2026', SuggType.event),
  SuggItem('Holi Festival Party 2026', SuggType.event),
  SuggItem('Stand Up Comedy Night', SuggType.event),
  SuggItem('Sunburn Festival 2026', SuggType.event),
  SuggItem('IPL 2026 Tickets', SuggType.sports),
  SuggItem('India vs Pakistan T20', SuggType.sports),
  SuggItem('Pro Kabaddi League', SuggType.sports),
  SuggItem('EDM Night Lucknow', SuggType.club),
  SuggItem('Phoenix Palassio Events', SuggType.venue),
];

const List<SuggItem> _kTrending = [
  SuggItem('Sunburn Festival 2026', SuggType.event),
  SuggItem('Arijit Singh Live', SuggType.artist),
  SuggItem('IPL 2026 Tickets', SuggType.sports),
  SuggItem('Holi Party 2026', SuggType.event),
  SuggItem('EDM Night', SuggType.club),
];

IconData _iconForType(SuggType type) {
  switch (type) {
    case SuggType.artist:
      return LucideIcons.mic2;
    case SuggType.event:
      return LucideIcons.calendar;
    case SuggType.sports:
      return LucideIcons.trophy;
    case SuggType.club:
      return LucideIcons.disc;
    case SuggType.venue:
      return LucideIcons.mapPin;
  }
}

Color _colorForType(SuggType type) {
  switch (type) {
    case SuggType.artist:
      return const Color(0xFF7C3AED);
    case SuggType.event:
      return const Color(0xFF2563EB);
    case SuggType.sports:
      return const Color(0xFFD97706);
    case SuggType.club:
      return const Color(0xFF4EB152);
    case SuggType.venue:
      return const Color(0xFF6B7280);
  }
}

class SearchBarWidget extends StatefulWidget {
  final VoidCallback? onTap;
  const SearchBarWidget({super.key, this.onTap});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final ValueNotifier<String> _queryNotifier = ValueNotifier('');

  OverlayEntry? _overlayEntry;
  late AnimationController _overlayAnim;

  bool _isActive = false;
  List<String> _recentSearches = ['Arijit Singh', 'IPL Tickets'];

  @override
  void initState() {
    super.initState();
    _overlayAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _focusNode.addListener(_onFocusChanged);
    _textController.addListener(
      () => _queryNotifier.value = _textController.text,
    );
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (!_isActive) setState(() => _isActive = true);
      _showOverlay();
      if (widget.onTap != null) widget.onTap!();
    } else {
      if (_isActive) setState(() => _isActive = false);
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _overlayAnim.forward();
  }

  void _hideOverlay() {
    _overlayAnim.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (ctx) {
        return _SearchOverlayScaffold(
          layerLink: _layerLink,
          queryNotifier: _queryNotifier,
          animController: _overlayAnim,
          recentSearches: List.unmodifiable(_recentSearches),
          onSuggestionTap: _onSuggestionSelected,
          onFillQuery: _fillQuery,
          onClearRecent: _removeRecentSearch,
          onDismiss: _dismissSearch,
        );
      },
    );
  }

  void _onSuggestionSelected(String suggestion) {
    _textController.text = suggestion;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() {
      _recentSearches = [
        suggestion,
        ..._recentSearches.where((s) => s != suggestion),
      ].take(5).toList();
    });
    _focusNode.unfocus();
  }

  void _fillQuery(String suggestion) {
    _textController.text = suggestion;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _queryNotifier.value = suggestion;
    _overlayEntry?.markNeedsBuild();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _removeRecentSearch(String search) {
    setState(
      () =>
          _recentSearches = _recentSearches.where((s) => s != search).toList(),
    );
    _overlayEntry?.markNeedsBuild();
  }

  void _dismissSearch() {
    _textController.clear();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    _queryNotifier.dispose();
    _overlayAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: r.h(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.radius(12)),
          border: Border.all(
            color: _isActive ? const Color(0xFF4EB152) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isActive ? 0.12 : 0.05),
              blurRadius: _isActive ? r.radius(22) : r.radius(10),
              offset: Offset(0, _isActive ? r.h(6) : r.h(2)),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(12)),
              child: Icon(
                Icons.search_rounded,
                color: _isActive
                    ? const Color(0xFF4EB152)
                    : Colors.grey.shade500,
                size: r.sp(20),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: GoogleFonts.poppins(
                  fontSize: r.sp(14),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  hintText: "Search for events, artists, venues...",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: r.sp(13),
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: r.h(14)),
                ),
              ),
            ),
            if (_isActive)
              GestureDetector(
                onTap: _textController.clear,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.w(12)),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade400,
                    size: r.sp(18),
                  ),
                ),
              ),
            Container(width: 1, height: r.h(24), color: Colors.grey.shade200),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(12)),
              child: Icon(
                Icons.mic,
                color: _isActive
                    ? const Color(0xFF4EB152)
                    : Colors.grey.shade500,
                size: r.sp(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchOverlayScaffold extends StatelessWidget {
  final LayerLink layerLink;
  final ValueNotifier<String> queryNotifier;
  final AnimationController animController;
  final List<String> recentSearches;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<String> onFillQuery;
  final ValueChanged<String> onClearRecent;
  final VoidCallback onDismiss;

  const _SearchOverlayScaffold({
    required this.layerLink,
    required this.queryNotifier,
    required this.animController,
    required this.recentSearches,
    required this.onSuggestionTap,
    required this.onFillQuery,
    required this.onClearRecent,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Stack(
        children: [
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: animController,
                curve: Curves.easeOut,
              ),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),
          CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, r.h(56)),
            child: ValueListenableBuilder<String>(
              valueListenable: queryNotifier,
              builder: (context, query, _) {
                final hasQuery = query.trim().isNotEmpty;
                final qLower = query.trim().toLowerCase();
                final filtered = hasQuery
                    ? _kAllSuggestions
                          .where((s) => s.query.toLowerCase().contains(qLower))
                          .take(6)
                          .toList()
                    : <SuggItem>[];

                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animController,
                    curve: Curves.easeOut,
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, -0.05),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animController,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: r.w(16)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(r.radius(16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 32,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasQuery) ...[
                              if (filtered.isNotEmpty) ...[
                                SizedBox(height: r.h(6)),
                                ...filtered.map(
                                  (e) => _SuggestionRow(
                                    item: e,
                                    query: query,
                                    onTap: () => onSuggestionTap(e.query),
                                    onFill: () => onFillQuery(e.query),
                                  ),
                                ),
                                SizedBox(height: r.h(6)),
                              ] else
                                Padding(
                                  padding: EdgeInsets.all(r.w(20)),
                                  child: Center(
                                    child: Text(
                                      "No matching events found.",
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade500,
                                        fontSize: r.sp(13),
                                      ),
                                    ),
                                  ),
                                ),
                            ] else ...[
                              if (recentSearches.isNotEmpty) ...[
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    r.w(16),
                                    r.h(16),
                                    r.w(16),
                                    r.h(8),
                                  ),
                                  child: Text(
                                    'Recent Searches',
                                    style: GoogleFonts.poppins(
                                      fontSize: r.sp(12),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                ...recentSearches.map(
                                  (s) => _RecentRow(
                                    text: s,
                                    onTap: () => onSuggestionTap(s),
                                    onFill: () => onFillQuery(s),
                                    onRemove: () => onClearRecent(s),
                                  ),
                                ),
                                Divider(height: 1, color: Colors.grey.shade200),
                              ],
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  r.w(16),
                                  r.h(16),
                                  r.w(16),
                                  r.h(8),
                                ),
                                child: Text(
                                  'Trending on Tixoo',
                                  style: GoogleFonts.poppins(
                                    fontSize: r.sp(12),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4EB152),
                                  ),
                                ),
                              ),
                              ..._kTrending.map(
                                (e) => _SuggestionRow(
                                  item: e,
                                  query: '',
                                  onTap: () => onSuggestionTap(e.query),
                                  onFill: () => onFillQuery(e.query),
                                ),
                              ),
                              SizedBox(height: r.h(8)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final SuggItem item;
  final String query;
  final VoidCallback onTap;
  final VoidCallback onFill;

  const _SuggestionRow({
    required this.item,
    required this.query,
    required this.onTap,
    required this.onFill,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final typeColor = _colorForType(item.type);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(12)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(r.w(8)),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(r.radius(8)),
              ),
              child: Icon(
                _iconForType(item.type),
                size: r.sp(16),
                color: typeColor,
              ),
            ),
            SizedBox(width: r.w(12)),
            Expanded(
              child: _HighlightedText(text: item.query, query: query),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.arrowUpLeft,
                size: r.sp(16),
                color: Colors.grey.shade400,
              ),
              onPressed: onFill,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final String text;
  final VoidCallback onTap, onFill, onRemove;

  const _RecentRow({
    required this.text,
    required this.onTap,
    required this.onFill,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(12)),
        child: Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: r.sp(16),
              color: Colors.grey.shade400,
            ),
            SizedBox(width: r.w(12)),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: r.sp(13),
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.x,
                size: r.sp(16),
                color: Colors.grey.shade400,
              ),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text, query;
  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final baseStyle = GoogleFonts.poppins(
      fontSize: r.sp(13),
      color: Colors.grey.shade800,
    );

    if (query.isEmpty) return Text(text, style: baseStyle);

    final matchIndex = text.toLowerCase().indexOf(query.toLowerCase());
    if (matchIndex == -1) return Text(text, style: baseStyle);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, matchIndex)),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + query.length),
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          TextSpan(text: text.substring(matchIndex + query.length)),
        ],
      ),
    );
  }
}
