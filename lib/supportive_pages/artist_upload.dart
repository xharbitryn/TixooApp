import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadArtistPage extends StatefulWidget {
  const UploadArtistPage({super.key});

  @override
  State<UploadArtistPage> createState() => _UploadArtistPageState();
}

class _UploadArtistPageState extends State<UploadArtistPage> {
  bool _isUploading = false;

  Future<Uint8List> _loadAssetImage(String path) async {
    final byteData = await rootBundle.load(path);
    return byteData.buffer.asUint8List();
  }

  Future<void> _uploadArtist() async {
    setState(() => _isUploading = true);

    try {
      final String artistName = "Samay Raina";
      final String bio =
          "Samay Raina is a talented artist known for his unique musical style and engaging performances.";
      final int listeners = 310000;
      final String videoUrl =
          "https://youtu.be/c_LUsDXA2CU?si=8jo4ivXQtVADXyf9";

      final storageRef = FirebaseStorage.instance.ref().child(
        "Artists/$artistName",
      );

      // Replace with your Smay Raina images inside assets/images/
      Uint8List posterData = await _loadAssetImage(
        'assets/images/samay_poster.jpeg',
      );
      Uint8List profileData = await _loadAssetImage(
        'assets/images/samay_image.jpeg',
      );

      // Upload Poster to Artists/Smay Raina/poster/poster.jpg
      final posterRef = storageRef.child("poster/poster.jpg");
      await posterRef.putData(posterData);
      final posterUrl = await posterRef.getDownloadURL();

      // Upload Profile Image to Artists/Smay Raina/image/image.jpg
      final imageRef = storageRef.child("image/image.jpg");
      await imageRef.putData(profileData);
      final imageUrl = await imageRef.getDownloadURL();

      // Save info in Firestore including videoUrl
      await FirebaseFirestore.instance
          .collection('Artists')
          .doc(artistName)
          .set({
            'name': artistName,
            'bio': bio,
            'poster': posterUrl,
            'image': imageUrl,
            'listeners': listeners,
            'videoUrl': videoUrl,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Smay Raina uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Artist')),
      body: Center(
        child: _isUploading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _uploadArtist,
                child: const Text('Upload Smay Raina Artist Data'),
              ),
      ),
    );
  }
}
