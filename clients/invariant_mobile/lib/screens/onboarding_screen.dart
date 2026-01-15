// clients/invariant_mobile/lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "PROOF OF\nDEVICE",
      "body": "Invariant anchors your identity to the secure silicon in your phone.",
      "icon": "shield"
    },
    {
      "title": "DAILY\nVERIFICATION",
      "body": "Tap once every 24 hours to prove your existence and build your reputation score.",
      "icon": "fingerprint" // Changed from 'bolt' to 'fingerprint'
    },
    {
      "title": "GENESIS\nCOHORT",
      "body": "Join the Testnet. Maintain your streak to be included in the Genesis Block.",
      "icon": "diamond"
    },
  ];

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = index);
  }

  Future<void> _requestPermissions() async {
    // Only notification permission needed now
    await Permission.notification.request();
  }

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart
      );
    } else {
      await _requestPermissions();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const AuthScreen(),
          transitionsBuilder: (_, anim, __, child) => 
            FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  // ... [Keep build method mostly same, just updating indicator logic] ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ... Background ...
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _AnimatedPageContent(
                        isActive: _currentPage == index,
                        data: _pages[index],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 4,
                            width: _currentPage == index ? 32 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? const Color(0xFF00FFC2) : Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentPage == 2 ? const Color(0xFF00FFC2) : Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        ),
                        child: Text(_currentPage == 2 ? "START" : "NEXT", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ... [Keep _AnimatedPageContent same] ...
class _AnimatedPageContent extends StatelessWidget {
  final bool isActive;
  final Map<String, String> data;

  const _AnimatedPageContent({required this.isActive, required this.data});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch(data['icon']) {
      case 'shield': icon = Icons.shield_outlined; break;
      case 'fingerprint': icon = Icons.fingerprint; break;
      default: icon = Icons.diamond_outlined; break;
    }
    // ... [Rest of widget same as before] ...
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF00FFC2)),
          const SizedBox(height: 48),
          Text(data['title']!, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Text(data['body']!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }
}