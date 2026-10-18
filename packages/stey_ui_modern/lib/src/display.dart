import 'dart:async';
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'messages.dart';
export 'loader.dart';
export 'banner.dart';

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
    animationBehavior: AnimationBehavior.preserve,
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

enum SteyClipboardSize { sm, base, lg }

enum SteyClipboardSide { top, bottom, left, right }

class SteyClipboardTooltip {
  const SteyClipboardTooltip({
    this.text,
    this.copiedText,
    this.side = SteyClipboardSide.top,
  });
  final String? text, copiedText;
  final SteyClipboardSide side;
}

class SteyClipboardText extends StatefulWidget {
  const SteyClipboardText(
    this.text, {
    super.key,
    this.inline = false,
    this.onCopied,
    this.textToCopy,
    SteyClipboardSize size = SteyClipboardSize.lg,
    this.tooltip,
    String? copyActionLabel,
    FocusNode? focusNode,
    bool autofocus = false,
    ValueChanged<Object>? onCopyError,
  }) : fieldSize = size,
       // Public argument names coexist with InlineCopyText's existing fields.
       // ignore: prefer_initializing_formals
       _copyActionLabel = copyActionLabel,
       // ignore: prefer_initializing_formals
       _focusNode = focusNode,
       // ignore: prefer_initializing_formals
       _autofocus = autofocus,
       // ignore: prefer_initializing_formals
       _onCopyError = onCopyError;
  final String text;
  final bool inline;
  final VoidCallback? onCopied;
  final String? textToCopy;
  // Keep size separate from the existing InlineCopyText subtype's text size.
  final SteyClipboardSize fieldSize;
  final SteyClipboardTooltip? tooltip;
  final String? _copyActionLabel;
  final FocusNode? _focusNode;
  final bool _autofocus;
  final ValueChanged<Object>? _onCopyError;
  @override
  State<SteyClipboardText> createState() => _SteyClipboardTextState();
}

