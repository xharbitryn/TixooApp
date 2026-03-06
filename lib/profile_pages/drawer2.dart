import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

void showBillingAddressDrawer(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const BillingAddressDrawer(),
  );
}

class BillingAddressDrawer extends StatefulWidget {
  const BillingAddressDrawer({super.key});

  @override
  State<BillingAddressDrawer> createState() => _BillingAddressDrawerState();
}

class _BillingAddressDrawerState extends State<BillingAddressDrawer> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();

  bool isLoadingLocation = false;

  Future<void> _getCurrentLocationAndSave() async {
    setState(() => isLoadingLocation = true);

    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final formattedAddress =
              "${place.name}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";

          await _saveBillingAddressDirect(formattedAddress);
          return; // stops further execution
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching location: $e")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
    }

    setState(() => isLoadingLocation = false);
  }

  Future<void> _saveBillingAddressDirect(String address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final billingAddress = {
      "address": address,
      "timestamp": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      "billing_address": billingAddress,
    }, SetOptions(merge: true));

    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Billing address saved")));
  }

  Future<void> _saveBillingAddressManual() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide an address")),
      );
      return;
    }

    final combinedAddress = [
      addressController.text.trim(),
      floorController.text.trim(),
      landmarkController.text.trim(),
    ].where((e) => e.isNotEmpty).join(", ");

    final billingAddress = {
      "address": combinedAddress,
      "timestamp": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      "billing_address": billingAddress,
    }, SetOptions(merge: true));

    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Billing address saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Add address details",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            InkWell(
              onTap: _getCurrentLocationAndSave,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Use your current location",
                        style: GoogleFonts.poppins(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLoadingLocation)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white54, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "OR",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white54, thickness: 1)),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Your complete address *"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: floorController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Enter your house/floor number"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: landmarkController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Enter a Landmark"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB7FF1C),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _saveBillingAddressManual,
                child: Text(
                  "Confirm",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: Colors.transparent,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[800]!),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.limeAccent),
      ),
    );
  }
}
