import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GenesisRing extends StatefulWidget {
  final int continuity; // Lifetime Score (The Ring Progress)
  final int streak;     // Current Streak (Visual flair/Unlock status)
  
  // 14 Days * 6 Cycles = 84 Total Cycles for Genesis
  final int totalCycles = 84; 
  
  final bool isSignaling;

  const GenesisRing({
    super.key, 
    required this.continuity, 
    required this.streak,
    this.isSignaling = false
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
    // 1. Slow HUD Rotation (Ambient)
    _rotationController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 20)
    )..repeat();

    // 2. "Breathing" Physics (Idle Pulse)
    _pulseController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 3), 
      lowerBound: 0.0, 
      upperBound: 1.0
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
    const accent = Color(0xFF00FFC2);
    
    // ⚡ LOGIC FIX: Progress is based on CONTINUITY (Lifetime Score).
    // This ensures the ring is "Stable" and doesn't crash to 0 on a missed cycle.
    final double progress = (widget.continuity / widget.totalCycles).clamp(0.0, 1.0);

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ambient Depth Halo
          Container(
            width: 180, 
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isDark ? 0.08 : 0.04), 
                  blurRadius: 50, 
                  spreadRadius: 10
                )
              ],
            ),
          ),

          // 2. Rotating Technical HUD
          RotationTransition(
            turns: _rotationController,
            child: CustomPaint(
              size: const Size(300, 300), 
              painter: _HudPainter(color: isDark ? Colors.white12 : Colors.black12)
            ),
          ),

          // 3. Pulsing Progress Track (The visual representation of Stability)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(seconds: 2),
                curve: Curves.easeOutExpo,
                builder: (context, value, _) {
                  return CustomPaint(
                    size: const Size(240, 240),
                    painter: _TrackPainter(
                      progress: value, 
                      color: accent, 
                      isDark: isDark, 
                      isSignaling: widget.isSignaling, 
                      pulse: _pulseController.value
                    ),
                  );
                },
              );
            },
          ),

          // 4. Central Data Display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: widget.isSignaling ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  // Show Verified if Lifetime Target reached (84 cycles)
                  widget.continuity >= widget.totalCycles ? Icons.verified : Icons.fingerprint, 
                  size: 44, 
                  color: widget.isSignaling ? accent : (isDark ? Colors.white : Colors.black87)
                ),
              ),
              const SizedBox(height: 12),
              
              // Big Percentage (Stability Index)
              Text(
                "${(progress * 100).toStringAsFixed(1)}%",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 42, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: -2, 
                  color: isDark ? Colors.white : Colors.black87
                ),
              ),
              
              // Small Label
              Text(
                widget.isSignaling ? "UPLOADING..." : "STABILITY INDEX",
                style: GoogleFonts.inter(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  color: accent, 
                  letterSpacing: 2
                ),
              ),
            ],
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

    // Background Shadow Track
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    canvas.drawCircle(center, radius, bgPaint);

    // Active Progress Arc (Breathing Thickness)
    final activeWidth = isSignaling ? 16.0 : (14.0 + (pulse * 1.5));
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = activeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [color.withValues(alpha: 0.3), color],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect);

    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, paint);

    // Glowing Head Point
    if (progress > 0) {
      final angle = -pi / 2 + (2 * pi * progress);
      final headPos = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      
      // Core White Dot
      canvas.drawCircle(headPos, 5, Paint()..color = Colors.white);
      
      // Outer Glow (Breathing Opacity)
      final glowRadius = isSignaling ? 15.0 : (10.0 + (pulse * 4.0));
      final glowOpacity = isSignaling ? 0.6 : (0.2 + (pulse * 0.2));
      
      canvas.drawCircle(
        headPos, 
        glowRadius, 
        Paint()
          ..color = color.withValues(alpha: glowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter old) => true;
}

class _HudPainter extends CustomPainter {
  final Color color;
  _HudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < 60; i++) {
      final angle = (i * 6) * pi / 180;
      final length = i % 5 == 0 ? 12.0 : 4.0;
      final p1 = Offset(center.dx + (radius - length) * cos(angle), center.dy + (radius - length) * sin(angle));
      final p2 = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(p1, p2, paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter old) => false;
}