import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🚀 IMPORTS FOR ROUTING
import 'package:tixxo/supportive_pages/event_details.dart';
import 'package:tixxo/supportive_pages/artist_detail.dart';
import 'package:tixxo/supportive_pages/promoter_detail.dart';

class SuggItem {
  final String id;
  final String query;
  final String type;
  final String image;
  const SuggItem(this.id, this.query, this.type, this.image);

  Map<String, dynamic> toJson() => {
    'id': id,
    'query': query,
    'type': type,
    'image': image,
  };
  factory SuggItem.fromJson(Map<String, dynamic> json) =>
      SuggItem(json['id'], json['query'], json['type'], json['image']);
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

  bool _isFocused = false;
  List<SuggItem> _recentSearches = [];
  List<SuggItem> _allEvents = [];

  List<SuggItem> _trendingEvents = [
    const SuggItem('static_1', 'Sunburn Festival', 'Event', ''),
    const SuggItem('static_2', 'Arijit Singh Live', 'Artist', ''),
    const SuggItem('static_3', 'Standup Comedy', 'Event', ''),
    const SuggItem('static_4', 'IPL Tickets', 'Event', ''),
  ];

  final List<String> _hintWords = [
    'events...',
    'artists...',
    'promoters...',
    'venues...',
  ];
  int _currentHintIndex = 0;
  Timer? _hintTimer;
  Timer? _debounceTimer;
  bool _isLoading = false;

  static const Color _primaryGreen = Color(0xFF4EB152);

