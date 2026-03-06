import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/auth/login.dart';

// 🚀 Imports
import '../services/ticket_api_service.dart';
import 'booking_review.dart';

class _AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color border = Color(0xFFE0E0E0);
}

class TicketSelectionPage extends StatefulWidget {
  final String eventId;
  const TicketSelectionPage({super.key, required this.eventId});

  @override
  State<TicketSelectionPage> createState() => _TicketSelectionPageState();
}

class _TicketSelectionPageState extends State<TicketSelectionPage> {
  bool loading = true;
  String eventTitle = "Choose your Tickets";
  String eventImageUrl = "";
  String eventVenue = "Venue TBA";

  List<dynamic> occurrences = [];
  String? selectedOccurrenceId;
  List<Map<String, dynamic>> combinedTickets = [];
  Map<String, int> quantities = {};

  static const LinearGradient _primaryGradient = LinearGradient(
    colors: [Color(0xFF245126), Color(0xFF4EB152)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  int get totalTickets => quantities.values.fold(0, (sum, qty) => sum + qty);

  double get totalPrice {
    double total = 0;
    for (var ticket in combinedTickets) {
      final String catId = ticket['categoryId'];
      final int qty = quantities[catId] ?? 0;
      final num price = ticket['price'] ?? 0;
      total += (qty * price);
    }
    return total;
  }

  Future<void> _fetchInitialData() async {
    try {
      // Fetch Event Metadata for the Review Screen
      final eventDoc = await FirebaseFirestore.instance
          .collection('Events')
          .doc(widget.eventId)
          .get();
      if (eventDoc.exists) {
        eventTitle = eventDoc.data()?['name'] ?? 'Event';
        eventImageUrl = eventDoc.data()?['poster'] ?? '';
        eventVenue =
            eventDoc.data()?['venueInfo']?['name'] ??
            eventDoc.data()?['location'] ??
            'Venue';
      }

      final fetchedOccurrences = await TicketApiService.getOccurrences(
        widget.eventId,
      );

      if (mounted) {
        setState(() {
          occurrences = fetchedOccurrences;
          if (occurrences.isNotEmpty) {
            selectedOccurrenceId = occurrences.first['id'];
          }
        });
      }

      await _fetchTicketsForSelection();
    } catch (e) {
      debugPrint("Error fetching initial data: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _fetchTicketsForSelection() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final results = await Future.wait([
        TicketApiService.getTicketCategories(widget.eventId),
        TicketApiService.getTicketAvailability(
          widget.eventId,
          occurrenceId: selectedOccurrenceId,
        ),
      ]);

      final categoriesData = results[0] as List<dynamic>;
      final availabilityData = results[1] as Map<String, dynamic>;
      final availabilityList =
          availabilityData['categories'] as List<dynamic>? ?? [];

      List<Map<String, dynamic>> unifiedList = [];

      for (var category in categoriesData) {
        final catId = category['id'];
        final availInfo = availabilityList.firstWhere(
          (a) => a['categoryId'] == catId,
          orElse: () => {'available': 0, 'total': 0},
        );

        unifiedList.add({
          'categoryId': catId,
          'name': category['name'],
          'price': category['price'],
          'available': availInfo['available'],
          'total': availInfo['total'],
        });

        quantities.putIfAbsent(catId, () => 0);
      }

      if (mounted) {
        setState(() {
          combinedTickets = unifiedList;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching tickets: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  void _onOccurrenceSelected(String occurrenceId) {
    if (selectedOccurrenceId == occurrenceId) return;
    setState(() {
      selectedOccurrenceId = occurrenceId;
      quantities.clear();
    });
    _fetchTicketsForSelection();
  }

  Future<void> _handleQuantityChange(
    String categoryId,
    int newQuantity,
    int currentQuantity,
  ) async {
    setState(() => quantities[categoryId] = newQuantity);

    try {
      final success = await TicketApiService.reserveTickets(
        eventId: widget.eventId,
        categoryId: categoryId,
        quantity: newQuantity,
        occurrenceId: selectedOccurrenceId,
      );

      if (!success) {
        setState(() => quantities[categoryId] = currentQuantity);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unable to reserve tickets.")),
          );
      }
    } catch (e) {
      setState(() => quantities[categoryId] = currentQuantity);
    }
  }

  // 🚀 NAVIGATE TO REVIEW SCREEN INSTEAD OF OPENING RAZORPAY
  void _handleCheckout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      bool? goToLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "Login Required",
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            "Login to book tickets.",
            style: GoogleFonts.poppins(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("No", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                "Yes",
                style: GoogleFonts.poppins(color: const Color(0xFF2E7D32)),
              ),
            ),
          ],
        ),
      );

      if (goToLogin == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage(onTap: () {})),
          (route) => false,
        );
      }
      return;
    }

    // 1. Gather filtered quantities
    final filteredQuantities = Map<String, int>.fromEntries(
      quantities.entries.where((e) => e.value > 0),
    );

    // 2. Gather Row Details for UI
    final List<BookingTicketRow> selectedRows = combinedTickets
        .where((t) => (quantities[t['categoryId']] ?? 0) > 0)
        .map(
          (t) => BookingTicketRow(
            name: t['name'],
            quantity: quantities[t['categoryId']]!.toString(),
            price: (t['price'] * quantities[t['categoryId']]!).toDouble(),
          ),
        )
        .toList();

    // 3. Raw Data for Success Details Page
    final List<Map<String, dynamic>> rawSelection = combinedTickets
        .where((t) => (quantities[t['categoryId']] ?? 0) > 0)
        .map(
          (t) => {
            'name': t['name'],
            'quantity': quantities[t['categoryId']],
            'price': t['price'],
            'totalPrice': t['price'] * quantities[t['categoryId']]!,
          },
        )
        .toList();

    // 4. Construct arguments (🚀 FIX: Added basePrice!)
    final args = BookingReviewArgs(
      eventId: widget.eventId,
      occurrenceId: selectedOccurrenceId,
      selectedQuantities: filteredQuantities,
      rawTicketsData: rawSelection,
      attendeeName: user.displayName ?? '',
      attendeeEmail: user.email ?? '',
      attendeePhone: user.phoneNumber ?? '',
      eventTitle: eventTitle,
      eventDate:
          'Selected Slot', // You can map selectedOccurrenceId to a readable date if required
      eventVenue: eventVenue,
      eventImageUrl: eventImageUrl,
      tickets: selectedRows,
      basePrice: totalPrice, // 🚀 Required parameter added here
      totalPrice: totalPrice,
    );

    // 5. Route to Review
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingReviewScreen(args: args)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: AppBar(
        backgroundColor: _AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          eventTitle,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _AppColors.textPrimary,
          ),
        ),
      ),
      body: loading && combinedTickets.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF2E7D32)),
              ),
            )
          : Column(
              children: [
                if (occurrences.isNotEmpty)
                  _OccurrenceSelector(
                    occurrences: occurrences,
                    selectedId: selectedOccurrenceId,
                    onSelect: _onOccurrenceSelected,
                  ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: combinedTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = combinedTickets[index];
                      final catId = ticket['categoryId'];
                      final qty = quantities[catId] ?? 0;
                      final availableCount = ticket['available'] ?? 0;

                      return _TicketCard(
                        name: ticket['name'],
                        price: ticket['price'].toString(),
                        quantity: qty,
                        availableCount: availableCount,
                        gradient: _primaryGradient,
                        showDivider: index < combinedTickets.length - 1,
                        onAdd: () => _handleQuantityChange(catId, 1, 0),
                        onIncrement: () {
                          if (availableCount > qty)
                            _handleQuantityChange(catId, qty + 1, qty);
                        },
                        onDecrement: () {
                          if (qty > 0)
                            _handleQuantityChange(catId, qty - 1, qty);
                        },
                      );
                    },
                  ),
                ),

                if (totalTickets > 0)
                  _BottomBar(
                    totalTickets: totalTickets,
                    totalPrice: totalPrice,
                    gradient: _primaryGradient,
                    onCheckout: _handleCheckout, // Routes to Review!
                  ),
              ],
            ),
    );
  }
}

