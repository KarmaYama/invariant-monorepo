// invariant_sdk/example/lib/main.dart

import 'package:flutter/material.dart';
import 'package:invariant_sdk/invariant_sdk.dart';
import 'dart:async';

void main() {
  runApp(const ShadowTestApp());
}

class ShadowTestApp extends StatelessWidget {
  const ShadowTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: const Color(0xFF00FFC2),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFC2),
          secondary: Colors.white,
          surface: Color(0xFF0A0A0A),
        ),
      ),
      home: const TerminalScreen(),
    );
  }
}

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> with SingleTickerProviderStateMixin {
  String _riskTier = 'WAITING_FOR_SIGNAL';
  bool _isVerified = false;
  bool _isLoading = false;
  final List<String> _logs = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _log("SYSTEM_BOOT", "Initializing Invariant SDK...");
    // Pilot initialization using the demo identifier
    Invariant.initialize(apiKey: "pilot_v1_evaluation");
    _log("SDK", "Ready. Hardware handshake available.");
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _log(String tag, String message) {
    setState(() {
      _logs.add("[${DateTime.now().toIso8601String().substring(11, 19)}] $tag: $message");
    });
  }

  Future<void> _runVerification() async {
    setState(() {
      _isLoading = true;
      _logs.clear(); 
      _riskTier = "ANALYZING...";
    });
    
    _log("NET", "Requesting Fresh Nonce...");
    _log("TEE", "Invoking Hardware Secure Enclave...");
    
    try {
      final startTime = DateTime.now();
      final result = await Invariant.verifyDevice();
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      if (!mounted) return;

      if (result.isVerified) {
        _log("SUCCESS", "Handshake Verified (${duration}ms)");
        _log("RISK_ENGINE", "Tier: ${result.riskTier} (Score: ${result.riskScore})");
      } else {
        _log("REJECTED", "Verification Failed: ${result.riskTier}");
      }

      setState(() {
        _isVerified = result.isVerified;
        _riskTier = result.riskTier;
        _isLoading = false;
      });

    } catch (e) {
      _log("CRITICAL", e.toString());
      setState(() {
        _riskTier = "FAULT";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _isLoading 
        ? Colors.white 
        : (_isVerified ? const Color(0xFF00FFC2) : Colors.redAccent);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "INVARIANT // SHADOW FILTER",
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 2.0,
                      color: Colors.white54,
                    ),
                  ),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 10)]
                    ),
                  )
                ],
              ),
              
              const Spacer(),

              // --- VISUAL INDICATOR ---
              Center(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: statusColor.withValues(alpha: _isLoading ? _pulseController.value : 0.5),
                              width: 2
                            ),
                          ),
                          child: Icon(
                            _isVerified ? Icons.security : Icons.lock_open_rounded, 
                            size: 64, 
                            color: statusColor
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _riskTier,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "HARDWARE CLASSIFICATION",
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.white38,
                        letterSpacing: 3.0,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // --- REAL-TIME LOGS ---
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  border: Border.all(color: Colors.white10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  reverse: true,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[(_logs.length - 1) - index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: log.contains("SUCCESS") ? const Color(0xFF00FFC2) : 
                                 log.contains("REJECTED") || log.contains("ERROR") ? Colors.redAccent : Colors.white60,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // --- TRIGGER ---
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _runVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFC2),
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text(
                        "RUN ATTESTATION",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
