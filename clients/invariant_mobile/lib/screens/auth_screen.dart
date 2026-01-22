// clients/invariant_mobile/lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_client.dart';
import 'identity_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('com.invariant.protocol/keystore');
  final LocalAuthentication auth = LocalAuthentication();
  final client = InvariantClient();
  final _storage = const FlutterSecureStorage();
  
  String _status = "TAP SENSOR TO INITIALIZE";
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBiometricInit() async {
    try {
      final bool didAuth = await auth.authenticate(
        localizedReason: 'Generate Identity Key',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      if (didAuth) await _performGenesisOrRecovery();
    } on PlatformException catch (e) {
      setState(() => _status = "AUTH ERROR: ${e.message}");
    }
  }

  Future<void> _performGenesisOrRecovery() async {
    setState(() { _isLoading = true; _status = "CONNECTING..."; });

    try {
      // 1. Get Nonce
      final nonce = await client.getGenesisChallenge();
      if (nonce == null) {
         setState(() => _status = "SERVER UNREACHABLE");
         _isLoading = false;
         return;
      }

      // 2. CHECK FOR EXISTING KEY (Recovery Mode)
      final bool hasKey = await platform.invokeMethod('hasIdentity');
      
      if (hasKey) {
        // Try recovery first
        bool recoverySuccess = await _tryRecover(nonce);
        if (recoverySuccess) return; // Success!

        // If recovery failed (Challenge Mismatch), we MUST rotate the key.
        setState(() => _status = "KEY STALE. ROTATING...");
        await Future.delayed(const Duration(seconds: 1));
      }

      // 3. GENERATE NEW KEY (Destructive Rotation)
      await _generateAndRegister(nonce);

    } catch (e) {
      setState(() => _status = "ERROR: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _tryRecover(String nonce) async {
    setState(() => _status = "RECOVERING HARDWARE KEY...");
    try {
      final data = await platform.invokeMethod('recoverIdentity');
      return await _registerOnServer(data, nonce);
    } catch (e) {
      debugPrint("Recovery failed: $e");
      return false;
    }
  }

  Future<void> _generateAndRegister(String nonce) async {
    setState(() => _status = "FORGING NEW KEY...");
    
    // ⚠️ CRITICAL FIX: Encode Nonce as Bytes for Native Layer
    final nonceBytes = InvariantClient.hexToBytes(nonce);

    final data = await platform.invokeMethod('generateIdentity', {
      'nonce': nonceBytes 
    });
    
    bool success = await _registerOnServer(data, nonce);
    if (!success) {
      setState(() => _status = "SERVER REJECTED PROOF");
    }
  }

  Future<bool> _registerOnServer(Map<Object?, Object?> data, String nonce) async {
      setState(() => _status = "SYNCING WITH NODE...");
      
      final pkBytes = (data['publicKey'] as List<Object?>).map((e) => e as int).toList();
      final chainBytes = (data['attestationChain'] as List<Object?>).map((c) => (c as List<Object?>).map((b) => b as int).toList()).toList();

      final String? identityId = await client.genesis(pkBytes, chainBytes, nonce);
      
      if (identityId != null) {
        await _storage.write(key: 'identity_id', value: identityId);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => IdentityCard(identityId: identityId)),
          );
        }
        return true;
      }
      return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(color: Colors.white54, letterSpacing: 2.0, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 60),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.cyanAccent)
                : ScaleTransition(
                    scale: _scaleAnimation,
                    child: GestureDetector(
                      onTap: _handleBiometricInit,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 2),
                          boxShadow: [BoxShadow(color: Colors.cyan.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 10)],
                        ),
                        child: const Icon(Icons.fingerprint, size: 60, color: Colors.cyanAccent),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}