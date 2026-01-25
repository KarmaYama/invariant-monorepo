import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_client.dart';
import 'identity_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  // ⚡ NATIVE CHANNEL ONLY
  // We no longer use 'local_auth' here. The native plugin handles the UI.
  static const platform = MethodChannel('com.invariant.protocol/keystore');
  
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
      vsync: this, 
      duration: const Duration(seconds: 2)
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ⚡ TRIGGER POINT
  // We skip Flutter-side auth entirely. We go straight to the native layer.
  Future<void> _handleBiometricInit() async {
    await _performGenesisOrRecovery();
  }

  Future<void> _performGenesisOrRecovery() async {
    setState(() { _isLoading = true; _status = "CONNECTING..."; });

    try {
      // 1. Get Nonce (Network Check First)
      final nonce = await client.getGenesisChallenge();
      if (nonce == null) {
         setState(() => _status = "SERVER UNREACHABLE");
         _isLoading = false;
         return;
      }

      // 2. CHECK FOR EXISTING KEY (Native)
      final bool hasKey = await platform.invokeMethod('hasIdentity');
      
      if (hasKey) {
        // Try recovery logic
        bool recoverySuccess = await _tryRecover(nonce);
        if (recoverySuccess) return; 

        // If recovery fails, we assume key is stale/broken
        setState(() => _status = "KEY STALE. ROTATING...");
        await Future.delayed(const Duration(seconds: 1));
      }

      // 3. GENERATE NEW KEY (Native UI Triggered Here)
      // This call will open the Android BiometricPrompt.
      await _generateAndRegister(nonce);

    } on PlatformException catch (e) {
      // Handle User Cancellation or Lockout
      if (e.code == "AUTH_ERROR") {
        setState(() => _status = "AUTH CANCELED");
      } else if (e.code == "DEVICE_INSECURE") {
        setState(() => _status = "SET LOCK SCREEN");
      } else {
        setState(() => _status = "HARDWARE ERROR: ${e.message}");
      }
    } catch (e) {
      setState(() => _status = "ERROR: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _tryRecover(String nonce) async {
    setState(() => _status = "RECOVERING HARDWARE KEY...");
    try {
      // Does not require Auth for Public Key retrieval
      final data = await platform.invokeMethod('recoverIdentity');
      return await _registerOnServer(data, nonce);
    } catch (e) {
      debugPrint("Recovery failed: $e");
      return false;
    }
  }

  Future<void> _generateAndRegister(String nonce) async {
    setState(() => _status = "WAITING FOR BIOMETRICS...");
    
    // Convert Nonce to Bytes
    final nonceBytes = InvariantClient.hexToBytes(nonce);

    // ⚡ BLOCKS HERE UNTIL USER AUTHENTICATES NATIVELY
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