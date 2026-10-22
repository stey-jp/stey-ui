import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'messages.dart';
import 'theme.dart';

/// Native label content. Associate an editor with [controlFocusNode] or [onTap]
/// and give that editor its own accessible name; this is not an HTML ID binding.
class SteyLabel extends StatelessWidget {
  const SteyLabel(
    this.text, {
    super.key,
    this.required,
    this.showOptional = false,
    this.optionalLabel,
    this.optionalContent,
    this.tooltip,
    this.tooltipContent,
    this.tooltipAriaLabel,
    this.tooltipSemanticLabel,
    this.asContent = false,
    this.excludeTextSemantics = false,
    this.weight = FontWeight.w500,
    this.onTap,
    this.controlFocusNode,
  }) : child = null;

  const SteyLabel.rich(
    Widget this.child, {
    super.key,
    this.required,
    this.showOptional = false,
    this.optionalLabel,
    this.optionalContent,
    this.tooltip,
    this.tooltipContent,
    this.tooltipAriaLabel,
    this.tooltipSemanticLabel,
    this.asContent = false,
    this.excludeTextSemantics = false,
    this.weight = FontWeight.w500,
    this.onTap,
    this.controlFocusNode,
  }) : text = '';

  final String text;
  final Widget? child, optionalContent, tooltipContent;
  final String? optionalLabel, tooltip, tooltipAriaLabel, tooltipSemanticLabel;
  final bool? required;
  final bool showOptional, asContent, excludeTextSemantics;
  final FontWeight weight;
  final VoidCallback? onTap;
  final FocusNode? controlFocusNode;

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final japanese = SteyMessages.of(context).japanese;
    final optional = showOptional || required == false;
    final help =
        tooltipContent ?? (tooltip?.isNotEmpty == true ? Text(tooltip!) : null);
    final style = asContent
        ? DefaultTextStyle.of(context).style
        : DefaultTextStyle.of(context).style.copyWith(
            fontSize: 14,
            height: 1.5,
            fontWeight: weight,
            color: c.text,
          );
    void activate() {
      final editor = controlFocusNode?.context
          ?.findAncestorStateOfType<EditableTextState>();
      if (editor != null) {
        editor.requestKeyboard();
      } else {
        controlFocusNode?.requestFocus();
      }
      onTap?.call();
    }

    final parts = <Widget>[
      ExcludeSemantics(
        excluding: excludeTextSemantics,
        child: child ?? Text(text),
      ),
      if (optional)
        ExcludeSemantics(
          excluding: excludeTextSemantics,
          child: DefaultTextStyle.merge(
            style: TextStyle(fontWeight: FontWeight.w400, color: c.subtle),
            child:
                optionalContent ??
                Text(optionalLabel ?? (japanese ? '（任意）' : '(optional)')),
          ),
        ),
      if (help != null)
        _LabelInfo(
          content: help,
          description: tooltipSemanticLabel ?? tooltip,
          semanticLabel:
              tooltipAriaLabel ?? (japanese ? '詳しい情報' : 'More information'),
        ),
    ];
    final measurable =
        (child == null || child is Text || child is RichText) &&
        (optionalContent == null ||
            optionalContent is Text ||
            optionalContent is RichText);
    return DefaultTextStyle.merge(
      style: style,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: onTap != null || controlFocusNode != null ? activate : null,
        child: measurable
            ? _LabelFlex(
                textCount: optional ? 2 : 1,
                direction: Directionality.of(context),
                children: parts,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Flexible(child: parts.first),
                  if (optional) Flexible(child: parts[1]),
                  if (help != null) parts.last,
                ],
              ),
      ),
    );
  }
}

class _LabelFlex extends MultiChildRenderObjectWidget {
  const _LabelFlex({
    required this.textCount,
    required this.direction,
    required super.children,
  });
  final int textCount;
  final TextDirection direction;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _LabelFlexBox(textCount, direction);
  @override
  void updateRenderObject(BuildContext context, _LabelFlexBox renderObject) =>
      renderObject.update(textCount, direction);
}

class _LabelFlexParentData extends ContainerBoxParentData<RenderBox> {}

