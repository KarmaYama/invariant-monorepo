// clients/invariant_mobile/lib/screens/boot_loader.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_client.dart'; 
import '../services/push_service.dart'; // Added
import 'identity_card.dart';
import 'onboarding_screen.dart';

class BootLoader extends StatefulWidget {
  const BootLoader({super.key});

  @override
  State<BootLoader> createState() => _BootLoaderState();
}

class _BootLoaderState extends State<BootLoader> {
  static const platform = MethodChannel('com.invariant.protocol/keystore');
  
  // FIXED: Add androidOptions to prevent some keystore issues
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );
  
  final _client = InvariantClient();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1. Branding Delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // 2. Load Local ID (With Safety Timeout)
    String? id;
    try {
      id = await _storage.read(key: 'identity_id')
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint("⚠️ Storage Read Failed/Timed out: $e");
      // If storage is corrupted, id remains null, logic falls back safely
    }
    
    if (!mounted) return;

    if (id != null) {
      // 2a. Init Push Service (Moved from main.dart)
      _initPushSafe(id);

      // 3. Verify Session
      bool isValid = false;
      try {
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
        _navigateToIdentity(id);
      } else {
        debugPrint("💀 Session Dead ($id). Attempting Resurrection...");
        await _attemptSilentResurrection();
      }
    } else {
      // 5. No Local ID: Check Hardware for existing key
      await _attemptSilentResurrection(fallbackToOnboarding: true);
    }
  }

  Future<void> _initPushSafe(String id) async {
    try {
      await PushService.initialize(id);
    } catch (e) {
      debugPrint("⚠️ Push Init Warning: $e");
    }
  }

  Future<void> _attemptSilentResurrection({bool fallbackToOnboarding = false}) async {
    try {
      // Safety Timeout on Native Channel
      final bool hasKey = await platform.invokeMethod('hasIdentity')
          .timeout(const Duration(seconds: 2));
      
      if (hasKey) {
        debugPrint("🔐 Hardware Key Detected. Resyncing...");
        
        // A. Get Challenge (Reduced Timeout for Boot)
        // If server is down, we don't want to wait 15s here. 3s is enough to know.
        final nonce = await _client.getGenesisChallenge()
            .timeout(const Duration(seconds: 3));
            
        if (nonce == null) throw Exception("Server Unreachable");

        // B. Get Key
        final result = await platform.invokeMethod('recoverIdentity');
        final Map<Object?, Object?> data = result;
        
        final pkBytes = (data['publicKey'] as List<Object?>).map((e) => e as int).toList();
        final chainBytes = (data['attestationChain'] as List<Object?>).map((c) => (c as List<Object?>).map((b) => b as int).toList()).toList();

        // C. Register
        final String? newId = await _client.genesis(pkBytes, chainBytes, nonce);

        if (newId != null) {
          debugPrint("✅ ACCOUNT RESTORED: $newId");
          await _storage.write(key: 'identity_id', value: newId);
          _initPushSafe(newId); // Init push for restored account
          
          if (!mounted) return;
          _navigateToIdentity(newId);
          return;
        }
      }
    } catch (e) {
      debugPrint("❌ Resurrection Failed: $e");
    }

    // Fallback: Wipe and Onboard
    await _storage.deleteAll();
    
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  void _navigateToIdentity(String id) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => IdentityCard(identityId: id)),
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