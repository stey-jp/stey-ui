part of 'flow.dart';

class _FlowCanvas extends StatefulWidget {
  const _FlowCanvas({
    required this.geometry,
    required this.padding,
    required this.height,
    required this.onOverflowChange,
    required this.child,
  });
  final _FlowGeometry geometry;
  final EdgeInsets padding;
  final double? height;
  final ValueChanged<({bool x, bool y})>? onOverflowChange;
  final Widget child;
  @override
  State<_FlowCanvas> createState() => _FlowCanvasState();
}

class _FlowCanvasState extends State<_FlowCanvas> {
  final position = _FlowCanvasPosition();
  bool hovered = false;
  ({bool x, bool y})? reported;
  @override
  void initState() {
    super.initState();
    position.addListener(changed);
  }

  void changed() {
    final overflow = (x: position.bounds.dx < 0, y: position.bounds.dy < 0);
    if (overflow != reported) {
      reported = overflow;
      widget.onOverflowChange?.call(overflow);
    }
  }

  bool accepts(PointerEvent event) {
    if (!position.overflow) return false;
    for (final node in widget.geometry.nodes.values) {
      final box = node.key.currentContext?.findRenderObject();
      if (box is RenderBox &&
          box.hasSize &&
          (Offset.zero & box.size).contains(
            box.globalToLocal(event.position),
          )) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    position.removeListener(changed);
    position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: position,
    child: widget.child,
    builder: (context, child) => MouseRegion(
      cursor: position.panning
          ? SystemMouseCursors.grabbing
          : position.overflow
          ? SystemMouseCursors.grab
          : MouseCursor.defer,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent && position.overflow) {
            GestureBinding.instance.pointerSignalResolver.register(event, (_) {
              position.move(-event.scrollDelta);
            });
          }
        },
        child: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            _FlowPanGesture:
                GestureRecognizerFactoryWithHandlers<_FlowPanGesture>(
                  () => _FlowPanGesture(),
                  (gesture) => gesture
                    ..accepts = accepts
                    ..dragStartBehavior = DragStartBehavior.down
                    ..gestureSettings = const DeviceGestureSettings(
                      touchSlop: 3,
                    )
                    ..onStart = ((_) => position.setPanning(true))
                    ..onUpdate = ((details) => position.move(details.delta))
                    ..onEnd = ((_) => position.setPanning(false))
                    ..onCancel = (() => position.setPanning(false)),
                ),
          },
          child: _FlowCanvasViewport(
            position: position,
            geometry: widget.geometry,
            padding: widget.padding,
            height: widget.height,
            hovered: hovered,
            colors: SteyTheme.colorsOf(context),
            child: child!,
          ),
        ),
      ),
    ),
  );
}

class _FlowPanGesture extends PanGestureRecognizer {
  late bool Function(PointerEvent) accepts;
  @override
  bool isPointerAllowed(PointerEvent event) =>
      accepts(event) && super.isPointerAllowed(event);
  @override
  bool isPointerPanZoomAllowed(PointerPanZoomStartEvent event) =>
      accepts(event) && super.isPointerPanZoomAllowed(event);
}

class _FlowCanvasPosition extends ChangeNotifier {
  Offset pan = Offset.zero, bounds = Offset.zero;
  Size viewport = Size.zero, content = Size.zero;
  EdgeInsets padding = EdgeInsets.zero;
  bool panning = false, scheduled = false, disposed = false;
  bool get overflow => bounds.dx < 0 || bounds.dy < 0;

