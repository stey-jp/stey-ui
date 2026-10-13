import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'messages.dart';

/// Native equivalent of Kumo's two SVG circles and independent SMIL timelines.
class SteyLoader extends StatefulWidget {
  const SteyLoader({
    super.key,
    this.size = 24,
    this.label = 'Loading',
    this.color,
  });
  final double size;
  final String label;
  final Color? color;
  @override
  State<SteyLoader> createState() => _SteyLoaderState();
}

class _SteyLoaderState extends State<SteyLoader>
    with SingleTickerProviderStateMixin {
  // The least common multiple of the 2s rotation and 1.5s dash timelines.
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
    animationBehavior: AnimationBehavior.preserve,
  )..repeat();
  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label == 'Loading'
        ? SteyMessages.of(context).loading
        : widget.label,
    liveRegion: true,
    child: SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => CustomPaint(
          painter: _LoaderPainter(
            animation.value,
            widget.color ??
                DefaultTextStyle.of(context).style.color ??
                SteyTheme.colorsOf(context).text,
          ),
        ),
      ),
    ),
  );
}

class _LoaderPainter extends CustomPainter {
  const _LoaderPainter(this.time, this.color);
  final double time;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    const radius = 9.5, circumference = 2 * math.pi * radius;
    final phase = (time * 4) % 1;
    final dash = phase <= .5 ? 84 * phase : 42.0;
    final offset = phase <= .5 ? -32 * phase : -16 - 86 * (phase - .5);
    final start = -offset;
    final end = math.min(start + dash, circumference);
    final rotation = ((time * 3) % 1) * 2 * math.pi;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const circle = Rect.fromLTWH(2.5, 2.5, 19, 19);
    if (end > start) {
      canvas.drawArc(
        circle,
        rotation + start / radius,
        (end - start) / radius,
        false,
        stroke,
      );
    } else if (dash == 0) {
      canvas.drawCircle(
        Offset(
          12 + radius * math.cos(rotation),
          12 + radius * math.sin(rotation),
        ),
        1,
        Paint()..color = color,
      );
    }
    canvas.drawCircle(
      const Offset(12, 12),
      radius,
      stroke..color = color.withValues(alpha: color.a * .1),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoaderPainter oldDelegate) =>
      time != oldDelegate.time || color != oldDelegate.color;
}
