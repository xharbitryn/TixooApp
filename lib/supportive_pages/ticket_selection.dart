// ticket_selection_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/widgets/buttons/neopop_button/neopop_button.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:tixxo/auth/login.dart';
import 'package:tixxo/services/razorpay.dart';
import 'package:tixxo/supportive_pages/payment_selection.dart';
import 'package:tixxo/supportive_pages/tickets_detail.dart';

class TicketSelectionPage extends StatefulWidget {
  final String eventId;

  const TicketSelectionPage({super.key, required this.eventId});

  @override
  State<TicketSelectionPage> createState() => _TicketSelectionPageState();
}

class _TicketSelectionPageState extends State<TicketSelectionPage> {
  Map<int, int> quantities = {};
  List<Map<String, dynamic>> tickets = [];
  Map<int, List<String>> reservedTickets =
      {}; // Track reserved tickets per category
  int totalSeat = 0;
  bool loading = true;
  String? currentUserId;

  RazorpayService? _razorpayService;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    fetchTickets();

    // Initialize Razorpay Service
    _razorpayService = RazorpayService(
      onPaymentSuccess: _handlePaymentSuccess,
      onPaymentError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    // Release any reserved tickets when leaving the page
    _releaseReservedTickets();
    _razorpayService?.dispose();
    super.dispose();
  }

  int get totalTickets => quantities.values.fold(0, (sum, qty) => sum + qty);

  double get totalPrice {
    double total = 0;
    for (var entry in quantities.entries) {
      total += entry.value * (tickets[entry.key]['price'] ?? 0);
    }
    return total;
  }

