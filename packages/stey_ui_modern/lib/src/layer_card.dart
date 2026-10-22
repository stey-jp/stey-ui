import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'theme.dart';

/// A single surface, or a layered card when direct children contain sections.
class SteyLayerCard extends StatelessWidget {
  const SteyLayerCard({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.padding,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
    this.semanticLabel,
  }) : children = null;

  const SteyLayerCard.layers({
    super.key,
    required this.children,
    this.padding,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
    this.semanticLabel,
  }) : child = null,
       header = null,
       footer = null;

  final Widget? child, header, footer;
  final List<Widget>? children;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Clip clipBehavior;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final legacy = header != null || footer != null;
    final parts = legacy
        ? <Widget>[
            if (header != null)
              SteyLayerCardSecondary(padding: padding, child: header!),
            SteyLayerCardPrimary(padding: padding, child: child!),
            if (footer != null)
              SteyLayerCardSecondary(padding: padding, child: footer!),
          ]
        : children ?? [child!];
    final layered = parts.any(
      (p) => p is SteyLayerCardPrimary || p is SteyLayerCardSecondary,
    );
    final radius = borderRadius ?? BorderRadius.circular(8);
    Widget content = Padding(
      padding: legacy ? EdgeInsets.zero : padding ?? EdgeInsets.zero,
      child: layered
          ? _LayeredCardBody(children: parts)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: parts,
            ),
    );
    if (clipBehavior != Clip.none) {
      content = ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: content,
      );
    }
    if (layered) {
      content = DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 14, height: 1.5),
        child: content,
      );
    }
    return Semantics(
      container: semanticLabel != null,
      explicitChildNodes: semanticLabel != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: layered ? c.elevated : c.base,
          borderRadius: radius,
          boxShadow: [
            if (!layered)
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            BoxShadow(color: layered ? c.hairline : c.line, spreadRadius: 1),
          ],
        ),
        child: content,
      ),
    );
  }
}

class SteyLayerCardPrimary extends StatelessWidget {
  const SteyLayerCardPrimary({
    super.key,
    this.child,
    this.children,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.clipBehavior = Clip.antiAlias,
    this.semanticLabel,
  }) : assert((child == null) != (children == null));
  final Widget? child;
  final List<Widget>? children;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    Widget content = Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: children ?? [child!],
      ),
    );
    if (clipBehavior != Clip.none) {
      content = ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: content,
      );
    }
    return Semantics(
      container: semanticLabel != null,
      explicitChildNodes: semanticLabel != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.base,
          borderRadius: borderRadius,
          boxShadow: [BoxShadow(color: c.fill, spreadRadius: 1)],
        ),
        child: content,
      ),
    );
  }
}

class SteyLayerCardSecondary extends StatelessWidget {
  const SteyLayerCardSecondary({
    super.key,
    this.child,
    this.children,
    this.padding,
    this.semanticLabel,
  }) : assert((child == null) != (children == null));
  final Widget? child;
  final List<Widget>? children;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return _SecondaryMargin(
      child: Semantics(
        container: semanticLabel != null,
        explicitChildNodes: semanticLabel != null,
        label: semanticLabel,
        child: ColoredBox(
          color: c.elevated,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: c.subtle,
                fontWeight: FontWeight.w500,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: children ?? [Flexible(child: child!)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum SteySurfaceColor { primary, secondary }

/// Deprecated Kumo compatibility wrapper. Both colors share the same paint.
@Deprecated('Use SteyLayerCard.')
class SteySurface extends SteyLayerCard {
  const SteySurface({
    super.key,
    required super.child,
    super.header,
    super.footer,
    super.padding,
    super.borderRadius = BorderRadius.zero,
    super.clipBehavior = Clip.none,
    super.semanticLabel,
    this.color = SteySurfaceColor.primary,
  });
  const SteySurface.layers({
    super.key,
    required super.children,
    super.padding,
    super.borderRadius = BorderRadius.zero,
    super.clipBehavior = Clip.none,
    super.semanticLabel,
    this.color = SteySurfaceColor.primary,
  }) : super.layers();
  final SteySurfaceColor color;
}

// CSS positioned Primary sections paint above static Secondary siblings,
// including a later footer. Keep document/semantics order for reading.
class _LayeredCardBody extends MultiChildRenderObjectWidget {
  const _LayeredCardBody({required super.children});
  Set<int> get foreground => {
    for (var i = 0; i < children.length; i++)
      if (children[i] is SteyLayerCardPrimary) i,
  };
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _LayeredCardFlex(foreground, Directionality.of(context));
  @override
  void updateRenderObject(BuildContext context, _LayeredCardFlex renderObject) {
    renderObject.foreground = foreground;
    renderObject.textDirection = Directionality.of(context);
  }
}

class _LayeredCardFlex extends RenderFlex {
  _LayeredCardFlex(this._foreground, TextDirection direction)
    : super(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        textDirection: direction,
      );
  Set<int> _foreground;
  set foreground(Set<int> value) {
    _foreground = value;
    markNeedsPaint();
  }

  List<RenderBox> get paintOrder {
    final background = <RenderBox>[], front = <RenderBox>[];
    var child = firstChild, index = 0;
    while (child != null) {
      (_foreground.contains(index) ? front : background).add(child);
      child = childAfter(child);
      index++;
    }
    return [...background, ...front];
  }

  @override
  void defaultPaint(PaintingContext context, Offset offset) {
    for (final child in paintOrder) {
      context.paintChild(
        child,
        offset + (child.parentData! as FlexParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in paintOrder.reversed) {
      if (result.addWithPaintOffset(
        offset: (child.parentData! as FlexParentData).offset,
        position: position,
        hitTest: (result, position) =>
            child.hitTest(result, position: position),
      )) {
        return true;
      }
    }
    return false;
  }
}

// CSS flex items with -8px block margins consume 16px less space. Preserve
// their actual painted, semantic and interactive bounds, including overlap.
class _SecondaryMargin extends SingleChildRenderObjectWidget {
  const _SecondaryMargin({required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _SecondaryMarginBox();
}

class _SecondaryMarginBox extends RenderShiftedBox {
  _SecondaryMarginBox() : super(null);
  BoxConstraints inner(BoxConstraints constraints) => constraints.copyWith(
    minHeight: constraints.minHeight + 16,
    maxHeight: constraints.maxHeight + 16,
  );
  Size outer(Size childSize, BoxConstraints constraints) => constraints
      .constrain(Size(childSize.width, math.max(0, childSize.height - 16)));
  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      outer(child!.getDryLayout(inner(constraints)), constraints);
  @override
  double computeMinIntrinsicWidth(double height) =>
      child!.getMinIntrinsicWidth(height + 16);
  @override
  double computeMaxIntrinsicWidth(double height) =>
      child!.getMaxIntrinsicWidth(height + 16);
  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(0, child!.getMinIntrinsicHeight(width) - 16);
  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(0, child!.getMaxIntrinsicHeight(width) - 16);
  @override
  void performLayout() {
    child!.layout(inner(constraints), parentUsesSize: true);
    size = outer(child!.size, constraints);
    (child!.parentData! as BoxParentData).offset = const Offset(0, -8);
  }

  @override
  Rect get paintBounds => super.paintBounds.expandToInclude(
    child!.paintBounds.shift(const Offset(0, -8)),
  );
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      hitTestChildren(result, position: position);
}
