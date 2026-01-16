// clients/invariant_mobile/lib/screens/identity_card.dart
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
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => _fetchData()); // Slower refresh = calmer
    
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
    HapticFeedback.heavyImpact(); // Heavy thud = commitment

    try {
      final client = InvariantClient();
      final nonce = await client.getHeartbeatChallenge();
      
      if (nonce == null) {
        _showSnack("UPLINK FAILURE");
        return;
      }

      String timestamp = TimeHelper.canonicalUtcTimestamp();
      final payload = "${widget.identityId}|$nonce|$timestamp";
      
      final signature = await platform.invokeMethod('signHeartbeat', {'payload': payload});
      final sigBytes = (signature as List<Object?>).map((e) => e as int).toList();

      final success = await client.heartbeat(widget.identityId, sigBytes, nonce, timestamp);
      
      if (success) {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 200));
        HapticFeedback.heavyImpact(); // Double thud for confirmation
        await _fetchData(); 
      } else {
        _showSnack("VERIFICATION REJECTED");
      }
    } catch (e) {
      debugPrint("Tap Error: $e");
      _showSnack("HARDWARE FAULT");
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

  // --- THE SYSTEM MANIFEST (Hidden Surface) ---
  void _showManifest() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(0))),
      builder: (context) => _SystemManifestSheet(data: _identityData, id: widget.identityId),
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
    // Keep username sheet same as before
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
    final int cycles = int.tryParse((_identityData?['score'] ?? '0').toString()) ?? 0;
    final String tier = (_identityData?['tier'] ?? 'HARDWARE').toString().toUpperCase();

    // STATUS LOGIC
    String statusText = "SYNCING...";
    Color statusColor = Colors.grey;
    if (_identityData != null) {
      if (_canTap) {
        statusText = "STATUS: PENDING";
        statusColor = const Color(0xFFFFD700); // Amber
      } else {
        statusText = "STATUS: SECURE";
        statusColor = const Color(0xFF00FFC2); // Cyan
      }
    }

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
                  
                  // --- HEADER: Minimal ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       // Tier is now small and technical, not a badge of honor
                      Text(
                        "CLASS: $tier",
                        style: GoogleFonts.inter(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.grey, 
                          letterSpacing: 1.5
                        ),
                      ),
                      IconButton(
                        onPressed: theme.toggle,
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.grey, size: 20),
                      )
                    ],
                  ),
                  
                  const Spacer(),

                  // --- CENTER OF GRAVITY: The Ring ---
                  GestureDetector(
                    onTap: _handleManualTap,
                    onLongPress: _showManifest, // 🛡️ HIDDEN ACCESS
                    child: GenesisRing(
                      continuity: cycles,
                      streak: streak,
                      isSignaling: _isSignaling,
                      canTap: _canTap, 
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // --- PRIMARY SIGNAL: Status ---
                  Text(
                    statusText,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: -1,
                      color: statusColor
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _canTap ? "PRESENCE UNCONFIRMED" : "CYCLE COMPLETE",
                    style: GoogleFonts.inter(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 3,
                      color: Colors.grey
                    ),
                  ),

                  const Spacer(),

                  // --- FOOTER: Ledger Style ---
                  _buildLedgerRow("CYCLE", "$cycles", isDark),
                  const SizedBox(height: 12),
                  _buildLedgerRow("STREAK", "$streak", isDark),
                  const SizedBox(height: 32),
                  
                  // Leaderboard Link (Subtle)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(myIdentityId: widget.identityId)));
                    },
                    child: Text(
                      "VIEW NETWORK CONSENSUS >", 
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.5)
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

  Widget _buildLedgerRow(String label, String value, bool isDark) {
    final color = isDark ? Colors.white : Colors.black;
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// --- SYSTEM MANIFEST SHEET (Read-Only) ---
class _SystemManifestSheet extends StatelessWidget {
  final Map<String, dynamic>? data;
  final String id;
  
  const _SystemManifestSheet({required this.data, required this.id});

  @override
  Widget build(BuildContext context) {
    // If we have data, parse it. If not, placeholders.
    final net = data?['network'] ?? 'UNKNOWN';
    final created = data?['created_at']?.toString().substring(0, 10) ?? '----';
    final hw = data?['tier'] ?? 'UNKNOWN';

    return Container(
      padding: const EdgeInsets.all(32),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SYSTEM MANIFEST", style: GoogleFonts.inter(color: const Color(0xFF00FFC2), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
              const Icon(Icons.qr_code_2, color: Colors.grey, size: 20)
            ],
          ),
          const SizedBox(height: 32),
          
          _manifestItem("IDENTITY_ID", id),
          _manifestItem("NETWORK", net.toString().toUpperCase()),
          _manifestItem("BINDING_TYPE", "HARDWARE_BACKED ($hw)"),
          _manifestItem("ATTESTATION", "VERIFIED"),
          _manifestItem("CREATED", created),
          _manifestItem("POLICY", "DAILY_CONFIRMATION_REQUIRED"),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () { Navigator.pop(context); },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
              ),
              child: Text("CLOSE INSPECTION", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _manifestItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label, 
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)
            )
          ),
          Expanded(
            child: Text(
              value, 
              style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            )
          ),
        ],
      ),
    );
  }
}

// ... [Keep _UsernameInputForm and _GridPainter as they were] ...
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
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24 
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