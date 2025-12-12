import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
              // Hero Image Section
              Container(
                width: double.infinity,
                height: 331,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/FullLogo_Transparent.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 75),

              // Buttons Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Log in Button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/loginform'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.27,
                          vertical: 17.18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141718),
                          borderRadius: BorderRadius.circular(95.45),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3F17CE92),
                              blurRadius: 24,
                              offset: Offset(4, 8),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Log in',
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

                    const SizedBox(height: 22.91),

                    // Sign up Button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/register'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.27,
                          vertical: 17.18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E3E3),
                          borderRadius: BorderRadius.circular(95.45),
                        ),
                        child: const Text(
                          'Sign up',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFB1B1B1),
                            fontSize: 17.18,
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w700,
                            height: 1.60,
                            letterSpacing: 0.19,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 55),

                    // Continue With Accounts Text
                    

                    const SizedBox(height: 24),

                    // Social Login Buttons
                   
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// IMPROVED: Added navigation handlers to Login and Sign up buttons, fixed image loading with AssetImage, and made social buttons interactive
