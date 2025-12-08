import 'package:flutter/material.dart';
import '../welcome_page/welcome_home.dart';

// Standalone welcome home screen shown after login
// Contains the HomeContent widget with "Get Started" button
class WelcomeHomeScreen extends StatelessWidget {
  const WelcomeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: HomeContent(),
      ),
    );
  }
}
