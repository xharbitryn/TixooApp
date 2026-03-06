import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ✅ IMPORTING YOUR PAGES
import 'package:tixxo/supportive_pages/event_details.dart';
import 'package:tixxo/supportive_pages/artist_detail.dart';
import 'package:tixxo/supportive_pages/promoter_detail.dart';

enum SearchType { home, location }

class SearchBarSection extends StatefulWidget {
  final List<String> hintWords;
  final SearchType searchType;
  final Function(String)? onLocationSelected;

  const SearchBarSection({
    super.key,
    required this.hintWords,
    this.searchType = SearchType.home,
    this.onLocationSelected,
  });

  @override
  State<SearchBarSection> createState() => _SearchBarSectionState();
}

class _SearchBarSectionState extends State<SearchBarSection> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  bool _isFocused = false;
  int _currentHintIndex = 0;
  Timer? _hintTimer;
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_isFocused && _controller.text.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });

    _controller.addListener(() {
      setState(() {});
      _onSearchChanged(_controller.text);
    });

    // Cycle Hint Text (Flipping Animation)
    _hintTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % widget.hintWords.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _debounceTimer?.cancel();
    _removeOverlay();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 🔍 SEARCH LOGIC
  // ───────────────────────────────────────────────────────────────────────────
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      setState(() => _isLoading = true);
      if (_overlayEntry == null)
        _showOverlay();
      else
        _overlayEntry!.markNeedsBuild();

      List<Map<String, dynamic>> results = [];
      String rawInput = query.trim();

      if (widget.searchType == SearchType.location) {
        // 📍 LOCATION MODE (Photon API)
        try {
          final url = Uri.parse(
            'https://photon.komoot.io/api/?q=$rawInput&limit=5&lang=en',
          );
          final response = await http.get(url);

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final features = data['features'] as List;

            results = features.map((f) {
              final props = f['properties'];
              String name = props['name'] ?? '';
              String? city = props['city'];
              String? state = props['state'];
              String? country = props['country'];

              List<String> parts = [name];
              if (city != null && city != name) parts.add(city);
              if (state != null) parts.add(state);
              if (country != null) parts.add(country);

              return {
                'type': 'Location',
                'id': name,
                'name': parts.join(', '),
                'simpleName': name,
                'image': '',
                'isVerified': true,
              };
            }).toList();
          }
        } catch (e) {
          debugPrint("API Error: $e");
        }

        if (rawInput.length >= 3 &&
            !results.any(
              (r) => r['simpleName'].toLowerCase() == rawInput.toLowerCase(),
            )) {
          String displayTerm =
              rawInput[0].toUpperCase() + rawInput.substring(1);
          results.add({
            'type': 'Location',
            'id': displayTerm,
            'name': "Use '$displayTerm'",
            'simpleName': displayTerm,
            'image': '',
            'isCustom': true,
          });
        }
      } else {
        // 🏠 HOME MODE: SCATTER-SHOT
        Set<String> searchTerms = {};
        searchTerms.add(rawInput);
        searchTerms.add(rawInput.toLowerCase());
        searchTerms.add(rawInput.toUpperCase());

        if (rawInput.isNotEmpty) {
          searchTerms.add(
            rawInput[0].toUpperCase() + rawInput.substring(1).toLowerCase(),
          );
        }

        try {
          List<Future<QuerySnapshot>> queries = [];

          for (String term in searchTerms) {
            queries.add(
              FirebaseFirestore.instance
                  .collection('Events')
                  .where('name', isGreaterThanOrEqualTo: term)
                  .where('name', isLessThan: '$term\uf8ff')
                  .limit(3)
                  .get(),
            );

            queries.add(
              FirebaseFirestore.instance
                  .collection('Events')
                  .where('eventName', isGreaterThanOrEqualTo: term)
                  .where('eventName', isLessThan: '$term\uf8ff')
                  .limit(3)
                  .get(),
            );

            queries.add(
              FirebaseFirestore.instance
                  .collection('Artists')
                  .where('name', isGreaterThanOrEqualTo: term)
                  .where('name', isLessThan: '$term\uf8ff')
                  .limit(2)
                  .get(),
            );

            queries.add(
              FirebaseFirestore.instance
                  .collection('promoters')
                  .where('displayName', isGreaterThanOrEqualTo: term)
                  .where('displayName', isLessThan: '$term\uf8ff')
                  .limit(2)
                  .get(),
            );
          }

          final List<QuerySnapshot> snapshots = await Future.wait(queries);
          final Set<String> addedIds = {};

          for (var snapshot in snapshots) {
            for (var doc in snapshot.docs) {
              if (addedIds.contains(doc.id)) continue;
              addedIds.add(doc.id);

              final data = doc.data() as Map<String, dynamic>;
              String path = doc.reference.parent.id;

              if (path == 'Events') {
                results.add({
                  'type': 'Event',
                  'id': doc.id,
                  'name': data['name'] ?? data['eventName'] ?? 'Event',
                  'image': data['poster'] ?? '',
                });
              } else if (path == 'Artists') {
                results.add({
                  'type': 'Artist',
                  'id': doc.id,
                  'name': data['name'] ?? 'Artist',
                  'image': data['image'] ?? data['poster'] ?? '',
                });
              } else if (path == 'promoters') {
                results.add({
                  'type': 'Promoter',
                  'id': doc.id,
                  'name':
                      data['displayName'] ??
                      data['publicdata']?['name'] ??
                      'Promoter',
                  'image': data['photoURL'] ?? '',
                });
              }
            }
          }
        } catch (e) {
          debugPrint("Search Error: $e");
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 🚀 NAVIGATION LOGIC
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _navigateToDetail(Map<String, dynamic> item) async {
    _focusNode.unfocus();
    _removeOverlay();

    if (widget.searchType == SearchType.location) {
      if (widget.onLocationSelected != null) {
        widget.onLocationSelected!(item['simpleName']);
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E5128)),
      ),
    );

    try {
      if (item['type'] == 'Event') {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventPage(eventId: item['id'])),
        );
      } else if (item['type'] == 'Artist') {
        final doc = await FirebaseFirestore.instance
            .collection('Artists')
            .doc(item['id'])
            .get();
        if (mounted) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArtistDetailPage(artistDoc: doc)),
          );
        }
      } else if (item['type'] == 'Promoter') {
        final doc = await FirebaseFirestore.instance
            .collection('promoters')
            .doc(item['id'])
            .get();
        if (mounted) {
          Navigator.pop(context);
          final data = doc.data() as Map<String, dynamic>?;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PromoterDetailsPage(
                uid: doc.id,
                displayName:
                    data?['displayName'] ??
                    data?['publicdata']?['name'] ??
                    'Unknown',
                email: data?['email'] ?? data?['publicdata']?['email'] ?? '',
                photoURL:
                    data?['photoURL'] ?? data?['publicdata']?['photoURL'] ?? '',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Navigation Error: $e");
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 🖥️ OVERLAY UI (Eye-Catchy & Visually Appealing)
  // ───────────────────────────────────────────────────────────────────────────
  void _showOverlay() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 12), // Added more spacing
          child: Material(
            elevation: 8, // Increased elevation for depth
            borderRadius: BorderRadius.circular(24), // Match SearchBar radius
            color: Colors.white,
            shadowColor: Colors.black.withOpacity(
              0.15,
            ), // Softer, premium shadow
            child: Container(
              constraints: const BoxConstraints(maxHeight: 340),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 80,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF1E5128),
                        ),
                      ),
                    )
                  : _searchResults.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "No matches found",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                      ), // Inner padding
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: Color(0xFFF5F5F5),
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        return _buildSuggestionTile(_searchResults[index]);
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // 🔹 Eye-Catchy Suggestion Tile
  Widget _buildSuggestionTile(Map<String, dynamic> item) {
    final String text = item['name'];
    final String query = _controller.text;
    int matchIndex = text.toLowerCase().indexOf(query.toLowerCase());

    bool isCustomLocation = item['isCustom'] == true;

    // Custom Icon Logic
    IconData getIcon() {
      if (isCustomLocation) return Icons.add_location_alt_rounded;
      if (item['type'] == 'Location') return Icons.location_on_rounded;
      if (item['type'] == 'Event') return Icons.calendar_month_rounded;
      if (item['type'] == 'Artist') return Icons.mic_external_on_rounded;
      return Icons.storefront_rounded;
    }

    return InkWell(
      // Using InkWell for splash effect
      onTap: () => _navigateToDetail(item),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 🎨 Icon Container (Visually Appealing)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (item['isCustom'] == true)
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(12), // Soft square
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item['image'] != ''
                    ? Image.network(
                        item['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(getIcon(), size: 20, color: Colors.grey[600]),
                      )
                    : Icon(
                        getIcon(),
                        color: (item['isCustom'] == true)
                            ? const Color(0xFF1E5128)
                            : Colors.grey[600],
                        size: 20,
                      ),
              ),
            ),

            const SizedBox(width: 14),

            // 📝 Text Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Highlighting Logic
                  matchIndex == -1
                      ? Text(
                          text,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: text.substring(0, matchIndex),
                                style: const TextStyle(color: Colors.grey),
                              ),
                              TextSpan(
                                text: text.substring(
                                  matchIndex,
                                  matchIndex + query.length,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: text.substring(matchIndex + query.length),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                  // Secondary Subtitle (Location or Type)
                  if (item['type'] == 'Location' && !isCustomLocation)
                    Text(
                      "City in ${item['name'].split(', ').last}",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),

            // 🏷️ Styled Type Badge (Pill)
            if (!isCustomLocation && item['type'] != 'Location')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item['type'].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

            // ↗ Arrow
            const SizedBox(width: 12),
            if (!isCustomLocation)
              GestureDetector(
                onTap: () {
                  _controller.text = item['name'];
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length),
                  );
                },
                child: Icon(
                  Icons.north_west_rounded,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showHint = _controller.text.isEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(_focusNode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _isFocused ? const Color(0xFF1E5128) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[400], size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // ✅ FLIPPING ANIMATION
                    if (showHint)
                      IgnorePointer(
                        child: Row(
                          children: [
                            Text(
                              'Search for ',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      final offsetAnimation = Tween<Offset>(
                                        begin: const Offset(0, 1),
                                        end: Offset.zero,
                                      ).animate(animation);
                                      return ClipRect(
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
                                    widget.hintWords[_currentHintIndex],
                                    style: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        _removeOverlay();
                        FocusScope.of(context).unfocus();
                        if (widget.searchType == SearchType.location &&
                            widget.onLocationSelected != null) {
                          widget.onLocationSelected!(value);
                        }
                      },
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        hintText: "",
                      ),
                      cursorColor: const Color(0xFF1E5128),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
