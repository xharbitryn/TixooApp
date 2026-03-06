import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventUploader extends StatefulWidget {
  const EventUploader({Key? key}) : super(key: key);

  @override
  State<EventUploader> createState() => _EventUploaderState();
}

class _EventUploaderState extends State<EventUploader> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<String> uploadImage(String path, String firebasePath) async {
    final bytes = await rootBundle.load(path);
    final ref = storage.ref(firebasePath);
    await ref.putData(bytes.buffer.asUint8List());
    return await ref.getDownloadURL();
  }

  Future<void> uploadEvent() async {
    try {
      const eventFolder = 'upcoming4';

      final posterUrl = await uploadImage(
        'assets/images/e4.jpg',
        'events/$eventFolder/posters/e4.jpg',
      );

      final galleryImages = await Future.wait([
        uploadImage(
          'assets/images/e1.jpg',
          'events/$eventFolder/gallery/e1.jpg',
        ),
        uploadImage(
          'assets/images/e2.jpg',
          'events/$eventFolder/gallery/e2.jpg',
        ),
        uploadImage(
          'assets/images/e3.jpg',
          'events/$eventFolder/gallery/e3.jpg',
        ),
        uploadImage(
          'assets/images/e4.jpg',
          'events/$eventFolder/gallery/e4.jpg',
        ),
      ]);

      final artistImageUrl = await uploadImage(
        'assets/images/e4.jpg',
        'events/$eventFolder/artists/e4.jpg',
      );

      final eventData = {
        "name": "Arjit Singh Concert",
        "location": "DY Patil Stadium, Mumbai",
        "status": "upcoming",
        "startTime": Timestamp.fromDate(DateTime.parse("2025-12-10T18:30:00Z")),
        "endTime": Timestamp.fromDate(DateTime.parse("2025-12-10T22:30:00Z")),
        "promoterId": "promoter_tswift_001",
        "totalSeat": 60000,
        "baseTicketPrice": 999,
        "lat": "19.0330",
        "long": "73.0297",
        "poster": posterUrl,
        "gallery": galleryImages,
        "description":
            "Taylor Swift is bringing The Eras Tour to Mumbai! Experience a magical night filled with all her musical eras, unforgettable performances, and stunning visuals.",
        "categoryId": "concert",
        "ticketCategories": [
          {"name": "General", "price": 999, "quantity": 40000},
          {"name": "VIP", "price": 1999, "quantity": 10000},
          {"name": "VVIP", "price": 3999, "quantity": 5000},
        ],
        "about": {
          "language": "English",
          "venueType": "Stadium",
          "duration": "4 Hours",
          "ageLimit": "All ages welcome",
          "seating": "Seating & Standing zones",
          "whatToExpect": [
            "Performances from all of Taylor's eras",
            "Massive LED screen visuals",
            "Tour-exclusive merchandise",
            "Special effects and pyrotechnics",
          ],
        },
        "venueInfo": {
          "name": "DY Patil Stadium",
          "capacity": 60000,
          "parking": "Paid parking available",
          "foodBeverages": "Wide range of food courts and beverage counters",
          "amenities": {
            "freeParking": false,
            "foodCourt": true,
            "security": "Full security & CCTV surveillance",
            "accessibility": "Wheelchair access and assistance",
          },
          "gettingThere": {
            "metro": "Navi Mumbai Metro (Belapur Station nearby)",
            "bus": "Buses available from major points in Mumbai & Navi Mumbai",
            "cab": "Ride-share & designated drop-off zones",
          },
        },
        "artistDetails": [
          {
            "name": "Taylor Swift",
            "listeners": "120M+ monthly listeners",
            "bio":
                "Taylor Swift is a global superstar known for her storytelling, genre-spanning albums, and fan-dedicated performances. Her Eras Tour is one of the biggest tours in history.",
            "image": artistImageUrl,
          },
          {
            "name": "Special Guest",
            "listeners": "TBA",
            "bio":
                "A special guest artist will join Taylor on stage. Stay tuned for the reveal!",
            "image": "", // Optional
          },
        ],
      };

      await firestore.collection("Events").add(eventData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("arjit event uploaded successfully")),
      );
    } catch (e) {
      debugPrint("Error uploading event: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to upload event: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Event")),
      body: Center(
        child: ElevatedButton(
          onPressed: uploadEvent,
          child: const Text("Upload arjit Event"),
        ),
      ),
    );
  }
}