// --- WIDGETS ---
class _OccurrenceSelector extends StatelessWidget {
  final List<dynamic> occurrences;
  final String? selectedId;
  final Function(String) onSelect;
  const _OccurrenceSelector({
    required this.occurrences,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _AppColors.border, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: occurrences.length,
        itemBuilder: (context, index) {
          final occ = occurrences[index];
          final isSelected = occ['id'] == selectedId;
          final dateString = occ['date'] ?? 'Slot ${index + 1}';

          return GestureDetector(
            onTap: () => onSelect(occ['id']),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2E7D32)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : _AppColors.border,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                dateString,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : _AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final String name, price;
  final int quantity, availableCount;
  final LinearGradient gradient;
  final VoidCallback onAdd, onIncrement, onDecrement;
  final bool showDivider;

  const _TicketCard({
    required this.name,
    required this.price,
    required this.quantity,
    required this.availableCount,
    required this.gradient,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: _AppColors.border, width: 1),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$name | Single",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹$price',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Available: $availableCount",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            quantity == 0
                ? (availableCount == 0
                      ? Container(
                          width: 88,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Sold Out',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onAdd,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 88,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Add',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ))
                : Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onDecrement,
                          child: Container(
                            width: 40,
                            height: 44,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.remove,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 44,
                          alignment: Alignment.center,
                          child: Text(
                            quantity.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onIncrement,
                          child: Container(
                            width: 40,
                            height: 44,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_box_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
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

class _BottomBar extends StatelessWidget {
  final int totalTickets;
  final double totalPrice;
  final LinearGradient gradient;
  final VoidCallback onCheckout;

  const _BottomBar({
    required this.totalTickets,
    required this.totalPrice,
    required this.gradient,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: _AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalTickets Ticket${totalTickets > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _AppColors.textSecondary,
                  ),
                ),
                Text(
                  '₹${totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCheckout,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Checkout',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
