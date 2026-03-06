import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/neopop.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tixxo/profile_pages/drawer2.dart';
import 'package:tixxo/services/razorpay.dart';

void showPlusMembershipDrawer(BuildContext context) {
  // Initialize RazorpayService
  final razorpayService = RazorpayService(
    onPaymentSuccess: (response) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment Successful: ${response.paymentId}")),
      );
      // ✅ Here you can also update Firestore: mark membership as active
    },
    onPaymentError: (response) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment Failed: ${response.message}")),
      );
    },
    onExternalWallet: (response) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("External Wallet: ${response.walletName}")),
      );
    },
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Card content
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB7FF1C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.star, color: Colors.black),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "tixoo PLUS",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "3 Month Membership",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "Valid till 25 June 2025",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹69",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildBenefitItem("10% off on every ticket"),
                  _buildBenefitItem("Extra discounts on Festivals"),
                  const SizedBox(height: 12),

                  // Billing address fetch & display
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox();
                      }

                      final data =
                          snapshot.data?.data() as Map<String, dynamic>?;
                      final billingAddress = data?['billing_address'];

                      final hasAddress =
                          billingAddress != null &&
                          billingAddress['address'] != null &&
                          billingAddress['address']
                              .toString()
                              .trim()
                              .isNotEmpty;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Add a billing address",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: hasAddress
                                    ? Text(
                                        billingAddress['address'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : Text(
                                        "No billing address yet",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white54,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB7FF1C),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(0),
                                  ),
                                ),
                                onPressed: () {
                                  showBillingAddressDrawer(context);
                                },
                                child: Text(
                                  hasAddress ? "Change" : "Add",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Base Price + Pay Now in same row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Base Price: ₹69",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              NeoPopButton(
                                color: hasAddress
                                    ? const Color(0xFFB7FF1C)
                                    : Colors.grey,
                                onTapUp: hasAddress
                                    ? () {
                                        razorpayService.startPayment(
                                          amount: 69,
                                          name: "Tixxo Plus",
                                          description:
                                              "3 Month Membership Purchase",
                                          email:
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.email ??
                                              "test@example.com",
                                          contact:
                                              "9876543210", // you can fetch user's phone
                                        );
                                      }
                                    : null,
                                onTapDown: hasAddress ? () {} : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    "Pay Now",
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  ).whenComplete(() {
    // Clear Razorpay listeners when drawer closes
    razorpayService.dispose();
  });
}

Widget _buildBenefitItem(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
        ),
      ],
    ),
  );
}
