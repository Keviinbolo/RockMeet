import 'dart:math';
import 'package:flutter/material.dart';

class WaveBackground extends StatefulWidget {
  final Widget child;
  const WaveBackground({super.key, required this.child});

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFFF0F4FF)),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _WavePainter(_controller.value),
            child: const SizedBox.expand(),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _wave(canvas, size,
        color: const Color(0xFF1976D2).withOpacity(0.12),
        amplitude: 28,
        frequency: 1.3,
        phase: t * 2 * pi,
        yFraction: 0.72);
    _wave(canvas, size,
        color: const Color(0xFF42A5F5).withOpacity(0.18),
        amplitude: 22,
        frequency: 1.6,
        phase: t * 2 * pi + pi / 2,
        yFraction: 0.80);
    _wave(canvas, size,
        color: const Color(0xFF1976D2).withOpacity(0.22),
        amplitude: 18,
        frequency: 2.0,
        phase: t * 2 * pi + pi,
        yFraction: 0.87);
  }

  void _wave(Canvas canvas, Size size,
      {required Color color,
      required double amplitude,
      required double frequency,
      required double phase,
      required double yFraction}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final baseY = size.height * yFraction;

    path.moveTo(0, size.height);
    path.lineTo(0, baseY);

    for (double x = 0; x <= size.width; x++) {
      final y = baseY +
          amplitude * sin((x / size.width * 2 * pi * frequency) + phase);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}
