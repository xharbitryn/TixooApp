import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tixxo/profile_pages/contact.dart';
import 'package:tixxo/screens/tickets.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  String referralCode = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userRef = FirebaseFirestore.instance.collection("Users").doc(uid);
      final doc = await userRef.get();

      if (doc.exists) {
        // If referral code already exists, use it
        if (doc.data()!.containsKey("referralCode")) {
          setState(() {
            referralCode = doc["referralCode"];
          });
          return;
        }

        final name = (doc["name"] ?? "user").toString();
        final email = (doc["email"] ?? "").toString();

        String safeName = name.replaceAll(" ", "").toUpperCase();
        String emailPrefix = email.contains("@")
            ? email.split("@").first.toUpperCase()
            : email.toUpperCase();

        // first 4 chars of name
        String part1 = safeName.length >= 4
            ? safeName.substring(0, 4)
            : safeName;

        // last 4 chars of email prefix
        String part2 = emailPrefix.length >= 4
            ? emailPrefix.substring(emailPrefix.length - 4)
            : emailPrefix;

        String code = (part1 + part2);

        // limit to 8 characters max
        if (code.length > 8) {
          code = code.substring(0, 8);
        }

        // save to Firestore so it remains fixed
        await userRef.update({"referralCode": code});

        setState(() {
          referralCode = code;
        });
      }
    } catch (e) {
      setState(() {
        referralCode = "ERROR";
      });
    }
  }

  Future<void> _handleContactsPermission(BuildContext context) async {
    var status = await Permission.contacts.status;

    if (status.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ContactsPage()),
      );
    } else if (status.isDenied) {
      if (await Permission.contacts.request().isGranted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ContactsPage()),
        );
      }
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enable contacts permission in Settings',
            style: GoogleFonts.poppins(color: Colors.black),
          ),
          backgroundColor: const Color(0xFFB7FF1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Earn by referring",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earn Text
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Earn ₹50",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB7FF1C),
                        ),
                      ),
                      TextSpan(
                        text: "\nfor every friend you refer",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Invite via referral link
              Container(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Handle share referral link
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Invite Via Referral link",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // You get / They get
              Row(
                children: [
                  Expanded(
                    child: _rewardBox(
                      Icons.card_giftcard,
                      "You Get",
                      "10% off upto ₹250 on your next ticket",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _rewardBox(
                      Icons.redeem,
                      "They Get",
                      "10% off upto ₹250 on their first ticket",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Referral code
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      referralCode,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: referralCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Referral code copied!',
                              style: GoogleFonts.poppins(color: Colors.black),
                            ),
                            backgroundColor: const Color(0xFFB7FF1C),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.copy,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // How it works
              _howItWorksSection(),
              const SizedBox(height: 25),

              // Refer history
              Text(
                "Refer History",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 15),

              // Empty state for history
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: Colors.grey[600],
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Find your friends",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Invite friends and start earning rewards",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
              Center(
                child: Text(
                  'Drix Entertainment Pvt. Ltd.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ), // Space for bottom button
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB7FF1C),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () => _handleContactsPermission(context),
            child: Text(
              "Invite from contacts",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rewardBox(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _howItWorksSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How referral works?",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _bulletPoint("Share the referral code or link with friends."),
          _bulletPoint(
            "When they buy their first ticket you both get rewards.",
          ),
          _bulletPoint(
            "Redeem your coupons at checkout to claim your rewards.",
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFB7FF1C),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
