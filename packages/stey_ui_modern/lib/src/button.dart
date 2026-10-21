import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'theme.dart';
import 'badge_link_scope.dart';
import 'messages.dart';
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
    this.style,
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
  final ButtonStyle? style;
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
    final hasContent = switch (widget.child) {
      Text(:final data, :final textSpan) =>
        (data ?? textSpan?.toPlainText() ?? '').isNotEmpty,
      SizedBox(width: 0, height: 0, child: null) => false,
      _ => true,
    };
    final hasLeading = widget.icon != null || widget.loading;
    final textLift = widget.shape == SteyButtonShape.base && hasContent
        ? (widget.size == SteySize.xs || widget.size == SteySize.sm ? .5 : 1.0)
        : 0.0;
    final gap = emphasis
        ? 6.0
        : switch (widget.size) {
            SteySize.xs || SteySize.sm => 4.0,
            SteySize.base => 6.0,
            SteySize.lg => 8.0,
          };
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
    final outerRadius = BorderRadius.circular(
      widget.shape == SteyButtonShape.circle ? 100 : widget.size.radius,
    );
    final group = context
        .dependOnInheritedWidgetOfExactType<_ButtonGroupSlot>();
    final radius =
        group?.radius(outerRadius, Directionality.of(context)) ?? outerRadius;
    final border = ghost
        ? Colors.transparent
        : emphasis
        ? danger
              ? c.dangerEmphasisRing
              : c.brandEmphasisRing
        : c.line;
    Widget? leading;
    if (hasLeading) {
      leading = Transform.translate(
        offset: Offset(0, textLift),
        child: widget.loading
            ? SteyLoader(size: widget.size == SteySize.lg ? 16 : 14)
            : IconTheme(
                data: IconThemeData(
                  size: widget.size.fontSize,
                  color: foreground,
                ),
                child: widget.icon!,
              ),
      );
      if (widget.shape != SteyButtonShape.base) {
        leading = Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, child: leading),
        );
      }
    }
    return Opacity(
      opacity: widget.onPressed == null || (widget.loading && emphasis)
          ? .5
          : 1,
      child: MergeSemantics(
        child: Semantics(
          label: widget.semanticLabel,
          hint: widget.semanticLabel != null && widget.loading
              ? SteyMessages.of(context).loading
              : null,
          child: TextButton(
            clipBehavior: Clip.none,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onPressed: disabled ? null : widget.onPressed,
            style: ButtonStyle(
              backgroundBuilder: emphasis
                  ? (context, states, child) => ClipRRect(
                      borderRadius: radius,
                      child: DecoratedBox(
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
                        child: CustomPaint(
                          painter: _ButtonTopHighlight(
                            danger
                                ? c.dangerEmphasisHover
                                : c.brandEmphasisHover,
                          ),
                          child: child,
                        ),
                      ),
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
                EdgeInsets.only(
                  left: widget.shape == SteyButtonShape.base
                      ? widget.size.padding -
                            (hasLeading && textLift > 0 ? 2 : 0)
                      : 0,
                  right: widget.shape == SteyButtonShape.base
                      ? widget.size.padding
                      : 0,
                  bottom: textLift * 2,
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
                  height: widget.size.fontSize == 12 ? 16 / 12 : 1.5,
                  letterSpacing: 0,
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
                  color: emphasis
                      ? border
                      : states.contains(WidgetState.focused)
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
            ).merge(widget.style),
            child: ExcludeSemantics(
              excluding: widget.semanticLabel != null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?leading,
                  if (hasLeading && hasContent) SizedBox(width: gap),
                  if (hasContent) Flexible(child: widget.child),
                  if (widget.trailing != null) ...[
                    SizedBox(width: gap),
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

/// Kumo's emphasis surface has a one-pixel inset highlight. It remains present
/// inside ButtonGroup, where only the control's outside drop shadow is removed.
class _ButtonTopHighlight extends CustomPainter {
  const _ButtonTopHighlight(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Rect.fromLTWH(0, 0, size.width, 1),
    Paint()..color = color,
  );
  @override
  bool shouldRepaint(_ButtonTopHighlight oldDelegate) =>
      color != oldDelegate.color;
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
    this.href,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final bool external;
  final Uri? href;
  @override
  Widget build(BuildContext context) => SteyBadgeLinkScope(
    child: Semantics(
      link: true,
      linkUrl: onPressed == null ? null : href,
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
    ),
  );
}

class SteyButtonGroup extends StatefulWidget {
  const SteyButtonGroup({
    super.key,
    required this.children,
    this.vertical = false,
    this.semanticLabel,
  });
  final List<Widget> children;
  final bool vertical;
  final String? semanticLabel;
  @override
  State<SteyButtonGroup> createState() => _SteyButtonGroupState();
}

class _SteyButtonGroupState extends State<SteyButtonGroup> {
  int? focused;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: widget.semanticLabel,
    child: _ButtonGroupLayout(
      vertical: widget.vertical,
      direction: Directionality.of(context),
      focused: focused,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Focus(
            key: ValueKey(widget.children[i].key ?? i),
            canRequestFocus: false,
            includeSemantics: false,
            onFocusChange: (value) {
              if (value || focused == i) {
                setState(() => focused = value ? i : null);
              }
            },
            child: _ButtonGroupSlot(
              first: i == 0,
              last: i == widget.children.length - 1,
              vertical: widget.vertical,
              child: widget.children[i],
            ),
          ),
      ],
    ),
  );
}

class _ButtonGroupSlot extends InheritedWidget {
  const _ButtonGroupSlot({
    required this.first,
    required this.last,
    required this.vertical,
    required super.child,
  });
  final bool first, last, vertical;
  BorderRadius radius(BorderRadius outer, TextDirection direction) {
    if (vertical) {
      return BorderRadius.only(
        topLeft: first ? outer.topLeft : Radius.zero,
        topRight: first ? outer.topRight : Radius.zero,
        bottomLeft: last ? outer.bottomLeft : Radius.zero,
        bottomRight: last ? outer.bottomRight : Radius.zero,
      );
    }
    final left = direction == TextDirection.ltr ? first : last;
    final right = direction == TextDirection.ltr ? last : first;
    return BorderRadius.only(
      topLeft: left ? outer.topLeft : Radius.zero,
      bottomLeft: left ? outer.bottomLeft : Radius.zero,
      topRight: right ? outer.topRight : Radius.zero,
      bottomRight: right ? outer.bottomRight : Radius.zero,
    );
  }

  @override
  bool updateShouldNotify(_ButtonGroupSlot oldWidget) =>
      first != oldWidget.first ||
      last != oldWidget.last ||
      vertical != oldWidget.vertical;
}

class _GroupParentData extends ContainerBoxParentData<RenderBox> {}

class _ButtonGroupLayout extends MultiChildRenderObjectWidget {
  const _ButtonGroupLayout({
    required this.vertical,
    required this.direction,
    required this.focused,
    required super.children,
  });
  final bool vertical;
  final TextDirection direction;
  final int? focused;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderButtonGroup(vertical, direction, focused);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderButtonGroup renderObject,
  ) {
    renderObject
      ..vertical = vertical
      ..direction = direction
      ..focused = focused
      ..markNeedsLayout();
  }
}

/// A one-pixel overlap without translating the controls away from their hit
/// regions. Paint order changes on focus; semantics and Tab order stay stable.
class _RenderButtonGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GroupParentData> {
  _RenderButtonGroup(this.vertical, this.direction, this.focused);
  bool vertical;
  TextDirection direction;
  int? focused;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GroupParentData) {
      child.parentData = _GroupParentData();
    }
  }

  BoxConstraints get childConstraints => vertical
      ? BoxConstraints(maxWidth: constraints.maxWidth)
      : BoxConstraints(maxHeight: constraints.maxHeight);
  @override
  void performLayout() {
    var main = 0.0, cross = 0.0;
    final children = getChildrenAsList();
    for (final child in children) {
      child.layout(childConstraints, parentUsesSize: true);
      main += vertical ? child.size.height : child.size.width;
      cross = (vertical ? child.size.width : child.size.height) > cross
          ? (vertical ? child.size.width : child.size.height)
          : cross;
    }
    if (children.length > 1) main -= children.length - 1;
    size = constraints.constrain(
      vertical ? Size(cross, main) : Size(main, cross),
    );
    var cursor = 0.0;
    for (final child in children) {
      child.layout(
        vertical
            ? BoxConstraints.tightFor(width: cross)
            : BoxConstraints.tightFor(height: cross),
        parentUsesSize: true,
      );
      final data = child.parentData! as _GroupParentData;
      data.offset = vertical
          ? Offset(0, cursor)
          : Offset(
              direction == TextDirection.rtl
                  ? main - cursor - child.size.width
                  : cursor,
              0,
            );
      cursor += (vertical ? child.size.height : child.size.width) - 1;
    }
  }

  Iterable<RenderBox> get paintOrder sync* {
    final children = getChildrenAsList();
    for (var i = 0; i < children.length; i++) {
      if (i != focused) yield children[i];
    }
    if (focused != null && focused! < children.length) yield children[focused!];
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in paintOrder) {
      context.paintChild(
        child,
        offset + (child.parentData! as _GroupParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in paintOrder.toList().reversed) {
      if (result.addWithPaintOffset(
        offset: (child.parentData! as _GroupParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      )) {
        return true;
      }
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.translateByDouble(
        (child.parentData! as _GroupParentData).offset.dx,
        (child.parentData! as _GroupParentData).offset.dy,
        0,
        1,
      );
}
