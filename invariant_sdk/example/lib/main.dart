import 'package:flutter/material.dart';
import 'package:invariant_sdk/invariant_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Idle';
  String _riskTier = '---';

  @override
  void initState() {
    super.initState();
    // 1. Initialize the SDK
    Invariant.initialize(apiKey: "demo_key_123");
  }

  Future<void> _runVerification() async {
    setState(() => _status = "Verifying...");

    try {
      // 2. Call the SDK
      final result = await Invariant.verifyDevice();

      if (!mounted) return;

      setState(() {
        _status = result.isVerified ? "Verified" : "Failed";
        _riskTier = result.riskTier;
      });
    } catch (e) {
      setState(() {
        _status = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Shadow Filter Test'),
          backgroundColor: const Color(0xFF050505),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Status: $_status', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Risk Tier: $_riskTier', style: const TextStyle(fontSize: 16, fontFamily: 'monospace')),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _runVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FFC2),
                  foregroundColor: Colors.black,
                ),
                child: const Text('VERIFY DEVICE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}