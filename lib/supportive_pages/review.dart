import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllReviewsPage extends StatelessWidget {
  final String promoterUid;
  final String promoterName;
  final double averageRating;
  final int totalReviews;

  const AllReviewsPage({
    super.key,
    required this.promoterUid,
    required this.promoterName,
    required this.averageRating,
    required this.totalReviews,
  });

  String _getTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "All Reviews",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promoters')
            .doc(promoterUid)
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No reviews yet",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            );
          }

          final allReviews = snapshot.data!.docs;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Rating Summary Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 28,
                            color: index < averageRating.round()
                                ? Colors.amber
                                : Colors.grey.shade300,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$totalReviews Reviews",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Reviews List
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allReviews.length,
                    separatorBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black,
                              Colors.grey,
                              Colors.grey,
                              Colors.white,
                            ],
                            stops: [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final reviewData =
                          allReviews[index].data() as Map<String, dynamic>;
                      final timestamp = reviewData['timestamp'] as Timestamp?;
                      final date = timestamp?.toDate();
                      final userId = reviewData['userId'] ?? '';
                      final comment = reviewData['comment'] ?? '';
                      final rating = reviewData['rating'] ?? 0;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(userId)
                            .get(),
                        builder: (context, userSnapshot) {
                          String userName = 'Anonymous';
                          String userProfileUrl = '';

                          if (userSnapshot.hasData &&
                              userSnapshot.data!.exists) {
                            final userData =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                            userName =
                                userData?['name'] ??
                                userData?['displayName'] ??
                                'Anonymous';
                            userProfileUrl = userData?['profileUrl'] ?? '';
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage: userProfileUrl.isNotEmpty
                                        ? NetworkImage(userProfileUrl)
                                        : null,
                                    child: userProfileUrl.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.grey,
                                            size: 22,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      userName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (starIndex) {
                                      return Icon(
                                        Icons.star,
                                        size: 16,
                                        color: starIndex < rating
                                            ? Colors.amber
                                            : Colors.grey.shade300,
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  if (date != null)
                                    Text(
                                      _getTimeAgo(date),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                comment,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
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
