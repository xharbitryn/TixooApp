import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import 'package:tixxo/auth/authservice.dart';
import 'package:tixxo/auth/signup.dart';
import 'package:tixxo/screens/navbar.dart';
import 'package:tixxo/widgets/cinematic_bg.dart';
import 'package:tixxo/widgets/premium_auth_widgets.dart';
import 'package:tixxo/widgets/phone_auth_modal.dart';
import 'package:tixxo/widgets/forgot_password_modal.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool isLoading = false;
  bool _isPasswordVisible = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool get _canSubmit => _isEmailValid && _isPasswordValid && !isLoading;

  late AnimationController _liquidController;
  late AnimationController _borderController;
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _clearGoogleSession();
    emailController.addListener(_validateForm);
    passwordController.addListener(_validateForm);

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
      ).hasMatch(emailController.text.trim());
      _isPasswordValid = passwordController.text.trim().length >= 6;
    });
  }

  @override
  void dispose() {
    _liquidController.dispose();
    _borderController.dispose();
    _entryController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ForgotPasswordBottomSheet(initialEmail: emailController.text.trim()),
    );
  }

  void _showPhoneLogin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PhoneAuthBottomSheet(isLoginMode: true),
    );
  }

  Future<void> _clearGoogleSession() async {
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) await googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google clean error: $e');
    }
  }

  Future<void> login() async {
    if (!_canSubmit) return;
    try {
      FocusScope.of(context).unfocus();
      setState(() => isLoading = true);
      await authService.signInWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      HapticFeedback.mediumImpact();
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      _showSnack(e.message ?? "An error occurred");
      setState(() => isLoading = false);
    } catch (e) {
      _showSnack("An error occurred");
      setState(() => isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() => isLoading = true);
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }
      final QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: googleUser.email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        await GoogleSignIn().signOut();
        _showSnack('No account found. Please sign up first.');
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_skipped_login');
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    } catch (e) {
      await _clearGoogleSession();
      _showSnack('Sign in failed. Check your internet or try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signInWithApple() async {
    try {
      setState(() => isLoading = true);
      final userCredential = await authService.signInWithApple();
      if (userCredential != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('has_skipped_login');
        if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
      }
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void skipLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_skipped_login', true);
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      Navigator.pushReplacement(
        context,
        // 🚀 FIX: Changed to MainNavBar
        MaterialPageRoute(builder: (context) => const MainNavBar()),
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.poppins(color: Colors.black)),
          backgroundColor: kTixooLightGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double paddingValue = Responsive.s(context, 24.0);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CinematicBackground(
          controller: _liquidController,
          child: SafeArea(
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
                          ),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: Responsive.s(context, 16.0),
                                      ),
                                      child: RotatingBorderButton(
                                        text: "Skip Login",
                                        controller: _borderController,
                                        onTap: skipLogin,
                                      ),
                                    ),
                                  ),
                                  Spacer(flex: size.height < 700 ? 1 : 2),
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
                                      "Hello,\nWelcome Back!",
                                      style: GoogleFonts.poppins(
                                        fontSize: Responsive.s(context, 40),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: Responsive.s(context, 12)),
                                  Text(
                                    "Your front row seat awaits.",
                                    style: GoogleFonts.poppins(
                                      fontSize: Responsive.s(context, 15),
                                      color: Colors.white54,
                                    ),
                                  ),
                                  SizedBox(height: Responsive.s(context, 40)),
                                  PremiumAuthField(
                                    controller: emailController,
                                    label: "Email Address",
                                    icon: Icons.alternate_email,
                                    shimmerController: _borderController,
                                    keyboardType: TextInputType.emailAddress,
                                    showValidation:
                                        emailController.text.isNotEmpty,
                                    isValid: _isEmailValid,
                                  ),
                                  SizedBox(height: Responsive.s(context, 16)),
                                  PremiumAuthField(
                                    controller: passwordController,
                                    label: "Password",
                                    icon: Icons.lock_outline_rounded,
                                    shimmerController: _borderController,
                                    isPassword: !_isPasswordVisible,
                                    showValidation:
                                        passwordController.text.isNotEmpty,
                                    isValid: _isPasswordValid,
                                    suffixWidget: CyberEyeButton(
                                      isVisible: _isPasswordVisible,
                                      onTap: () => setState(
                                        () => _isPasswordVisible =
                                            !_isPasswordVisible,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _showForgotPassword,
                                      child: Text(
                                        "Forgot Password?",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white54,
                                          fontSize: Responsive.s(context, 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: Responsive.s(context, 20)),
                                  ScaleButton(
                                    onTap: _canSubmit ? login : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      height: Responsive.s(context, 56),
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
                                                "Sign In",
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
                                  SizedBox(height: Responsive.s(context, 24)),
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
                                  SizedBox(height: Responsive.s(context, 24)),
                                  ScaleButton(
                                    onTap: isLoading ? null : signInWithGoogle,
                                    child: Container(
                                      height: Responsive.s(context, 56),
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
                                            height: Responsive.s(context, 24),
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
                                    SizedBox(height: Responsive.s(context, 16)),
                                    ScaleButton(
                                      onTap: isLoading ? null : signInWithApple,
                                      child: Container(
                                        height: Responsive.s(context, 56),
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
                                              size: Responsive.s(context, 28),
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
                                  SizedBox(height: Responsive.s(context, 16)),
                                  ScaleButton(
                                    onTap: _showPhoneLogin,
                                    child: Container(
                                      height: Responsive.s(context, 56),
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
                                            size: Responsive.s(context, 24),
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
                                  Spacer(flex: 3),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: Responsive.s(context, 20.0),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
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
                                                        SignUpPage(
                                                          onTap: () {},
                                                        ),
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
                                            "Sign up",
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
