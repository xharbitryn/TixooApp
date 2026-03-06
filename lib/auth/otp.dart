import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/widgets/buttons/neopop_button/neopop_button.dart';
import 'package:tixxo/screens/navbar.dart';

class OTPPage extends StatefulWidget {
  final String verificationId;
  final String fullName;
  final String phone;

  const OTPPage({
    super.key,
    required this.verificationId,
    required this.fullName,
    required this.phone,
  });

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((controller) => controller.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      _controllers[index].text = value[0];
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _verifyOtp() async {
    final otp = _otp;

    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid 6-digit OTP')));
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not signed in')));
        return;
      }

      await currentUser.linkWithCredential(credential);

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .set({
            'name': widget.fullName,
            'phone': widget.phone,
            'otpVerified': true,
            'profileCompleted': true,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      Navigator.pushAndRemoveUntil(
        context,
        // 🚀 FIX: Changed to MainNavBar
        MaterialPageRoute(builder: (_) => const MainNavBar()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OTP Error: ${e.message}')));
    }
  }

  void _resendCode() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Code resent successfully')));
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: const Color(0xFFB7FF1C), width: 2.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        keyboardType: TextInputType.number,
        maxLength: 1,
        showCursor: false,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => _onDigitChanged(value, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),
                Text(
                  'Enter code',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a verification code to mobile number +91${widget.phone}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return Flexible(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: _buildOtpBox(index),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _resendCode,
                        child: Text(
                          'Click to resend',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFB7FF1C),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: NeoPopButton(
                    color: const Color(0xFFB7FF1C),
                    depth: 4,
                    animationDuration: const Duration(milliseconds: 300),
                    onTapUp: _verifyOtp,
                    onTapDown: () {},
                    border: Border.all(
                      color: const Color(0xFFB7FF1C),
                      width: 1,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 105,
                        vertical: 14,
                      ),
                      child: Text(
                        'Verify',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 110),
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
        ),
      ),
    );
  }
}
