import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'messages.dart';
import 'theme.dart';

enum SteyEmptySize { sm, base, lg }

/// An empty state with optional illustration, copyable command and actions.
class SteyEmpty extends StatefulWidget {
  const SteyEmpty({
    super.key,
    required this.title,
    this.description,
    this.commandLine,
    this.contents,
    this.size = SteyEmptySize.base,
    this.illustration,
    this.icon,
    this.action,
    this.copyActionLabel,
    this.onCopied,
    this.onCopyError,
  });
  final String title;
  final String? description, commandLine, copyActionLabel;
  final Widget? contents, illustration;

  /// Compatibility for existing callers. Prefer illustration for arbitrary art.
  final IconData? icon;

  /// Compatibility alias, used when contents is omitted.
  final Widget? action;
  final SteyEmptySize size;
  final VoidCallback? onCopied;
  final ValueChanged<Object>? onCopyError;
  @override
  State<SteyEmpty> createState() => _SteyEmptyState();
}

class _SteyEmptyState extends State<SteyEmpty>
    with SingleTickerProviderStateMixin {
  Timer? reset;
  int attempt = 0;
  bool copied = false;
  bool spacePressed = false;
  final selectionFocus = FocusNode(skipTraversal: true);
  late final bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    animationBehavior: AnimationBehavior.preserve,
  );
  late final scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: .6,
        end: 1.2,
      ).chain(CurveTween(curve: const Cubic(0, 0, .2, 1))),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.2,
        end: 1.0,
      ).chain(CurveTween(curve: const Cubic(0, 0, .2, 1))),
      weight: 50,
    ),
  ]).animate(bounce);

  Future<void> copy() async {
    final command = widget.commandLine;
    if (command == null || command.isEmpty) return;
    final current = ++attempt;
    reset?.cancel();
    try {
      await Clipboard.setData(ClipboardData(text: command));
      if (!mounted || current != attempt) return;
      final wasCopied = copied;
      setState(() => copied = true);
      if (!wasCopied) bounce.forward(from: 0);
      reset = Timer(const Duration(milliseconds: 1000), () {
        if (mounted && current == attempt) setState(() => copied = false);
      });
      widget.onCopied?.call();
    } catch (error) {
      if (!mounted || current != attempt) return;
      setState(() => copied = false);
      widget.onCopyError?.call(error);
    }
  }

  @override
  void dispose() {
    attempt++;
    reset?.cancel();
    bounce.dispose();
    selectionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final description = widget.description;
    final described = description != null && description.isNotEmpty;
    final (horizontal, vertical, gap) = switch (widget.size) {
      SteyEmptySize.sm => (24.0, 32.0, 16.0),
      SteyEmptySize.base => (40.0, 64.0, 24.0),
      SteyEmptySize.lg => (48.0, 80.0, 32.0),
    };
    final art =
        widget.illustration ??
        (widget.icon == null
            ? null
            : Icon(widget.icon, size: 48, color: c.subtle));
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: c.control,
        border: Border.all(color: c.fill),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: gap,
        children: [
          if (art != null) ExcludeSemantics(child: art),
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              Semantics(
                headingLevel: 2,
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: described ? 20 : 14,
                    height: described ? 1.4 : 1.5,
                    fontWeight: described ? FontWeight.w600 : FontWeight.w400,
                    color: described ? c.text : c.subtle,
                  ),
                ),
              ),
              if (described)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: c.subtle,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.commandLine?.isNotEmpty ?? false) command(context),
          ?widget.contents ?? widget.action,
        ],
      ),
    );
  }

  Widget command(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final textScale = MediaQuery.textScalerOf(context);
    final style = TextStyle(
      fontFamily: 'SteyCodeMono',
      package: 'stey_ui_modern',
      fontSize: 14,
      height: 1.5,
      color: c.text,
    );
    double width(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: textScale,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final natural =
            width(widget.commandLine!) + width(r'$') + 8 + 8 + 26 + 22;
        final maximum = constraints.maxWidth * .8;
        // Keep the prompt and action usable with enlarged text. Only the command
        // scrolls, preserving its raw value and the fixed physical L/R padding.
        return SizedBox(
          width: math.min(natural, maximum),
          height: math.max(40, textScale.scale(14) * 1.5 + 2),
          child: CustomPaint(
            foregroundPainter: _CommandRing(c.line),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.overlay,
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0d000000),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 1, 9, 1),
                child: Row(
                  spacing: 8,
                  children: [
                    ExcludeSemantics(
                      child: Text(r'$', style: style.copyWith(color: c.subtle)),
                    ),
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectionArea(
                            focusNode: selectionFocus,
                            child: Text(
                              widget.commandLine!,
                              softWrap: false,
                              style: style,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Focus(
                      canRequestFocus: false,
                      includeSemantics: false,
                      onFocusChange: (focused) {
                        if (!focused) spacePressed = false;
                      },
                      onKeyEvent: (_, event) {
                        if (event.logicalKey != LogicalKeyboardKey.space) {
                          return KeyEventResult.ignored;
                        }
                        if (event is KeyDownEvent) spacePressed = true;
                        if (event is KeyUpEvent) {
                          final armed = spacePressed;
                          spacePressed = false;
                          if (armed) copy();
                        }
                        return KeyEventResult.handled;
                      },
                      child: SteyButton(
                        variant: SteyButtonVariant.ghost,
                        size: SteySize.sm,
                        shape: SteyButtonShape.square,
                        foregroundColor: c.subtle,
                        onPressed: copy,
                        semanticLabel:
                            widget.copyActionLabel ??
                            (SteyMessages.of(context).japanese
                                ? 'コマンドをコピー'
                                : 'Copy command'),
                        child: ExcludeSemantics(
                          child: AnimatedBuilder(
                            animation: bounce,
                            builder: (context, _) => Opacity(
                              opacity: copied
                                  ? const Cubic(
                                      0,
                                      0,
                                      .2,
                                      1,
                                    ).transform((bounce.value * 2).clamp(0, 1))
                                  : 1,
                              child: Transform.scale(
                                scale: copied ? scale.value : 1,
                                child: CustomPaint(
                                  size: const Size.square(16),
                                  painter: _CommandIcon(
                                    copied,
                                    copied ? c.success : c.subtle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CommandRing extends CustomPainter {
  const _CommandRing(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(.5),
      const Radius.circular(8.5),
    ),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  @override
  bool shouldRepaint(_CommandRing oldDelegate) => color != oldDelegate.color;
}

// Native paths corresponding to the Phosphor regular Copy and Check.
class _CommandIcon extends CustomPainter {
  const _CommandIcon(this.checked, this.color);
  final bool checked;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 256, size.height / 256);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (checked) {
      canvas.drawPath(
        Path()
          ..moveTo(40, 144)
          ..lineTo(96, 200)
          ..lineTo(224, 72),
        paint,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(32, 80, 176, 224),
          const Radius.circular(8),
        ),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(88, 80)
          ..lineTo(88, 40)
          ..lineTo(216, 40)
          ..lineTo(216, 168)
          ..lineTo(176, 168),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CommandIcon oldDelegate) =>
      checked != oldDelegate.checked || color != oldDelegate.color;
}
