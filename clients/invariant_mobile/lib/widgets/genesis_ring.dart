import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GenesisRing extends StatefulWidget {
  final int streak;
  final int totalCycles;
  final bool isSignaling;

  const GenesisRing({
    super.key,
    required this.streak,
    this.totalCycles = 84,
    this.isSignaling = false,
  });

  @override
  State<GenesisRing> createState() => _GenesisRingState();
}

class _GenesisRingState extends State<GenesisRing> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _idlePulseController;
  late final AnimationController _signalScaleController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _idlePulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
      lowerBound: 0.92,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _signalScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant GenesisRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    // pop animation whenever signaling is newly true
    if (!oldWidget.isSignaling && widget.isSignaling) {
      _signalScaleController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _idlePulseController.dispose();
    _signalScaleController.dispose();
    super.dispose();
  }

  double _clampedProgress() {
    final raw = widget.totalCycles > 0 ? (widget.streak / widget.totalCycles) : 0.0;
    return raw.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    // These are used below in painters and center content
    const gradientColors = <Color>[Color(0xFF00FFC2), Color(0xFF008F7A)];
    final progress = _clampedProgress();

    return SizedBox(
      width: 280,
      height: 280,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _idlePulseController, _signalScaleController]),
        builder: (context, _) {
          final idlePulse = _idlePulseController.value; // ~0.92 .. 1.0
          final signalT = Curves.elasticOut.transform(_signalScaleController.value.clamp(0.0, 1.0));
          final signalScale = 1.0 + (signalT * 0.03); // up to +3%
          final isSignaling = widget.isSignaling;
          final visualScale = isSignaling ? signalScale : idlePulse;

          // painterPulse remaps idlePulse into a tight range for stroke/glow subtlety
          final painterPulse = isSignaling ? 1.0 : (0.9 + ((idlePulse - 0.92) / (1.0 - 0.92)) * 0.1);

          return Transform.scale(
            scale: visualScale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner halo for mass (const-friendly)
                const SizedBox(
                  width: 180,
                  height: 180,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x0F00FFC2), blurRadius: 36, spreadRadius: 8),
                      ],
                    ),
                  ),
                ),

                // Rotating HUD (thin, low-weight)
                RotationTransition(
                  turns: _rotationController,
                  child: const CustomPaint(
                    size: Size(280, 280),
                    painter: _HudPainter(color: Color(0x14FFFFFF)), // ~0.08 alpha
                  ),
                ),

                // Static background track
                const CustomPaint(
                  size: Size(230, 230),
                  painter: _TrackPainter(color: Color(0x14FFFFFF)),
                ),

                // Inner subtle shadow ring for depth
                const CustomPaint(size: Size(230, 230), painter: _InnerShadowPainter()),

                // Progress arc (pulse controls stroke & glow)
                CustomPaint(
                  size: const Size(230, 230),
                  painter: _ProgressPainter(
                    progress: progress,
                    gradientColors: gradientColors,
                    isSignaling: widget.isSignaling,
                    pulse: painterPulse,
                  ),
                ),

                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.streak >= widget.totalCycles ? Icons.verified : Icons.fingerprint,
                      size: 48,
                      color: widget.isSignaling ? Colors.white : const Color(0xFF00FFC2),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      "${(progress * 100).toStringAsFixed(1)}%",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1.0,
                        shadows: const [BoxShadow(color: Color(0x73000000), blurRadius: 10)],
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.isSignaling ? "SIGNING..." : "GENESIS UPTIME",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isSignaling ? const Color(0xFF00FFC2) : const Color(0xB3FFFFFF),
                        letterSpacing: 2.0,
                        fontFamily: GoogleFonts.inter().fontFamily,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(color: Color(0x14141414), borderRadius: BorderRadius.all(Radius.circular(4))),
                      child: Text(
                        "${(widget.totalCycles - widget.streak).clamp(0, widget.totalCycles)} CYCLES LEFT",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0x8CFFFFFF),
                          fontFamily: GoogleFonts.inter().fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* =========================
   Painters
   ========================= */

class _ProgressPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  final bool isSignaling;
  final double pulse; // ~0.9..1.0 (idle) or 1.0 when signaling

  const _ProgressPainter({
    required this.progress,
    required this.gradientColors,
    required this.isSignaling,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const baseStroke = 14.0;
    final strokeWidth = (baseStroke * pulse).clamp(10.0, 18.0);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: gradientColors,
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect);

    final sweepAngle = 2 * pi * (progress.clamp(0.0, 1.0));
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, paint);

    if (progress > 0) {
      final headAngle = -pi / 2 + sweepAngle;
      final headX = center.dx + radius * cos(headAngle);
      final headY = center.dy + radius * sin(headAngle);

      final dotRadius = isSignaling ? 7.5 : 4.5;
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(headX, headY), dotRadius, dotPaint);

      // dynamic glow alpha uses withValues to avoid precision warnings when variable
      final glowAlpha = isSignaling ? 0.46 * pulse : 0.36 * pulse;
      final glowPaint = Paint()
        ..color = const Color(0xFF00FFC2).withValues(alpha: glowAlpha)
        ..style = PaintingStyle.fill;
      final glowBase = isSignaling ? 14.0 : 10.0;
      canvas.drawCircle(Offset(headX, headY), glowBase * pulse, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter old) {
    return old.progress != progress || old.isSignaling != isSignaling || old.pulse != pulse;
  }
}

class _TrackPainter extends CustomPainter {
  final Color color;

  const _TrackPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = stroke;
    canvas.drawCircle(center, (size.width / 2) - (stroke / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HudPainter extends CustomPainter {
  final Color color;

  const _HudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.0;

    const dashWidth = 2.0;
    const dashSpace = 15.0;
    final circumference = 2 * pi * radius;
    final count = (circumference / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < count; i++) {
      final startAngle = (i * (dashWidth + dashSpace)) / radius;
      final sweepAngle = dashWidth / radius;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _InnerShadowPainter extends CustomPainter {
  const _InnerShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0x47000000) // alpha ~ 0.28
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final radius = (size.width / 2) - 8;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