class _LabelFlexBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _LabelFlexParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _LabelFlexParentData> {
  _LabelFlexBox(this.textCount, this.direction);
  int textCount;
  TextDirection direction;
  void update(int count, TextDirection value) {
    if (count == textCount && value == direction) return;
    textCount = count;
    direction = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _LabelFlexParentData) {
      child.parentData = _LabelFlexParentData();
    }
  }

  List<RenderBox> get boxes {
    final result = <RenderBox>[];
    RenderBox? current = firstChild;
    while (current != null) {
      result.add(current);
      current = childAfter(current);
    }
    return result;
  }

  // RenderParagraph's intrinsic painter can retain pre-fallback font metrics
  // after systemFontsDidChange. Measure a fresh painter so CJK labels are not
  // constrained to the earlier missing-glyph width after their font loads.
  TextPainter? textPainter(RenderBox child) {
    RenderParagraph? paragraph;
    void visit(RenderObject object) {
      if (object is RenderParagraph) {
        paragraph ??= object;
      } else {
        object.visitChildren(visit);
      }
    }

    visit(child);
    final text = paragraph;
    if (text == null || text.childCount != 0) return null;
    return TextPainter(
      text: text.text,
      textAlign: text.textAlign,
      textDirection: text.textDirection,
      textScaler: text.textScaler,
      maxLines: text.maxLines,
      ellipsis: text.overflow == TextOverflow.ellipsis ? '\u2026' : null,
      locale: text.locale,
      strutStyle: text.strutStyle,
      textWidthBasis: text.textWidthBasis,
      textHeightBehavior: text.textHeightBehavior,
    );
  }

  (double, double) intrinsicWidths(RenderBox child) {
    final painter = textPainter(child);
    if (painter == null) {
      return (
        child.getMinIntrinsicWidth(double.infinity),
        child.getMaxIntrinsicWidth(double.infinity),
      );
    }
    try {
      painter.layout();
      return (painter.minIntrinsicWidth, painter.maxIntrinsicWidth);
    } finally {
      painter.dispose();
    }
  }

  double intrinsicHeight(RenderBox child, double width, {required bool max}) {
    final painter = textPainter(child);
    if (painter == null) {
      return max
          ? child.getMaxIntrinsicHeight(width)
          : child.getMinIntrinsicHeight(width);
    }
    try {
      painter.layout(maxWidth: width);
      return painter.height;
    } finally {
      painter.dispose();
    }
  }

  List<double> widths(double available, List<RenderBox> children) {
    final metrics = [for (final child in children) intrinsicWidths(child)];
    final preferred = [for (final metric in metrics) metric.$2];
    final minimum = [
      for (var i = 0; i < children.length; i++)
        i < textCount ? metrics[i].$1 : preferred[i],
    ];
    final gap = (children.length - 1) * 4.0;
    final limit = available.isFinite
        ? (available - gap).clamp(0.0, double.infinity)
        : preferred.fold(0.0, (a, b) => a + b);
    final result = List<double>.of(preferred);
    final frozen = <int>{for (var i = textCount; i < children.length; i++) i};
    for (var pass = 0; pass <= children.length; pass++) {
      final excess = result.fold(0.0, (a, b) => a + b) - limit;
      if (excess <= .001) break;
      final weight = [
        for (var i = 0; i < textCount; i++)
          if (!frozen.contains(i)) preferred[i],
      ].fold(0.0, (a, b) => a + b);
      if (weight <= 0) break;
      for (var i = 0; i < textCount; i++) {
        if (frozen.contains(i)) continue;
        final proposed = result[i] - excess * preferred[i] / weight;
        result[i] = proposed < minimum[i] ? minimum[i] : proposed;
        if (proposed <= minimum[i]) frozen.add(i);
      }
    }
    return result;
  }

  Size layoutChildren(BoxConstraints constraints, {required bool dry}) {
    final children = boxes, allocation = widths(constraints.maxWidth, boxes);
    var height = 0.0, total = (children.length - 1) * 4.0;
    final sizes = <Size>[];
    for (var i = 0; i < children.length; i++) {
      final inner = BoxConstraints.tightFor(width: allocation[i]);
      final childSize = dry
          ? Size(
              allocation[i],
              intrinsicHeight(children[i], allocation[i], max: true),
            )
          : (children[i]..layout(inner, parentUsesSize: true)).size;
      sizes.add(childSize);
      total += childSize.width;
      if (height < childSize.height) height = childSize.height;
    }
    final result = constraints.constrain(Size(total, height));
    if (!dry) {
      var x = direction == TextDirection.ltr ? 0.0 : result.width;
      for (var i = 0; i < children.length; i++) {
        if (direction == TextDirection.rtl) x -= sizes[i].width;
        (children[i].parentData! as _LabelFlexParentData).offset = Offset(
          x,
          (height - sizes[i].height) / 2,
        );
        x += direction == TextDirection.ltr ? sizes[i].width + 4 : -4;
      }
    }
    return result;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      layoutChildren(constraints, dry: true);
  @override
  void performLayout() {
    size = layoutChildren(constraints, dry: false);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      boxes.fold(0.0, (v, c) => v + intrinsicWidths(c).$1) +
      (childCount - 1) * 4;
  @override
  double computeMaxIntrinsicWidth(double height) =>
      boxes.fold(0.0, (v, c) => v + intrinsicWidths(c).$2) +
      (childCount - 1) * 4;
  @override
  double computeMinIntrinsicHeight(double width) {
    final children = boxes, allocation = widths(width, boxes);
    var height = 0.0;
    for (var i = 0; i < children.length; i++) {
      final childHeight = intrinsicHeight(
        children[i],
        allocation[i],
        max: false,
      );
      if (height < childHeight) height = childHeight;
    }
    return height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final children = boxes, allocation = widths(width, boxes);
    var height = 0.0;
    for (var i = 0; i < children.length; i++) {
      final childHeight = intrinsicHeight(
        children[i],
        allocation[i],
        max: true,
      );
      if (height < childHeight) height = childHeight;
    }
    return height;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

class _LabelInfo extends StatefulWidget {
  const _LabelInfo({
    required this.content,
    required this.semanticLabel,
    this.description,
  });
  final Widget content;
  final String semanticLabel;
  final String? description;
  @override
  State<_LabelInfo> createState() => _LabelInfoState();
}

class _LabelInfoState extends State<_LabelInfo>
    with SingleTickerProviderStateMixin {
  final focus = FocusNode();
  final anchorKey = GlobalKey();
  OverlayEntry? entry;
  Rect? lastAnchor;
  bool tracking = false;
  final placement = _LabelTooltipPlacement();
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    animationBehavior: AnimationBehavior.preserve,
  );
  late final progress = CurvedAnimation(parent: animation, curve: Curves.ease);
  Timer? pending;
  bool hovered = false;
  @override
  void initState() {
    super.initState();
    focus.addListener(focusChanged);
    animation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) removeEntry();
    });
  }

  void focusChanged() {
    if (focus.hasFocus) {
      show();
    } else {
      hide();
    }
  }

  void show() {
    pending?.cancel();
    if (entry == null) {
      entry = OverlayEntry(
        builder: (_) {
          final anchor = anchorRect();
          if (anchor == null) return const SizedBox.shrink();
          return Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _LabelTooltipLayout(anchor, placement),
              child: MediaQuery(
                data: MediaQuery.of(context),
                child: TapRegion(
                  groupId: this,
                  child: MouseRegion(
                    onEnter: (_) => pending?.cancel(),
                    onExit: (_) {
                      if (!focus.hasFocus) hide();
                    },
                    child: buildPopup(context),
                  ),
                ),
              ),
            ),
          );
        },
      );
      Overlay.of(context).insert(entry!);
      if (!tracking) {
        tracking = true;
        WidgetsBinding.instance.addPostFrameCallback(trackAnchor);
      }
    }
    animation.forward();
  }

  void hide() {
    pending?.cancel();
    if (animation.isDismissed) {
      removeEntry();
    } else {
      animation.reverse();
    }
  }

  Rect? anchorRect() {
    final box = anchorKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(context).context.findRenderObject();
    if (box is! RenderBox ||
        overlay is! RenderBox ||
        !box.attached ||
        !box.hasSize) {
      return null;
    }
    return MatrixUtils.transformRect(
      box.getTransformTo(overlay),
      Offset.zero & box.size,
    );
  }

  void trackAnchor(Duration _) {
    if (!mounted || entry == null) {
      tracking = false;
      return;
    }
    final next = anchorRect();
    if (next != lastAnchor) {
      lastAnchor = next;
      entry?.markNeedsBuild();
    }
    // Scroll/resize/paint animations schedule their own frames; do not keep an
    // idle application rendering solely for a stationary information popup.
    WidgetsBinding.instance.addPostFrameCallback(trackAnchor);
  }

  void removeEntry() {
    final old = entry;
    entry = null;
    lastAnchor = null;
    old?.remove();
    old?.dispose();
  }

  @override
  void didUpdateWidget(_LabelInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    refreshEntry();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    refreshEntry();
  }

  void refreshEntry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) entry?.markNeedsBuild();
    });
  }

  @override
  void dispose() {
    pending?.cancel();
    removeEntry();
    focus.removeListener(focusChanged);
    focus.dispose();
    progress.dispose();
    animation.dispose();
    super.dispose();
  }

  Widget buildPopup(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return FadeTransition(
      opacity: progress,
      child: ScaleTransition(
        scale: Tween(begin: .9, end: 1.0).animate(progress),
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (MediaQuery.sizeOf(context).width - 20).clamp(
              0,
              double.infinity,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.base,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(color: c.line, spreadRadius: 1),
                BoxShadow(
                  color: Colors.black.withValues(alpha: .1),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomPaint(
              foregroundPainter: _LabelTooltipArrow(c, placement),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: 'Inter',
                    package: 'stey_ui_modern',
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: c.text,
                  ),
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    child: widget.content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.tab &&
            focus.hasFocus) {
          final backwards = HardwareKeyboard.instance.isShiftPressed;
          if (backwards) {
            focus.previousFocus();
          } else {
            focus.nextFocus();
          }
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          hide();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TapRegion(
        key: anchorKey,
        groupId: this,
        onTapOutside: (_) => hide(),
        child: MouseRegion(
          cursor: SystemMouseCursors.basic,
          onEnter: (_) {
            hovered = true;
            pending?.cancel();
            pending = Timer(const Duration(milliseconds: 600), () {
              if (mounted && hovered) show();
            });
          },
          onExit: (_) {
            hovered = false;
            pending?.cancel();
            if (!focus.hasFocus) {
              pending = Timer(const Duration(milliseconds: 80), () {
                if (mounted) hide();
              });
            }
          },
          child: MergeSemantics(
            child: Semantics(
              hint: widget.description,
              child: SteyButton(
                focusNode: focus,
                onPressed: show,
                variant: SteyButtonVariant.ghost,
                size: SteySize.xs,
                shape: SteyButtonShape.square,
                style: const ButtonStyle(
                  mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.basic),
                ),
                semanticLabel: widget.semanticLabel,
                child: OverflowBox(
                  minWidth: 16,
                  maxWidth: 16,
                  minHeight: 16,
                  maxHeight: 16,
                  child: CustomPaint(
                    size: const Size.square(16),
                    painter: _LabelInfoIcon(c.text),
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

class _LabelTooltipLayout extends SingleChildLayoutDelegate {
  const _LabelTooltipLayout(this.anchor, this.placement);
  final Rect anchor;
  final _LabelTooltipPlacement placement;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          (constraints.maxWidth - 10).clamp(0, double.infinity),
          (constraints.maxHeight - 10).clamp(0, double.infinity),
        ),
      );
  @override
  Offset getPositionForChild(Size size, Size childSize) => placement.position(
    TooltipPositionContext(
      target: anchor.center,
      targetSize: anchor.size,
      tooltipSize: childSize,
      overlaySize: size,
      verticalOffset: 10,
      preferBelow: false,
    ),
  );
  @override
  bool shouldRelayout(_LabelTooltipLayout oldDelegate) =>
      anchor != oldDelegate.anchor || placement != oldDelegate.placement;
}

class _LabelTooltipPlacement {
  bool below = false;
  double arrowX = 10;
  Offset position(TooltipPositionContext context) {
    final s = context.tooltipSize, limit = context.overlaySize;
    final top =
        context.target.dy - context.targetSize.height / 2 - 10 - s.height;
    below = top < 5;
    final x = (context.target.dx - s.width / 2).clamp(
      5.0,
      (limit.width - s.width - 5).clamp(5.0, double.infinity),
    );
    final y =
        (below ? context.target.dy + context.targetSize.height / 2 + 10 : top)
            .clamp(
              5.0,
              (limit.height - s.height - 5).clamp(5.0, double.infinity),
            );
    arrowX = (context.target.dx - x).clamp(
      10.0,
      (s.width - 10).clamp(10.0, double.infinity),
    );
    return Offset(x, y);
  }
}

class _LabelInfoIcon extends CustomPainter {
  const _LabelInfoIcon(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    // Phosphor regular Info geometry, MIT.
    canvas.save();
    canvas.scale(size.width / 256, size.height / 256);
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: Offset(128, 128), radius: 104))
      ..addOval(Rect.fromCircle(center: Offset(128, 128), radius: 88));
    final stem = Path()
      ..moveTo(144, 176)
      ..arcToPoint(const Offset(136, 184), radius: const Radius.circular(8))
      ..arcToPoint(const Offset(120, 168), radius: const Radius.circular(16))
      ..lineTo(120, 128)
      ..arcToPoint(const Offset(120, 112), radius: const Radius.circular(8))
      ..arcToPoint(const Offset(136, 128), radius: const Radius.circular(16))
      ..lineTo(136, 168)
      ..arcToPoint(const Offset(144, 176), radius: const Radius.circular(8))
      ..close();
    final paint = Paint()..color = color;
    canvas.drawPath(ring, paint);
    canvas.drawPath(stem, paint);
    canvas.drawCircle(const Offset(124, 84), 12, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LabelInfoIcon oldDelegate) => color != oldDelegate.color;
}

class _LabelTooltipArrow extends CustomPainter {
  const _LabelTooltipArrow(this.colors, this.placement);
  final SteyColors colors;
  final _LabelTooltipPlacement placement;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(
      placement.arrowX - 10,
      placement.below ? -8 : size.height - 2,
    );
    if (!placement.below) {
      canvas.translate(20, 10);
      canvas.rotate(3.141592653589793);
    }
    final fill = Path()
      ..moveTo(9.66437, 2.60207)
      ..lineTo(4.80758, 6.97318)
      ..cubicTo(4.07308, 7.63423, 3.11989, 8, 2.13172, 8)
      ..lineTo(0, 8)
      ..lineTo(0, 10)
      ..lineTo(20, 10)
      ..lineTo(20, 8)
      ..lineTo(18.5349, 8)
      ..cubicTo(17.5468, 8, 16.5936, 7.63423, 15.8591, 6.97318)
      ..lineTo(11.0023, 2.60207)
      ..cubicTo(10.622, 2.2598, 10.0447, 2.25979, 9.66437, 2.60207)
      ..close();
    final edge = Path()
      ..moveTo(8.99542, 1.85876)
      ..cubicTo(9.75604, 1.17425, 10.9106, 1.17422, 11.6713, 1.85878)
      ..lineTo(16.5281, 6.22989)
      ..cubicTo(17.0789, 6.72568, 17.7938, 7.00001, 18.5349, 7.00001)
      ..lineTo(15.89, 7)
      ..lineTo(11.0023, 2.60207)
      ..cubicTo(10.622, 2.2598, 10.0447, 2.2598, 9.66436, 2.60207)
      ..lineTo(4.77734, 7)
      ..lineTo(2.13171, 7.00001)
      ..cubicTo(2.87284, 7.00001, 3.58774, 6.72568, 4.13861, 6.22989)
      ..close();
    final stroke = Path()
      ..moveTo(10.3333, 3.34539)
      ..lineTo(5.47654, 7.71648)
      ..cubicTo(4.55842, 8.54279, 3.36693, 9, 2.13172, 9)
      ..lineTo(0, 9)
      ..lineTo(0, 8)
      ..lineTo(2.13172, 8)
      ..cubicTo(3.11989, 8, 4.07308, 7.63423, 4.80758, 6.97318)
      ..lineTo(9.66437, 2.60207)
      ..cubicTo(10.0447, 2.25979, 10.622, 2.2598, 11.0023, 2.60207)
      ..lineTo(15.8591, 6.97318)
      ..cubicTo(16.5936, 7.63423, 17.5468, 8, 18.5349, 8)
      ..lineTo(20, 8)
      ..lineTo(20, 9)
      ..lineTo(18.5349, 9)
      ..cubicTo(17.2998, 9, 16.1083, 8.54278, 15.1901, 7.71648)
      ..close();
    canvas.drawPath(fill, Paint()..color = colors.base);
    canvas.drawPath(
      edge,
      Paint()..color = colors.dark ? Colors.transparent : colors.line,
    );
    canvas.drawPath(
      stroke,
      Paint()
        ..color = colors.dark ? const Color(0xff333333) : Colors.transparent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LabelTooltipArrow oldDelegate) => true;
}
