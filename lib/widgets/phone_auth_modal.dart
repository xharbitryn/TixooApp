import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tixxo/auth/authservice.dart';
import 'package:tixxo/auth/signup.dart';
import 'package:tixxo/widgets/premium_auth_widgets.dart';
import 'package:tixxo/widgets/cinematic_bg.dart';

class PhoneAuthBottomSheet extends StatefulWidget {
  final bool isLoginMode;
  const PhoneAuthBottomSheet({super.key, required this.isLoginMode});

  @override
  State<PhoneAuthBottomSheet> createState() => _PhoneAuthBottomSheetState();
}

class _PhoneAuthBottomSheetState extends State<PhoneAuthBottomSheet> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final GlobalKey<ScaffoldMessengerState> _localMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  int _step = 1;
  bool _isLoading = false;
  String _selectedCountryCode = '+91';
  String? _verificationId;
  Timer? _timer;
  int _start = 60;

  void _processPhoneNumber() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 7 || phone.length > 15) {
      _showLocalError("Invalid phone number length");
      return;
    }

    setState(() => _isLoading = true);
    final fullNumber = "$_selectedCountryCode$phone";

    if (widget.isLoginMode) {
      final exists = await _authService.checkPhoneExists(fullNumber, phone);
      if (!exists) {
        setState(() => _isLoading = false);
        _showLocalError("Looks like you're new! Redirecting to Sign Up...");
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SignUpPage(onTap: () {})),
            );
          }
        });
        return;
      }
    }

    await _authService.verifyPhoneNumber(
      phoneNumber: fullNumber,
      codeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _step = 2;
            _isLoading = false;
            _startTimer();
          });
        }
        HapticFeedback.mediumImpact();
      },
      verificationFailed: (e) {
        if (mounted) setState(() => _isLoading = false);
        _showLocalError(e.message ?? "Verification failed");
      },
      verificationCompleted: (credential) {
        if (mounted) Navigator.pop(context);
      },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );
  }

  void _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showLocalError("Enter 6-digit code");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithOTP(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showLocalError("Invalid OTP");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editPhoneNumber() {
    setState(() {
      _step = 1;
      _otpController.clear();
      _isLoading = false;
      _timer?.cancel();
    });
  }

  void _startTimer() {
    _start = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() => timer.cancel());
      } else {
        setState(() => _start--);
      }
    });
  }

  void _showLocalError(String msg) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    _localMessengerKey.currentState?.removeCurrentSnackBar();
    _localMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: kTixooLightGreen,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: bottomInset + 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchInputDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFF111111),
      hintText: "Search country...",
      hintStyle: GoogleFonts.poppins(color: Colors.white38),
      prefixIcon: const Icon(Icons.search, color: Colors.white54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kTixooLightGreen, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );

    final pinTheme = PinTheme(
      width: 46,
      height: 55,
      textStyle: GoogleFonts.poppins(
        fontSize: 22,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
    );

    return ScaffoldMessenger(
      key: _localMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF0F0F0F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    _step == 1 ? "Enter Mobile Number" : "Verify OTP",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_step == 1)
                    Text(
                      "We'll send a verification code to your number.",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    )
                  else
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Code sent to ",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                        GestureDetector(
                          onTap: _editPhoneNumber,
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "$_selectedCountryCode ${_phoneController.text} ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: kTixooLightGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: kTixooLightGreen,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 30),

                  if (_step == 1) ...[
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              primaryColor: kTixooLightGreen,
                              colorScheme: const ColorScheme.dark(
                                primary: kTixooLightGreen,
                                surface: Color(0xFF1E1E1E),
                                onSurface: Colors.white,
                              ),
                              // 🚀 FIX: Used dialogBackgroundColor instead of dialogTheme
                              dialogBackgroundColor: const Color(0xFF1E1E1E),
                            ),
                            child: CountryCodePicker(
                              onChanged: (c) => setState(
                                () => _selectedCountryCode = c.dialCode!,
                              ),
                              initialSelection: 'IN',
                              favorite: const ['+91', 'US'],
                              textStyle: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              dialogTextStyle: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              searchStyle: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              searchDecoration: searchInputDecoration,
                              boxDecoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              closeIcon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              barrierColor: Colors.black.withOpacity(0.85),
                              showFlag: true,
                              showDropDownButton: true,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white10,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: GoogleFonts.spaceMono(
                                color: Colors.white,
                                fontSize: 18,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: "00000 00000",
                                hintStyle: GoogleFonts.spaceMono(
                                  color: Colors.white12,
                                  letterSpacing: 2.0,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_step == 2) ...[
                    Center(
                      child: Pinput(
                        controller: _otpController,
                        length: 6,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        defaultPinTheme: pinTheme,
                        focusedPinTheme: pinTheme.copyWith(
                          decoration: pinTheme.decoration!.copyWith(
                            border: Border.all(color: kTixooLightGreen),
                            boxShadow: [
                              BoxShadow(
                                color: kTixooLightGreen.withOpacity(0.2),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                        onCompleted: (_) => _verifyOTP(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: _start > 0
                          ? Text(
                              "Resend in 00:${_start.toString().padLeft(2, '0')}",
                              style: GoogleFonts.poppins(color: Colors.white38),
                            )
                          : GestureDetector(
                              onTap: _processPhoneNumber,
                              child: Text(
                                "Resend Code",
                                style: GoogleFonts.poppins(
                                  color: kTixooLightGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  ScaleButton(
                    onTap: _isLoading
                        ? null
                        : (_step == 1 ? _processPhoneNumber : _verifyOTP),
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kTixooLightGreen,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kTixooLightGreen.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _step == 1 ? "Continue" : "Verify",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
