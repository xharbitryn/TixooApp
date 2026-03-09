import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import 'package:tixxo/auth/authservice.dart';
import 'package:tixxo/auth/login.dart';
import 'package:tixxo/auth/phoneno.dart';
import 'package:tixxo/widgets/cinematic_bg.dart';
import 'package:tixxo/widgets/premium_auth_widgets.dart';
import 'package:tixxo/widgets/phone_auth_modal.dart';

class SignUpPage extends StatefulWidget {
  final VoidCallback onTap;
  const SignUpPage({super.key, required this.onTap});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool _isPasswordVisible = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmValid = false;
  bool get _canSubmit =>
      _isEmailValid && _isPasswordValid && _isConfirmValid && !isLoading;

  late AnimationController _liquidController;
  late AnimationController _borderController;
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);

    _liquidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutQuart),
        );
    _entryController.forward();
  }

  void _validateForm() {
    setState(() {
      _isEmailValid = RegExp(
        r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(_emailController.text.trim());
      _isPasswordValid = _passwordController.text.trim().length >= 6;
      _isConfirmValid =
          _passwordController.text == _confirmPasswordController.text &&
          _isPasswordValid;
    });
  }

  @override
  void dispose() {
    _liquidController.dispose();
    _borderController.dispose();
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.black),
          ),
          backgroundColor: kTixooLightGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showPhoneLogin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PhoneAuthBottomSheet(isLoginMode: false),
    );
  }

  void _signUp() async {
    if (!_canSubmit) return;
    setState(() => isLoading = true);
    try {
      final userCredential = await _authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'otpVerified': false,
            'profileCompleted': false,
          });
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PhoneInputPage()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void signInWithGoogle() async {
    try {
      setState(() => isLoading = true);
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('Users')
            .doc(userCredential.user!.uid);
        final snapshot = await userDoc.get();
        if (!snapshot.exists) {
          await userDoc.set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PhoneInputPage()),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signInWithApple() async {
    try {
      setState(() => isLoading = true);
      final userCredential = await _authService.signInWithApple();
      if (userCredential != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PhoneInputPage()),
          );
        }
      }
    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double paddingValue = Responsive.s(context, 24.0);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CinematicBackground(
          controller: _liquidController,
          child: SafeArea(
            // 🚀 FIX: Ensures safe stretching or gentle scrolling without overflowing
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Center(
                        child: Container(
                          constraints: Responsive.formConstraints(context),
                          padding: EdgeInsets.symmetric(
                            horizontal: paddingValue,
                            vertical: 16,
                          ),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Spacer(flex: 3),
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        colors: [
                                          Colors.white,
                                          const Color(0xFFE0E0E0),
                                          kTixooDarkGreen,
                                          kTixooLightGreen,
                                          Colors.white,
                                        ],
                                        stops: const [
                                          0.0,
                                          0.3,
                                          0.45,
                                          0.55,
                                          1.0,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        transform: GradientRotation(
                                          _liquidController.value * 2 * math.pi,
                                        ),
                                      ).createShader(bounds);
                                    },
                                    child: Text(
                                      "Create\nAccount",
                                      style: GoogleFonts.poppins(
                                        fontSize: Responsive.s(context, 38),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: Responsive.s(context, 8)),
                                  Text(
                                    "Join the community now!",
                                    style: GoogleFonts.poppins(
                                      fontSize: Responsive.s(context, 14),
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const Spacer(flex: 4),
                                  PremiumAuthField(
                                    controller: _emailController,
                                    label: "Email Address",
                                    icon: Icons.email_outlined,
                                    shimmerController: _borderController,
                                    keyboardType: TextInputType.emailAddress,
                                    isValid: _isEmailValid,
                                    showValidation:
                                        _emailController.text.isNotEmpty,
                                  ),
                                  SizedBox(height: Responsive.s(context, 14)),
                                  PremiumAuthField(
                                    controller: _passwordController,
                                    label: "Create Password",
                                    icon: Icons.lock_outline,
                                    shimmerController: _borderController,
                                    isPassword: !_isPasswordVisible,
                                    suffixWidget: CyberEyeButton(
                                      isVisible: _isPasswordVisible,
                                      onTap: () => setState(
                                        () => _isPasswordVisible =
                                            !_isPasswordVisible,
                                      ),
                                    ),
                                    isValid: _isPasswordValid,
                                    showValidation:
                                        _passwordController.text.isNotEmpty,
                                  ),
                                  SizedBox(height: Responsive.s(context, 14)),
                                  PremiumAuthField(
                                    controller: _confirmPasswordController,
                                    label: "Confirm Password",
                                    icon: Icons.lock_outline,
                                    shimmerController: _borderController,
                                    isPassword: !_isPasswordVisible,
                                    isValid: _isConfirmValid,
                                    showValidation: _confirmPasswordController
                                        .text
                                        .isNotEmpty,
                                  ),
                                  SizedBox(height: Responsive.s(context, 24)),
                                  ScaleButton(
                                    onTap: _canSubmit ? _signUp : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      height: Responsive.s(context, 54),
                                      decoration: BoxDecoration(
                                        color: _canSubmit
                                            ? kTixooLightGreen
                                            : const Color(0xFF1C1C1E),
                                        borderRadius: BorderRadius.circular(
                                          Responsive.s(context, 12),
                                        ),
                                        boxShadow: _canSubmit
                                            ? [
                                                BoxShadow(
                                                  color: kTixooLightGreen
                                                      .withOpacity(0.4),
                                                  blurRadius: 25,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ]
                                            : [],
                                        border: Border.all(
                                          color: _canSubmit
                                              ? Colors.transparent
                                              : Colors.white10,
                                        ),
                                      ),
                                      child: Center(
                                        child: isLoading
                                            ? SizedBox(
                                                height: Responsive.s(
                                                  context,
                                                  24,
                                                ),
                                                width: Responsive.s(
                                                  context,
                                                  24,
                                                ),
                                                child:
                                                    const CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(
                                                "Create Account",
                                                style: GoogleFonts.poppins(
                                                  color: _canSubmit
                                                      ? Colors.black
                                                      : Colors.white38,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: Responsive.s(
                                                    context,
                                                    16,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(flex: 3),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white10,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: Responsive.s(context, 16),
                                        ),
                                        child: Text(
                                          "OR",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white24,
                                            fontSize: Responsive.s(context, 12),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(flex: 3),
                                  ScaleButton(
                                    onTap: isLoading ? null : signInWithGoogle,
                                    child: Container(
                                      height: Responsive.s(context, 54),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF151515),
                                        borderRadius: BorderRadius.circular(
                                          Responsive.s(context, 12),
                                        ),
                                        border: Border.all(
                                          color: Colors.white10,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            "assets/images/googlelogo.png",
                                            height: Responsive.s(context, 22),
                                          ),
                                          SizedBox(
                                            width: Responsive.s(context, 12),
                                          ),
                                          Text(
                                            "Continue with Google",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: Responsive.s(
                                                context,
                                                14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (Platform.isIOS) ...[
                                    SizedBox(height: Responsive.s(context, 12)),
                                    ScaleButton(
                                      onTap: isLoading ? null : signInWithApple,
                                      child: Container(
                                        height: Responsive.s(context, 54),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            Responsive.s(context, 12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.apple,
                                              color: Colors.black,
                                              size: Responsive.s(context, 26),
                                            ),
                                            SizedBox(
                                              width: Responsive.s(context, 12),
                                            ),
                                            Text(
                                              "Continue with Apple",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                                fontSize: Responsive.s(
                                                  context,
                                                  14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: Responsive.s(context, 12)),
                                  ScaleButton(
                                    onTap: _showPhoneLogin,
                                    child: Container(
                                      height: Responsive.s(context, 54),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF151515),
                                        borderRadius: BorderRadius.circular(
                                          Responsive.s(context, 12),
                                        ),
                                        border: Border.all(
                                          color: Colors.white10,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.phone_iphone_rounded,
                                            color: Colors.white,
                                            size: Responsive.s(context, 22),
                                          ),
                                          SizedBox(
                                            width: Responsive.s(context, 12),
                                          ),
                                          Text(
                                            "Continue with Phone",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: Responsive.s(
                                                context,
                                                14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(flex: 4),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: Responsive.s(context, 8.0),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Already have an account? ",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white54,
                                            fontSize: Responsive.s(context, 14),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushReplacement(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder:
                                                    (context, animation, _) =>
                                                        LoginPage(onTap: () {}),
                                                transitionsBuilder:
                                                    (
                                                      context,
                                                      animation,
                                                      _,
                                                      child,
                                                    ) => FadeTransition(
                                                      opacity: animation,
                                                      child: child,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            "Sign in",
                                            style: GoogleFonts.poppins(
                                              color: kTixooLightGreen,
                                              fontWeight: FontWeight.w600,
                                              fontSize: Responsive.s(
                                                context,
                                                14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
