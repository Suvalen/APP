import 'package:flutter/material.dart';
import '../widgets/settings_item.dart';

// Profile page with user info and settings
class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          const SizedBox(height: 20),
          const Text(
            'Profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF141718),
              fontSize: 22,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              height: 1.59,
            ),
          ),
          const SizedBox(height: 30),

          // Profile picture section
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 105,
                height: 105,
                decoration: const ShapeDecoration(
                  image: DecorationImage(
                    image: NetworkImage("https://via.placeholder.com/105x105"),
                    fit: BoxFit.cover,
                  ),
                  shape: OvalBorder(),
                ),
              ),
              Positioned(
                right: -5,
                bottom: 5,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const ShapeDecoration(
                    color: Color(0xFF141718),
                    shape: OvalBorder(
                      side: BorderSide(width: 4, color: Colors.white),
                    ),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name
          const Text(
            'Tom Hillson',
            style: TextStyle(
              color: Color(0xFF212121),
              fontSize: 27,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Email
          Opacity(
            opacity: 0.52,
            child: const Text(
              'Tomhill@mail.com',
              style: TextStyle(
                color: Color(0xFF323142),
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 50),

          // Settings items
          SettingsItem(
            icon: Icons.settings_outlined,
            title: 'Preferences',
            onTap: () {
              // TODO: Navigate to preferences
              print('Preferences tapped');
            },
          ),
          const Divider(height: 1, indent: 49, endIndent: 49),

          SettingsItem(
            icon: Icons.security_outlined,
            title: 'Account Security',
            onTap: () {
              // TODO: Navigate to account security
              print('Account Security tapped');
            },
          ),
          const Divider(height: 1, indent: 49, endIndent: 49),

          SettingsItem(
            icon: Icons.medical_services_outlined,
            title: 'Medical Profile',
            onTap: () {
              // TODO: Navigate to medical profile
              print('Medical Profile tapped');
            },
          ),
          const Divider(height: 1, indent: 49, endIndent: 49),

          SettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              // TODO: Implement logout
              _showLogoutDialog(context);
            },
            iconColor: const Color(0xFFD32F2F),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to login
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/welcome',
                  (route) => false,
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFD32F2F)),
              ),
            ),
          ],
        );
      },
    );
  }
}
