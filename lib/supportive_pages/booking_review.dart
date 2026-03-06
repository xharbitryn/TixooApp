import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

// 🚀 Production backend services
import 'package:tixxo/services/razorpay.dart';
import 'package:tixxo/services/ticket_api_service.dart';
import 'package:tixxo/supportive_pages/tickets_detail.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants from Sandbox
// ─────────────────────────────────────────────────────────────────────────────
class ReviewColors {
  ReviewColors._();
  static const Color lime = Color(0xFFCDDC39);
  static const Color timerBannerBg = Color(0xFFF4FAE8);
  static const Color timerBannerBorder = Color(0xFFD4E89A);
  static const Color timerDot = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF999999);
  static const Color textLime = Color(0xFF8FAF00);
  static const Color dividerDash = Color(0xFFCCCCCC);
  static const Color tixedBadgeBg = Color(0xFFCDDC39);
  static const Color tixedBadgeText = Color(0xFF1A1A1A);
  static const Color couponRowBg = Colors.white;
  static const Color couponRowBorder = Color(0xFFE8E8E8);
  static const Color checkboxBorder = Color(0xFFCCCCCC);
  static const Color bottomBarBg = Colors.white;
  static const Color bookButtonBg = Color(0xFFCDDC39);
  static const Color bookButtonText = Color(0xFF1A1A1A);
}

class ReviewTextStyles {
  ReviewTextStyles._();
  static const TextStyle appBarTotal = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: ReviewColors.textPrimary,
  );
  static const TextStyle timerText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ReviewColors.textPrimary,
  );
  static const TextStyle timerBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: ReviewColors.textPrimary,
  );
  static const TextStyle eventDate = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ReviewColors.textMuted,
  );
  static const TextStyle eventTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: ReviewColors.textPrimary,
    height: 1.35,
  );
  static const TextStyle eventVenue = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ReviewColors.textSecondary,
  );
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: ReviewColors.textPrimary,
  );
  static const TextStyle ticketName = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: ReviewColors.textPrimary,
  );
  static const TextStyle ticketPrice = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ReviewColors.textSecondary,
  );
  static const TextStyle ticketTax = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ReviewColors.textMuted,
  );
  static const TextStyle viewBreakdown = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ReviewColors.textLime,
    decoration: TextDecoration.none,
  );
  static const TextStyle mTicketNote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: ReviewColors.textSecondary,
  );
  static const TextStyle couponRowLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ReviewColors.textPrimary,
  );
  static const TextStyle attendeeName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ReviewColors.textPrimary,
  );
  static const TextStyle attendeeEdit = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ReviewColors.textSecondary,
  );
  static const TextStyle tixedBadge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: ReviewColors.tixedBadgeText,
    letterSpacing: 0.5,
  );
  static const TextStyle attendeePhone = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ReviewColors.textPrimary,
  );
  static const TextStyle attendeeDetail = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: ReviewColors.textSecondary,
  );
  static const TextStyle infoNote = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ReviewColors.textSecondary,
    height: 1.5,
  );
  static const TextStyle tixooCash = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ReviewColors.textPrimary,
  );
  static const TextStyle seeBalance = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ReviewColors.textLime,
  );
  static const TextStyle basePriceLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ReviewColors.textSecondary,
  );
  static const TextStyle basePriceValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: ReviewColors.textPrimary,
  );
  static const TextStyle bookButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ReviewColors.bookButtonText,
  );
}

class ReviewSpacing {
  ReviewSpacing._();
  static const double pagePadding = 16.0;
  static const double sectionGap = 20.0;
  static const double cardPadding = 16.0;
  static const double itemGap = 12.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Argument Model (Updated with Production Backend Requirements)
// ─────────────────────────────────────────────────────────────────────────────
class BookingTicketRow {
  final String name;
  final String quantity;
  final double price;
  final String currency;
  final bool hasTax;
  final VoidCallback? onViewBreakdown;

  const BookingTicketRow({
    required this.name,
    required this.quantity,
    required this.price,
    this.currency = '₹',
    this.hasTax = true,
    this.onViewBreakdown,
  });

  String get displayName => '$quantity $name';
  String get displayPrice => '$currency${price.toStringAsFixed(0)}';
}

class BookingReviewArgs {
  // Production ID routing
  final String eventId;
  final String? occurrenceId;
  final Map<String, int> selectedQuantities;
  final List<Map<String, dynamic>> rawTicketsData;

  // UI Strings
  final String attendeeName;
  final String attendeePhone;
  final String attendeeEmail;
  final String attendeeState;
  final String eventTitle;
  final String eventDate;
  final String eventVenue;
  final String eventImageUrl;
  final List<BookingTicketRow> tickets;
  final double basePrice;
  final double totalPrice;
  final double tixooCashBalance;
  final String currency;

