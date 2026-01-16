// clients/invariant_mobile/lib/widgets/genesis_ring.dart
import 'dart:math';
import 'package:flutter/material.dart';

class GenesisRing extends StatefulWidget {
  final int continuity;
  final int streak;
  final bool isSignaling;
  final bool canTap; 

  const GenesisRing({
    super.key, 
    required this.continuity, 
    required this.streak,
    this.isSignaling = false,
    this.canTap = false,
  });

  @override
  State<GenesisRing> createState() => _GenesisRingState();
}

class _GenesisRingState extends State<GenesisRing> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Very slow rotation = Stability
    _rotationController = AnimationController(
      vsync: this, duration: const Duration(seconds: 60) 
    )..repeat();

    // Subtle breathing only when action is required
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4), 
      lowerBound: 0.0, upperBound: 1.0
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Green/Cyan for Secure (Done), Amber for Pending (Action Required)
    final accent = widget.canTap ? const Color(0xFFFFD700) : const Color(0xFF00FFC2); 
    final double progress = (widget.continuity / 84).clamp(0.0, 1.0);

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Halo (Visible only when action needed)
          if (widget.canTap)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 180 + (_pulseController.value * 20),
                  height: 180 + (_pulseController.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.15), 
                        blurRadius: 40,
                        spreadRadius: 2
                      )
                    ],
                  ),
                );
              }
            ),

          // 2. HUD (Technical Lines)
          RotationTransition(
            turns: _rotationController,
            child: CustomPaint(
              size: const Size(300, 300), 
              painter: _HudPainter(color: isDark ? Colors.white10 : Colors.black12)
            ),
          ),

          // 3. Track (Progress)
          CustomPaint(
            size: const Size(240, 240),
            painter: _TrackPainter(
              progress: progress, 
              color: accent, 
              isDark: isDark, 
              isSignaling: widget.isSignaling,
              pulse: widget.canTap ? _pulseController.value : 0.0 // Only pulse if pending
            ),
          ),

          // 4. Center Icon (State)
          Icon(
            widget.canTap ? Icons.fingerprint : Icons.shield_outlined,
            size: 44,
            color: widget.isSignaling ? Colors.white : accent
          ),
        ],
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;
  final bool isSignaling;
  final double pulse;

  _TrackPainter({
    required this.progress, 
    required this.color, 
    required this.isDark, 
    required this.isSignaling,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background Track (Thin)
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    canvas.drawCircle(center, radius, bgPaint);

    // Active Track
    // If signaling, it constricts (visual feedback)
    final activeWidth = isSignaling ? 8.0 : (4.0 + (pulse * 2));
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = activeWidth
      ..strokeCap = StrokeCap.butt // Mechanical feel
      ..color = color.withValues(alpha: isSignaling ? 1.0 : 0.8);

    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _TrackPainter old) => true;
}

class _HudPainter extends CustomPainter {
  final Color color;
  _HudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < 12; i++) { // Fewer lines, cleaner
      final angle = (i * 30) * pi / 180;
      final p1 = Offset(center.dx + (radius - 10) * cos(angle), center.dy + (radius - 10) * sin(angle));
      final p2 = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(p1, p2, paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter old) => false;
}