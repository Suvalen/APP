import 'package:flutter/material.dart';

// Content-only widget (no Scaffold, no bottom nav)
// Used inside MainLayout
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),

        // Medi-Bot Image
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: AssetImage('assets/images/FullLogo_Transparent.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Welcome Text
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Start chatting with Medi-Bot now.\nYou can ask me anything.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF616161),
              fontSize: 18,
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w400,
              height: 1.60,
              letterSpacing: 0.20,
            ),
          ),
        ),

        const Spacer(flex: 1),

        // Get Started Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: GestureDetector(
            onTap: () {
              // Navigate directly to chat screen
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 17,
              ),
              decoration: ShapeDecoration(
                color: const Color(0xFF141718),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(95),
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x3F17CE92),
                    blurRadius: 24,
                    offset: Offset(4, 8),
                    spreadRadius: 0,
                  )
                ],
              ),
              child: const Text(
                'Get Started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w700,
                  height: 1.60,
                  letterSpacing: 0.20,
                ),
              ),
            ),
          ),
        ),

        const Spacer(flex: 1),
      ],
    );
  }
}

// IMPROVED: Refactored from MediBotLandingScreen to HomeContent - content-only widget (no Scaffold, no footer) for use in MainLayout with Main Scaffold Pattern
// Original Figma design (node 92-1269) maintained - responsive layout, Medi-Bot image, welcome text, Get Started button
// Bottom nav now managed centrally in MainLayout via CustomBottomNav widget
// IMPROVED: Get Started button now navigates directly to chat screen ('/home'), skipping the questionnaire - diagnosis mode is now available via the diagnosis button in chat
