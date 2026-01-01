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

  // Added "SYSTEM OVERRIDE" as page 3 (index 3)
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
    {
      "title": "SYSTEM\nOVERRIDE",
      "body": "Android kills background apps to save battery.\n\nTo survive the 14-day test, you must grant Unrestricted Battery and Notification access.",
      "icon": "warning"
    },
  ];

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = index);
  }

  Future<void> _requestPermissions() async {
    // 1. Notifications (for Reaper Warnings)
    await Permission.notification.request();

    // 2. Battery Optimization (The Killer)
    // We open the system dialog. The user must click "Allow".
    var status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart
      );
    } else {
      // Perform final permission check before routing
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF00FFC2).withValues(alpha: 0.05),
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
                      return _AnimatedPageContent(
                        isActive: _currentPage == index,
                        data: _pages[index],
                        // Show permission buttons only on the last page
                        showActions: index == 3, 
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
                      
                      // Action Button
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentPage == 3 
                              ? const Color(0xFF00FFC2) // Highlight on last step
                              : Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? "GRANT & START" : "NEXT",
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

class _AnimatedPageContent extends StatelessWidget {
  final bool isActive;
  final Map<String, String> data;
  final bool showActions;

  const _AnimatedPageContent({
    required this.isActive, 
    required this.data, 
    this.showActions = false
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor = const Color(0xFF00FFC2);
    
    switch(data['icon']) {
      case 'shield': icon = Icons.shield_outlined; break;
      case 'bolt': icon = Icons.bolt; break;
      case 'warning': 
        icon = Icons.power_off; 
        iconColor = Colors.orangeAccent; // Visual danger
        break;
      default: icon = Icons.diamond_outlined; break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: isActive ? 1.0 : 0.0,
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: iconColor.withValues(alpha: 0.1), blurRadius: 20)
                ]
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
          ),
          const SizedBox(height: 48),
          
          // Title
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isActive ? 1.0 : 0.0,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
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
          
          // Body
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: isActive ? 1.0 : 0.0,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
            child: Transform.translate(
              offset: isActive ? Offset.zero : const Offset(0, 20),
              child: Text(
                data['body']!,
                style: GoogleFonts.inter(
                  color: Colors.white70,
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