  const BookingReviewArgs({
    required this.eventId,
    this.occurrenceId,
    required this.selectedQuantities,
    required this.rawTicketsData,
    required this.attendeeName,
    required this.attendeePhone,
    required this.attendeeEmail,
    this.attendeeState = '',
    required this.eventTitle,
    required this.eventDate,
    required this.eventVenue,
    this.eventImageUrl = '',
    required this.tickets,
    required this.basePrice,
    required this.totalPrice,
    this.tixooCashBalance = 699,
    this.currency = '₹',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class BookingReviewScreen extends StatefulWidget {
  final BookingReviewArgs args;
  const BookingReviewScreen({super.key, required this.args});

  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  BookingReviewArgs get _args => widget.args;

  RazorpayService? _razorpayService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService(
      onPaymentSuccess: _handlePaymentSuccess,
      onPaymentError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _razorpayService?.dispose();
    super.dispose();
  }

  // 🚀 PRODUCTION API & RAZORPAY INTEGRATION 🚀
  void _onBookTickets() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Create Booking in custom backend
      await TicketApiService.createBooking(
        eventId: _args.eventId,
        selectedTickets: _args.selectedQuantities,
        occurrenceId: _args.occurrenceId,
      );

      // 2. Open Razorpay Interface
      _razorpayService?.startPayment(amount: _args.totalPrice);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initiate payment. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailsPage(
          eventId: _args.eventId,
          selectedTickets: _args.rawTicketsData,
          paymentId: response.paymentId ?? '',
          totalAmount: _args.totalPrice,
        ),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment Failed: ${response.message}"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _onTimerExpired() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
          'Your booking session has expired. Please start again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to Ticket Selection
            },
            child: const Text('OK', style: TextStyle(color: ReviewColors.lime)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReviewColors.background,
      appBar: AppBar(
        backgroundColor: ReviewColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: ReviewColors.textPrimary,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
        titleSpacing: 0,
        title: Text(
          'Total: ${_args.currency}${_args.totalPrice.toStringAsFixed(0)}',
          style: ReviewTextStyles.appBarTotal,
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              BookingTimerBanner(
                initialSeconds: 600,
                onExpired: _onTimerExpired,
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: ReviewSpacing.sectionGap),
                    BookingEventSummaryCard(
                      imageUrl: _args.eventImageUrl,
                      date: _args.eventDate,
                      title: _args.eventTitle,
                      venue: _args.eventVenue,
                    ),
                    const SizedBox(height: ReviewSpacing.sectionGap),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ReviewSpacing.pagePadding,
                      ),
                      child: BookingDashedDivider(),
                    ),
                    const SizedBox(height: ReviewSpacing.sectionGap),
                    BookingTicketDetailsSection(tickets: _args.tickets),
                    const SizedBox(height: ReviewSpacing.sectionGap),
                    const BookingSaveSection(),
                    const SizedBox(height: ReviewSpacing.sectionGap),
                    BookingAttendeeSection(
                      name: _args.attendeeName,
                      phone: _args.attendeePhone,
                      email: _args.attendeeEmail,
                      state: _args.attendeeState.isEmpty
                          ? 'Not Provided'
                          : _args.attendeeState,
                      onEdit: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              BookingTixooCashRow(
                cashAmount: _args.tixooCashBalance,
                currency: _args.currency,
              ),
              BookingBottomBar(
                basePrice: _args.basePrice,
                currency: _args.currency,
                onBookTickets: _onBookTickets,
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: ReviewColors.lime),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Embedded Sandbox Widgets
// ─────────────────────────────────────────────────────────────────────────────

class BookingTimerBanner extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onExpired;

  const BookingTimerBanner({
    super.key,
    this.initialSeconds = 600,
    this.onExpired,
  });

  @override
  State<BookingTimerBanner> createState() => _BookingTimerBannerState();
}

class _BookingTimerBannerState extends State<BookingTimerBanner>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _countdown;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          _countdown?.cancel();
          widget.onExpired?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} mins';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ReviewColors.timerBannerBg,
        border: Border.all(color: ReviewColors.timerBannerBorder, width: 1),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Opacity(
              opacity: _pulseAnim.value,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: ReviewColors.timerDot,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: ReviewTextStyles.timerText,
                children: [
                  const TextSpan(text: 'Complete your booking in '),
                  TextSpan(
                    text: _formattedTime,
                    style: ReviewTextStyles.timerBold,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingEventSummaryCard extends StatelessWidget {
  final String imageUrl, date, title, venue;

  const BookingEventSummaryCard({
    super.key,
    required this.imageUrl,
    required this.date,
    required this.title,
    required this.venue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ReviewColors.cardBackground,
      padding: const EdgeInsets.all(ReviewSpacing.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 90,
              height: 90,
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(date, style: ReviewTextStyles.eventDate),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: ReviewTextStyles.eventTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  venue,
                  style: ReviewTextStyles.eventVenue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7D32).withOpacity(0.8),
            const Color(0xFF1B5E20),
          ],
        ),
      ),
      child: const Icon(Icons.event, color: Colors.white54, size: 28),
    );
  }
}

class BookingTicketDetailsSection extends StatelessWidget {
  final List<BookingTicketRow> tickets;
  const BookingTicketDetailsSection({super.key, required this.tickets});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ReviewColors.cardBackground,
      padding: const EdgeInsets.all(ReviewSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ticket Details', style: ReviewTextStyles.sectionHeader),
          const SizedBox(height: 14),
          const BookingDashedDivider(),
          ...tickets.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      t.displayName,
                      style: ReviewTextStyles.ticketName,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(t.displayPrice, style: ReviewTextStyles.ticketPrice),
                      if (t.hasTax) ...[
                        const SizedBox(height: 2),
                        const Text(
                          '+ Applied Taxes',
                          style: ReviewTextStyles.ticketTax,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const BookingDashedDivider(),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_outlined,
                  size: 18,
                  color: ReviewColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'This is an M-Ticket, please bring it for entry',
                  style: ReviewTextStyles.mTicketNote,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BookingSaveSection extends StatelessWidget {
  const BookingSaveSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ReviewColors.cardBackground,
      padding: const EdgeInsets.all(ReviewSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Save On Tickets', style: ReviewTextStyles.sectionHeader),
          const SizedBox(height: 14),
          const BookingDashedDivider(),
          const SizedBox(height: 12),
          _SavingsRow(icon: Icons.local_offer_outlined, label: 'Apply Coupon'),
          const SizedBox(height: 10),
          _SavingsRow(
            icon: Icons.card_giftcard_outlined,
            label: 'Payment Offers',
          ),
        ],
      ),
    );
  }
}

class _SavingsRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SavingsRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: ReviewColors.couponRowBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ReviewColors.couponRowBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: ReviewColors.textPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: ReviewTextStyles.couponRowLabel),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: ReviewColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class BookingAttendeeSection extends StatelessWidget {
  final String name, phone, email, state;
  final VoidCallback? onEdit;

  const BookingAttendeeSection({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.state,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ReviewColors.cardBackground,
      padding: const EdgeInsets.all(ReviewSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? 'Guest User' : name,
                  style: ReviewTextStyles.attendeeName,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: const Text('Edit', style: ReviewTextStyles.attendeeEdit),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ReviewColors.tixedBadgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('TIXED', style: ReviewTextStyles.tixedBadge),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const BookingDashedDivider(),
          const SizedBox(height: 14),
          Text(phone, style: ReviewTextStyles.attendeePhone),
          const SizedBox(height: 4),
          Text(email, style: ReviewTextStyles.attendeeDetail),
          const SizedBox(height: 2),
          Text(state, style: ReviewTextStyles.attendeeDetail),
          const SizedBox(height: 14),
          const BookingDashedDivider(),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: ReviewColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'This information mentioned will be used for generating the invoice and sending you the M-Ticket',
                  style: ReviewTextStyles.infoNote,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BookingTixooCashRow extends StatefulWidget {
  final double cashAmount;
  final String currency;

  const BookingTixooCashRow({
    super.key,
    required this.cashAmount,
    this.currency = '₹',
  });

  @override
  State<BookingTixooCashRow> createState() => _BookingTixooCashRowState();
}

class _BookingTixooCashRowState extends State<BookingTixooCashRow> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ReviewColors.cardBackground,
      padding: const EdgeInsets.symmetric(
        horizontal: ReviewSpacing.cardPadding,
        vertical: 14,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isChecked = !_isChecked),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _isChecked ? ReviewColors.lime : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _isChecked
                      ? ReviewColors.lime
                      : ReviewColors.checkboxBorder,
                  width: 1.5,
                ),
              ),
              child: _isChecked
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: ReviewTextStyles.tixooCash,
                children: [
                  const TextSpan(text: 'Tixoo Cash: '),
                  TextSpan(
                    text:
                        '${widget.currency}${widget.cashAmount.toStringAsFixed(0)}',
                    style: ReviewTextStyles.tixooCash.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingBottomBar extends StatelessWidget {
  final double basePrice;
  final String currency;
  final VoidCallback onBookTickets;

  const BookingBottomBar({
    super.key,
    required this.basePrice,
    required this.onBookTickets,
    this.currency = '₹',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: ReviewSpacing.cardPadding,
        right: ReviewSpacing.cardPadding,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: ReviewColors.bottomBarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
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
                const Text(
                  'Total Payable',
                  style: ReviewTextStyles.basePriceLabel,
                ),
                const SizedBox(height: 2),
                Text(
                  '$currency${basePrice.toStringAsFixed(0)}',
                  style: ReviewTextStyles.basePriceValue,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBookTickets,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF245126), Color(0xFF4EB152)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Proceed to Pay',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

class BookingDashedDivider extends StatelessWidget {
  const BookingDashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: ReviewColors.dividerDash),
              ),
            );
          }),
        );
      },
    );
  }
}
