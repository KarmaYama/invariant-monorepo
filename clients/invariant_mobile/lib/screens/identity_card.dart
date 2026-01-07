import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../utils/time_helper.dart';
import '../utils/genesis_logic.dart'; 
import '../widgets/genesis_ring.dart'; 
import 'leaderboard_screen.dart';
import '../theme_manager.dart';
import '../services/update_service.dart';

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
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchData());
    
    // Check for updates after the UI builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUsernameStatus();
      UpdateService().checkForUpdate(context);
    });
  }

  Future<void> _checkSystemHealth() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (mounted) setState(() => _isBatteryOptimized = !status.isGranted);
  }

  Future<void> _requestBatteryFix() async {
    await Permission.ignoreBatteryOptimizations.request();
    await _checkSystemHealth();
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
    if (!mounted) return;

    if (_identityData != null && _identityData!['username'] == null) {
      _showUsernameSheet();
    }
  }

  void _showUsernameSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      isDismissible: false,
      backgroundColor: Colors.transparent, 
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom
        ),
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
    HapticFeedback.lightImpact();
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
    } catch (e) { debugPrint("HB Error: $e"); }
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
    
    // ⚡ DECOUPLED METRICS:
    // 1. Streak = Volatile (Can reset to 1)
    final int streak = int.tryParse((_identityData?['streak'] ?? '0').toString()) ?? 0;
    // 2. Continuity/Score = Permanent (Lifetime Stability)
    final int continuity = int.tryParse((_identityData?['score'] ?? '0').toString()) ?? 0;
    
    // TIER LOGIC (Uses Streak for daily titles)
    final String timeTier = GenesisLogic.getTitle(streak); 
    
    final String hardwareTier = (_identityData?['tier'] ?? 'HARDWARE').toString().toUpperCase();
    final String? username = _identityData?['username'];

    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white38 : Colors.black38;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03);
    final cardBorder = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter(isDark: isDark))),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: IntrinsicHeight( 
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            // --- HEADER ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    _buildStatusBadge(hardwareTier, const Color(0xFF00FFC2)),
                                    const SizedBox(width: 8),
                                    _buildStatusBadge(timeTier, subTextColor),
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
                                    size: 20,
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
                                  letterSpacing: 1,
                                  color: textColor,
                                )),
                            ],

                            const Spacer(),

                            // --- HERO RING ---
                            // Pass both metrics:
                            // continuity -> fills the ring (Stability)
                            // streak -> passed for potential flair
                            GenesisRing(
                              continuity: continuity, 
                              streak: streak, 
                              isSignaling: _isSignaling
                            ),

                            const Spacer(),

                            // --- GLASS STATS GRID ---
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  // Show the VOLATILE streak here
                                  _buildStat("CURRENT STREAK", "$streak", textColor, subTextColor),
                                  Container(width: 1, height: 30, color: cardBorder),
                                  // Show the Mining Timer
                                  _buildStat("PULSE", _nextPulse, textColor, subTextColor),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // --- BATTERY WARNING ---
                            if (_isBatteryOptimized)
                              GestureDetector(
                                onTap: _requestBatteryFix,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "SYSTEM RESTRICTION DETECTED\nTap to enable background mining.",
                                          style: GoogleFonts.inter(
                                            color: Colors.redAccent, 
                                            fontSize: 11, 
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // --- LEADERBOARD BUTTON ---
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 600),
                                    pageBuilder: (_, __, ___) => LeaderboardScreen(myIdentityId: widget.identityId),
                                    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: cardBorder),
                                  borderRadius: BorderRadius.circular(4),
                                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.public, size: 14, color: isDark ? Colors.white70 : Colors.black54),
                                    const SizedBox(width: 8),
                                    Text(
                                      "VIEW GLOBAL CONSENSUS",
                                      style: GoogleFonts.inter(
                                        color: isDark ? Colors.white70 : Colors.black54,
                                        fontSize: 11,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(),
                            
                            // Footer ID
                            Opacity(
                              opacity: 0.3,
                              child: Text(
                                "NODE_ID: ${widget.identityId.substring(0, 16).toUpperCase()}...", 
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 10, 
                                  letterSpacing: 1,
                                  color: textColor,
                                )
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1)),
    );
  }

  Widget _buildStat(String label, String value, Color textColor, Color subColor) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: subColor, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
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
  bool _isLoading = false;
  bool _isValid = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("IDENTIFICATION", style: GoogleFonts.spaceGrotesk(color: const Color(0xFF00FFC2), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Text("Enter callsign.", style: GoogleFonts.spaceGrotesk(color: text, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              style: GoogleFonts.spaceGrotesk(color: text, fontSize: 20, fontWeight: FontWeight.bold),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(15),
                TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(text: newValue.text.toLowerCase())),
              ],
              onChanged: (value) => setState(() => _isValid = value.length >= 3),
              decoration: InputDecoration(
                prefixText: "> @ ",
                prefixStyle: GoogleFonts.spaceGrotesk(color: const Color(0xFF00FFC2), fontSize: 20),
                hintText: "satoshi",
                hintStyle: GoogleFonts.spaceGrotesk(color: text.withValues(alpha: 0.2)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: text.withValues(alpha: 0.2))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FFC2))),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isValid && !_isLoading) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FFC2),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                  : Text("ESTABLISH LINK", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    final success = await InvariantClient().claimUsername(widget.identityId, _controller.text);
    if (success) {
      HapticFeedback.heavyImpact();
      widget.onSuccess();
    } else {
      HapticFeedback.vibrate();
      setState(() => _isLoading = false);
    }
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