import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tixxo/auth/authservice.dart';
import 'package:tixxo/widgets/premium_auth_widgets.dart';
import 'package:tixxo/widgets/cinematic_bg.dart';

class ForgotPasswordBottomSheet extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordBottomSheet({super.key, this.initialEmail});

  @override
  State<ForgotPasswordBottomSheet> createState() =>
      _ForgotPasswordBottomSheetState();
}

class _ForgotPasswordBottomSheetState extends State<ForgotPasswordBottomSheet>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TextEditingController _emailController;
  late AnimationController _borderController;

  final GlobalKey<ScaffoldMessengerState> _localMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isLoading = false;
  bool _isSent = false;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _validateEmail();
    _emailController.addListener(_validateEmail);

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = RegExp(
        r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(_emailController.text.trim());
    });
  }

  Future<void> _sendResetLink() async {
    if (!_isEmailValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      // Check existence first
      final exists = await _authService.checkEmailExists(email);

      if (!exists) {
        setState(() => _isLoading = false);
        HapticFeedback.heavyImpact();
        _showLocalError("No account found with this email.");
        return;
      }

      await _authService.sendPasswordResetEmail(email);

      HapticFeedback.mediumImpact();
      setState(() {
        _isLoading = false;
        _isSent = true;
      });
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _isLoading = false);
      _showLocalError(e.message ?? "Failed to send reset link");
    } catch (e) {
      setState(() => _isLoading = false);
      _showLocalError("An unexpected error occurred");
    }
  }

  void _showLocalError(String msg) {
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
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _localMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Center(
            child: Container(
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
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isSent ? _buildSuccessView() : _buildInputView(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputView() {
    return Column(
      key: const ValueKey("Input"),
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
          "Reset Password",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter the email associated with your account and we'll send you a link to reset your password.",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white54,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 30),

        PremiumAuthField(
          controller: _emailController,
          label: "Email Address",
          icon: Icons.email_outlined,
          shimmerController: _borderController,
          keyboardType: TextInputType.emailAddress,
          isValid: _isEmailValid,
          showValidation: _emailController.text.isNotEmpty,
        ),

        const SizedBox(height: 30),

        ScaleButton(
          onTap: (_isEmailValid && !_isLoading) ? _sendResetLink : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isEmailValid ? kTixooLightGreen : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isEmailValid
                  ? [
                      BoxShadow(
                        color: kTixooLightGreen.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
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
                      "Send Reset Link",
                      style: GoogleFonts.poppins(
                        color: _isEmailValid ? Colors.black : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      key: const ValueKey("Success"),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kTixooLightGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: kTixooLightGreen,
            size: 50,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Check your Inbox!",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "We have sent a password recovery link to:\n${_emailController.text}",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white54,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        ScaleButton(
          onTap: () => Navigator.pop(context),
          child: Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                "Back to Login",
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
    );
  }
}
