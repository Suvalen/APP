import 'package:flutter/material.dart';

// Reusable settings item widget with modern styling and animations
// Used in profile/settings pages for clickable menu items
class SettingsItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool showChevron;
  final bool isLogout;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.showChevron = true,
    this.isLogout = false,
  });

  @override
  State<SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<SettingsItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: _isPressed
              ? LinearGradient(
                  colors: [
                    const Color(0xFF155DFC).withOpacity(0.1),
                    const Color(0xFF1E6FFF).withOpacity(0.05),
                  ],
                )
              : const LinearGradient(
                  colors: [Colors.white, Colors.white],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? const Color(0xFF155DFC).withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _isPressed ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with gradient
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: widget.isLogout
                    ? const LinearGradient(
                        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          const Color(0xFF155DFC).withOpacity(0.15),
                          const Color(0xFF1E6FFF).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (_isPressed)
                    BoxShadow(
                      color: widget.isLogout
                          ? const Color(0xFFD32F2F).withOpacity(0.3)
                          : const Color(0xFF155DFC).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: 24,
                color: widget.isLogout
                    ? Colors.white
                    : const Color(0xFF155DFC),
              ),
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  color: widget.isLogout
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF212121),
                  fontSize: 17,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Chevron arrow
            if (widget.showChevron)
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: _isPressed ? 0.05 : 0,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: widget.isLogout
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF9E9E9E),
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
