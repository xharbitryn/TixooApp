import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tixxo/supportive_pages/artist_detail.dart';
import 'package:tixxo/widgets/divider.dart';

class ArtistsSection extends StatefulWidget {
  final String? eventCategory;
  final String? eventSubCategory;

  const ArtistsSection({super.key, this.eventCategory, this.eventSubCategory});

  @override
  State<ArtistsSection> createState() => _ArtistsSectionState();
}

class _ArtistsSectionState extends State<ArtistsSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// Title Section
        GradientDivider(title: "Artists On Tixxo"),
        const SizedBox(height: 15),
        SizedBox(
          height: 150, // reduced height
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Artists')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No artists found',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                );
              }

              var docs = snapshot.data!.docs;

              // Filtering
              if (widget.eventCategory != null) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['eventCategory'] == widget.eventCategory;
                }).toList();
              }

              if (widget.eventSubCategory != null) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['eventSubCategory'] == widget.eventSubCategory;
                }).toList();
              }

              if (docs.isEmpty) {
                if (widget.eventCategory != null ||
                    widget.eventSubCategory != null) {
                  return const SizedBox.shrink();
                }
                return Center(
                  child: Text(
                    'No artists found',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                );
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown';
                  final imageUrl = data['image'] ?? '';

                  return ArtistCard(
                    name: name,
                    imageUrl: imageUrl,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ArtistDetailPage(artistDoc: docs[index]),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ArtistCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const ArtistCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          /// Image Container
          Container(
            width: 100, // smaller size
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Colors.grey[400],
                                ),
                              ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 45,
                            color: Colors.grey[400],
                          ),
                        ),
                ),

                /// Heart icon with white stroke
                Positioned(
                  top: 6,
                  right: 6,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 21),
                      Icon(
                        Icons.favorite,
                        color: const Color(0xFF4EB152), // ✅ heart green
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// Artist Name
          SizedBox(
            width: 100,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