class _SteyClipboardTextState extends State<SteyClipboardText>
    with TickerProviderStateMixin {
  final portal = OverlayPortalController();
  final ownFocus = FocusNode();
  final selectionFocus = FocusNode(skipTraversal: true);
  Timer? reset, hoverDelay;
  bool copied = false, hovered = false, focusVisible = false;
  bool tooltipVisible = false, spacePressed = false;
  late final slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    animationBehavior: AnimationBehavior.preserve,
  );
  late final bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
    animationBehavior: AnimationBehavior.preserve,
  );
  late final progress = CurvedAnimation(
    parent: slide,
    curve: const Cubic(.4, 0, .2, 1),
  );
  late final bumpScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.04,
      ).chain(CurveTween(curve: const Cubic(.34, 1.56, .64, 1))),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.04,
        end: 1.0,
      ).chain(CurveTween(curve: const Cubic(.34, 1.56, .64, 1))),
      weight: 65,
    ),
  ]).animate(bump);

  void hideTooltip() {
    hoverDelay?.cancel();
    if (!tooltipVisible) return;
    tooltipVisible = false;
    if (!copied) portal.hide();
  }

  void showTooltip({bool immediate = false}) {
    hoverDelay?.cancel();
    if (widget.tooltip == null || copied) return;
    void show() {
      if (!mounted || copied || widget.tooltip == null) return;
      setState(() => tooltipVisible = true);
      portal.show();
    }

    if (immediate) {
      show();
    } else {
      hoverDelay = Timer(const Duration(milliseconds: 600), show);
    }
  }

  Future<void> copy() async {
    try {
      await Clipboard.setData(
        ClipboardData(text: widget.textToCopy ?? widget.text),
      );
      if (!mounted) return;
      final repeat = copied;
      reset?.cancel();
      hoverDelay?.cancel();
      setState(() {
        copied = true;
        tooltipVisible = false;
      });
      slide.forward();
      if (widget.tooltip != null) {
        portal.show();
        if (repeat) bump.forward(from: 0);
      }
      reset = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() => copied = false);
        slide.reverse();
        portal.hide();
        reset = null;
      });
      widget.onCopied?.call();
    } catch (error) {
      if (mounted) widget._onCopyError?.call(error);
    }
  }

  @override
  void didUpdateWidget(SteyClipboardText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tooltip == null && oldWidget.tooltip != null) {
      hoverDelay?.cancel();
      tooltipVisible = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.tooltip == null) portal.hide();
      });
    } else if (widget.tooltip != null && oldWidget.tooltip == null && copied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.tooltip != null && copied) portal.show();
      });
    }
  }

  @override
  void dispose() {
    reset?.cancel();
    hoverDelay?.cancel();
    ownFocus.dispose();
    selectionFocus.dispose();
    progress.dispose();
    slide.dispose();
    bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inline) {
      return SteyInlineCopyText(
        widget.text,
        value: widget.textToCopy,
        onCopied: widget.onCopied,
        copyActionLabel: widget._copyActionLabel,
        focusNode: widget._focusNode,
        autofocus: widget._autofocus,
        onCopyError: widget._onCopyError,
      );
    }
    final c = SteyTheme.colorsOf(context);
    final size = switch (widget.fieldSize) {
      SteyClipboardSize.sm => SteySize.sm,
      SteyClipboardSize.base => SteySize.base,
      SteyClipboardSize.lg => SteySize.lg,
    };
    final iconSize = size.fontSize;
    final textSize = size == SteySize.sm ? 12.0 : 13.0;
    final textHeight = size == SteySize.sm ? 1 / .75 : 1 / .85;
    final iconLift = size == SteySize.sm ? .5 : 1.0;
    final radius = BorderRadius.circular(size.radius);
    final copiedText =
        widget.tooltip?.copiedText ?? SteyMessages.of(context).copied;
    final copyLabel =
        widget._copyActionLabel ??
        (Localizations.maybeLocaleOf(context)?.languageCode == 'ja'
            ? 'クリップボードにコピー'
            : 'Copy to clipboard');
    final node = widget._focusNode ?? ownFocus;
    Widget button = Focus(
      canRequestFocus: false,
      includeSemantics: false,
      onKeyEvent: (_, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          hideTooltip();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.space) {
          if (event is KeyDownEvent) spacePressed = true;
          if (event is KeyUpEvent && spacePressed) {
            spacePressed = false;
            copy();
          }
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) copy();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: FocusableActionDetector(
        focusNode: node,
        autofocus: widget._autofocus,
        onFocusChange: (v) {
          if (!v) {
            spacePressed = false;
            hideTooltip();
          }
        },
        onShowFocusHighlight: (v) {
          setState(() => focusVisible = v);
          if (v) showTooltip(immediate: true);
        },
        child: Semantics(
          button: true,
          label: copyLabel,
          excludeSemantics: true,
          onTap: () {
            node.requestFocus();
            copy();
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              setState(() => hovered = true);
              showTooltip();
            },
            onExit: (_) {
              setState(() => hovered = false);
              hideTooltip();
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: () {
                node.requestFocus();
                copy();
              },
              child: CustomPaint(
                foregroundPainter: focusVisible
                    ? _ClipboardFocus(c.brand, size.radius)
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(size.radius),
                    bottomRight: Radius.circular(size.radius),
                  ),
                  child: Container(
                    width: 25 + iconSize,
                    height: size.height,
                    decoration: BoxDecoration(
                      color: hovered ? c.tint : c.base,
                      border: Border(left: BorderSide(color: c.line)),
                    ),
                    child: ClipRect(
                      child: AnimatedBuilder(
                        animation: progress,
                        builder: (context, _) => Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: 1 - progress.value,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  -(copied ? size.height : iconSize) *
                                          progress.value -
                                      iconLift,
                                ),
                                child: CustomPaint(
                                  size: Size.square(iconSize),
                                  painter: _ClipboardCopyIcon(c.text),
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: progress.value,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  (copied ? iconSize : size.height) *
                                          (1 - progress.value) -
                                      iconLift,
                                ),
                                child: CustomPaint(
                                  size: Size.square(iconSize),
                                  painter: _InlineCopyIcon(true, c.text),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: portal,
      overlayChildBuilder: (context, info) {
        final anchor = MatrixUtils.transformRect(
          info.childPaintTransform,
          Rect.fromLTWH(
            Directionality.of(context) == TextDirection.rtl
                ? 0
                : info.childSize.width - 25 - iconSize,
            0,
            25 + iconSize,
            size.height,
          ),
        );
        final tooltipText =
            widget.tooltip?.text ??
            (Localizations.maybeLocaleOf(context)?.languageCode == 'ja'
                ? 'コピー'
                : 'Copy');
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomSingleChildLayout(
              delegate: _ClipboardPopupLayout(
                anchor,
                widget.tooltip?.side ?? SteyClipboardSide.top,
              ),
              child: AnimatedBuilder(
                animation: bump,
                builder: (context, child) {
                  return Transform.scale(scale: bumpScale.value, child: child);
                },
                child: Semantics(
                  container: true,
                  role: copied ? SemanticsRole.status : SemanticsRole.none,
                  tooltip: copied ? null : tooltipText,
                  excludeSemantics: !copied,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.base,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .1),
                          blurRadius: copied ? 15 : 6,
                          offset: Offset(0, copied ? 10 : 4),
                        ),
                      ],
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: c.line,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: Text(
                      copied ? copiedText : tooltipText,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        package: 'stey_ui_modern',
                        fontSize: 12,
                        height: 1 / .75,
                        color: c.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(color: c.base, borderRadius: radius),
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: c.line,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: SizedBox(
                  height: size.height,
                  child: Row(
                    spacing: switch (size) {
                      SteySize.sm => 4,
                      SteySize.base => 6,
                      _ => 8,
                    },
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 16,
                            end: 8,
                          ),
                          child: Semantics(
                            label: widget.text,
                            excludeSemantics: true,
                            child: ExcludeFocusTraversal(
                              child: SelectionArea(
                                focusNode: selectionFocus,
                                child: Text(
                                  widget.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'SteyCodeMono',
                                    package: 'stey_ui_modern',
                                    fontSize: textSize,
                                    height: textHeight,
                                    color: c.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      button,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              width: 1,
              height: 1,
              child: Semantics(
                container: true,
                liveRegion: true,
                label: copied ? copiedText : '',
                child: const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClipboardFocus extends CustomPainter {
  const _ClipboardFocus(this.color, this.radius);
  final Color color;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    BorderRadius.only(
      topRight: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    ).toRRect((Offset.zero & size).deflate(1)),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  @override
  bool shouldRepaint(_ClipboardFocus oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}

class _ClipboardCopyIcon extends CustomPainter {
  const _ClipboardCopyIcon(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 256, size.height / 256);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(32, 80, 176, 224),
          const Radius.circular(8),
        ),
      )
      ..addRect(const Rect.fromLTRB(48, 96, 160, 208));
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      Path()
        ..moveTo(88, 80)
        ..lineTo(88, 40)
        ..lineTo(216, 40)
        ..lineTo(216, 168)
        ..lineTo(176, 168),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ClipboardCopyIcon oldDelegate) =>
      color != oldDelegate.color;
}

class _ClipboardPopupLayout extends SingleChildLayoutDelegate {
  const _ClipboardPopupLayout(this.anchor, this.side);
  final Rect anchor;
  final SteyClipboardSide side;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          (constraints.maxWidth - 10).clamp(0, double.infinity),
          (constraints.maxHeight - 10).clamp(0, double.infinity),
        ),
      );
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    Offset position(SteyClipboardSide side) => switch (side) {
      SteyClipboardSide.top => Offset(
        anchor.center.dx - childSize.width / 2,
        anchor.top - 8 - childSize.height,
      ),
      SteyClipboardSide.bottom => Offset(
        anchor.center.dx - childSize.width / 2,
        anchor.bottom + 8,
      ),
      SteyClipboardSide.left => Offset(
        anchor.left - 8 - childSize.width,
        anchor.center.dy - childSize.height / 2,
      ),
      SteyClipboardSide.right => Offset(
        anchor.right + 8,
        anchor.center.dy - childSize.height / 2,
      ),
    };
    bool fits(Offset p) => switch (side) {
      SteyClipboardSide.top || SteyClipboardSide.bottom =>
        p.dy >= 5 && p.dy + childSize.height <= size.height - 5,
      SteyClipboardSide.left || SteyClipboardSide.right =>
        p.dx >= 5 && p.dx + childSize.width <= size.width - 5,
    };
    var p = position(side);
    if (!fits(p)) {
      final opposite = switch (side) {
        SteyClipboardSide.top => SteyClipboardSide.bottom,
        SteyClipboardSide.bottom => SteyClipboardSide.top,
        SteyClipboardSide.left => SteyClipboardSide.right,
        SteyClipboardSide.right => SteyClipboardSide.left,
      };
      if (fits(position(opposite))) p = position(opposite);
    }
    return Offset(
      p.dx.clamp(
        5,
        (size.width - childSize.width - 5).clamp(5, double.infinity),
      ),
      p.dy.clamp(
        5,
        (size.height - childSize.height - 5).clamp(5, double.infinity),
      ),
    );
  }

  @override
  bool shouldRelayout(_ClipboardPopupLayout oldDelegate) =>
      anchor != oldDelegate.anchor || side != oldDelegate.side;
}

enum SteyInlineCopyVariant {
  body,
  secondary,
  success,
  error,
  mono,
  monoSecondary,
}

enum SteyInlineCopySize { xs, sm, base, lg }

/// A compact copy control. A rich child requires an explicit clipboard value.
class SteyInlineCopyText extends SteyClipboardText {
  const SteyInlineCopyText(
    super.text, {
    super.key,
    super.onCopied,
    this.value,
    this.disabled = false,
    this.truncate = true,
    this.variant = SteyInlineCopyVariant.monoSecondary,
    this.size = SteyInlineCopySize.base,
    this.bold = false,
    this.copyActionLabel,
    this.copiedLabel,
    this.focusNode,
    this.autofocus = false,
    this.onBeforeCopy,
    this.onCopyError,
  }) : child = null,
       super(inline: true);

  const SteyInlineCopyText.rich(
    Widget this.child, {
    super.key,
    super.onCopied,
    required String value,
    this.disabled = false,
    this.truncate = true,
    this.variant = SteyInlineCopyVariant.monoSecondary,
    this.size = SteyInlineCopySize.base,
    this.bold = false,
    this.copyActionLabel,
    this.copiedLabel,
    this.focusNode,
    this.autofocus = false,
    this.onBeforeCopy,
    this.onCopyError,
  }) : value = value,
       super(value, inline: true);

  final Widget? child;
  final String? value, copyActionLabel, copiedLabel;
  final bool disabled, truncate, bold, autofocus;
  final SteyInlineCopyVariant variant;
  final SteyInlineCopySize size;
  final FocusNode? focusNode;

  /// Return false to cancel activation before clipboard IO and feedback reset.
  final bool Function()? onBeforeCopy;
  final ValueChanged<Object>? onCopyError;
  @override
  State<SteyInlineCopyText> createState() => _SteyInlineCopyTextState();
}

/// Native counterpart of an enclosing Kumo `group`: hover or focus within the
/// group reveals descendant copy icons without changing their text colors.
class SteyInlineCopyGroup extends StatefulWidget {
  const SteyInlineCopyGroup({super.key, required this.child});
  final Widget child;
  @override
  State<SteyInlineCopyGroup> createState() => _SteyInlineCopyGroupState();
}

class _CopyReveal extends InheritedWidget {
  const _CopyReveal({required this.visible, required super.child});
  final bool visible;
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CopyReveal>()?.visible ??
      false;
  @override
  bool updateShouldNotify(_CopyReveal oldWidget) =>
      visible != oldWidget.visible;
}

class _SteyInlineCopyGroupState extends State<SteyInlineCopyGroup> {
  bool hovered = false, focused = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: Focus(
      canRequestFocus: false,
      includeSemantics: false,
      onFocusChange: (v) => setState(() => focused = v),
      child: _CopyReveal(
        visible: hovered || focused || _CopyReveal.of(context),
        child: widget.child,
      ),
    ),
  );
}

class _SteyInlineCopyTextState extends State<SteyInlineCopyText>
    with SingleTickerProviderStateMixin {
  final ownFocus = FocusNode();
  final timers = <Timer>{};
  Timer? reset;
  bool copied = false, hovered = false, focused = false, focusVisible = false;
  bool spacePressed = false;
  bool iconVisible = false;
  late final fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    animationBehavior: AnimationBehavior.preserve,
  );

  Future<void> copy() async {
    if (widget.disabled || widget.onBeforeCopy?.call() == false) return;
    reset?.cancel();
    timers.remove(reset);
    try {
      await Clipboard.setData(ClipboardData(text: widget.value ?? widget.text));
      if (!mounted) return;
      setState(() => copied = true);
      // Match upstream completion ordering, including overlapping requests.
      // Own every timer so a late completion can never leave a live timer on disposal.
      late final Timer timer;
      timer = Timer(const Duration(milliseconds: 1500), () {
        timers.remove(timer);
        if (mounted) setState(() => copied = false);
        if (reset == timer) reset = null;
      });
      reset = timer;
      timers.add(timer);
      widget.onCopied?.call();
    } catch (error) {
      if (!mounted) return;
      setState(() => copied = false);
      widget.onCopyError?.call(error);
    }
  }

  @override
  void dispose() {
    for (final timer in timers) {
      timer.cancel();
    }
    ownFocus.dispose();
    fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final mono =
        widget.variant == SteyInlineCopyVariant.mono ||
        widget.variant == SteyInlineCopyVariant.monoSecondary;
    final fontSize = mono
        ? (widget.size == SteyInlineCopySize.lg ? 14.0 : 13.0)
        : switch (widget.size) {
            SteyInlineCopySize.xs => 12.0,
            SteyInlineCopySize.sm => 13.0,
            SteyInlineCopySize.base => 14.0,
            SteyInlineCopySize.lg => 16.0,
          };
    final active = hovered || focusVisible;
    final color = switch (widget.variant) {
      SteyInlineCopyVariant.secondary => c.subtle,
      SteyInlineCopyVariant.monoSecondary => active ? c.text : c.subtle,
      SteyInlineCopyVariant.success => c.link,
      SteyInlineCopyVariant.error => c.dangerText,
      _ => c.text,
    };
    final reveal = active || _CopyReveal.of(context);
    if (iconVisible != reveal) {
      iconVisible = reveal;
      fade.animateTo(reveal ? 1 : 0, curve: const Cubic(.4, 0, .2, 1));
    }
    final copiedLabel = widget.copiedLabel ?? SteyMessages.of(context).copied;
    final copyLabel =
        widget.copyActionLabel ??
        (Localizations.maybeLocaleOf(context)?.languageCode == 'ja'
            ? 'クリップボードにコピー'
            : 'Copy to clipboard');
    final node = widget.focusNode ?? ownFocus;
    final icon = CustomPaint(
      size: const Size(14, 14),
      painter: _InlineCopyIcon(copied, c.text),
    );
    final style = TextStyle(
      fontFamily: mono ? 'SteyCodeMono' : 'Inter',
      package: 'stey_ui_modern',
      fontSize: fontSize,
      height: 1.5,
      color: color,
      fontWeight: !mono && widget.bold ? FontWeight.w500 : FontWeight.w400,
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Focus(
        canRequestFocus: false,
        includeSemantics: false,
        onKeyEvent: (_, event) {
          if (widget.disabled) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.space) {
            if (event is KeyDownEvent) spacePressed = true;
            if (event is KeyUpEvent && spacePressed) {
              spacePressed = false;
              copy();
            }
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (event is KeyDownEvent || event is KeyRepeatEvent) copy();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: FocusableActionDetector(
          enabled: !widget.disabled,
          focusNode: node,
          autofocus: widget.autofocus,
          onFocusChange: (v) => setState(() {
            focused = v;
            if (!v) spacePressed = false;
          }),
          onShowFocusHighlight: (v) => setState(() => focusVisible = v),
          child: Semantics(
            button: true,
            enabled: !widget.disabled,
            focusable: !widget.disabled,
            focused: focused,
            label: copied ? copiedLabel : copyLabel,
            liveRegion: copied,
            excludeSemantics: true,
            onTap: widget.disabled
                ? null
                : () {
                    node.requestFocus();
                    copy();
                  },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => hovered = true),
              onExit: (_) => setState(() => hovered = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: widget.disabled
                    ? null
                    : () {
                        node.requestFocus();
                        copy();
                      },
                child: CustomPaint(
                  foregroundPainter: focusVisible
                      ? _InlineCopyFocus(c.brand)
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: IgnorePointer(
                          child: ExcludeFocus(
                            child: DefaultTextStyle(
                              style: style,
                              maxLines: widget.truncate ? 1 : null,
                              overflow: widget.truncate
                                  ? TextOverflow.ellipsis
                                  : TextOverflow.clip,
                              child: widget.child ?? Text(widget.text),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ExcludeSemantics(
                        child: copied
                            ? icon
                            : FadeTransition(opacity: fade, child: icon),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Native geometry equivalent to the Phosphor regular CopySimple/Check paths.
class _InlineCopyFocus extends CustomPainter {
  const _InlineCopyFocus(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(1),
      const Radius.circular(3),
    ),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  @override
  bool shouldRepaint(_InlineCopyFocus oldDelegate) =>
      color != oldDelegate.color;
}

class _InlineCopyIcon extends CustomPainter {
  const _InlineCopyIcon(this.checked, this.color);
  final bool checked;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 256, size.height / 256);
    final paint = Paint()..color = color;
    if (checked) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        Path()
          ..moveTo(40, 144)
          ..lineTo(96, 200)
          ..lineTo(224, 72),
        paint,
      );
    } else {
      final outline = Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(32, 64, 192, 224),
            const Radius.circular(8),
          ),
        )
        ..addRect(const Rect.fromLTRB(48, 80, 176, 208));
      canvas.drawPath(outline, paint);
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        Path()
          ..moveTo(72, 40)
          ..lineTo(216, 40)
          ..lineTo(216, 184),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InlineCopyIcon oldDelegate) =>
      checked != oldDelegate.checked || color != oldDelegate.color;
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
          semanticsLabel: code,
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
