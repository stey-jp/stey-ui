import 'package:flutter/material.dart';

import 'theme.dart';

enum SteyTextVariant {
  heading,
  heading1,
  heading2,
  heading3,
  body,
  secondary,
  success,
  error,
  mono,
  monoSecondary,
}

enum SteyTextSize { xs, sm, base, lg }

/// Native Kumo typography. Visual headings do not imply a document heading:
/// set [headingLevel] to 1..6, or 0 for decorative text.
class SteyText extends StatelessWidget {
  const SteyText(
    this.data, {
    super.key,
    this.variant,
    this.size = SteyTextSize.base,
    this.bold = false,
    this.truncate = false,
    this.headingLevel,
    this.semanticLabel,
    this.textAlign,
    this.heading = 0,
    this.subtle = false,
  }) : textSpan = null,
       assert(headingLevel == null || headingLevel >= 0 && headingLevel <= 6),
       assert(heading >= 0 && heading <= 6);

  const SteyText.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.variant,
    this.size = SteyTextSize.base,
    this.bold = false,
    this.truncate = false,
    this.headingLevel,
    this.semanticLabel,
    this.textAlign,
    this.heading = 0,
    this.subtle = false,
  }) : data = '',
       assert(headingLevel == null || headingLevel >= 0 && headingLevel <= 6),
       assert(heading >= 0 && heading <= 6);

  final String data;
  final InlineSpan? textSpan;
  final SteyTextVariant? variant;
  final SteyTextSize size;
  final bool bold, truncate;
  final int? headingLevel;
  final String? semanticLabel;
  final TextAlign? textAlign;

  /// Original Stey preview heading sizes and semantic outline, kept for callers.
  /// Prefer [variant] with an explicit [headingLevel] for new code.
  final int heading;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final inherited = DefaultTextStyle.of(context).style;
    final legacy = variant == null && heading > 0;
    final effective =
        variant ?? (subtle ? SteyTextVariant.secondary : SteyTextVariant.body);
    final mono =
        effective == SteyTextVariant.mono ||
        effective == SteyTextVariant.monoSecondary;
    final visualHeading =
        legacy ||
        const [
          SteyTextVariant.heading,
          SteyTextVariant.heading1,
          SteyTextVariant.heading2,
          SteyTextVariant.heading3,
        ].contains(effective);
    final fontSize = legacy
        ? switch (heading) {
            1 => 30.0,
            2 => 24.0,
            3 => 20.0,
            4 => 16.0,
            _ => 14.0,
          }
        : switch (effective) {
            SteyTextVariant.heading => size == SteyTextSize.lg ? 20.0 : 16.0,
            SteyTextVariant.heading1 => 30.0,
            SteyTextVariant.heading2 => 24.0,
            SteyTextVariant.heading3 => 16.0,
            SteyTextVariant.mono || SteyTextVariant.monoSecondary =>
              size == SteyTextSize.lg ? 14.0 : 13.0,
            _ => switch (size) {
              SteyTextSize.xs => 12.0,
              SteyTextSize.sm => 13.0,
              SteyTextSize.base => 14.0,
              SteyTextSize.lg => 16.0,
            },
          };
    // CSS line-height:inherit inherits the parent's computed pixel height,
    // rather than applying its multiplier to each new font size.
    final inheritedLine =
        (inherited.fontSize ?? 14) * (inherited.height ?? 1.5);
    final line = legacy
        ? fontSize * 1.5
        : switch (effective) {
            SteyTextVariant.heading => size == SteyTextSize.lg ? 28.0 : 24.0,
            SteyTextVariant.heading1 => 36.0,
            SteyTextVariant.heading2 => 32.0,
            SteyTextVariant.heading3 => 24.0,
            _ => inheritedLine,
          };
    final color = legacy && subtle
        ? c.subtle
        : switch (effective) {
            SteyTextVariant.secondary ||
            SteyTextVariant.monoSecondary => c.subtle,
            SteyTextVariant.success => c.link,
            SteyTextVariant.error => c.danger,
            _ => c.text,
          };
    final style = TextStyle(
      fontFamily: mono ? 'SteyCodeMono' : null,
      package: mono ? 'stey_ui_modern' : null,
      fontSize: fontSize,
      height: line / fontSize,
      fontWeight: visualHeading
          ? FontWeight.w600
          : !mono && bold
          ? FontWeight.w500
          : inherited.fontWeight ?? FontWeight.w400,
      letterSpacing: inherited.letterSpacing ?? 0,
      color: color,
    );
    final level = headingLevel ?? (legacy ? heading : 0);
    if ((textSpan?.toPlainText() ?? data).isEmpty) {
      return Semantics(
        key: ValueKey(level),
        headingLevel: level == 0 ? null : level,
        label: semanticLabel,
        child: const SizedBox(height: 0),
      );
    }
    final text = Text.rich(
      textSpan ?? TextSpan(text: data),
      style: style,
      textAlign: textAlign,
      semanticsLabel: semanticLabel,
      maxLines: truncate ? 1 : null,
      softWrap: !truncate,
      overflow: truncate ? TextOverflow.ellipsis : TextOverflow.visible,
      textWidthBasis: TextWidthBasis.parent,
    );
    // Flutter Web chooses h1..h6 when creating a semantic node. A new node
    // is required for a changed level so its HTML heading is updated as well.
    return Semantics(
      key: ValueKey(level),
      headingLevel: level == 0 ? null : level,
      child: text,
    );
  }
}
