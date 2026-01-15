import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../utils/time_helper.dart';
import '../widgets/genesis_ring.dart'; 
import '../theme_manager.dart';
import '../services/update_service.dart';
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
  bool _isSignaling = false; 
  bool _canTap = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => _fetchData());
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUsernameStatus();
      UpdateService().checkForUpdate(context);
    });
  }

  Future<void> _fetchData() async {
    try {
      final data = await InvariantClient().getIdentityStatus(widget.identityId);
      if (mounted && data != null) {
        setState(() {
          _identityData = data;
          _checkCooldown(data['next_available']);
        });
      }
    } catch (e) { debugPrint("Sync Error: $e"); }
  }

  void _checkCooldown(String? nextAvailable) {
    if (nextAvailable == null) return;
    final target = DateTime.parse(nextAvailable).toLocal();
    final now = DateTime.now();
    setState(() => _canTap = now.isAfter(target));
  }

  Future<void> _handleManualTap() async {
    if (!_canTap || _isSignaling) return;
    
    setState(() => _isSignaling = true);
    HapticFeedback.lightImpact();

    try {
      final client = InvariantClient();
      final nonce = await client.getHeartbeatChallenge();
      
      if (nonce == null) {
        _showSnack("Server Unreachable");
        return;
      }

      String timestamp = TimeHelper.canonicalUtcTimestamp();
      final payload = "${widget.identityId}|$nonce|$timestamp";
      
      final signature = await platform.invokeMethod('signHeartbeat', {'payload': payload});
      final sigBytes = (signature as List<Object?>).map((e) => e as int).toList();

      final success = await client.heartbeat(widget.identityId, sigBytes, nonce, timestamp);
      
      if (success) {
        HapticFeedback.heavyImpact();
        await _fetchData(); 
        _showSnack("IDENTITY VERIFIED");
      } else {
        _showSnack("VERIFICATION FAILED");
      }
    } catch (e) {
      debugPrint("Tap Error: $e");
      _showSnack("HARDWARE ERROR");
    } finally {
      if (mounted) setState(() => _isSignaling = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.spaceGrotesk(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00FFC2),
        duration: const Duration(seconds: 2),
      )
    );
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDark;
    
    final int streak = int.tryParse((_identityData?['streak'] ?? '0').toString()) ?? 0;
    final int continuity = int.tryParse((_identityData?['score'] ?? '0').toString()) ?? 0;
    final String tier = (_identityData?['tier'] ?? 'HARDWARE').toString().toUpperCase();
    final String? username = _identityData?['username'];

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
                  
                  // --- HEADER (Badges Restored) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildStatusBadge(tier, const Color(0xFF00FFC2)),
                          const SizedBox(width: 8),
                          _buildStatusBadge("STREAK: $streak", isDark ? Colors.white54 : Colors.black54),
                        ],
                      ),
                      IconButton(
                        onPressed: theme.toggle,
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.grey),
                      )
                    ],
                  ),
                  
                  if (username != null) 
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("@$username", style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      ),
                    ),

                  const Spacer(),

                  // HERO RING
                  GestureDetector(
                    onTap: _handleManualTap,
                    child: GenesisRing(
                      continuity: continuity,
                      streak: streak,
                      isSignaling: _isSignaling,
                      canTap: _canTap, 
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // ACTION LABEL
                  Text(
                    _canTap ? "TAP TO VERIFY" : "VERIFIED FOR TODAY",
                    style: GoogleFonts.inter(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 2,
                      color: _canTap ? const Color(0xFF00FFC2) : Colors.grey
                    ),
                  ),

                  const Spacer(),

                  // Stats Footer
                  _buildStatsRow(streak, isDark),
                  const SizedBox(height: 24),
                  
                  // Leaderboard Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(myIdentityId: widget.identityId)));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text("VIEW GLOBAL CONSENSUS", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
                      ),
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

  Widget _buildStatsRow(int streak, bool isDark) {
    final color = isDark ? Colors.white : Colors.black;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat("LIFETIME SCORE", "$streak", color), 
        _buildStat("STATUS", _canTap ? "READY" : "SECURE", _canTap ? const Color(0xFF00FFC2) : Colors.grey),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// 🐛 FIXED: Overflow & Keyboard Issues
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

    // FIX: Using SingleChildScrollView + viewInsets padding prevents keyboard overflow
    return Container(
      padding: EdgeInsets.only(
        left: 24, 
        right: 24, 
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24 // Dynamic Padding
      ),
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