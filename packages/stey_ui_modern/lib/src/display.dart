import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'theme.dart';
export 'loader.dart';

class SteyText extends StatelessWidget {
  const SteyText(
    this.data, {
    super.key,
    this.heading = 0,
    this.subtle = false,
    this.bold = false,
  });
  final String data;
  final int heading;
  final bool subtle, bold;
  @override
  Widget build(BuildContext context) => Semantics(
    header: heading > 0,
    child: Text(
      data,
      style: TextStyle(
        fontSize: switch (heading) {
          1 => 30,
          2 => 24,
          3 => 20,
          4 => 16,
          _ => 14,
        },
        height: 1.5,
        fontWeight: heading > 0
            ? FontWeight.w600
            : bold
            ? FontWeight.w500
            : FontWeight.w400,
        color: subtle
            ? SteyTheme.colorsOf(context).subtle
            : SteyTheme.colorsOf(context).text,
      ),
    ),
  );
}

enum SteyBadgeVariant {
  primary,
  secondary,
  error,
  warning,
  success,
  destructive,
  info,
  beta,
  outline,
  red,
  green,
  neutral,
  orange,
  purple,
  teal,
  tealSubtle,
  blue,
}

enum SteyBadgeAppearance { filled, dot }

class SteyBadge extends StatelessWidget {
  const SteyBadge({
    super.key,
    required this.child,
    this.tone,
    this.dot = false,
    this.outline = false,
    this.variant,
    this.icon,
    this.appearance = SteyBadgeAppearance.filled,
  });
  final Widget child;
  final SteyTone? tone;
  final bool dot, outline;
  final SteyBadgeVariant? variant;
  final Widget? icon;
  final SteyBadgeAppearance appearance;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final selectedVariant =
        variant ?? (tone == null ? SteyBadgeVariant.primary : null);
    final isDot = dot || appearance == SteyBadgeAppearance.dot;
    final (background, foreground) = switch (selectedVariant) {
      SteyBadgeVariant.primary => (c.badgeInverted, c.badgeInverseText),
      SteyBadgeVariant.secondary => (c.fill, c.badgeNeutralText),
      SteyBadgeVariant.error => (c.dangerTint, c.dangerText),
      SteyBadgeVariant.warning => (c.warningTint, c.warningText),
      SteyBadgeVariant.success => (c.successTint, c.successText),
      SteyBadgeVariant.info => (c.infoTint, c.link),
      SteyBadgeVariant.beta => (Colors.transparent, c.link),
      SteyBadgeVariant.outline => (c.base, c.text),
      SteyBadgeVariant.red ||
      SteyBadgeVariant.destructive => (c.badgeRed, Colors.white),
      SteyBadgeVariant.green => (c.badgeGreen, Colors.white),
      SteyBadgeVariant.neutral => (c.badgeNeutral, Colors.white),
      SteyBadgeVariant.orange => (c.badgeOrange, Colors.black),
      SteyBadgeVariant.purple => (c.badgePurple, Colors.white),
      SteyBadgeVariant.teal => (c.badgeTeal, Colors.white),
      SteyBadgeVariant.blue => (c.badgeBlue, Colors.white),
      SteyBadgeVariant.tealSubtle => (
        // Upstream references an undefined background token at the pinned SHA.
        Colors.transparent,
        c.badgeTealText,
      ),
      null => (tone!.background(c), tone!.foreground(c)),
    };
    final dotColor = switch (selectedVariant) {
      SteyBadgeVariant.success => c.success,
      SteyBadgeVariant.warning => c.badgeOrange,
      SteyBadgeVariant.error => c.badgeRed,
      SteyBadgeVariant.neutral => c.badgeNeutral,
      null => tone!.foreground(c),
      _ => null,
    };
    final bordered =
        !isDot &&
        (outline ||
            selectedVariant == SteyBadgeVariant.outline ||
            selectedVariant == SteyBadgeVariant.beta);
    final beta = !isDot && selectedVariant == SteyBadgeVariant.beta;
    return CustomPaint(
      foregroundPainter: isDot || beta
          ? _BadgeBorder(
              color: isDot ? c.hairline : c.brand,
              dashed: beta,
              outside: isDot,
            )
          : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDot
              ? Colors.transparent
              : outline
              ? c.base
              : background,
          borderRadius: BorderRadius.circular(99),
          border: bordered && !beta ? Border.all(color: c.fill) : null,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            (icon != null && !isDot ? 6 : 8) + (bordered ? 1 : 0),
            bordered ? 3 : 2,
            bordered ? 9 : 8,
            bordered ? 3 : 2,
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 4 / 3,
              color: isDot ? c.text : foreground,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDot && dotColor != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (icon != null && !isDot) ...[
                  IconTheme(
                    data: IconThemeData(size: 12, color: foreground),
                    child: icon!,
                  ),
                  const SizedBox(width: 4),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeBorder extends CustomPainter {
  const _BadgeBorder({
    required this.color,
    required this.dashed,
    required this.outside,
  });
  final Color color;
  final bool dashed, outside;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).inflate(outside ? .5 : -.5);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 6) {
        canvas.drawPath(metric.extractPath(offset, offset + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BadgeBorder oldDelegate) =>
      color != oldDelegate.color ||
      dashed != oldDelegate.dashed ||
      outside != oldDelegate.outside;
}

class SteyBanner extends StatelessWidget {
  const SteyBanner({
    super.key,
    required this.child,
    this.tone = SteyTone.info,
    this.onDismiss,
    this.action,
  });
  final Widget child;
  final SteyTone tone;
  final VoidCallback? onDismiss;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.background(c),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                switch (tone) {
                  SteyTone.danger => Icons.error_outline,
                  SteyTone.warning => Icons.warning_amber,
                  SteyTone.success => Icons.check_circle_outline,
                  _ => Icons.info_outline,
                },
                size: 18,
                color: tone.foreground(c),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: tone.foreground(c),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  child: child,
                ),
              ),
              ?action,
              if (onDismiss != null)
                SteyButton(
                  onPressed: onDismiss,
                  size: SteySize.xs,
                  variant: SteyButtonVariant.ghost,
                  semanticLabel: 'Dismiss notification',
                  child: const Icon(Icons.close, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SteyLayerCard extends StatelessWidget {
  const SteyLayerCard({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });
  final Widget child;
  final Widget? header, footer;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: c.line, spreadRadius: 1),
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .3 : .06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) Padding(padding: padding, child: header),
          Padding(
            padding: const EdgeInsets.all(4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.base,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
          if (footer != null) Padding(padding: padding, child: footer),
        ],
      ),
    );
  }
}

