import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tixxo/auth/authgate.dart';
import 'package:tixxo/auth/authservice.dart';
import 'package:tixxo/supportive_pages/promoter_detail.dart';

class PromoPage extends StatelessWidget {
  const PromoPage({super.key});

  void _logout(BuildContext context) async {
    try {
      await AuthService().signOut();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        title: Center(
          child: Text(
            'Promoters',
            style: GoogleFonts.poppins(color: Colors.black87),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promoters')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          Widget content;

          if (snapshot.connectionState == ConnectionState.waiting) {
            content = const Center(
              child: CircularProgressIndicator(color: Colors.black87),
            );
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            content = const Center(
              child: Text(
                'No promoters found.',
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
            );
          } else {
            final promoters = snapshot.data!.docs;
            content = ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: promoters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = promoters[index];
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final uid = doc.id;
                final displayName = data['displayName'] ?? 'Unknown';
                final email = data['email'] ?? 'No email';
                final photoURL = data['photoURL'] ?? '';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PromoterDetailsPage(
                          uid: uid,
                          displayName: displayName,
                          email: email,
                          photoURL: photoURL,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: photoURL.isNotEmpty
                            ? NetworkImage(photoURL)
                            : null,
                        child: photoURL.isEmpty
                            ? Icon(
                                Icons.person_rounded,
                                color: Colors.grey.shade600,
                                size: 26,
                              )
                            : null,
                      ),
                      title: Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          email,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return Column(
            children: [
              Expanded(child: content),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Drix Entertainment Pvt. Ltd.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
