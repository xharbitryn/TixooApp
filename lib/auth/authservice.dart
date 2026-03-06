import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  User? getCurrentUser() => auth.currentUser;
  Stream<User?> get authStateChanges => auth.authStateChanges();

  Future<void> ensureUserDocumentExists(User user) async {
    final docRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'otpVerified': user.phoneNumber != null,
        'profileCompleted': false,
      });
    }
  }

  // --- CHECK IF EMAIL EXISTS ---
  Future<bool> checkEmailExists(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // --- CHECK PHONE EXISTS (UPDATED FIX) ---
  Future<bool> checkPhoneExists(String fullNumber, String rawNumber) async {
    try {
      // 1. Check for 'phoneNumber' (saved with country code)
      final query1 = await FirebaseFirestore.instance
          .collection('Users')
          .where('phoneNumber', isEqualTo: fullNumber)
          .limit(1)
          .get();

      if (query1.docs.isNotEmpty) return true;

      // 2. Check for 'phone' (saved without country code during signup)
      final query2 = await FirebaseFirestore.instance
          .collection('Users')
          .where('phone', isEqualTo: rawNumber)
          .limit(1)
          .get();

      return query2.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // --- EMAIL & PASSWORD ---
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await ensureUserDocumentExists(userCredential.user!);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await ensureUserDocumentExists(userCredential.user!);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      throw FirebaseAuthException(
        code: 'empty-email',
        message: 'Please enter your email',
      );
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // --- GOOGLE SIGN IN ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await auth.signInWithCredential(
        credential,
      );
      if (userCredential.user != null) {
        await ensureUserDocumentExists(userCredential.user!);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception("Google Sign-In failed: ${e.message}");
    }
  }

  // --- APPLE SIGN IN ---
  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final sha256Nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256Nonce,
      );

      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      UserCredential userCredential = await auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('Users')
            .doc(userCredential.user!.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          String? fullName;
          if (appleCredential.givenName != null) {
            fullName =
                "${appleCredential.givenName} ${appleCredential.familyName ?? ''}"
                    .trim();
            await userCredential.user!.updateDisplayName(fullName);
          }
          await userDoc.set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'name': fullName,
            'createdAt': FieldValue.serverTimestamp(),
            'otpVerified': false,
            'profileCompleted': false,
          });
        }
      }
      return userCredential;
    } catch (e) {
      throw Exception("Apple Sign-In error: $e");
    }
  }

  // --- PHONE AUTH ---
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
    required Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
        verificationCompleted(credential);
      },
      verificationFailed: verificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential = await auth.signInWithCredential(
        credential,
      );
      if (userCredential.user != null) {
        await ensureUserDocumentExists(userCredential.user!);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "OTP Verification failed");
    }
  }

  // --- NONCE HELPERS ---
  String _generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signOut() async {
    await googleSignIn.signOut();
    await auth.signOut();
  }
}
