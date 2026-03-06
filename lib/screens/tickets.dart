import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/supportive_pages/tickets_detail.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({Key? key}) : super(key: key);

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _userDocId;

  @override
  void initState() {
    super.initState();
    _getUserDocId();
  }

  Future<void> _getUserDocId() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final querySnapshot = await _firestore
        .collection('Users')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _userDocId = querySnapshot.docs.first.id;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTickets() async {
    if (_userDocId == null) return [];

    final ticketSnapshot = await _firestore
        .collection('Users')
        .doc(_userDocId)
        .collection('tickets')
        .orderBy('purchaseDate', descending: true)
        .get();

    final now = DateTime.now();

    for (var doc in ticketSnapshot.docs) {
      final startTime = (doc['startTime'] as Timestamp?)?.toDate();

      // If ticket is in the past and still active → mark as deactive
      if (startTime != null &&
          startTime.isBefore(DateTime(now.year, now.month, now.day)) &&
          (doc['status'] ?? '').toLowerCase() == 'active') {
        await doc.reference.update({'status': 'deactive'});
      }
    }

    return ticketSnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  String _getTicketStatus(Map<String, dynamic> ticket) {
    final startTime = (ticket['startTime'] as Timestamp?)?.toDate();
    final status = (ticket['status'] ?? '').toLowerCase();

    if (status == 'cancelled') return 'Cancelled';

    if (startTime != null) {
      final now = DateTime.now();
      if (startTime.isBefore(DateTime(now.year, now.month, now.day))) {
        return 'Finished';
      } else if (startTime.year == now.year &&
          startTime.month == now.month &&
          startTime.day == now.day) {
        return 'Ongoing';
      }
    }
    return 'Upcoming';
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final startTime =
        (ticket['startTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final purchaseDate =
        (ticket['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final eventSubCategory = ticket['eventSubCategory'] ?? '';
    final status = _getTicketStatus(ticket);

    // Calculate total tickets
    int totalTickets = 0;
    String ticketType = '';
    if (ticket['selectedTickets'] != null) {
      final selectedTickets = List<Map<String, dynamic>>.from(
        ticket['selectedTickets'],
      );
      for (var t in selectedTickets) {
        totalTickets += (t['quantity'] as int?) ?? 0;
        if (ticketType.isEmpty) {
          ticketType = t['name'] ?? '';
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ordered on text - outside container
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Ordered on: ${DateFormat('dd MMM, yyyy \'at\' h:mm:ss a').format(purchaseDate)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Ticket container
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event poster
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 100,
                        height: 120,
                        color: Colors.grey.shade200,
                        child:
                            ticket['poster'] != null &&
                                ticket['poster'].toString().isNotEmpty
                            ? Image.network(
                                ticket['poster'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade300,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey.shade600,
                                    ),
                                  );
                                },
                              )
                            : Icon(Icons.event, color: Colors.grey.shade600),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Event details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date and category
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat(
                                  'E, dd MMM, h:mm a',
                                ).format(startTime),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (eventSubCategory.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    eventSubCategory,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Event name
                          Text(
                            ticket['eventName'] ?? 'No name',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          // Location
                          Text(
                            ticket['location'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // Ticket info
                          Text(
                            '$totalTickets Tickets: $ticketType',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Gradient Divider with padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black,
                        Colors.grey.shade400,
                        Colors.grey.shade300,
                        Colors.grey.shade200,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // Status badge
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: status == 'Upcoming'
                            ? const LinearGradient(
                                colors: [Color(0xFF2C3E2C), Color(0xFF4A7C4A)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF000000), Color(0xFF414651)],
                              ),
                        borderRadius: BorderRadius.circular(4),
                      ),

                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status == 'Finished'
                            ? 'Hope you enjoyed alot!'
                            : status == 'Cancelled'
                            ? 'We will initiate your refund soon'
                            : status == 'Upcoming'
                            ? 'Will see you soon'
                            : '',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketsList(List<Map<String, dynamic>> tickets) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'You have no more Tickets',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            final ticket = tickets[index];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketDetailsPage(
                  eventId: ticket['eventId'] ?? '',
                  selectedTickets: List<Map<String, dynamic>>.from(
                    ticket['selectedTickets'] ?? [],
                  ),
                  paymentId: ticket['paymentId'] ?? '',
                  totalAmount: (ticket['totalAmount'] ?? 0).toDouble(),
                  existingTicketId: ticket['id'],
                  isExistingTicket: true,
                ),
              ),
            );
          },
          child: _buildTicketCard(tickets[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Tickets',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _userDocId == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB7FF1C)),
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTickets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB7FF1C)),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading tickets',
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }

                final allTickets = snapshot.data ?? [];

                // Categorize tickets
                final eventsTickets = allTickets.where((ticket) {
                  return ticket['eventCategory'] == 'basicEvent';
                }).toList();

                final sportsTickets = allTickets.where((ticket) {
                  return ticket['eventCategory'] == 'Sports';
                }).toList();

                final clubTickets = allTickets.where((ticket) {
                  return ticket['eventCategory'] == 'clubEvents';
                }).toList();

                return DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          labelColor: Colors.green,
                          unselectedLabelColor: Colors.grey.shade600,
                          indicatorColor: Colors.green,
                          indicatorWeight: 3,
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: const [
                            Tab(text: "Events"),
                            Tab(text: "Sports"),
                            Tab(text: "Club Events"),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildTicketsList(eventsTickets),
                            _buildTicketsList(sportsTickets),
                            _buildTicketsList(clubTickets),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