@Deprecated('Use SteyLayerCard.')
class SteySurface extends SteyLayerCard {
  const SteySurface({
    super.key,
    required super.child,
    super.header,
    super.footer,
  });
}

class SteyEmpty extends StatelessWidget {
  const SteyEmpty({
    super.key,
    required this.title,
    this.description,
    this.action,
    this.icon = Icons.inbox_outlined,
  });
  final String title;
  final String? description;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 32, color: SteyTheme.colorsOf(context).subtle),
        const SizedBox(height: 12),
        SteyText(title, heading: 4),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SteyText(description!, subtle: true),
          ),
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 20), child: action),
      ],
    ),
  );
}

class SteyMeter extends StatelessWidget {
  const SteyMeter({
    super.key,
    required this.value,
    this.max = 100,
    this.label,
    this.tone = SteyTone.info,
  });
  final double value, max;
  final String? label;
  final SteyTone tone;
  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final c = SteyTheme.colorsOf(context);
    return Semantics(
      excludeSemantics: true,
      label: label,
      value: '${(fraction * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SteyText(label!),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              color: tone.foreground(c),
              backgroundColor: c.fill,
            ),
          ),
        ],
      ),
    );
  }
}

class SteySkeletonLine extends StatefulWidget {
  const SteySkeletonLine({super.key, this.width, this.height = 14});
  final double? width;
  final double height;
  @override
  State<SteySkeletonLine> createState() => _SteySkeletonLineState();
}

class _SteySkeletonLineState extends State<SteySkeletonLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();
  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-3 + 6 * animation.value, 0),
              end: Alignment(-1 + 6 * animation.value, 0),
              colors: [c.fill, c.tint, c.fill],
            ),
          ),
        ),
      ),
    );
  }
}

class SteyClipboardText extends StatefulWidget {
  const SteyClipboardText(
    this.text, {
    super.key,
    this.inline = false,
    this.onCopied,
  });
  final String text;
  final bool inline;
  final VoidCallback? onCopied;
  @override
  State<SteyClipboardText> createState() => _SteyClipboardTextState();
}

class _SteyClipboardTextState extends State<SteyClipboardText> {
  bool copied = false;
  Future<void> copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => copied = true);
    widget.onCopied?.call();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => copied = false);
  }

  @override
  Widget build(BuildContext context) => SteyButton(
    onPressed: copy,
    variant: widget.inline
        ? SteyButtonVariant.ghost
        : SteyButtonVariant.secondary,
    semanticLabel: copied ? 'Copied' : 'Copy ${widget.text}',
    trailing: Icon(copied ? Icons.check : Icons.copy, size: 14),
    child: Text(
      widget.text,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12.6),
    ),
  );
}

class SteyInlineCopyText extends SteyClipboardText {
  const SteyInlineCopyText(super.text, {super.key, super.onCopied})
    : super(inline: true);
}

class SteyCode extends StatelessWidget {
  const SteyCode(
    this.code, {
    super.key,
    this.block = false,
    this.copyable = false,
  });
  final String code;
  final bool block, copyable;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(block ? 10 : 0),
    decoration: block
        ? BoxDecoration(
            color: SteyTheme.colorsOf(context).base,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: SteyTheme.colorsOf(context).fill),
          )
        : null,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 20 / 14,
            color: SteyTheme.colorsOf(context).subtle,
          ),
        ),
        if (copyable)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SteyClipboardText(code),
          ),
      ],
    ),
  );
}

class SteyCodeBlock extends SteyCode {
  const SteyCodeBlock(super.code, {super.key, super.copyable})
    : super(block: true);
}

class SteyGrid extends StatelessWidget {
  const SteyGrid({
    super.key,
    required this.children,
    this.minWidth = 240,
    this.gap = 16,
    this.maxColumns = 4,
  });
  final List<Widget> children;
  final double minWidth, gap;
  final int maxColumns;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = ((constraints.maxWidth + gap) / (minWidth + gap))
          .floor()
          .clamp(1, maxColumns);
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}