  void measure(Size view, Size child, EdgeInsets inset) {
    if (view == viewport && child == content && inset == padding) return;
    viewport = view;
    content = child;
    padding = inset;
    bounds = Offset(
      math.min(0, view.width - child.width),
      math.min(0, view.height - child.height),
    );
    pan = clamp(pan);
    if (!scheduled) {
      scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scheduled = false;
        if (!disposed) notifyListeners();
      });
    }
  }

  Offset clamp(Offset next) =>
      Offset(next.dx.clamp(bounds.dx, 0), next.dy.clamp(bounds.dy, 0));

  void move(Offset delta) {
    final next = clamp(pan + delta);
    if (next == pan) return;
    pan = next;
    notifyListeners();
  }

  void setPanning(bool value) {
    if (panning == value) return;
    panning = value;
    notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class _FlowCanvasViewport extends SingleChildRenderObjectWidget {
  const _FlowCanvasViewport({
    required this.position,
    required this.geometry,
    required this.padding,
    required this.height,
    required this.hovered,
    required this.colors,
    required super.child,
  });
  final _FlowCanvasPosition position;
  final _FlowGeometry geometry;
  final EdgeInsets padding;
  final double? height;
  final bool hovered;
  final SteyColors colors;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFlowCanvas(this);
  @override
  void updateRenderObject(BuildContext context, _RenderFlowCanvas object) {
    object.config = this;
    object.markNeedsLayout();
    object.markNeedsSemanticsUpdate();
  }
}

class _RenderFlowCanvas extends RenderProxyBox {
  _RenderFlowCanvas(this.config);
  _FlowCanvasViewport config;
  Offset get childOffset =>
      config.position.pan +
      Offset(math.max(0, (size.width - child!.size.width) / 2), 0);
  @override
  void performLayout() {
    config.geometry.viewportWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : null;
    child!.layout(const BoxConstraints(), parentUsesSize: true);
    size = constraints.constrain(
      Size(
        constraints.hasBoundedWidth ? constraints.maxWidth : child!.size.width,
        config.height ?? child!.size.height,
      ),
    );
    config.position.measure(size, child!.size, config.padding);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Offset.zero & size, (
      ctx,
      o,
    ) {
      ctx.paintChild(child!, o + childOffset);
      if (!config.hovered) return;
      final p = config.position;
      void scrollbar(bool horizontal) {
        final bound = horizontal ? p.bounds.dx : p.bounds.dy;
        if (bound >= 0) return;
        final available = horizontal
            ? size.width - config.padding.horizontal
            : size.height - config.padding.vertical;
        final content = horizontal
            ? child!.size.width - config.padding.horizontal
            : child!.size.height - config.padding.vertical;
        final fraction = content > 0 && available > 0
            ? math.max(.1, available / content)
            : 0.0;
        final track = horizontal
            ? Rect.fromLTWH(4, size.height - 10, math.max(0, size.width - 8), 6)
            : Rect.fromLTWH(
                size.width - 10,
                4,
                6,
                math.max(0, size.height - 8),
              );
        final progress = (horizontal ? p.pan.dx : p.pan.dy) / bound;
        final thumb = horizontal
            ? Rect.fromLTWH(
                track.left + track.width * (1 - fraction) * progress,
                track.top,
                track.width * fraction,
                track.height,
              )
            : Rect.fromLTWH(
                track.left,
                track.top + track.height * (1 - fraction) * progress,
                track.width,
                track.height * fraction,
              );
        ctx.canvas.drawRRect(
          RRect.fromRectAndRadius(track.shift(o), const Radius.circular(3)),
          Paint()..color = config.colors.hairline.withValues(alpha: .5),
        );
        ctx.canvas.drawRRect(
          RRect.fromRectAndRadius(thumb.shift(o), const Radius.circular(3)),
          Paint()..color = config.colors.fill,
        );
      }

      scrollbar(true);
      scrollbar(false);
    });
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintOffset(
        offset: childOffset,
        position: position,
        hitTest: (result, transformed) =>
            child!.hitTest(result, position: transformed),
      );
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.translateByDouble(childOffset.dx, childOffset.dy, 0, 1);
  @override
  Rect? describeApproximatePaintClip(RenderObject child) => Offset.zero & size;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    if (this.config.position.bounds.dx < 0) {
      config.onScrollLeft = () =>
          this.config.position.move(Offset(-size.width * .8, 0));
      config.onScrollRight = () =>
          this.config.position.move(Offset(size.width * .8, 0));
    }
    if (this.config.position.bounds.dy < 0) {
      config.onScrollUp = () =>
          this.config.position.move(Offset(0, -size.height * .8));
      config.onScrollDown = () =>
          this.config.position.move(Offset(0, size.height * .8));
    }
  }
}
