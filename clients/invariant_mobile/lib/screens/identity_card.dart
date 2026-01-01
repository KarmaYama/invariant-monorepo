import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../utils/time_helper.dart';
import '../utils/genesis_logic.dart'; // IMPORT THIS
import '../widgets/genesis_ring.dart';
import '../theme_manager.dart';
import 'leaderboard_screen.dart';

class IdentityCard extends StatefulWidget {
  final String identityId;
  const IdentityCard({super.key, required this.identityId});

  @override
  State<IdentityCard> createState() => _IdentityCardState();
}

class _IdentityCardState extends State<IdentityCard> {
  static const platform = MethodChannel('com.invariant.protocol/keystore');

  Map<String, dynamic>? _identityData;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  DateTime? _targetTime; 
  String _nextPulse = "SYNCING...";
  bool _isSignaling = false; 
  bool _isBatteryOptimized = true;

  @override
  void initState() {
    super.initState();
    _checkSystemHealth();
    _fetchData();
    _startCountdown();
    // Refresh every 30s to keep sync
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchData());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUsernameStatus());
  }

  Future<void> _checkSystemHealth() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (mounted) setState(() => _isBatteryOptimized = !status.isGranted);
  }

  Future<void> _fetchData() async {
    try {
      final data = await InvariantClient().getIdentityStatus(widget.identityId);
      if (mounted && data != null) {
        setState(() {
          _identityData = data;
          if (data['next_available'] != null) {
            _targetTime = DateTime.parse(data['next_available']).toLocal();
          }
        });
      }
    } catch (e) { debugPrint("Sync Error: $e"); }
  }

  Future<void> _checkUsernameStatus() async {
    if (_identityData == null) await _fetchData();
    if (_identityData != null && _identityData!['username'] == null) {
      if (mounted) _showUsernameSheet();
    }
  }

  void _showUsernameSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _UsernameInputForm(
          identityId: widget.identityId,
          onSuccess: () { Navigator.pop(context); _fetchData(); },
        ),
      ),
    );
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_targetTime == null) return;
      final now = DateTime.now();
      final remaining = _targetTime!.difference(now);
      if (remaining.isNegative) {
        if (!_isSignaling) _triggerAutoHeartbeat();
        if (mounted) setState(() => _nextPulse = _isSignaling ? "SIGNALING..." : "READY");
      } else {
        final formatted = "${remaining.inHours}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}";
        if (mounted) setState(() => _nextPulse = formatted);
      }
    });
  }

  Future<void> _triggerAutoHeartbeat() async {
    if (_isSignaling) return;
    setState(() => _isSignaling = true);
    try {
      String timestamp = TimeHelper.canonicalUtcTimestamp();
      final payload = "${widget.identityId}|$timestamp";
      final signature = await platform.invokeMethod('signHeartbeat', {'payload': payload});
      final sigBytes = (signature as List<Object?>).map((e) => e as int).toList();
      final success = await InvariantClient().heartbeat(widget.identityId, sigBytes, timestamp);
      if (success) {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(seconds: 2));
        await _fetchData();
      }
    } catch (e) { debugPrint("Heartbeat Error: $e"); }
    finally { if (mounted) setState(() => _isSignaling = false); }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDark;
    
    final int streak = int.tryParse((_identityData?['streak'] ?? '0').toString()) ?? 0;
    final bool isGenesis = (_identityData?['is_genesis_eligible'] ?? false) as bool;
    final String? username = _identityData?['username'];

    // 1. USE GENESIS LOGIC FOR TITLES
    final String tierTitle = GenesisLogic.getTitle(streak); 

    final subTextColor = isDark ? Colors.white38 : Colors.black38;
    final cardBorderColor = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter(isDark: isDark))),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // TOP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildStatusBadge(isGenesis ? "GENESIS" : "NODE", isGenesis ? Colors.amber : const Color(0xFF00FFC2)),
                          const SizedBox(width: 8),
                          // 2. DISPLAY DYNAMIC TITLE
                          _buildStatusBadge(tierTitle, subTextColor),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          theme.toggle();
                        },
                        icon: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, 
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  if (username != null) ...[
                    const SizedBox(height: 20),
                    Text("@$username", 
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : Colors.black87,
                      )),
                  ],

                  const Spacer(),
                  // 3. PASS 84 AS TOTAL CYCLES
                  GenesisRing(
                    streak: streak, 
                    totalCycles: GenesisLogic.totalCycles, // 84
                    isSignaling: _isSignaling
                  ),
                  const Spacer(),

                  if (_isBatteryOptimized)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        "⚠️ SYSTEM RESTRICTED: DISABLE BATTERY OPT.",
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat("CONTINUITY", "$streak", isDark),
                        Container(width: 1, height: 30, color: cardBorderColor),
                        _buildStat("PULSE", _nextPulse, isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildTelemetryButton(isDark, cardBorderColor),
                  const Spacer(),
                  
                  Opacity(
                    opacity: 0.3,
                    child: Text(
                      "NODE_ID: ${widget.identityId.substring(0, 16).toUpperCase()}...", 
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 10, 
                        color: isDark ? Colors.white : Colors.black,
                      )
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Keep existing _buildTelemetryButton, _buildStatusBadge, _buildStat, _UsernameInputForm, _GridPainter)
  Widget _buildTelemetryButton(bool isDark, Color borderColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(myIdentityId: widget.identityId)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(4),
          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public, size: 14, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 8),
            Text(
              "VIEW GLOBAL CONSENSUS",
              style: GoogleFonts.inter(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildStat(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }
}

class _UsernameInputForm extends StatefulWidget {
  final String identityId;
  final VoidCallback onSuccess;
  const _UsernameInputForm({required this.identityId, required this.onSuccess});

  @override
  State<_UsernameInputForm> createState() => _UsernameInputFormState();
}

class _UsernameInputFormState extends State<_UsernameInputForm> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("IDENTITY CLAIM", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
          TextField(controller: _controller, decoration: const InputDecoration(hintText: "Enter Username")),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : () async {
              setState(() => _loading = true);
              final success = await InvariantClient().claimUsername(widget.identityId, _controller.text);
              if (success) widget.onSuccess();
              if (mounted) setState(() => _loading = false);
            }, 
            child: _loading ? const CircularProgressIndicator() : const Text("Claim")
          )
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for(double x=0; x<size.width; x+=40) { canvas.drawLine(Offset(x,0), Offset(x, size.height), paint); }
    for(double y=0; y<size.height; y+=40) { canvas.drawLine(Offset(0,y), Offset(size.width, y), paint); }
  }
  @override
  bool shouldRepaint(covariant _GridPainter old) => old.isDark != isDark;
}