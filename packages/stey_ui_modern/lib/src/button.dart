import 'package:flutter/material.dart';

import 'theme.dart';
import 'loader.dart';

class _ButtonRingBorder extends RoundedRectangleBorder {
  const _ButtonRingBorder({required super.borderRadius, super.side});
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  _ButtonRingBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => _ButtonRingBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
  );
  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is RoundedRectangleBorder
      ? _ButtonRingBorder(
          side: BorderSide.lerp(a.side, side, t),
          borderRadius: BorderRadiusGeometry.lerp(
            a.borderRadius,
            borderRadius,
            t,
          )!,
        )
      : super.lerpFrom(a, t);
  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is RoundedRectangleBorder
      ? _ButtonRingBorder(
          side: BorderSide.lerp(side, b.side, t),
          borderRadius: BorderRadiusGeometry.lerp(
            borderRadius,
            b.borderRadius,
            t,
          )!,
        )
      : super.lerpTo(b, t);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawRRect(
      borderRadius.resolve(textDirection).toRRect(rect).inflate(side.width / 2),
      side.toPaint(),
    );
  }
}

enum SteyButtonVariant {
  primary,
  secondary,
  ghost,
  destructive,
  secondaryDestructive,
  outline,
}

enum SteyButtonShape { base, square, circle }

class SteyButton extends StatefulWidget {
  const SteyButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = SteyButtonVariant.secondary,
    this.size = SteySize.base,
    this.shape = SteyButtonShape.base,
    this.icon,
    this.trailing,
    this.loading = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.alignment = Alignment.center,
    this.backgroundColor,
    this.foregroundColor,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final SteyButtonVariant variant;
  final SteySize size;
  final SteyButtonShape shape;
  final Widget? icon, trailing;
  final bool loading, autofocus;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final AlignmentGeometry alignment;
  final Color? backgroundColor, foregroundColor;
  @override
  State<SteyButton> createState() => _SteyButtonState();
}

