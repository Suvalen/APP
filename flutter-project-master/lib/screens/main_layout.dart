import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import 'chat_screen.dart';
import 'search_content.dart';
import 'profile_content.dart';
import '../services/api_service.dart';

// Main layout with bottom navigation
// Manages which content to display based on selected tab
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // List of content widgets for each tab
  final List<Widget> _pages = const [
    ChatScreen(),       // Main chat interface
    SearchContent(),    // Search page
    ProfileContent(),   // Profile page
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

