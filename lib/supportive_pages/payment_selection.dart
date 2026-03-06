// payment_selection_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentSelectionPage extends StatelessWidget {
  const PaymentSelectionPage({super.key});

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[700])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _paymentTile({
    required String title,
    String? subtitle,
    Widget? leading,
    VoidCallback? onTap,
    String? trailingText,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            if (leading != null) leading,
            if (leading != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB7FF1C),
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Select Payment Method",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            _sectionTitle("Recommended"),
            _paymentTile(
              title: "Google Pay UPI",
              leading: Image.asset("assets/images/googlelogo.png", height: 24),
              onTap: () {},
            ),
            _paymentTile(
              title: "Paytm UPI",
              leading: Image.asset("assets/images/googlelogo.png", height: 24),
              onTap: () {},
            ),

            _sectionTitle("Cards"),
            _paymentTile(
              title: "Personal",
              subtitle: "**** 3366 | Secured",
              leading: const Icon(Icons.credit_card, color: Color(0xFFB7FF1C)),
              onTap: () {},
            ),
            _paymentTile(
              title: "Personal",
              subtitle: "**** 3366 | Secured",
              leading: const Icon(Icons.credit_card, color: Color(0xFFB7FF1C)),
              onTap: () {},
            ),
            _paymentTile(
              title: "Add credit or Debit Card",
              trailingText: "Add",
              onTap: () {},
            ),

            _sectionTitle("Pay by any UPI App"),
            _paymentTile(
              title: "Personal",
              subtitle: "**** 3366 | Secured",
              leading: const Icon(Icons.credit_card, color: Color(0xFFB7FF1C)),
              onTap: () {},
            ),
            _paymentTile(
              title: "Personal",
              subtitle: "**** 3366 | Secured",
              leading: const Icon(
                Icons.credit_card,
                color: const Color(0xFFB7FF1C),
              ),
              onTap: () {},
            ),
            _paymentTile(
              title: "Add credit or Debit Card",
              trailingText: "Add",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
