import 'package:flutter/material.dart';

// Splash visual widget moved here so it can be routed to directly.
class SplashVisual extends StatefulWidget {
  const SplashVisual({super.key});

  @override
  State<SplashVisual> createState() => _SplashVisualState();
}

class _SplashVisualState extends State<SplashVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth,
      height: screenHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
      ),
      child: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/images/FullLogo_Transparent.png', // <- use assets/ path and match pubspec.yaml
                width: screenWidth * 0.6,
                fit: BoxFit.contain,
                semanticLabel: 'App Logo',
                errorBuilder: (context, error, stackTrace) {
                  // Shows a visible placeholder on failure and logs the error to console.
                  // Helpful when emulator can't find the asset (case/path mismatch or missing pubspec entry).
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    debugPrint('Image.asset load failed: $error');
                  });
                  return const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey,
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.1,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
