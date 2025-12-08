import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 19.22,
        left: 48.05,
        right: 48.05,
        bottom: 38.44,
      ),
      decoration: const ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment(1.01, 0.01),
          end: Alignment(0.00, 1.00),
          colors: [Color(0xFFFBFCFC), Color(0xFFFBFCFC)],
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1.20,
            color: Color(0xFFD9D9D9),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Home Icon
          _NavItem(
            icon: Icons.home,
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),

          // Search Icon
          _NavItem(
            icon: Icons.search,
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),

          // Profile Icon
          _NavItem(
            icon: Icons.person,
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF131416) : const Color(0xFF616161),
              size: 28,
            ),
            // Animated indicator dot with smooth fade and scale
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 7.21,
              height: 7.21,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF131416) : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
