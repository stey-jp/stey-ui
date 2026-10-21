import 'dart:async';
import 'dart:ui' show SemanticsRole;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'messages.dart';

enum SteyLoaderSize {
  sm(16),
  base(24),
  lg(32);

  const SteyLoaderSize(this.pixels);
  final double pixels;
}

/// Native equivalent of Kumo's two SVG circles and independent SMIL timelines.
class SteyLoader extends StatefulWidget {
  const SteyLoader({
    super.key,
    double size = 24,
    this.label = 'Loading',
    this.color,
  }) : assert(size >= 0 && size < double.infinity),
       _size = size,
       _preset = null;
  const SteyLoader.preset({
    super.key,
    SteyLoaderSize size = SteyLoaderSize.base,
    this.label = 'Loading',
    this.color,
  }) : _size = 24,
       _preset = size;
  final double _size;
  final SteyLoaderSize? _preset;
  double get size => _preset?.pixels ?? _size;
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
    role: SemanticsRole.status,
    label: widget.label == 'Loading'
        ? SteyMessages.of(context).loading
        : widget.label,
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

/// Randomized percent-width skeleton. Explicit width/height retain the original
/// Flutter API; blockHeight centers the line without changing its thickness.
class SteySkeletonLine extends StatefulWidget {
  const SteySkeletonLine({
    super.key,
    this.width,
    this.height = 8,
    this.minWidth = 30,
    this.maxWidth = 100,
    this.minDuration = 1.3,
    this.maxDuration = 1.7,
    this.minDelay = 0,
    this.maxDelay = .5,
    this.blockHeight,
  }) : assert(minWidth >= 0 && maxWidth >= minWidth),
       assert(minDuration > 0 && maxDuration >= minDuration),
       assert(minDelay >= 0 && maxDelay >= minDelay),
       assert(height >= 0),
       assert(width == null || width >= 0),
       assert(blockHeight == null || blockHeight >= 0);
  final double? width, blockHeight;
  final double height, minDuration, maxDuration, minDelay, maxDelay;
  final int minWidth, maxWidth;
  @override
  State<SteySkeletonLine> createState() => _SkeletonState();
}

class _SkeletonState extends State<SteySkeletonLine>
    with SingleTickerProviderStateMixin {
  final random = math.Random();
  late double fraction;
  late final animation = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
  );
  Timer? start;
  @override
  void initState() {
    super.initState();
    reset();
  }

  void reset() {
    start?.cancel();
    animation.stop();
    animation.value = 0;
    fraction =
        (widget.minWidth +
            random.nextInt(widget.maxWidth - widget.minWidth + 1)) /
        100;
    double pick(double a, double b) =>
        ((a + random.nextDouble() * (b - a)) * 100).round() / 100;
    animation.duration = Duration(
      microseconds: (pick(widget.minDuration, widget.maxDuration) * 1000000)
          .round(),
    );
    final delay = Duration(
      microseconds: (pick(widget.minDelay, widget.maxDelay) * 1000000).round(),
    );
    if (delay == Duration.zero) {
      animation.repeat();
    } else {
      start = Timer(delay, () {
        if (mounted) animation.repeat();
      });
    }
  }

  @override
  void didUpdateWidget(SteySkeletonLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minWidth != widget.minWidth ||
        oldWidget.maxWidth != widget.maxWidth ||
        oldWidget.minDuration != widget.minDuration ||
        oldWidget.maxDuration != widget.maxDuration ||
        oldWidget.minDelay != widget.minDelay ||
        oldWidget.maxDelay != widget.maxDelay) {
      reset();
    }
  }

  @override
  void dispose() {
    start?.cancel();
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox(
          width:
              widget.width ??
              (constraints.hasBoundedWidth ? constraints.maxWidth : 125) *
                  fraction,
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => CustomPaint(
                painter: _SkeletonPainter(
                  SteyTheme.colorsOf(context).dark,
                  const Cubic(.42, 0, .58, 1).transform(animation.value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      child: widget.blockHeight == null
          ? line
          : SizedBox(
              height: widget.blockHeight,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: line,
              ),
            ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  const _SkeletonPainter(this.dark, this.value);
  final bool dark;
  final double value;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? const Color(0x0fffffff) : const Color(0xfff3f4f6),
    );
    canvas.save();
    canvas.translate((-1 + 2 * value) * size.width, 0);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            dark ? const Color(0x0dffffff) : const Color(0x14000000),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkeletonPainter oldDelegate) =>
      dark != oldDelegate.dark || value != oldDelegate.value;
}