class _SteyButtonState extends State<SteyButton> {
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final emphasis =
        widget.variant == SteyButtonVariant.primary ||
        widget.variant == SteyButtonVariant.destructive;
    final danger =
        widget.variant == SteyButtonVariant.destructive ||
        widget.variant == SteyButtonVariant.secondaryDestructive;
    final ghost = widget.variant == SteyButtonVariant.ghost;
    final disabled = widget.onPressed == null || widget.loading;
    final compactHeight = widget.size == SteySize.xs
        ? 14.0
        : widget.size.height;
    final accent = danger ? c.danger : c.brand;
    final foreground =
        widget.foregroundColor ??
        (emphasis
            ? Colors.white
            : danger
            ? c.dangerText
            : c.text);
    final radius = BorderRadius.circular(
      widget.shape == SteyButtonShape.circle ? 100 : widget.size.radius,
    );
    final border = ghost
        ? Colors.transparent
        : emphasis
        ? danger
              ? c.dangerEmphasisRing
              : c.brandEmphasisRing
        : c.line;
    return Opacity(
      opacity: widget.onPressed == null || (widget.loading && emphasis)
          ? .5
          : 1,
      child: MergeSemantics(
        child: Semantics(
          label: widget.semanticLabel,
          hint: widget.semanticLabel != null && widget.loading
              ? 'Loading'
              : null,
          child: TextButton(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onPressed: disabled ? null : widget.onPressed,
            style: ButtonStyle(
              backgroundBuilder: emphasis
                  ? (context, states, child) => DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            (danger
                                ? (states.contains(WidgetState.hovered)
                                      ? c.dangerEmphasisHover
                                      : c.dangerEmphasisStart)
                                : (states.contains(WidgetState.hovered)
                                      ? c.brandEmphasisHover
                                      : c.brandEmphasisStart)),
                            accent,
                          ],
                        ),
                      ),
                      child: child,
                    )
                  : null,
              alignment: widget.alignment,
              animationDuration: Duration.zero,
              minimumSize: WidgetStatePropertyAll(
                Size(
                  0,
                  widget.shape == SteyButtonShape.base
                      ? widget.size.height
                      : compactHeight,
                ),
              ),
              fixedSize: widget.shape == SteyButtonShape.base
                  ? null
                  : WidgetStatePropertyAll(Size.square(compactHeight)),
              maximumSize: widget.shape == SteyButtonShape.base
                  ? null
                  : WidgetStatePropertyAll(Size.square(compactHeight)),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(
                  horizontal: widget.shape == SteyButtonShape.base
                      ? widget.size.padding
                      : 0,
                ),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.standard,
              textStyle: WidgetStatePropertyAll(
                TextStyle(
                  fontFamily: 'Inter',
                  package: 'stey_ui_modern',
                  fontSize: widget.size.fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (disabled && !emphasis) {
                  return ghost || widget.variant == SteyButtonVariant.outline
                      ? c.subtle
                      : foreground.withValues(alpha: .7);
                }
                if (widget.variant == SteyButtonVariant.outline &&
                    states.contains(WidgetState.hovered)) {
                  return c.strong;
                }
                return foreground;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (widget.backgroundColor != null) {
                  return widget.backgroundColor;
                }
                if (emphasis) {
                  return Colors.transparent;
                }
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.pressed)) {
                  if (ghost || widget.variant == SteyButtonVariant.secondary) {
                    return c.tint;
                  }
                }
                return ghost || widget.variant == SteyButtonVariant.outline
                    ? Colors.transparent
                    : disabled
                    ? c.base.withValues(alpha: .5)
                    : c.base;
              }),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.focused)
                      ? c.brand
                      : states.contains(WidgetState.hovered) &&
                            !disabled &&
                            widget.variant ==
                                SteyButtonVariant.secondaryDestructive
                      ? c.danger.withValues(alpha: .3)
                      : states.contains(WidgetState.hovered) &&
                            !disabled &&
                            widget.variant == SteyButtonVariant.outline
                      ? c.focus.withValues(alpha: .25)
                      : border,
                  width: states.contains(WidgetState.focused) ? 2 : 1,
                ),
              ),
              shape: WidgetStatePropertyAll(
                _ButtonRingBorder(borderRadius: radius),
              ),
            ),
            child: ExcludeSemantics(
              excluding: widget.semanticLabel != null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.loading)
                    SteyLoader(size: widget.size == SteySize.lg ? 16 : 14)
                  else if (widget.icon != null)
                    IconTheme(
                      data: IconThemeData(size: 16, color: foreground),
                      child: widget.icon!,
                    ),
                  if (widget.icon != null || widget.loading)
                    const SizedBox(width: 6),
                  Flexible(child: widget.child),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 6),
                    widget.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SteyRefreshButton extends StatelessWidget {
  const SteyRefreshButton({
    super.key,
    required this.onPressed,
    this.refreshing = false,
    this.label = 'Refresh',
  });
  final VoidCallback? onPressed;
  final bool refreshing;
  final String label;
  @override
  Widget build(BuildContext context) => SteyButton(
    onPressed: onPressed,
    loading: refreshing,
    icon: const Icon(Icons.refresh),
    child: Text(label),
  );
}

class SteyLink extends StatelessWidget {
  const SteyLink({
    super.key,
    required this.child,
    required this.onPressed,
    this.external = false,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final bool external;
  @override
  Widget build(BuildContext context) => Semantics(
    link: true,
    child: SteyButton(
      onPressed: onPressed,
      variant: SteyButtonVariant.ghost,
      trailing: external ? const Icon(Icons.open_in_new, size: 12) : null,
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: SteyTheme.colorsOf(context).link,
          decoration: TextDecoration.underline,
        ),
        child: child,
      ),
    ),
  );
}

class SteyButtonGroup extends StatelessWidget {
  const SteyButtonGroup({
    super.key,
    required this.children,
    this.vertical = false,
  });
  final List<Widget> children;
  final bool vertical;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
    child: Flex(
      direction: vertical ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  );
}
