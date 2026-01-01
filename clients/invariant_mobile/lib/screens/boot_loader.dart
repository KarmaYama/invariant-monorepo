import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/miner_service.dart';
import '../api_client.dart'; 
import 'identity_card.dart';
import 'onboarding_screen.dart'; // <--- IMPORT THIS

class BootLoader extends StatefulWidget {
  const BootLoader({super.key});

  @override
  State<BootLoader> createState() => _BootLoaderState();
}

class _BootLoaderState extends State<BootLoader> {
  final _storage = const FlutterSecureStorage();
  final _client = InvariantClient();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    // Artificial delay to show the logo for a split second (feels more pro)
    await Future.delayed(const Duration(milliseconds: 1500));

    String? id = await _storage.read(key: 'identity_id');
    
    if (!mounted) return;

    if (id != null) {
      // 1. Verify Session with Server
      final isValid = await _client.checkSession(id);

      if (!mounted) return;

      if (isValid) {
        // Happy Path -> Dashboard
        MinerService.startMining();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => IdentityCard(identityId: id)),
        );
      } else {
        // Zombie Path -> Wipe and Restart
        debugPrint("⚠️ Zombie Session Detected. Wiping local credentials.");
        await _storage.deleteAll();
        
        if (!mounted) return;

        // Route to Onboarding instead of Auth
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()), 
        );
      }
    } else {
      // New User -> Onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // A simple black screen with a logo while loading looks better than a spinner
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Icon(Icons.shield_outlined, size: 80, color: Colors.cyanAccent),
      ),
    );
  }
}