import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Add google_fonts to pubspec.yaml
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
      "body": "Invariant anchors your identity to the secure silicon in your phone.\n\nNot your face.\nNot your name.\nJust your hardware.",
      "icon": "shield"
    },
    {
      "title": "ZERO\nFRICTION",
      "body": "No daily tasks. No ads. No mining games.\n\nThe protocol runs silently in the background, verifying your existence via cryptographic heartbeats.",
      "icon": "bolt"
    },
    {
      "title": "GENESIS\nCOHORT",
      "body": "You are joining the Testnet.\n\nMaintain 14 days of uptime to permanently etch your device into the protocol's Genesis Block.",
      "icon": "diamond"
    },
  ];

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick(); // Subtle tick feel
    setState(() => _currentPage = index);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600), 
        curve: Curves.easeOutQuart // "Physical" easing
      );
    } else {
      HapticFeedback.mediumImpact();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background: Subtle Gradient Drift
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF00FFC2).withValues(alpha: 0.05), // Faint cyan glow
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      // Animated Page Content
                      return _AnimatedPageContent(
                        isActive: _currentPage == index,
                        data: _pages[index],
                      );
                    },
                  ),
                ),
                
                // Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicators
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 4,
                            width: _currentPage == index ? 32 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index 
                                ? const Color(0xFF00FFC2) 
                                : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      
                      // Button
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? "INITIALIZE" : "NEXT",
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700, 
                            letterSpacing: 1.0
                          ),
                        ),
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

// Staggered Animation Widget
class _AnimatedPageContent extends StatelessWidget {
  final bool isActive;
  final Map<String, String> data;

  const _AnimatedPageContent({required this.isActive, required this.data});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch(data['icon']) {
      case 'shield': icon = Icons.shield_outlined; break;
      case 'bolt': icon = Icons.bolt; break;
      default: icon = Icons.diamond_outlined; break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Icon (Fastest)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: isActive ? 1.0 : 0.0,
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00FFC2).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00FFC2).withValues(alpha: 0.1), blurRadius: 20)
                ]
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF00FFC2)),
            ),
          ),
          const SizedBox(height: 48),
          
          // 2. Title (Medium Delay)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isActive ? 1.0 : 0.0,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut), // Staggered
            child: Transform.translate(
              offset: isActive ? Offset.zero : const Offset(0, 20),
              child: Text(
                data['title']!,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 40,
                  height: 0.9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 3. Body (Slowest)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: isActive ? 1.0 : 0.0,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut), // More Staggered
            child: Transform.translate(
              offset: isActive ? Offset.zero : const Offset(0, 20),
              child: Text(
                data['body']!,
                style: GoogleFonts.inter(
                  color: Colors.white70, // Increased contrast (was white60/54)
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}