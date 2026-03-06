import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Privacy Policy",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: "At Tixoo, your privacy is important to us",
              content:
                  "This Privacy Policy outlines how we collect, use, disclose, and protect your personal information when you use our platform, including our website, mobile application, and associated services (collectively referred to as the “Platform”).\n\n"
                  "By using Tixoo, you agree to the practices described in this policy.",
            ),
            _divider(),
            _buildSection(
              title: "1. Information We Collect",
              content:
                  "1.1 Information You Provide\n"
                  "• Personal Information: Name, email, mobile number, location, gender, age, and other profile-related fields.\n"
                  "• Payment Details: While we do not store credit/debit card information directly, we collect transaction data processed through third-party gateways.\n"
                  "• Promoter Data: Company name, GST details, bank details, and uploaded KYC documents.\n\n"
                  "1.2 Information We Collect Automatically\n"
                  "• IP address, device type, OS version, and browser type.\n"
                  "• Cookies and tracking data (e.g., session ID, referring URLs).\n"
                  "• Event browsing behavior and booking patterns.\n"
                  "• Usage logs and time-stamped activity data.",
            ),
            _divider(),
            _buildSection(
              title: "2. How We Use Your Information",
              content:
                  "Tixoo uses your data to:\n"
                  "• Create and manage user and promoter accounts.\n"
                  "• Process bookings and payments securely.\n"
                  "• Deliver booking confirmations and reminders.\n"
                  "• Improve recommendations and event discovery.\n"
                  "• Monitor platform performance and security.\n"
                  "• Prevent fraud, spam, or unauthorized use.\n"
                  "• Contact you with promotional and service-related updates (you can opt out).",
            ),
            _divider(),
            _buildSection(
              title: "3. Sharing Your Information",
              content:
                  "We do not sell your data. However, we may share limited information under these conditions:\n"
                  "• With Promoters: If you book an event, your name and contact details may be shared with the event organizer to facilitate access and communication.\n"
                  "• With Service Providers: For payment processing, hosting, customer support, analytics, etc.\n"
                  "• With Authorities: To comply with legal obligations or respond to valid requests from law enforcement.",
            ),
            _divider(),
            _buildSection(
              title: "4. Data Storage & Security",
              content:
                  "• All personal data is stored securely on encrypted servers.\n"
                  "• Sensitive fields (like passwords) are hashed using industry-standard algorithms.\n"
                  "• Access to data is limited to authorized personnel only.\n"
                  "• Despite all precautions, no system is entirely immune to breaches. In case of a data breach, affected users will be notified under applicable laws.",
            ),
            _divider(),
            _buildSection(
              title: "5. Your Rights & Choices",
              content:
                  "You have the right to:\n"
                  "• Access or update your personal information anytime via your profile.\n"
                  "• Delete your account by contacting support (data may remain in backups).\n"
                  "• Opt out of marketing emails and non-critical push notifications.\n"
                  "• Request data export (as per India’s Digital Personal Data Protection Act).",
            ),
            _divider(),
            _buildSection(
              title: "6. Cookies & Tracking",
              content:
                  "We use cookies and similar technologies to:\n"
                  "• Keep you logged in during sessions.\n"
                  "• Analyze traffic and user interactions.\n"
                  "• Improve features and user experience.\n\n"
                  "You can modify your cookie preferences in your browser settings. Disabling cookies may limit certain functionalities of the Platform.",
            ),
            _divider(),
            _buildSection(
              title: "7. Third-Party Links",
              content:
                  "Our platform may contain links to third-party sites (e.g., social links on promoter profiles). We are not responsible for their privacy practices and encourage you to read their policies.",
            ),
            _divider(),
            _buildSection(
              title: "8. Data Retention",
              content:
                  "• Booking history and transaction data may be retained for up to 7 years as per financial compliance laws.\n"
                  "• Profile and usage data are retained as long as your account is active.\n"
                  "• Reviews and event contributions may remain visible even after account deletion, unless manually requested.",
            ),
            _divider(),
            _buildSection(
              title: "9. Children’s Privacy",
              content:
                  "Tixoo is not intended for use by individuals under the age of 13. We do not knowingly collect personal data from minors. If we learn that we have inadvertently collected data from a child, we will take steps to delete it promptly.",
            ),
            _divider(),
            _buildSection(
              title: "10. Changes to This Policy",
              content:
                  "We may update this Privacy Policy periodically. When we do, we will revise the “Effective Date” and may notify you via email or app notification if the changes are significant.",
            ),
            _divider(),
            _buildSection(
              title: "11. Contact Us",
              content:
                  "For any questions, feedback, or privacy-related concerns, please reach out to:\n"
                  "Tixoo Privacy Officer\n"
                  "📧 privacy@tixoo.in\n"
                  "📍 Gomti Nagar, Lucknow – 226010, Uttar Pradesh",
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Drix Entertainment Pvt. Ltd.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }
}
