import 'dart:ui' show FontFeature, SemanticsRole;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import 'theme.dart';

typedef SteyMeterValueText = String Function(
  String formattedValue,
  double value,
);

/// A measured value in a known finite range, rather than an indeterminate task.
class SteyMeter extends StatefulWidget {
  const SteyMeter({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.label,
    this.customValue,
    this.showValue = true,
    this.format,
    this.locale,
    this.getAriaValueText,
    this.color,
    this.trackColor,
    this.tone,
  }) : assert(min > double.negativeInfinity && min < double.infinity),
       assert(max > double.negativeInfinity && max < double.infinity),
       assert(max > min);

  final double value, min, max;
  final String? label, customValue, locale;
  final bool showValue;

  /// Formats the clamped numeric value. Without this, displays a percentage.
  final NumberFormat? format;

  /// Receives formatted text and the original, unclamped value.
  final SteyMeterValueText? getAriaValueText;
  final Color? color, trackColor;

  /// Compatibility extension. With no explicit tone, uses Kumo's brand token.
  final SteyTone? tone;

  double get clampedValue => (value.isNaN ? min : value).clamp(min, max);
  double get fraction {
    final raw = (value - min) / (max - min);
    return (raw.isNaN ? 0.0 : raw).clamp(0.0, 1.0);
  }

  @override
  State<SteyMeter> createState() => _SteyMeterState();
}

class _SteyMeterState extends State<SteyMeter>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    animationBehavior: AnimationBehavior.preserve,
  );
  late double begin = widget.fraction, end = widget.fraction;
  // Tailwind's ease-out token, including interrupted width transitions.
  static const curve = Cubic(0, 0, .2, 1);
  double get displayed =>
      begin + (end - begin) * curve.transform(animation.value);

  @override
  void didUpdateWidget(SteyMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fraction != end) {
      begin = displayed;
      end = widget.fraction;
      animation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final locale = widget.locale ?? Localizations.localeOf(context).toString();
    final formatted =
        widget.format?.format(widget.clampedValue) ??
        NumberFormat.percentPattern(locale).format(widget.fraction);
    final description =
        widget.getAriaValueText?.call(formatted, widget.value) ?? formatted;
    final custom = widget.customValue;
    final visibleValue = custom != null && custom.isNotEmpty
        ? custom
        : widget.showValue
        ? formatted
        : null;
    return Semantics(
      container: true,
      excludeSemantics: true,
      // Flutter currently exposes progressBar but no meter role. Keep the
      // numeric range correct and supply formatted text through the hint.
      role: SemanticsRole.progressBar,
      label: widget.label,
      value: '${widget.clampedValue}',
      minValue: '${widget.min}',
      maxValue: '${widget.max}',
      hint: description,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Row(
              spacing: visibleValue == null ? 0 : 16,
              children: [
                Expanded(
                  child: Text(
                    widget.label ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1 / .75,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                      color: c.subtle,
                    ),
                  ),
                ),
                if (visibleValue != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth / 2,
                    ),
                    child: Text(
                      visibleValue,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1 / .85,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: c.text,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: ColoredBox(
                color: widget.trackColor ?? c.fill,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: displayed,
                      heightFactor: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: ColoredBox(
                          color:
                              widget.color ??
                              widget.tone?.foreground(c) ??
                              c.brand,
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
    );
  }
}
