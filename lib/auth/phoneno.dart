import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopop/widgets/buttons/neopop_button/neopop_button.dart';
import 'package:tixxo/auth/login.dart';
import 'package:tixxo/auth/otp.dart';
import 'package:tixxo/widgets/auth_text_field.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _showSnackBar(
        'Please enter both full name and phone number',
        isError: true,
      );
      return;
    }

    if (phone.length != 10) {
      _showSnackBar(
        'Please enter a valid 10-digit phone number',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showSnackBar('Verification failed: ${e.message}', isError: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPPage(
                verificationId: verificationId,
                fullName: name,
                phone: phone,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('An error occurred. Please try again.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError
            ? Colors.red.shade600
            : const Color(0xFFAFFF00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const SizedBox(height: 40),

              SvgPicture.asset(
                'assets/images/logo.svg',
                height: 50, // adjust as needed
                width: 150, // adjust as needed
              ),
              const SizedBox(height: 20),
              Text(
                'Enter your details to get started',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 15),

              // Name Input
              AuthTextField(
                controller: _nameController,
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                hintText: 'Name',
              ),
              const SizedBox(height: 24),

              // Phone Input
              AuthTextField(
                controller: _phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.number,
                hintText: 'Phone Number',
              ),
              const SizedBox(height: 40),

              // Get OTP Button
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _sendOTP,
                  child: AnimatedBuilder(
                    animation: _buttonScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonScaleAnimation.value,
                        child: NeoPopButton(
                          color: const Color(0xFFB7FF1C),
                          animationDuration: const Duration(milliseconds: 500),
                          onTapUp: _isLoading ? null : _sendOTP,
                          onTapDown: () {},

                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 100,
                              vertical: 16,
                            ),
                            child: Text(
                              _isLoading ? 'Sending OTP' : 'Get OTP',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 45),

              Center(
                child: Text(
                  'By continuing, you agree to our Terms & Privacy Policy',
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 60),
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
    );
  }
}