  void fetchTickets() async {
    final doc = await FirebaseFirestore.instance
        .collection('Events')
        .doc(widget.eventId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        tickets = List<Map<String, dynamic>>.from(
          data['ticketCategories'] ?? [],
        );
        totalSeat = data['totalSeat'] ?? 0;
        quantities = {for (int i = 0; i < tickets.length; i++) i: 0};
        reservedTickets = {for (int i = 0; i < tickets.length; i++) i: []};
        loading = false;
      });
    }
  }

  // Get available tickets for a category (not booked and not reserved by others)
  List<String> _getAvailableTickets(int categoryIndex) {
    if (categoryIndex >= tickets.length) return [];

    List<String> allTickets = List<String>.from(
      tickets[categoryIndex]['tickets'] ?? [],
    );
    List<String> bookedTickets = List<String>.from(
      tickets[categoryIndex]['bookedTickets'] ?? [],
    );

    return allTickets
        .where((ticket) => !bookedTickets.contains(ticket))
        .toList();
  }

  // Reserve tickets for the current user
  Future<bool> _reserveTickets(int categoryIndex, int quantity) async {
    try {
      final eventRef = FirebaseFirestore.instance
          .collection('Events')
          .doc(widget.eventId);

      return await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) return false;

        final data = eventDoc.data()!;
        List<Map<String, dynamic>> currentTickets =
            List<Map<String, dynamic>>.from(data['ticketCategories'] ?? []);

        if (categoryIndex >= currentTickets.length) return false;

        List<String> allTickets = List<String>.from(
          currentTickets[categoryIndex]['tickets'] ?? [],
        );
        List<String> bookedTickets = List<String>.from(
          currentTickets[categoryIndex]['bookedTickets'] ?? [],
        );
        Map<String, dynamic> reservations = Map<String, dynamic>.from(
          currentTickets[categoryIndex]['reservations'] ?? {},
        );

        // Remove expired reservations (older than 10 minutes)
        final now = DateTime.now().millisecondsSinceEpoch;
        reservations.removeWhere((ticketId, reservationData) {
          final reservedAt = reservationData['timestamp'] ?? 0;
          return now - reservedAt > 10 * 60 * 1000; // 10 minutes
        });

        // Get current user's reservations for this category
        List<String> userReservedTickets = [];
        reservations.forEach((ticketId, reservationData) {
          if (reservationData['userId'] == currentUserId) {
            userReservedTickets.add(ticketId);
          }
        });

        // If user already has the required quantity, return true
        if (userReservedTickets.length == quantity) {
          setState(() {
            reservedTickets[categoryIndex] = userReservedTickets;
          });
          return true;
        }

        // If user needs more tickets
        if (userReservedTickets.length < quantity) {
          // Find available tickets (not booked and not reserved by others)
          List<String> reservedByOthers = [];
          reservations.forEach((ticketId, reservationData) {
            if (reservationData['userId'] != currentUserId) {
              reservedByOthers.add(ticketId);
            }
          });

          List<String> availableTickets = allTickets
              .where(
                (ticket) =>
                    !bookedTickets.contains(ticket) &&
                    !reservedByOthers.contains(ticket),
              )
              .toList();

          int additionalTicketsNeeded = quantity - userReservedTickets.length;
          List<String> newTicketsToReserve = availableTickets
              .where((ticket) => !userReservedTickets.contains(ticket))
              .take(additionalTicketsNeeded)
              .toList();

          if (newTicketsToReserve.length < additionalTicketsNeeded) {
            return false;
          }

          // Reserve the additional tickets
          for (String ticketId in newTicketsToReserve) {
            reservations[ticketId] = {
              'userId': currentUserId,
              'timestamp': now,
            };
          }

          userReservedTickets.addAll(newTicketsToReserve);
        }
        // If user has more tickets than needed, remove excess
        else if (userReservedTickets.length > quantity) {
          int ticketsToRemove = userReservedTickets.length - quantity;
          List<String> ticketsToUnreserve = userReservedTickets.reversed
              .take(ticketsToRemove)
              .toList();

          for (String ticketId in ticketsToUnreserve) {
            reservations.remove(ticketId);
            userReservedTickets.remove(ticketId);
          }
        }

        // Update the category with new reservations
        currentTickets[categoryIndex]['reservations'] = reservations;

        // Update the document
        transaction.update(eventRef, {'ticketCategories': currentTickets});

        // Update local state
        setState(() {
          reservedTickets[categoryIndex] = userReservedTickets;
        });

        return true;
      });
    } catch (e) {
      print('Error reserving tickets: $e');
      return false;
    }
  }

  // Release reserved tickets
  Future<void> _releaseReservedTickets() async {
    if (currentUserId == null) return;

    try {
      final eventRef = FirebaseFirestore.instance
          .collection('Events')
          .doc(widget.eventId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) return;

        final data = eventDoc.data()!;
        List<Map<String, dynamic>> currentTickets =
            List<Map<String, dynamic>>.from(data['ticketCategories'] ?? []);

        bool hasChanges = false;

        for (int i = 0; i < currentTickets.length; i++) {
          Map<String, dynamic> reservations = Map<String, dynamic>.from(
            currentTickets[i]['reservations'] ?? {},
          );

          // Remove reservations by current user
          reservations.removeWhere(
            (ticketId, reservationData) =>
                reservationData['userId'] == currentUserId,
          );

          if (reservations.length !=
              (currentTickets[i]['reservations'] ?? {}).length) {
            currentTickets[i]['reservations'] = reservations;
            hasChanges = true;
          }
        }

        if (hasChanges) {
          transaction.update(eventRef, {'ticketCategories': currentTickets});
        }
      });
    } catch (e) {
      print('Error releasing reserved tickets: $e');
    }
  }

  // Book reserved tickets permanently
  Future<bool> _bookReservedTickets() async {
    if (currentUserId == null) return false;

    try {
      final eventRef = FirebaseFirestore.instance
          .collection('Events')
          .doc(widget.eventId);

      return await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) return false;

        final data = eventDoc.data()!;
        List<Map<String, dynamic>> currentTickets =
            List<Map<String, dynamic>>.from(data['ticketCategories'] ?? []);

        for (int categoryIndex in reservedTickets.keys) {
          if (categoryIndex >= currentTickets.length) continue;

          List<String> bookedTickets = List<String>.from(
            currentTickets[categoryIndex]['bookedTickets'] ?? [],
          );
          Map<String, dynamic> reservations = Map<String, dynamic>.from(
            currentTickets[categoryIndex]['reservations'] ?? {},
          );

          // Move reserved tickets to booked
          for (String ticketId in reservedTickets[categoryIndex] ?? []) {
            if (reservations[ticketId]?['userId'] == currentUserId) {
              bookedTickets.add(ticketId);
              reservations.remove(ticketId);
            }
          }

          currentTickets[categoryIndex]['bookedTickets'] = bookedTickets;
          currentTickets[categoryIndex]['reservations'] = reservations;

          // Update available quantity
          int totalTickets =
              (currentTickets[categoryIndex]['tickets'] as List).length;
          currentTickets[categoryIndex]['quantity'] =
              totalTickets - bookedTickets.length;
        }

        transaction.update(eventRef, {'ticketCategories': currentTickets});
        return true;
      });
    } catch (e) {
      print('Error booking tickets: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> _getSelectedTickets() {
    List<Map<String, dynamic>> selectedTickets = [];
    for (var entry in quantities.entries) {
      if (entry.value > 0) {
        selectedTickets.add({
          'name': tickets[entry.key]['name'] ?? '',
          'quantity': entry.value,
          'price': tickets[entry.key]['price'] ?? 0,
          'totalPrice': entry.value * (tickets[entry.key]['price'] ?? 0),
          'ticketIds':
              reservedTickets[entry.key] ?? [], // Include specific ticket IDs
        });
      }
    }
    return selectedTickets;
  }

  // Razorpay Handlers
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Book the reserved tickets permanently
    bool booked = await _bookReservedTickets();

    if (booked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment Successful: ${response.paymentId}")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDetailsPage(
            eventId: widget.eventId,
            selectedTickets: _getSelectedTickets(),
            paymentId: response.paymentId ?? '',
            totalAmount: totalPrice,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error booking tickets. Please try again."),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet Selected: ${response.walletName}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFB7FF1C)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Choose your Tickets",

          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // Tickets List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length + 1,
              separatorBuilder: (context, index) {
                if (index == 0) return const SizedBox(height: 16);
                return Container(
                  height: 1,
                  color: Colors.grey[800],
                  margin: const EdgeInsets.symmetric(vertical: 12),
                );
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Total Seats: $totalSeat",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final ticketIndex = index - 1;
                final ticket = tickets[ticketIndex];
                final qty = quantities[ticketIndex] ?? 0;
                final availableTickets = _getAvailableTickets(ticketIndex);
                final reservedForUser = reservedTickets[ticketIndex] ?? [];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      "${ticket['name']} | Single",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "₹${ticket['price']}",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Available: ${availableTickets.length} tickets",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        if (reservedForUser.isNotEmpty)
                          Text(
                            "Reserved: ${reservedForUser.join(', ')}",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFB7FF1C),
                              fontSize: 11,
                            ),
                          ),
                        const SizedBox(height: 4),
                      ],
                    ),
                    trailing: qty == 0
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: availableTickets.isEmpty
                                  ? Colors.grey
                                  : const Color(0xFFB7FF1C),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: availableTickets.isEmpty
                                ? null
                                : () async {
                                    bool reserved = await _reserveTickets(
                                      ticketIndex,
                                      1,
                                    );
                                    if (reserved) {
                                      setState(() {
                                        quantities[ticketIndex] = 1;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Unable to reserve ticket. Please try again.",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: Text(
                              availableTickets.isEmpty ? "Sold Out" : "Add",
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  if (quantities[ticketIndex]! > 0) {
                                    setState(() {
                                      quantities[ticketIndex] =
                                          quantities[ticketIndex]! - 1;
                                    });

                                    if (quantities[ticketIndex] == 0) {
                                      await _releaseReservedTickets();
                                      setState(() {
                                        reservedTickets[ticketIndex] = [];
                                      });
                                    } else {
                                      // Update reservations to match new quantity
                                      await _reserveTickets(
                                        ticketIndex,
                                        quantities[ticketIndex]!,
                                      );
                                    }
                                  }
                                },
                              ),
                              Text(
                                "$qty",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ), 
                              IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  if (availableTickets.length > qty) {
                                    bool reserved = await _reserveTickets(
                                      ticketIndex,
                                      qty + 1,
                                    );
                                    if (reserved) {
                                      setState(() {
                                        quantities[ticketIndex] =
                                            quantities[ticketIndex]! + 1;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Unable to reserve additional ticket.",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),

          // Checkout Bar
          if (totalTickets > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.white, width: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$totalTickets Ticket${totalTickets > 1 ? 's' : ''}",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "₹${totalPrice.toStringAsFixed(0)}",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFB7FF1C),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  NeoPopButton(
                    color: const Color(0xFFB7FF1C),
                    animationDuration: const Duration(milliseconds: 500),
                    onTapUp: () async {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user == null) {
                        bool? goToLogin = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.black,
                            title: Text(
                              "Login Required",
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            content: Text(
                              "Login to book tickets. Want to navigate to login page?",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  "No",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  "Yes",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFB7FF1C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (goToLogin == true) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginPage(onTap: () {}),
                            ),
                            (route) => false,
                          );
                        }
                      } else {
                        _razorpayService?.startPayment(amount: totalPrice);
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => const PaymentSelectionPage(),
                        //   ),
                        // );
                      }
                    },
                    onTapDown: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text(
                        'CheckOut',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
