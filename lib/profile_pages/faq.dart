import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<Map<String, dynamic>> _faqList = [
    {
      "question": "How do I book an event on Tixoo?",
      "answer":
          "To book an event, simply browse or search for your preferred event, select your ticket category, and proceed to checkout. You’ll receive a confirmation instantly via email and in your bookings tab.",
      "isOpen": true,
    },
    {
      "question": "What makes Tixoo different from other ticketing platforms?",
      "answer":
          "Tixoo is India’s first event booking platform with zero convenience fees for users. We’re built for simplicity, speed, and transparency — whether you're attending an open mic or a music festival.",
      "isOpen": false,
    },
    {
      "question": "Can I resell or transfer my tickets?",
      "answer":
          "Currently, Tixoo does not support ticket resale. However, for selected events, you can transfer tickets to another Tixoo user before the event starts. Just head to “My Bookings” and check eligibility.",
      "isOpen": false,
    },
    {
      "question": "I’m a promoter. How do I list my event?",
      "answer":
          "Sign up as a promoter, complete your KYC, and start creating events in minutes. Our dashboard lets you manage ticketing, track performance, and scan entries — all from one place.",
      "isOpen": false,
    },
    {
      "question":
          "What should I do if I don’t receive my ticket or face payment issues?",
      "answer":
          "No worries — reach out to our support team at support@tixoo.in or tap “Help” in the app menu. We’ll respond within 24 hours, usually much faster.",
      "isOpen": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    const gradientColors = [Color(0xFF2C3E2C), Color(0xFF4A7C4A)];
    const bgColor = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0, // removes space between back arrow and title
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            "How can we help you?",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Search FAQs",
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// FAQ List
            Expanded(
              child: ListView.builder(
                itemCount: _faqList.length,
                itemBuilder: (context, index) {
                  final faq = _faqList[index];
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _faqList[index]["isOpen"] =
                                !_faqList[index]["isOpen"];
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: gradientColors,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                  child: Text(
                                    faq["question"],
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Icon(
                                faq["isOpen"]
                                    ? Icons.remove_circle_outline
                                    : Icons.add_circle_outline,
                                color: Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (faq["isOpen"])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            faq["answer"],
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade800,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      Divider(color: Colors.grey.shade300),
                    ],
                  );
                },
              ),
            ),

            /// Chat Button with strong gradient
            Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {},
                  child: Text(
                    'Chat With Us',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
