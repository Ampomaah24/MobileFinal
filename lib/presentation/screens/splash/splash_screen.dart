// lib/presentation/screens/splash/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Add delay to ensure this runs after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Get the auth service
      final authService = Provider.of<AuthService>(context, listen: false);

      // Add a delay for splash screen effect
      await Future.delayed(const Duration(seconds: 2));

      // Check if user is logged in
      if (authService.user != null) {
        print("User is logged in: ${authService.user!.uid}");
        
        // Ensure user data is fully loaded
        if (authService.userModel == null) {
          print("Fetching user data...");
          // Wait for user data to load
          await Future.delayed(const Duration(seconds: 1));
        }
        
        // Check if user is admin
        if (authService.isAdmin) {
          print("User is admin, navigating to admin dashboard");
          // Navigate to admin dashboard
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          print("User is not admin, navigating to home");
          // Navigate to home screen
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        print("User is not logged in, navigating to login screen");
        // Navigate to login screen
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print("Error in splash screen: $e");
      // If there's an error, default to login screen
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or text
            Text(
              'Evently',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Discover. Book. Experience.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}