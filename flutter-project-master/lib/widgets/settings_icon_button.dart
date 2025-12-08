import 'package:flutter/material.dart';

// Reusable settings icon button
// Appears in top-right of main pages and navigates to settings
class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      top: 20,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed('/settings');
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.settings_outlined,
            color: Color(0xFF141718),
            size: 22,
          ),
        ),
      ),
    );
  }
}
