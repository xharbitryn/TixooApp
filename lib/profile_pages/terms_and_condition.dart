import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> sections = [
      {
        "title": "1. Overview",
        "content":
            "1.1 What We Do\nTixoo connects users (“you” or “attendees”) with event organizers (“promoters”) and allows discovery, booking, and check-in for events, all without additional booking fees. Promoters can manage ticketing, analytics, and check-ins via a comprehensive dashboard.\n\n"
            "1.2 Changes to Terms\nTixoo reserves the right to amend these Terms at any time. We will notify you of significant changes, but it is your responsibility to review them regularly. Continued use of the Platform signifies your acceptance of the updated Terms.",
      },
      {
        "title": "2. Account Access & Responsibilities",
        "content":
            "You must create an account to access booking or event creation features.\n\n"
            "You agree to provide accurate, complete, and current information during sign-up.\n\n"
            "You are responsible for maintaining the confidentiality of your account credentials.\n\n"
            "Tixoo reserves the right to suspend or terminate accounts that violate our policies or appear fraudulent.",
      },
      {
        "title": "3. Event Booking & Tickets",
        "content":
            "3.1 Ticket Booking\nAll tickets are subject to availability and confirmation post-payment.\nTicket prices are determined by promoters and may vary across event types.\nNo convenience fee is charged to the user unless explicitly stated (e.g., premium services or upgrades).\n\n"
            "3.2 Refunds & Cancellations\nTixoo does not guarantee refunds unless the promoter initiates or allows them.\nIn case of event cancellation, Tixoo will assist in communicating and processing eligible refunds.\nRefund timelines depend on the payment gateway and the promoter’s policy.\n\n"
            "3.3 Transfers & Modifications\nBooked tickets are generally non-transferable unless permitted by the promoter.\nAttendees are responsible for ensuring accurate booking details before final submission.",
      },
      {
        "title": "4. Promoter Responsibilities",
        "content":
            "If you are a promoter using Tixoo to list events:\n• You must hold the necessary rights, licenses, and permissions to host your events.\n• Event listings must be honest, clear, and not misleading.\n• You are solely responsible for the execution and safety of your event.\n• Revenue disbursal follows the subscription and payout schedule defined in your promoter account.\nTixoo reserves the right to delist, flag, or suspend any event that violates public policy or legal norms.",
      },
      {
        "title": "5. Subscription & Payment",
        "content":
            "5.1 For Promoters\nTixoo operates on a subscription model for promoters, with varying plans based on event count, features, and support level.\nNo hidden commissions or platform fees are deducted unless part of an advanced plan.\n\n"
            "5.2 For Attendees\nTicket prices include all taxes and platform usage unless stated otherwise.\nPayments are securely processed through certified third-party gateways. Tixoo does not store card or banking data.",
      },
      {
        "title": "6. Content Guidelines",
        "content":
            "You agree not to:\n• Upload, share, or distribute content that is offensive, false, illegal, or harmful.\n• Impersonate other individuals or organizations.\n• Violate copyrights, trademarks, or any proprietary rights.\nTixoo reserves the right to moderate content (event titles, images, reviews) and remove anything deemed inappropriate without prior notice.",
      },
      {
        "title": "7. Platform Availability",
        "content":
            "Tixoo is provided on an “as-is” and “as-available” basis. While we strive for uninterrupted service, we do not guarantee the platform will always be available, error-free, or fully secure.",
      },
      {
        "title": "8. Limitation of Liability",
        "content":
            "Tixoo is a facilitator and does not assume liability for:\n• Event cancellations or promoter misconduct\n• Injuries, damages, or losses at events\n• Technical failures or payment gateway errors\nYou agree to hold Tixoo and its team harmless from any claims arising out of your use of the platform.",
      },
      {
        "title": "9. Termination",
        "content":
            "Tixoo may suspend or terminate access to your account without prior notice if you violate these Terms or misuse the platform in any way.",
      },
      {
        "title": "10. Governing Law",
        "content":
            "These Terms shall be governed by and interpreted under the laws of India. Any disputes will be subject to the exclusive jurisdiction of the courts located in Lucknow, Uttar Pradesh.",
      },
      {
        "title": "11. Contact Us",
        "content":
            "For queries, concerns, or support, please reach out to:\nTixoo Support\n📧 support@tixoo.in\n📍 Gomti Nagar, Lucknow – 226010, Uttar Pradesh",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Terms & Conditions",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
      ),
      backgroundColor: Colors.black,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: sections.length + 1, // extra item for footer
        separatorBuilder: (context, index) =>
            Divider(color: Colors.white.withOpacity(0.2)),
        itemBuilder: (context, index) {
          if (index < sections.length) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sections[index]["title"]!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sections[index]["content"]!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            );
          } else {
            // Footer
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Drix Entertainment Pvt. Ltd.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
