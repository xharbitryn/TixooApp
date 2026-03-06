// lib/main.dart

import 'package:flutter/material.dart';
import 'package:tixxo/auth/authgate.dart';
import 'package:tixxo/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tixxo/screens/navbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'constants/design_constants.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Wrap MyApp with ProviderScope to enable Riverpod state management
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtil for absolute pixel-perfect responsiveness across all devices
    return ScreenUtilInit(
      designSize: DesignConstants.designSize, // 440 x 956 from Figma
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Tixoo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          home: child,
        );
      },
      child: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSkippedLogin = prefs.getBool('has_skipped_login') ?? false;

    if (hasSkippedLogin) {
      // User has skipped login before, go directly to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // Check authentication state through AuthGate
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Color(0xFFB7FF1C))),
    );
  }
}

// Updated skipLogin function for LoginPage
class SkipLoginHelper {
  // Save skip login state
  static Future<void> setSkipLoginState(bool hasSkipped) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_skipped_login', hasSkipped);
  }

  // Check if user has skipped login
  static Future<bool> hasSkippedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_skipped_login') ?? false;
  }

  // Clear skip login state (call this when user actually logs in)
  static Future<void> clearSkipLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_skipped_login');
  }
}
