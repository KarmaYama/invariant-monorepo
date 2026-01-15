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
    _rotationController = AnimationController(
      vsync: this, duration: const Duration(seconds: 20)
    )..repeat();

    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 3), 
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
    final accent = widget.canTap ? const Color(0xFF00FFC2) : Colors.grey; 
    final double progress = (widget.continuity / 84).clamp(0.0, 1.0);

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Halo
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: widget.canTap ? 0.2 : 0.05), // FIXED
                  blurRadius: widget.canTap ? 60 : 30,
                  spreadRadius: widget.canTap ? 10 : 5
                )
              ],
            ),
          ),

          // 2. HUD
          RotationTransition(
            turns: _rotationController,
            child: CustomPaint(
              size: const Size(300, 300), 
              painter: _HudPainter(color: isDark ? Colors.white12 : Colors.black12)
            ),
          ),

          // 3. Track
          CustomPaint(
            size: const Size(240, 240),
            painter: _TrackPainter(
              progress: progress, 
              color: accent, 
              isDark: isDark, 
              isSignaling: widget.isSignaling,
              pulse: _pulseController.value
            ),
          ),

          // 4. Center Icon
          Icon(
            widget.canTap ? Icons.touch_app : Icons.verified_user,
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

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05); // FIXED
    canvas.drawCircle(center, radius, bgPaint);

    final activeWidth = isSignaling ? 16.0 : (14.0 + (pulse * 1.5));
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = activeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [color.withValues(alpha: 0.3), color], // FIXED
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect);

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