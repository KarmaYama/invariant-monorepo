// clients/invariant_mobile/lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_client.dart';

class LeaderboardScreen extends StatefulWidget {
  final String myIdentityId;
  const LeaderboardScreen({super.key, required this.myIdentityId});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await InvariantClient().fetchLeaderboard();
      if (mounted) {
        setState(() {
          _leaderboardData = data;
          _isLoading = false;
          _hasError = data.isEmpty;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Ledger Style)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "NETWORK CONSENSUS", 
                        style: GoogleFonts.inter(
                          color: Colors.grey, 
                          fontSize: 10, 
                          letterSpacing: 2, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Stability Ledger", 
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white, 
                          fontSize: 24, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20)
                    ),
                  )
                ],
              ),
            ),
            
            // 2. Technical Divider
            const Divider(color: Colors.white10, height: 1),

            // 3. Data List
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.white12, strokeWidth: 2))
                : _hasError 
                  ? _buildErrorState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _leaderboardData.length,
                      itemBuilder: (context, index) {
                        return _buildLedgerRow(_leaderboardData[index]);
                      },
                    ),
            ),
            
            // 4. Footer Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10))
              ),
              child: Text(
                _isLoading ? "SYNCING NODE LIST..." : "TOTAL NODES: ${_leaderboardData.length}",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey.shade800, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerRow(Map<String, dynamic> data) {
    final isMe = data['id'] == widget.myIdentityId;
    
    return Container(
      decoration: BoxDecoration(
        // Subtle highlight for self
        color: isMe ? const Color(0xFF00FFC2).withValues(alpha: 0.05) : null,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.02)))
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 50,
            child: Text(
              "#${data['rank'].toString().padLeft(2, '0')}", 
              style: GoogleFonts.sourceCodePro(
                color: isMe ? const Color(0xFF00FFC2) : Colors.grey.shade700, 
                fontSize: 14,
                fontWeight: FontWeight.bold
              )
            )
          ),
          
          // Handle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "@${data['handle']}", 
                  style: GoogleFonts.inter(
                    color: isMe ? const Color(0xFF00FFC2) : Colors.white, 
                    fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14
                  )
                ),
                if (isMe)
                  Text(
                    "YOUR NODE",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00FFC2).withValues(alpha: 0.5),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0
                    ),
                  )
              ],
            )
          ),
          
          // Score (Cycles)
          Text(
            "${data['score']} Cycles", 
            style: GoogleFonts.sourceCodePro(
              color: isMe ? Colors.white : Colors.white38, 
              fontSize: 12
            )
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off, color: Colors.white12, size: 48),
          const SizedBox(height: 16),
          Text(
            "NO CONSENSUS REACHED",
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _loadData,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              foregroundColor: Colors.white
            ),
            child: Text("RETRY UPLINK", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}