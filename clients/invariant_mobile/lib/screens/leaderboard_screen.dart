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
    HapticFeedback.lightImpact();
    final data = await InvariantClient().fetchLeaderboard();
    if (mounted) {
      setState(() {
        _leaderboardData = data;
        _isLoading = false;
        _hasError = data.isEmpty; // Assume empty is error/offline for now
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find my entry for the sticky footer
    Map<String, dynamic>? myEntry;
    try {
      myEntry = _leaderboardData.firstWhere(
        (e) => e['id'] == widget.myIdentityId,
      );
    } catch (e) {
      // Not in top 50, create a placeholder
      myEntry = null;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // 1. Background Grid
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          SafeArea(
            child: Column(
              children: [
                // 2. Header
                _buildHeader(),

                // 3. List or Loading
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FFC2)))
                    : _hasError 
                      ? _buildErrorState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 16, bottom: 120), // Space for footer
                          itemCount: _leaderboardData.length,
                          itemBuilder: (context, index) {
                            return _AnimatedLeaderboardItem(
                              index: index,
                              data: _leaderboardData[index],
                              isMe: _leaderboardData[index]['id'] == widget.myIdentityId,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // 4. Sticky Footer (Your Rank)
          if (!_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildStickyFooter(myEntry),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.signal_wifi_off, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          Text(
            "NO CONSENSUS",
            style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
            child: const Text("RETRY UPLINK", style: TextStyle(color: Color(0xFF00FFC2))),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GLOBAL CONSENSUS",
                style: GoogleFonts.inter(
                  color: const Color(0xFF00FFC2),
                  fontSize: 10,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Top Nodes",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStickyFooter(Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00FFC2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF00FFC2).withValues(alpha: 0.3)),
              ),
              child: Text(
                data != null ? "#${data['rank']}" : "--",
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF00FFC2),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "YOUR NODE",
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  data != null ? "@${data['handle']}" : "Unranked",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              data != null ? "${data['score']} PTS" : "Syncing...",
              style: GoogleFonts.sourceCodePro(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ANIMATED LIST ITEM ---
class _AnimatedLeaderboardItem extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final bool isMe;

  const _AnimatedLeaderboardItem({required this.index, required this.data, required this.isMe});

  @override
  State<_AnimatedLeaderboardItem> createState() => _AnimatedLeaderboardItemState();
}

class _AnimatedLeaderboardItemState extends State<_AnimatedLeaderboardItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Stagger effect: items appear one by one
    final delay = widget.index * 50; // Fast 50ms cascade
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rank = widget.data['rank'] as int;
    final isTop3 = rank <= 3;

    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFF00FFC2); // Cyan
    } else if (rank == 2) {
      rankColor = Colors.white;
    } else if (rank == 3) {
      rankColor = Colors.white54;
    } else {
      rankColor = Colors.white24;
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: widget.isMe 
                ? const Color(0xFF00FFC2).withValues(alpha: 0.05) 
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.isMe 
                  ? const Color(0xFF00FFC2).withValues(alpha: 0.3) 
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 32,
                child: Text(
                  rank.toString().padLeft(2, '0'),
                  style: GoogleFonts.spaceGrotesk(
                    color: rankColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),

              // Handle & Tier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "@${widget.data['handle']}",
                      style: GoogleFonts.spaceGrotesk(
                        color: widget.isMe ? const Color(0xFF00FFC2) : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isTop3) ...[
                          Icon(Icons.star, size: 10, color: rankColor),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          widget.data['tier'] ?? "STEEL",
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Score
              Text(
                widget.data['score'].toString(),
                style: GoogleFonts.sourceCodePro(
                  color: isTop3 ? Colors.white : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.02)..strokeWidth = 1;
    double step = 40;
    for(double x=0; x<size.width; x+=step) {
      canvas.drawLine(Offset(x,0), Offset(x, size.height), paint);
    }
    for(double y=0; y<size.height; y+=step) {
      canvas.drawLine(Offset(0,y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}