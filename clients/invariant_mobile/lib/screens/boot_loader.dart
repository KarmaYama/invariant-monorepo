// clients/invariant_mobile/lib/screens/boot_loader.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_client.dart'; 
import 'identity_card.dart';
import 'onboarding_screen.dart';

class BootLoader extends StatefulWidget {
  const BootLoader({super.key});

  @override
  State<BootLoader> createState() => _BootLoaderState();
}

class _BootLoaderState extends State<BootLoader> {
  static const platform = MethodChannel('com.invariant.protocol/keystore');
  final _storage = const FlutterSecureStorage();
  final _client = InvariantClient();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1. Minimum Branding Time (1.5s) so the logo isn't a glitch
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // 2. Load Local ID
    String? id = await _storage.read(key: 'identity_id');
    
    if (!mounted) return;

    if (id != null) {
      // 3. Verify Session (With Strict Timeout)
      bool isValid = false;
      try {
        // We give the server 5 seconds to say "Yes, I know this ID".
        // If it times out, we assume we are OFFLINE and let the user in (Fail Open).
        // But if it returns false (404), we know we are wiped.
        isValid = await _client.checkSession(id).timeout(const Duration(seconds: 5));
      } on TimeoutException {
        debugPrint("⚠️ BootNet Timeout: Entering Offline Mode");
        isValid = true; 
      } catch (e) {
        debugPrint("⚠️ BootNet Error: $e");
        isValid = true; // Fail Open
      }

      if (!mounted) return;

      if (isValid) {
        // Happy Path: Go to Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => IdentityCard(identityId: id)),
        );
      } else {
        // 4. DEAD SESSION (Server said 404). 
        // Attempt Silent Resurrection first.
        debugPrint("💀 Session Dead ($id). Attempting Resurrection...");
        await _attemptSilentResurrection();
      }
    } else {
      // 5. No Local ID: Check Hardware for existing key (Reinstall case)
      await _attemptSilentResurrection(fallbackToOnboarding: true);
    }
  }

  /// Tries to recover an account using the Hardware Key if Local Storage is empty/invalid.
  Future<void> _attemptSilentResurrection({bool fallbackToOnboarding = false}) async {
    try {
      final bool hasKey = await platform.invokeMethod('hasIdentity');
      
      if (hasKey) {
        debugPrint("🔐 Hardware Key Detected. Resyncing...");
        
        // A. Get Challenge
        final nonce = await _client.getGenesisChallenge();
        if (nonce == null) throw Exception("Server Unreachable");

        // B. Get Key (Non-Destructive)
        final result = await platform.invokeMethod('recoverIdentity');
        final Map<Object?, Object?> data = result;
        
        final pkBytes = (data['publicKey'] as List<Object?>).map((e) => e as int).toList();
        final chainBytes = (data['attestationChain'] as List<Object?>).map((c) => (c as List<Object?>).map((b) => b as int).toList()).toList();

        // C. Register (Server handles de-duplication)
        final String? newId = await _client.genesis(pkBytes, chainBytes, nonce);

        if (newId != null) {
          debugPrint("✅ ACCOUNT RESTORED: $newId");
          await _storage.write(key: 'identity_id', value: newId);
          
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => IdentityCard(identityId: newId)),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint("❌ Resurrection Failed: $e");
    }

    // Fallback: If resurrection failed or no key exists, go to Onboarding
    // First, wipe any garbage storage to be safe.
    await _storage.deleteAll();
    
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Icon(Icons.shield_outlined, size: 80, color: Colors.cyanAccent),
      ),
    );
  }
}