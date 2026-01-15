// clients/invariant_mobile/lib/screens/boot_loader.dart
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
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    // 1. Check Local Storage (Fast Path)
    String? id = await _storage.read(key: 'identity_id');
    
    if (id != null) {
      if (await _validateSession(id)) return;
    }

    // 2. RECOVERY PATH: Check Hardware Keystore
    // If we lost local storage (app reinstall/clear data) but key remains in TEE
    try {
      final bool hasKey = await platform.invokeMethod('hasIdentity');
      
      if (hasKey) {
        debugPrint("🔐 HARDWARE KEY FOUND. ATTEMPTING SILENT RECOVERY...");
        await _attemptSilentRecovery();
        return;
      }
    } catch (e) {
      debugPrint("Recovery Check Failed: $e");
    }

    // 3. New User Path
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  Future<bool> _validateSession(String id) async {
    final isValid = await _client.checkSession(id);
    if (!mounted) return false;

    if (isValid) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => IdentityCard(identityId: id)),
      );
      return true;
    } else {
      await _storage.deleteAll(); // Wipe invalid session
      return false;
    }
  }

  Future<void> _attemptSilentRecovery() async {
    try {
      // 1. Get a fresh nonce (Protocol Requirement)
      // Even though we aren't generating a new key, we need a nonce 
      // if the server requires it for chain validation (though technically
      // for existing keys we might just need the pubkey, reusing genesis endpoint 
      // is the cleanest path because it handles the "Lookup by PubKey" logic).
      final nonce = await _client.getGenesisChallenge();
      if (nonce == null) throw Exception("Server unreachable");

      // 2. Get Existing Key Materials (Non-Destructive)
      final result = await platform.invokeMethod('recoverIdentity');
      final Map<Object?, Object?> data = result;
      
      final pkBytes = (data['publicKey'] as List<Object?>).map((e) => e as int).toList();
      final chainBytes = (data['attestationChain'] as List<Object?>).map((c) => (c as List<Object?>).map((b) => b as int).toList()).toList();

      // 3. Send to Server
      // The server's `process_genesis` logic checks:
      // "if public_key exists, return existing identity"
      // This acts as our login!
      final String? recoveredId = await _client.genesis(pkBytes, chainBytes, nonce);

      if (recoveredId != null) {
        debugPrint("✅ ACCOUNT RECOVERED: $recoveredId");
        await _storage.write(key: 'identity_id', value: recoveredId);
        
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => IdentityCard(identityId: recoveredId)),
        );
      } else {
        throw Exception("Server rejected recovery");
      }
    } catch (e) {
      debugPrint("❌ Silent Recovery Failed: $e");
      // Fallback to onboarding if recovery fails
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 80, color: Colors.cyanAccent),
            SizedBox(height: 20),
            Text("VERIFYING INTEGRITY...", style: TextStyle(color: Colors.white54, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}