import 'dart:math' as math;
import 'package:flutter/material.dart';

const _pinkDark = Color(0xFF8E0B3A);
const _pinkBright = Color(0xFFFF4081);
const _pink = Color(0xFFD81860);
const _cream = Color(0xFFFFF0F5);

class IntroScreen extends StatefulWidget {
  final Widget next;
  const IntroScreen({super.key, required this.next});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _finish() {
    if (_finished || !mounted) return;
    _c.stop();
    setState(() => _finished = true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Returns 0 before [a] seconds, 1 after [b] seconds, and a value in between.
  static double _window(double t, double a, double b) {
    if (t <= a) return 0;
    if (t >= b) return 1;
    return (t - a) / (b - a);
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return widget.next;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 10; // seconds, 0 to 10
          final bg = Color.lerp(_pinkDark, _pinkBright, _window(t, 0, 2))!;
          final pulse = t > 7 ? 1 + 0.03 * math.sin((t - 7) * 6) : 1.0;

          return Scaffold(
            backgroundColor: bg,
            body: Stack(
              children: [
                // 0 to 2s: glowing spiral
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SpiralPainter(t, _window(t, 0, 0.3) * (1 - _window(t, 1.2, 2.2))),
                  ),
                ),
                // 1 to 3.5s: cream splash
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SplashPainter(
                      _window(t, 1, 2.5),
                      _window(t, 1, 1.2) * (1 - _window(t, 3, 3.6)),
                    ),
                  ),
                ),
                // 2 to 3s and onward: logo zooms in and pulses at the end
                Align(
                  alignment: const Alignment(0, -0.1),
                  child: Opacity(
                    opacity: _window(t, 2, 2.6),
                    child: Transform.scale(
                      scale: (0.6 + 0.4 * Curves.easeOut.transform(_window(t, 2, 3.2))) * pulse,
                      child: Image.asset('assets/icon.png', height: 260,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  ),
                ),
                // 3 to 5s: mascot pops in, then fades
                Align(
                  alignment: const Alignment(0, -0.55),
                  child: Opacity(
                    opacity: _window(t, 3, 3.4) * (1 - _window(t, 4.4, 5)),
                    child: Transform.scale(
                      scale: Curves.easeOutBack.transform(_window(t, 3, 4)),
                      child: Image.asset('assets/robot.png', height: 180,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  ),
                ),
                // 4 to 7.6s: ice cream cone bounces in, then fades
                Align(
                  alignment: const Alignment(0, 0.7),
                  child: Opacity(
                    opacity: _window(t, 4, 4.4) * (1 - _window(t, 7, 7.6)),
                    child: Transform.scale(
                      scale: Curves.elasticOut.transform(_window(t, 4, 5.5)),
                      child: Image.asset('assets/cone.png', height: 220,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  ),
                ),
                // 8.5 to 10s: tagline
                Align(
                  alignment: const Alignment(0, 0.95),
                  child: Opacity(
                    opacity: _window(t, 8.5, 9.2),
                    child: const Text('Sweet Service. Always!',
                        style: TextStyle(color: _cream, fontSize: 18, fontStyle: FontStyle.italic)),
                  ),
                ),
                // Hint so the user knows they can tap to skip
                const Positioned(
                  top: 40,
                  right: 16,
                  child: Text('Tap to skip', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SpiralPainter extends CustomPainter {
  final double t;
  final double opacity;
  _SpiralPainter(this.t, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final c = size.center(Offset.zero);
    for (int i = 0; i < 40; i++) {
      final paint = Paint()
        ..color = _pinkBright.withOpacity(opacity * (1 - i / 45))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 6.0 + i * 4.5),
        t * 3 + i * 0.25,
        math.pi * 1.4,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpiralPainter old) => old.t != t || old.opacity != opacity;
}

class _SplashPainter extends CustomPainter {
  final double p;       // 0 to 1, how far the splash has spread
  final double opacity;
  _SplashPainter(this.p, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final c = size.center(Offset.zero);
    final paint = Paint()..color = Colors.white.withOpacity(0.9 * opacity);
    for (int i = 0; i < 9; i++) {
      final a = i * math.pi * 2 / 9;
      final pos = c + Offset(math.cos(a), math.sin(a)) * (40 + 180 * p);
      canvas.drawCircle(pos, 26 * p + 6, paint);
    }
    canvas.drawCircle(c, 120 * p, Paint()..color = Colors.white.withOpacity(0.7 * opacity));
  }

  @override
  bool shouldRepaint(_SplashPainter old) => old.p != p || old.opacity != opacity;
}
