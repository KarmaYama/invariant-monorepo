// clients/invariant_mobile/lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_client.dart';
import '../services/miner_service.dart';
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
    _controller = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBiometricInit() async {
    final bool canCheck = await auth.canCheckBiometrics;
    if (!canCheck) {
      setState(() => _status = "BIOMETRICS UNAVAILABLE");
      return;
    }

    try {
      final bool didAuth = await auth.authenticate(
        localizedReason: 'Generate Identity Key',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );

      if (didAuth) await _generateIdentity();
    } on PlatformException catch (e) {
      setState(() => _status = "AUTH ERROR: ${e.message}");
    }
  }

  Future<void> _generateIdentity() async {
    setState(() { _isLoading = true; _status = "FETCHING CHALLENGE..."; });

    try {
      // 1. Get Challenge from Server (Anti-Replay)
      final nonce = await client.getGenesisChallenge();
      if (nonce == null) {
         setState(() => _status = "SERVER UNREACHABLE");
         _isLoading = false;
         return;
      }

      setState(() => _status = "FORGING HARDWARE KEY...");

      // 2. Generate Key bound to this Nonce
      final result = await platform.invokeMethod('generateIdentity', {
        'nonce': nonce 
      });

      final Map<Object?, Object?> data = result;
      final pkBytes = (data['publicKey'] as List<Object?>).map((e) => e as int).toList();
      final chainBytes = (data['attestationChain'] as List<Object?>).map((c) => (c as List<Object?>).map((b) => b as int).toList()).toList();

      setState(() => _status = "SUBMITTING PROOF...");

      // 3. Submit for Verification
      final String? identityId = await client.genesis(pkBytes, chainBytes, nonce);
      
      if (identityId != null) {
        await _storage.write(key: 'identity_id', value: identityId);
        MinerService.startMining(); 

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => IdentityCard(identityId: identityId)),
          );
        }
      } else {
        setState(() => _status = "SERVER REJECTED ATTESTATION");
      }
    } on PlatformException catch (e) {
      setState(() => _status = "HARDWARE ERROR: ${e.message}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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