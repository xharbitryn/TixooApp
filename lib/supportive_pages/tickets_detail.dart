import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tixxo/screens/navbar.dart';
import 'dart:math';
import 'dart:convert';
import 'package:tixxo/screens/tickets.dart';
import 'package:tixxo/sections/offers.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketDetailsPage extends StatefulWidget {
  final String eventId;
  final List<Map<String, dynamic>> selectedTickets;
  final String paymentId;
  final double totalAmount;
  final String? existingTicketId;
  final bool isExistingTicket;

  const TicketDetailsPage({
    super.key,
    required this.eventId,
    required this.selectedTickets,
    required this.paymentId,
    required this.totalAmount,
    this.existingTicketId,
    this.isExistingTicket = false,
  });

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  late ConfettiController _confettiController;
  List<String> ticketIds = [];
  bool isCreatingTicket = true;
  late ScrollController _scrollController;
  bool showCompactTicket = false;
  String? qrData;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    if (widget.isExistingTicket) {
      setState(() {
        ticketIds = [widget.existingTicketId!];
        isCreatingTicket = false;
      });
      _generateQRData();
    } else {
      _createTicketsAndShowConfetti();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !showCompactTicket) {
      setState(() {
        showCompactTicket = true;
      });
    } else if (_scrollController.offset <= 200 && showCompactTicket) {
      setState(() {
        showCompactTicket = false;
      });
    }
  }

  void _generateQRData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && ticketIds.isNotEmpty) {
      final qrDataMap = {
        'ticketId': ticketIds.first,
        'userId': user.uid,
        'eventId': widget.eventId,
        'paymentId': widget.paymentId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      setState(() {
        qrData = jsonEncode(qrDataMap);
      });
    }
  }

  Future<void> _createTicketsAndShowConfetti() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final eventDoc = await FirebaseFirestore.instance
            .collection('Events')
            .doc(widget.eventId)
            .get();
        final eventData = eventDoc.data() as Map<String, dynamic>;

        final ticketRef = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('tickets')
            .add({
              'eventId': widget.eventId,
              'eventCategory': eventData['eventCategory'],
              'eventName': eventData['name'] ?? 'Event Name',
              'selectedTickets': widget.selectedTickets,
              'totalAmount': widget.totalAmount,
              'location': eventData['location'] ?? 'Location TBA',
              'startTime': eventData['startTime'],
              'poster': eventData['poster'],
              'purchaseDate': FieldValue.serverTimestamp(),
              'status': 'active',
              'userId': user.uid,
              'paymentId': widget.paymentId,
            });

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(ticketRef.id)
            .set({
              'ticketId': ticketRef.id,
              'eventId': widget.eventId,
              'eventName': eventData['name'] ?? 'Event Name',
              'selectedTickets': widget.selectedTickets,
              'totalAmount': widget.totalAmount,
              'location': eventData['location'] ?? 'Location TBA',
              'startTime': eventData['startTime'],
              'poster': eventData['poster'],
              'purchaseDate': FieldValue.serverTimestamp(),
              'status': 'active',
              'userId': user.uid,
              'userEmail': user.email,
              'paymentId': widget.paymentId,
            });
        setState(() {
          ticketIds = [ticketRef.id];
          isCreatingTicket = false;
        });

        _generateQRData();
        _confettiController.play();
      }
    } catch (e) {
      print('Error creating tickets: $e');
      setState(() {
        isCreatingTicket = false;
      });
    }
  }

  String get totalTicketsCount {
    int total = 0;
    for (var ticket in widget.selectedTickets) {
      total += ticket['quantity'] as int;
    }
    return total.toString();
  }

  Widget _buildTicketShape({required Widget child}) {
    return CustomPaint(
      painter: TicketShapePainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildQRCode({double size = 80}) {
    if (qrData == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(size > 50 ? 12 : 8),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size > 50 ? 4 : 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(size > 50 ? 4 : 8),
      ),
      child: QrImageView(
        data: qrData!,
        version: QrVersions.auto,
        backgroundColor: Colors.transparent,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.grey,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCompactTicket(Map<String, dynamic> data) {
    String formattedDateTime = '';
    if (data['startTime'] != null) {
      if (data['startTime'] is Timestamp) {
        DateTime dateTime = (data['startTime'] as Timestamp).toDate();
        formattedDateTime = DateFormat(
          'MMM dd, yyyy • hh:mm a',
        ).format(dateTime);
      } else if (data['startTime'] is String) {
        formattedDateTime = data['startTime'];
      }
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          showCompactTicket = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildTicketShape(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB7FF1C).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'Tap to expand',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFB7FF1C),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.expand_more,
                          color: Color(0xFFB7FF1C),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                data['name'] ?? 'Event Name',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFB7FF1C),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data['location'] ?? 'Location TBA',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_outlined,
                    color: Color(0xFFB7FF1C),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      formattedDateTime.isNotEmpty
                          ? formattedDateTime
                          : 'Date & Time TBA',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BOOKING ID',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFB7FF1C),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ticketIds.isNotEmpty
                            ? '#${ticketIds.first.substring(0, 8).toUpperCase()}'
                            : '#LOADING...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  _buildQRCode(size: 100),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullTicket(Map<String, dynamic> data) {
    String formattedDateTime = '';
    if (data['startTime'] != null) {
      if (data['startTime'] is Timestamp) {
        DateTime dateTime = (data['startTime'] as Timestamp).toDate();
        formattedDateTime = DateFormat(
          'MMM dd, yyyy • hh:mm a',
        ).format(dateTime);
      } else if (data['startTime'] is String) {
        formattedDateTime = data['startTime'];
      }
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          showCompactTicket = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildTicketShape(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB7FF1C).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tap to collapse',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFB7FF1C),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.expand_less,
                          color: Color(0xFFB7FF1C),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data['poster'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(data['poster']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                data['name'] ?? 'Event Name',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.selectedTickets
                    .map(
                      (ticket) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB7FF1C).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFB7FF1C).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${ticket['name'].toString().toUpperCase()} TICKETS',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFB7FF1C),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB7FF1C),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'x${ticket['quantity']}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (ticket['ticketIds'] != null &&
                                (ticket['ticketIds'] as List).isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    List<String>.from(ticket['ticketIds'] ?? [])
                                        .map(
                                          (ticketId) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              ticketId,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ] else
                              Text(
                                'Booking ID: #${ticketIds.isNotEmpty ? ticketIds.first.substring(0, 8).toUpperCase() : 'LOADING...'}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${ticket['price']} each • Total: ₹${ticket['totalPrice']}',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFB7FF1C),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data['location'] ?? 'Location TBA',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_outlined,
                    color: Color(0xFFB7FF1C),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formattedDateTime.isNotEmpty
                          ? formattedDateTime
                          : 'Date & Time TBA',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 1,
                width: double.infinity,
                child: CustomPaint(painter: DottedLinePainter()),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BOOKING ID',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFB7FF1C),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ticketIds.isNotEmpty
                              ? '#${ticketIds.first.substring(0, 8).toUpperCase()}'
                              : '#LOADING...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalTicketsCount Ticket${int.parse(totalTicketsCount) > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildQRCode(size: 100),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB7FF1C).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFB7FF1C), width: 1),
                ),
                child: Text(
                  'ACTIVE TICKET',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB7FF1C),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Events')
                .doc(widget.eventId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || isCreatingTicket) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFFB7FF1C)),
                  ),
                );
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              return SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              widget.isExistingTicket
                                  ? 'Ticket Details'
                                  : 'Your Tickets',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: showCompactTicket
                                  ? _buildCompactTicket(data)
                                  : _buildFullTicket(data),
                            ),
                            const SizedBox(height: 20),
                            OffersSection(),
                            SizedBox(height: 30),
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFB7FF1C,
                                  ).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Purchase Summary',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFB7FF1C),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...widget.selectedTickets
                                      .map(
                                        (ticket) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${ticket['name']} x ${ticket['quantity']}',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '₹${ticket['totalPrice'].toStringAsFixed(0)}',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  const Divider(color: Colors.white24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Amount',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFB7FF1C),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '₹${widget.totalAmount.toStringAsFixed(0)}',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFB7FF1C),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Payment ID: ${widget.paymentId}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              height: 50,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (widget.isExistingTicket) {
                                    Navigator.pop(context);
                                  } else {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      // 🚀 FIX: Changed to MainNavBar
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MainNavBar(initialIndex: 2),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB7FF1C),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  widget.isExistingTicket
                                      ? 'BACK TO TICKETS'
                                      : 'GO TO TICKETS',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (!widget.isExistingTicket)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xFFB7FF1C),
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.red,
                  Colors.yellow,
                ],
                numberOfParticles: 20,
                emissionFrequency: 0.05,
                gravity: 1,
              ),
            ),
        ],
      ),
    );
  }
}

class TicketShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    final borderPath = Path();

    const double radius = 12.0;
    const double notchRadius = 15.0;
    const double notchOffset = 60.0;

    path.moveTo(radius, 0);
    borderPath.moveTo(radius, 0);

    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width, radius),
      radius: const Radius.circular(radius),
    );

    borderPath.lineTo(size.width - radius, 0);
    borderPath.arcToPoint(
      Offset(size.width, radius),
      radius: const Radius.circular(radius),
    );

    path.lineTo(size.width, notchOffset);
    path.arcToPoint(
      Offset(size.width, notchOffset + notchRadius * 2),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height - radius);

    borderPath.lineTo(size.width, notchOffset);
    borderPath.arcToPoint(
      Offset(size.width, notchOffset + notchRadius * 2),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    borderPath.lineTo(size.width, size.height - radius);

    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: const Radius.circular(radius),
    );
    borderPath.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: const Radius.circular(radius),
    );

    path.lineTo(radius, size.height);
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: const Radius.circular(radius),
    );

    borderPath.lineTo(radius, size.height);
    borderPath.arcToPoint(
      Offset(0, size.height - radius),
      radius: const Radius.circular(radius),
    );

    path.lineTo(0, notchOffset + notchRadius * 2);
    path.arcToPoint(
      Offset(0, notchOffset),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, radius);

    borderPath.lineTo(0, notchOffset + notchRadius * 2);
    borderPath.arcToPoint(
      Offset(0, notchOffset),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    borderPath.lineTo(0, radius);

    path.arcToPoint(Offset(radius, 0), radius: const Radius.circular(radius));
    borderPath.arcToPoint(
      Offset(radius, 0),
      radius: const Radius.circular(radius),
    );

    path.close();
    borderPath.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      final endX = (startX + dashWidth > size.width)
          ? size.width
          : startX + dashWidth;
      canvas.drawLine(Offset(startX, 0), Offset(endX, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
