import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'messages.dart';
import 'theme.dart';

enum SteyBreadcrumbsSize { sm, base }

class SteyBreadcrumb {
  const SteyBreadcrumb(
    this.label, {
    this.onPressed,
    this.href,
    this.icon,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final Uri? href;
  final Widget? icon;
  final bool loading;
}

/// A single line trail. Only Current parts shrink; at viewport widths below
/// 640px, three or more direct Link/Current parts become ... / parent / current.
class SteyBreadcrumbs extends StatefulWidget {
  const SteyBreadcrumbs({
    super.key,
    this.items = const [],
    this.children = const [],
    this.size = SteyBreadcrumbsSize.base,
    this.semanticLabel,
  });
  final List<SteyBreadcrumb> items;
  final List<Widget> children;
  final SteyBreadcrumbsSize size;
  final String? semanticLabel;
  @override
  State<SteyBreadcrumbs> createState() => _BreadcrumbsState();
}

class _BreadcrumbsState extends State<SteyBreadcrumbs> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    assert(widget.items.isEmpty || widget.children.isEmpty);
    final c = SteyTheme.colorsOf(context),
        compact = widget.size == SteyBreadcrumbsSize.sm;
    var children = widget.children.isNotEmpty
        ? widget.children
        : <Widget>[
            for (var i = 0; i < widget.items.length; i++) ...[
              if (i > 0) const SteyBreadcrumbsSeparator(),
              if (widget.items[i].onPressed != null ||
                  widget.items[i].href != null)
                SteyBreadcrumbsLink(
                  href: widget.items[i].href,
                  onPressed: widget.items[i].onPressed,
                  icon: widget.items[i].icon,
                  child: Text(widget.items[i].label),
                )
              else
                SteyBreadcrumbsCurrent(
                  icon: widget.items[i].icon,
                  loading: widget.items[i].loading,
                  child: Text(widget.items[i].label),
                ),
            ],
          ];
    final parts = children
        .where((w) => w is SteyBreadcrumbsLink || w is SteyBreadcrumbsCurrent)
        .toList();
    if (MediaQuery.sizeOf(context).width < 640 && parts.length > 2) {
      children = [
        ExcludeSemantics(
          child: Text('...', style: TextStyle(color: c.subtle)),
        ),
        const SteyBreadcrumbsSeparator(),
        parts[parts.length - 2],
        const SteyBreadcrumbsSeparator(),
        parts.last,
        ...children.where(
          (w) =>
              w is! SteyBreadcrumbsLink &&
              w is! SteyBreadcrumbsCurrent &&
              w is! SteyBreadcrumbsSeparator,
        ),
      ];
    }
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.navigation,
        label:
            widget.semanticLabel ??
            (SteyMessages.of(context).japanese ? 'パンくず' : 'breadcrumb'),
        child: MouseRegion(
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: _BreadcrumbScope(
            hovered: hovered,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                height: compact ? 1 / .85 : 1.5,
                fontWeight: FontWeight.w400,
                color: c.text,
              ),
              child: _TrailLayout(
                height: compact ? 40 : 48,
                gap: compact ? 2 : 4,
                direction: Directionality.of(context),
                shrink: {
                  for (var i = 0; i < children.length; i++)
                    if (children[i] is SteyBreadcrumbsCurrent) i,
                },
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbScope extends InheritedWidget {
  const _BreadcrumbScope({required this.hovered, required super.child});
  final bool hovered;
  @override
  bool updateShouldNotify(_BreadcrumbScope oldWidget) =>
      hovered != oldWidget.hovered;
}

class SteyBreadcrumbsLink extends StatefulWidget {
  const SteyBreadcrumbsLink({
    super.key,
    required this.child,
    this.href,
    this.onPressed,
    this.icon,
    this.focusNode,
    this.autofocus = false,
  });
  final Widget child;
  final Widget? icon;
  final Uri? href;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  @override
  State<SteyBreadcrumbsLink> createState() => _LinkState();
}

class _LinkState extends State<SteyBreadcrumbsLink> {
  bool highlight = false;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return MergeSemantics(
      child: Semantics(
        link: true,
        // Preserve the active Flutter Web route/query when the DOM anchor is
        // resolved against <base href="/">.
        linkUrl: kIsWeb && widget.href?.toString().startsWith('#') == true
            ? Uri.base.resolveUri(widget.href!)
            : widget.href,
        onTap: widget.onPressed,
        child: FocusableActionDetector(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (v) => setState(() => highlight = v),
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space):
                DoNothingAndStopPropagationIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed?.call();
                return null;
              },
            ),
          },
          child: Focus(
            canRequestFocus: false,
            includeSemantics: false,
            onKeyEvent: (_, event) =>
                event.logicalKey == LogicalKeyboardKey.space
                ? KeyEventResult.handled
                : KeyEventResult.ignored,
            child: GestureDetector(
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              child: CustomPaint(
                foregroundPainter: highlight ? _LinkFocus(c.brand) : null,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: c.subtle,
                    decoration: TextDecoration.none,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      if (widget.icon != null)
                        ExcludeSemantics(child: widget.icon!),
                      widget.child,
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

class SteyBreadcrumbsCurrent extends StatelessWidget {
  const SteyBreadcrumbsCurrent({
    super.key,
    required this.child,
    this.icon,
    this.loading = false,
  });
  final Widget child;
  final Widget? icon;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final content = _TrailLayout(
      height: null,
      gap: 4,
      direction: Directionality.of(context),
      shrink: {icon == null ? 0 : 1},
      children: [
        if (icon != null) ExcludeSemantics(child: icon!),
        if (loading)
          const _BreadcrumbSkeleton()
        else
          DefaultTextStyle.merge(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(fontWeight: FontWeight.w500),
            child: child,
          ),
      ],
    );
    return loading
        ? ExcludeSemantics(child: SizedBox(width: 125, child: content))
        : Semantics(
            selected: true,
            hint: SteyMessages.of(context).japanese ? '現在のページ' : 'Current page',
            child: content,
          );
  }
}

class SteyBreadcrumbsSeparator extends StatelessWidget {
  const SteyBreadcrumbsSeparator({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: const Size.square(24),
      painter: _Separator(
        SteyTheme.colorsOf(context).dark
            ? const Color(0xff525252)
            : const Color(0xffd4d4d4),
      ),
    ),
  );
}

class SteyBreadcrumbsClipboard extends StatefulWidget {
  const SteyBreadcrumbsClipboard({
    super.key,
    required this.text,
    this.copyActionLabel,
    this.tooltip,
    this.focusNode,
    this.onCopied,
    this.onCopyError,
  });
  final String text;
  final String? copyActionLabel, tooltip;
  final FocusNode? focusNode;
  final VoidCallback? onCopied;
  final ValueChanged<Object>? onCopyError;
  @override
  State<SteyBreadcrumbsClipboard> createState() => _ClipboardState();
}

class _ClipboardState extends State<SteyBreadcrumbsClipboard>
    with SingleTickerProviderStateMixin {
  bool copied = false, focused = false, spacePressed = false;
  int attempt = 0;
  Timer? reset;
  late final opacity = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    animationBehavior: AnimationBehavior.preserve,
  );
  bool visible = false;
  Future<void> copy() async {
    if (widget.text.isEmpty) return;
    final current = ++attempt;
    reset?.cancel();
    try {
      await Clipboard.setData(ClipboardData(text: widget.text));
      if (!mounted || current != attempt) return;
      setState(() => copied = true);
      reset = Timer(const Duration(seconds: 2), () {
        if (mounted && current == attempt) setState(() => copied = false);
      });
      widget.onCopied?.call();
    } catch (error) {
      if (!mounted || current != attempt) return;
      setState(() => copied = false);
      widget.onCopyError?.call(error);
    }
  }

  void updateVisibility() {
    final next =
        focused ||
        (context
                .dependOnInheritedWidgetOfExactType<_BreadcrumbScope>()
                ?.hovered ??
            false);
    if (visible != next) {
      visible = next;
      opacity.animateTo(
        next ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        curve: const Cubic(.4, 0, .2, 1),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateVisibility();
  }

  @override
  void dispose() {
    attempt++;
    reset?.cancel();
    opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context),
        japanese = SteyMessages.of(context).japanese;
    return Focus(
      canRequestFocus: false,
      includeSemantics: false,
      onFocusChange: (v) {
        setState(() => focused = v);
        if (!v) spacePressed = false;
        updateVisibility();
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
      child: FadeTransition(
        opacity: opacity,
        alwaysIncludeSemantics: true,
        child: Tooltip(
          message: widget.tooltip ?? (japanese ? 'クリックしてコピー' : 'Click to copy'),
          waitDuration: const Duration(milliseconds: 600),
          child: SteyButton(
            variant: SteyButtonVariant.ghost,
            size: SteySize.sm,
            shape: SteyButtonShape.square,
            focusNode: widget.focusNode,
            semanticLabel:
                widget.copyActionLabel ?? (japanese ? 'コピー' : 'Copy'),
            onPressed: copy,
            child: ExcludeSemantics(
              child: CustomPaint(
                size: const Size.square(12),
                painter: _CopyIcon(copied, copied ? c.success : c.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbSkeleton extends StatefulWidget {
  const _BreadcrumbSkeleton();
  @override
  State<_BreadcrumbSkeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_BreadcrumbSkeleton>
    with SingleTickerProviderStateMixin {
  final random = math.Random();
  late final fraction = (30 + random.nextInt(71)) / 100;
  late final delay = Duration(milliseconds: random.nextInt(501));
  late final animation = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1300 + random.nextInt(401)),
    animationBehavior: AnimationBehavior.preserve,
  );
  Timer? start;
  @override
  void initState() {
    super.initState();
    start = Timer(delay, () {
      if (mounted) animation.repeat();
    });
  }

  @override
  void dispose() {
    start?.cancel();
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final dark = SteyTheme.colorsOf(context).dark;
      return Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        child: SizedBox(
          width: constraints.hasBoundedWidth
              ? constraints.maxWidth * fraction
              : 125 * fraction,
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => CustomPaint(
                painter: _Shimmer(
                  dark,
                  const Cubic(.42, 0, .58, 1).transform(animation.value),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Shimmer extends CustomPainter {
  const _Shimmer(this.dark, this.value);
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
  bool shouldRepaint(_Shimmer oldDelegate) =>
      dark != oldDelegate.dark || value != oldDelegate.value;
}

class _Separator extends CustomPainter {
  const _Separator(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(10.75, 8.75)
      ..lineTo(14.25, 12)
      ..lineTo(10.75, 15.25),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  @override
  bool shouldRepaint(_Separator oldDelegate) => color != oldDelegate.color;
}

class _LinkFocus extends CustomPainter {
  const _LinkFocus(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    (Offset.zero & size).inflate(1),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  @override
  bool shouldRepaint(_LinkFocus oldDelegate) => color != oldDelegate.color;
}

class _CopyIcon extends CustomPainter {
  const _CopyIcon(this.checked, this.color);
  final bool checked;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 256, size.height / 256);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = checked ? 24 : 16
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    if (checked) {
      canvas.drawPath(
        Path()
          ..moveTo(40, 144)
          ..lineTo(96, 200)
          ..lineTo(224, 72),
        paint,
      );
    } else {
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..moveTo(216, 32)
        ..lineTo(88, 32)
        ..arcToPoint(
          const Offset(80, 40),
          radius: const Radius.circular(8),
          clockwise: false,
        )
        ..lineTo(80, 80)
        ..lineTo(40, 80)
        ..arcToPoint(
          const Offset(32, 88),
          radius: const Radius.circular(8),
          clockwise: false,
        )
        ..lineTo(32, 216)
        ..arcToPoint(
          const Offset(40, 224),
          radius: const Radius.circular(8),
          clockwise: false,
        )
        ..lineTo(168, 224)
        ..arcToPoint(
          const Offset(176, 216),
          radius: const Radius.circular(8),
          clockwise: false,
        )
        ..lineTo(176, 176)
        ..lineTo(216, 176)
        ..arcToPoint(
          const Offset(224, 168),
          radius: const Radius.circular(8),
          clockwise: false,
        )
        ..lineTo(224, 40)
        ..arcToPoint(
          const Offset(216, 32),
          radius: const Radius.circular(8),
          clockwise: false,
        )
        ..close()
        ..addRect(const Rect.fromLTRB(48, 96, 160, 208))
        ..moveTo(208, 160)
        ..lineTo(176, 160)
        ..lineTo(176, 88)
        ..arcToPoint(
          const Offset(168, 80),
          radius: const Radius.circular(8),
          clockwise: false,
        )
        ..lineTo(96, 80)
        ..lineTo(96, 48)
        ..lineTo(208, 48)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CopyIcon oldDelegate) =>
      checked != oldDelegate.checked || color != oldDelegate.color;
}

class _TrailData extends ContainerBoxParentData<RenderBox> {}

class _TrailLayout extends MultiChildRenderObjectWidget {
  const _TrailLayout({
    required this.height,
    required this.gap,
    required this.direction,
    required this.shrink,
    required super.children,
  });
  final double? height;
  final double gap;
  final TextDirection direction;
  final Set<int> shrink;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTrail(height, gap, direction, shrink);
  @override
  void updateRenderObject(BuildContext context, _RenderTrail renderObject) {
    renderObject
      ..height = height
      ..gap = gap
      ..direction = direction
      ..shrink = shrink
      ..markNeedsLayout();
  }
}

/// CSS-like shrink only for designated children. Fixed ancestors may extend
/// outside the clipped trail, avoiding proportional truncation or Flex errors.
class _RenderTrail extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TrailData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TrailData> {
  _RenderTrail(this.height, this.gap, this.direction, this.shrink);
  double? height;
  double gap;
  TextDirection direction;
  Set<int> shrink;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TrailData) child.parentData = _TrailData();
  }

  @override
  void performLayout() {
    final boxes = getChildrenAsList(), widths = <double>[];
    var total = math.max(0, boxes.length - 1) * gap,
        shrinkWidth = 0.0,
        maxHeight = 0.0;
    for (var i = 0; i < boxes.length; i++) {
      boxes[i].layout(
        BoxConstraints(maxHeight: height ?? constraints.maxHeight),
        parentUsesSize: true,
      );
      widths.add(boxes[i].size.width);
      total += widths.last;
      if (shrink.contains(i)) shrinkWidth += widths.last;
    }
    final width = constraints.hasBoundedWidth
        ? height != null
              ? constraints.maxWidth
              : math.min(total, constraints.maxWidth)
        : total;
    final deficit = math.max(0, total - width);
    for (var i = 0; i < boxes.length; i++) {
      if (shrink.contains(i) && shrinkWidth > 0) {
        widths[i] = math.max(0, widths[i] - deficit * widths[i] / shrinkWidth);
        boxes[i].layout(
          BoxConstraints(
            maxWidth: widths[i],
            maxHeight: height ?? constraints.maxHeight,
          ),
          parentUsesSize: true,
        );
      }
      maxHeight = math.max(maxHeight, boxes[i].size.height);
    }
    size = constraints.constrain(Size(width, height ?? maxHeight));
    var x = direction == TextDirection.ltr ? 0.0 : size.width;
    for (final box in boxes) {
      if (direction == TextDirection.rtl) x -= box.size.width;
      (box.parentData! as _TrailData).offset = Offset(
        x,
        (size.height - box.size.height) / 2,
      );
      x += (direction == TextDirection.ltr ? box.size.width + gap : -gap);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) => context.pushClipRect(
    needsCompositing,
    offset,
    Offset.zero & size,
    defaultPaint,
  );
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
  @override
  Rect? describeSemanticsClip(RenderObject? child) => Offset.zero & size;
}