  @override
  void initState() {
    super.initState();
    _allEvents = _trendingEvents;

    _overlayAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _focusNode.addListener(_onFocusChanged);

    _textController.addListener(() {
      _queryNotifier.value = _textController.text;
      _overlayEntry?.markNeedsBuild();
      _onSearchChanged(_textController.text);
    });

    _hintTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _textController.text.isEmpty && !_isFocused) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _hintWords.length;
        });
      }
    });

    _loadRecentSearches();
    _fetchInitialData();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? recentsJson = prefs.getStringList(
      'tixoo_recent_searches',
    );
    if (recentsJson != null && mounted) {
      setState(() {
        _recentSearches = recentsJson
            .map((str) => SuggItem.fromJson(jsonDecode(str)))
            .toList();
      });
    }
  }

  Future<void> _saveRecentSearch(SuggItem item) async {
    if (item.id.startsWith('static_')) return;

    setState(() {
      _recentSearches.removeWhere((x) => x.id == item.id);
      _recentSearches.insert(0, item);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    });

    final prefs = await SharedPreferences.getInstance();
    final recentsJson = _recentSearches
        .map((x) => jsonEncode(x.toJson()))
        .toList();
    await prefs.setStringList('tixoo_recent_searches', recentsJson);
  }

  Future<void> _removeRecentSearch(SuggItem item) async {
    setState(() {
      _recentSearches.removeWhere((s) => s.id == item.id);
    });
    final prefs = await SharedPreferences.getInstance();
    final recentsJson = _recentSearches
        .map((x) => jsonEncode(x.toJson()))
        .toList();
    await prefs.setStringList('tixoo_recent_searches', recentsJson);
    _overlayEntry?.markNeedsBuild();
  }

  Future<void> _fetchInitialData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Events')
          .limit(6)
          .get();
      if (snapshot.docs.isEmpty) return;

      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        return SuggItem(
          doc.id,
          data['name'] ?? 'Event',
          'Event',
          data['poster'] ?? '',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _trendingEvents = events;
          if (_textController.text.isEmpty) {
            _allEvents = _trendingEvents;
            _overlayEntry?.markNeedsBuild();
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching initial events: $e");
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _allEvents = _trendingEvents;
        _isLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      _overlayEntry?.markNeedsBuild();

      List<SuggItem> results = [];
      String term = query.trim();

      try {
        final eventQuery = FirebaseFirestore.instance
            .collection('Events')
            .where('name', isGreaterThanOrEqualTo: term)
            .where('name', isLessThan: '$term\uf8ff')
            .limit(4)
            .get();

        final artistQuery = FirebaseFirestore.instance
            .collection('Artists')
            .where('name', isGreaterThanOrEqualTo: term)
            .where('name', isLessThan: '$term\uf8ff')
            .limit(2)
            .get();

        final promoterQuery = FirebaseFirestore.instance
            .collection('promoters')
            .where('displayName', isGreaterThanOrEqualTo: term)
            .where('displayName', isLessThan: '$term\uf8ff')
            .limit(2)
            .get();

        final snapshots = await Future.wait([
          eventQuery,
          artistQuery,
          promoterQuery,
        ]);

        for (var doc in snapshots[0].docs) {
          final data = doc.data() as Map<String, dynamic>;
          results.add(
            SuggItem(
              doc.id,
              data['name'] ?? 'Event',
              'Event',
              data['poster'] ?? '',
            ),
          );
        }
        for (var doc in snapshots[1].docs) {
          final data = doc.data() as Map<String, dynamic>;
          results.add(
            SuggItem(
              doc.id,
              data['name'] ?? 'Artist',
              'Artist',
              data['image'] ?? '',
            ),
          );
        }
        for (var doc in snapshots[2].docs) {
          final data = doc.data() as Map<String, dynamic>;
          results.add(
            SuggItem(
              doc.id,
              data['displayName'] ?? 'Promoter',
              'Promoter',
              data['photoURL'] ?? '',
            ),
          );
        }
      } catch (e) {
        debugPrint("Search Error: $e");
      }

      if (mounted) {
        setState(() {
          _allEvents = results;
          _isLoading = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  void _onFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_isFocused) {
      _showOverlay();
      if (widget.onTap != null) widget.onTap!();
    } else {
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

  void _fillQuery(String text) {
    _textController.text = text;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _onSuggestionSelected(SuggItem suggestion) {
    _focusNode.unfocus();
    _hideOverlay();

    _saveRecentSearch(suggestion);

    if (suggestion.type == 'Event') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventPage(eventId: suggestion.id)),
      );
    } else if (suggestion.type == 'Artist') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtistDetailPage(artistId: suggestion.id),
        ),
      );
    } else if (suggestion.type == 'Promoter') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PromoterDetailsPage(
            uid: suggestion.id,
            displayName: suggestion.query,
            email: '',
            photoURL: suggestion.image,
          ),
        ),
      );
    }
  }

  OverlayEntry _buildOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // 🚀 COMPLETELY TRANSPARENT BACKDROP: Catches taps without dimming or glitching the UI
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),

            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 60),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _overlayAnim,
                    curve: Curves.easeOut,
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, -0.05),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _overlayAnim,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: Container(
                      // 🚀 FIXED BOUNDS: Prevents layout thrashing when keyboard animates
                      constraints: const BoxConstraints(maxHeight: 340),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isLoading)
                                      const _ShimmerLoadingState()
                                    else if (_textController.text.isNotEmpty &&
                                        _allEvents.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 40,
                                          horizontal: 20,
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.search_off_rounded,
                                                color: Colors.grey.shade300,
                                                size: 40,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                "No matches found for '${_textController.text}'",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else ...[
                                      if (_textController.text.isEmpty &&
                                          _recentSearches.isNotEmpty) ...[
                                        _buildSectionHeader('RECENT SEARCHES'),
                                        ..._recentSearches.map(
                                          (s) => _RecentRow(
                                            item: s,
                                            onTap: () =>
                                                _onSuggestionSelected(s),
                                            onFill: () => _fillQuery(s.query),
                                            onRemove: () =>
                                                _removeRecentSearch(s),
                                          ),
                                        ),
                                        Divider(
                                          height: 1,
                                          color: Colors.grey.shade100,
                                          indent: 16,
                                          endIndent: 16,
                                        ),
                                      ],
                                      if (_allEvents.isNotEmpty) ...[
                                        _buildSectionHeader(
                                          _textController.text.isEmpty
                                              ? 'TRENDING ON TIXOO'
                                              : 'SEARCH RESULTS',
                                        ),
                                        ..._allEvents.map(
                                          (e) => _SuggestionRow(
                                            item: e,
                                            query: _textController.text,
                                            onTap: () =>
                                                _onSuggestionSelected(e),
                                            onFill: () => _fillQuery(e.query),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (_textController.text.isNotEmpty &&
                                _allEvents.isNotEmpty)
                              _buildSeeAllResultsButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSeeAllResultsButton() {
    return InkWell(
      onTap: () {
        _focusNode.unfocus();
        _hideOverlay();
        debugPrint(
          "Navigate to full search results for: ${_textController.text}",
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_rounded, size: 16, color: _primaryGreen),
            const SizedBox(width: 8),
            Text(
              'See all results for "${_textController.text}"',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    _queryNotifier.dispose();
    _overlayAnim.dispose();
    _hintTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showHint = _textController.text.isEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(_focusNode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: _isFocused ? _primaryGreen : Colors.grey.shade200,
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isFocused ? 0.06 : 0.02),
                blurRadius: _isFocused ? 20 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.search_rounded,
                color: _isFocused ? _primaryGreen : Colors.grey.shade400,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (showHint)
                      IgnorePointer(
                        child: Row(
                          children: [
                            Text(
                              'Search for ',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      final offsetAnimation = Tween<Offset>(
                                        begin: const Offset(0, 0.5),
                                        end: Offset.zero,
                                      ).animate(animation);
                                      final fadeAnimation = Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(animation);
                                      return FadeTransition(
                                        opacity: fadeAnimation,
                                        child: SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        ),
                                      );
                                    },
                                child: Align(
                                  key: ValueKey<int>(_currentHintIndex),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _hintWords[_currentHintIndex],
                                    style: GoogleFonts.poppins(
                                      color: _primaryGreen,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        hintText: "",
                      ),
                      cursorColor: _primaryGreen,
                    ),
                  ],
                ),
              ),
              if (_isFocused || _textController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _textController.clear();
                    FocusScope.of(context).requestFocus(_focusNode);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.cancel,
                      color: Colors.grey.shade300,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
    const typeColor = Color(0xFF4EB152);

    IconData getIcon() {
      if (item.type == 'Event') return LucideIcons.calendar;
      if (item.type == 'Artist') return LucideIcons.mic2;
      return LucideIcons.store;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.image.isNotEmpty
                      ? Image.network(
                          item.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(getIcon(), size: 20, color: typeColor),
                        )
                      : Icon(getIcon(), size: 20, color: typeColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HighlightedText(text: item.query, query: query),
                    const SizedBox(height: 2),
                    Text(
                      item.type.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  LucideIcons.arrowUpLeft,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
                onPressed: onFill,
                splashRadius: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final SuggItem item;
  final VoidCallback onTap;
  final VoidCallback onFill;
  final VoidCallback onRemove;

  const _RecentRow({
    required this.item,
    required this.onTap,
    required this.onFill,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.clock,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.query,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  LucideIcons.arrowUpLeft,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
                onPressed: onFill,
                splashRadius: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.x,
                  size: 20,
                  color: Colors.grey.shade300,
                ),
                onPressed: onRemove,
                splashRadius: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
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
    final baseStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: Colors.grey.shade600,
      fontWeight: FontWeight.w400,
    );
    if (query.isEmpty)
      return Text(
        text,
        style: baseStyle.copyWith(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

    final matchIndex = text.toLowerCase().indexOf(query.toLowerCase());
    if (matchIndex == -1)
      return Text(
        text,
        style: baseStyle.copyWith(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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

class _ShimmerLoadingState extends StatefulWidget {
  const _ShimmerLoadingState();
  @override
  State<_ShimmerLoadingState> createState() => _ShimmerLoadingStateState();
}

class _ShimmerLoadingStateState extends State<_ShimmerLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 140,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 80,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
