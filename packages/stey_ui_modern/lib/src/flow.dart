import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'button.dart';
import 'theme.dart';
import 'messages.dart';

enum SteyFlowOrientation { horizontal, vertical }

enum SteyFlowAlign { start, center }

sealed class SteyFlowElement {
  const SteyFlowElement();
}

class SteyFlowList extends SteyFlowElement {
  const SteyFlowList(this.children);
  final List<SteyFlowElement> children;
}

class SteyFlowParallel extends SteyFlowElement {
  const SteyFlowParallel(this.children, {this.alignEnd = false});
  final List<SteyFlowElement> children;
  final bool alignEnd;
}

class SteyFlowNode extends SteyFlowElement {
  const SteyFlowNode(
    this.id,
    this.child, {
    this.disabled = false,
    this.onPressed,
    this.custom = false,
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
  });
  final String id;
  final Widget child;
  final bool disabled;
  final VoidCallback? onPressed;
  final bool custom;
  final EdgeInsetsGeometry margin;
  final double? width, height;
}

class SteyFlowEdge {
  const SteyFlowEdge(this.source, this.target, {this.label});
  final String source, target;
  final String? label;
}

class SteyFlow extends StatefulWidget {
  const SteyFlow({
    super.key,
    required this.nodes,
    required this.edges,
    this.nodeWidth = 160,
    this.nodeHeight = 44,
    this.gap = 64,
    this.verticalGap = 16,
    this.interactive = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
    this.orientation = SteyFlowOrientation.horizontal,
    this.align = SteyFlowAlign.start,
    this.canvas = true,
    this.viewportHeight,
  }) : structure = null;

  /// Native counterpart of Flow's List/Parallel composition. Nodes are measured
  /// from their content unless a width or height is explicitly supplied.
  const SteyFlow.composed({
    super.key,
    required List<SteyFlowElement> children,
    this.nodeWidth,
    this.nodeHeight,
    this.gap = 64,
    this.verticalGap = 16,
    this.interactive = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
    this.orientation = SteyFlowOrientation.horizontal,
    this.align = SteyFlowAlign.start,
    this.canvas = true,
    this.viewportHeight,
  }) : structure = children,
       nodes = const [],
       edges = const [];
  final List<SteyFlowNode> nodes;
  final List<SteyFlowEdge> edges;
  final List<SteyFlowElement>? structure;
  final double? nodeWidth, nodeHeight, viewportHeight;
  final double gap, verticalGap;
  final bool interactive;
  final bool canvas;
  final SteyFlowOrientation orientation;
  final SteyFlowAlign align;
  final EdgeInsetsGeometry padding;
  @override
  State<SteyFlow> createState() => _SteyFlowState();
}

class _SteyFlowState extends State<SteyFlow> {
  final geometry = _FlowGeometry();
  Size measuredSize = Size.zero;
  bool sizeScheduled = false;
  @override
  void dispose() {
    geometry.dispose();
    super.dispose();
  }

  void measured(Size size) {
    if (!widget.canvas ||
        !widget.interactive ||
        measuredSize == size ||
        sizeScheduled) {
      return;
    }
    sizeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sizeScheduled = false;
      if (mounted && measuredSize != size) setState(() => measuredSize = size);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tree = widget.structure == null
        ? null
        : SteyFlowList(widget.structure!);
    final nodes = tree == null ? widget.nodes : _flowNodes(tree);
    final edges = tree == null ? widget.edges : _flowEdges(tree);
    final ids = nodes.map((n) => n.id).toSet();
    if (ids.length != nodes.length) {
      throw ArgumentError('Flow node IDs must be unique');
    }
    _flowDepths(nodes, edges);
    geometry.nodes.removeWhere((id, _) => !ids.contains(id));
    for (final node in nodes) {
      geometry.nodes.putIfAbsent(node.id, () => _NodeGeometry(geometry));
    }
    final colors = SteyTheme.colorsOf(context);
    final diagram = CustomPaint(
      key: geometry.diagramKey,
      painter: _FlowPainter(
        geometry,
        geometry.rects,
        edges,
        nodes.where((n) => n.disabled).map((n) => n.id).toSet(),
        colors,
        vertical: widget.orientation == SteyFlowOrientation.vertical,
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.list,
        label: SteyMessages.of(context).flow(nodes.length, edges.length),
        child: _FlowLayout(
          config: widget,
          nodes: nodes,
          edges: edges,
          tree: tree,
          geometry: geometry,
          onMeasured: measured,
          direction: Directionality.of(context),
          children: [
            for (final n in nodes)
              Semantics(
                key: geometry.nodes[n.id]!.key,
                container: true,
                explicitChildNodes: true,
                role: SemanticsRole.listItem,
                enabled: n.onPressed == null ? null : !n.disabled,
                child: _AnchorScope(
                  entry: geometry.nodes[n.id]!,
                  child: n.custom
                      ? n.child
                      : n.onPressed != null
                      ? SteyButton(
                          onPressed: n.disabled ? null : n.onPressed,
                          child: n.child,
                        )
                      : Container(
                          alignment: AlignmentDirectional.centerStart,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.base,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .1),
                                offset: const Offset(0, 1),
                                blurRadius: .8660254,
                                spreadRadius: -1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .1),
                                offset: const Offset(0, 1),
                                blurRadius: 1.7320508,
                              ),
                              // CSS shadows paint front to back; Flutter paints
                              // back to front. Match CSS blur/2 with Skia sigma.
                              BoxShadow(color: colors.line, spreadRadius: 1),
                            ],
                          ),
                          child: n.child,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
    if (!widget.canvas) return diagram;
    if (!widget.interactive) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: diagram,
      );
    }
    return SizedBox(
      height:
          widget.viewportHeight ??
          (measuredSize.height > 0 ? measuredSize.height : 172),
      child: InteractiveViewer(
        constrained: false,
        minScale: .3,
        maxScale: 3,
        child: diagram,
      ),
    );
  }
}

List<SteyFlowNode> _flowNodes(SteyFlowElement element) => switch (element) {
  SteyFlowNode n => [n],
  SteyFlowList(:final children) ||
  SteyFlowParallel(:final children) => children.expand(_flowNodes).toList(),
};

List<SteyFlowEdge> _flowEdges(SteyFlowElement element) {
  List<String> entries(SteyFlowElement e, bool first) => switch (e) {
    SteyFlowNode(:final id) => [id],
    SteyFlowParallel(:final children) =>
      children.expand((c) => entries(c, first)).toList(),
    SteyFlowList(:final children) =>
      children.isEmpty
          ? []
          : entries(first ? children.first : children.last, first),
  };
  final children = switch (element) {
    SteyFlowNode() => <SteyFlowElement>[],
    SteyFlowList(:final children) ||
    SteyFlowParallel(:final children) => children,
  };
  final edges = children.expand(_flowEdges).toList();
  if (element is SteyFlowList) {
    for (var i = 0; i < children.length - 1; i++) {
      final a = children[i], b = children[i + 1];
      if (a is SteyFlowParallel && b is SteyFlowParallel) continue;
      for (final from in entries(a, false)) {
        for (final to in entries(b, true)) {
          edges.add(SteyFlowEdge(from, to));
        }
      }
    }
  }
  return edges;
}

Map<String, int> _flowDepths(
  List<SteyFlowNode> nodes,
  List<SteyFlowEdge> edges,
) {
  final depths = {for (final n in nodes) n.id: 0};
  for (final e in edges) {
    if (!depths.containsKey(e.source) || !depths.containsKey(e.target)) {
      throw ArgumentError('Unknown flow node');
    }
  }
  for (var i = 0; i < nodes.length; i++) {
    var changed = false;
    for (final e in edges) {
      if (depths[e.target]! <= depths[e.source]!) {
        depths[e.target] = depths[e.source]! + 1;
        changed = true;
      }
    }
    if (!changed) break;
    if (i == nodes.length - 1) throw ArgumentError('Flow must be acyclic');
  }
  return depths;
}

class _FlowLayout extends MultiChildRenderObjectWidget {
  const _FlowLayout({
    required this.config,
    required this.nodes,
    required this.edges,
    required this.tree,
    required this.geometry,
    required this.onMeasured,
    required this.direction,
    required super.children,
  });
  final SteyFlow config;
  final List<SteyFlowNode> nodes;
  final List<SteyFlowEdge> edges;
  final SteyFlowList? tree;
  final _FlowGeometry geometry;
  final ValueChanged<Size> onMeasured;
  final TextDirection direction;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFlowLayout(this);
  @override
  void updateRenderObject(BuildContext context, _RenderFlowLayout object) {
    object.config = this;
    object.markNeedsLayout();
  }
}

class _FlowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderFlowLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FlowParentData> {
  _RenderFlowLayout(this.config);
  _FlowLayout config;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FlowParentData) {
      child.parentData = _FlowParentData();
    }
  }

  @override
  void performLayout() {
    final c = config.config,
        vertical = c.orientation == SteyFlowOrientation.vertical;
    final boxes = getChildrenAsList(), sizes = <String, Size>{};
    for (var i = 0; i < boxes.length; i++) {
      final n = config.nodes[i];
      boxes[i].layout(
        BoxConstraints.tightFor(
          width: n.width ?? c.nodeWidth,
          height: n.height ?? c.nodeHeight,
        ),
        parentUsesSize: true,
      );
      sizes[n.id] = boxes[i].size;
    }
    final positions = <String, Offset>{};
    double main(Size s) => vertical ? s.height : s.width;
    double cross(Size s) => vertical ? s.width : s.height;
    Size fromAxes(double m, double x) => vertical ? Size(x, m) : Size(m, x);
    Offset offset(double m, double x) => vertical ? Offset(x, m) : Offset(m, x);
    final groupSizes = <SteyFlowElement, Size>{};
    List<SteyFlowElement> childrenOf(SteyFlowElement e) => switch (e) {
      SteyFlowList(:final children) ||
      SteyFlowParallel(:final children) => children,
      _ => const [],
    };
    Size measure(SteyFlowElement element) =>
        groupSizes.putIfAbsent(element, () {
          if (element is SteyFlowNode) return sizes[element.id]!;
          final list = element is SteyFlowList, children = childrenOf(element);
          var total = 0.0, largest = 0.0;
          for (final child in children) {
            final s = measure(child);
            total += list ? main(s) : cross(s);
            largest = math.max(largest, list ? cross(s) : main(s));
          }
          total +=
              math.max(0, children.length - 1) * (list ? c.gap : c.verticalGap);
          return list ? fromAxes(total, largest) : fromAxes(largest, total);
        });
    void place(SteyFlowElement element, Offset origin) {
      if (element is SteyFlowNode) {
        positions[element.id] = origin;
        return;
      }
      final list = element is SteyFlowList,
          children = childrenOf(element),
          group = measure(element);
      final largest = list ? cross(group) : main(group);
      var cursor = 0.0;
      for (final child in children) {
        final s = measure(child);
        final shift = list
            ? (c.align == SteyFlowAlign.center ? (largest - cross(s)) / 2 : 0.0)
            : (element is SteyFlowParallel && element.alignEnd
                  ? largest - main(s)
                  : 0.0);
        place(
          child,
          origin + (list ? offset(cursor, shift) : offset(shift, cursor)),
        );
        cursor += (list ? main(s) : cross(s)) + (list ? c.gap : c.verticalGap);
      }
    }

    Size content;
    if (config.tree != null) {
      content = measure(config.tree!);
      place(config.tree!, Offset.zero);
    } else {
      final depths = _flowDepths(config.nodes, config.edges),
          maxDepth = depths.values.fold(0, math.max);
      final columns = [
        for (var d = 0; d <= maxDepth; d++)
          config.nodes.where((n) => depths[n.id] == d).toList(),
      ];
      final breadth = [
        for (final col in columns)
          col.fold(0.0, (v, n) => v + cross(sizes[n.id]!)) +
              math.max(0, col.length - 1) * c.verticalGap,
      ];
      final widest = breadth.fold(0.0, math.max);
      var cursor = 0.0;
      for (var d = 0; d < columns.length; d++) {
        var crossCursor = c.align == SteyFlowAlign.center
            ? (widest - breadth[d]) / 2
            : 0.0;
        var maxMain = 0.0;
        for (final n in columns[d]) {
          positions[n.id] = offset(cursor, crossCursor);
          crossCursor += cross(sizes[n.id]!) + c.verticalGap;
          maxMain = math.max(maxMain, main(sizes[n.id]!));
        }
        cursor += maxMain + (d < columns.length - 1 ? c.gap : 0);
      }
      content = fromAxes(cursor, widest);
    }
    final padding = c.padding.resolve(config.direction);
    final wanted = Size(
      content.width + padding.horizontal,
      content.height + padding.vertical,
    );
    size = constraints.constrain(wanted);
    config.geometry.rects.clear();
    for (var i = 0; i < boxes.length; i++) {
      final node = config.nodes[i],
          margin = node.margin.resolve(config.direction);
      final origin =
          positions[node.id]! +
          Offset(padding.left + margin.left, padding.top + margin.top);
      (boxes[i].parentData! as _FlowParentData).offset = origin;
      config.geometry.rects[node.id] = origin & boxes[i].size;
    }
    config.geometry.changed();
    config.onMeasured(wanted);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final offset = (child.parentData! as _FlowParentData).offset;
    transform.translateByDouble(offset.dx, offset.dy, 0, 1);
  }
}

class _FlowPainter extends CustomPainter {
  _FlowPainter(
    this.geometry,
    this.rects,
    this.edges,
    this.disabled,
    this.colors, {
    this.vertical = false,
  }) : super(repaint: geometry);
  final _FlowGeometry geometry;
  final Map<String, Rect> rects;
  final List<SteyFlowEdge> edges;
  final Set<String> disabled;
  final SteyColors colors;
  final bool vertical;
  Map<String, ({Offset start, Offset end})> get endpoints => {
    for (final edge in edges)
      '${edge.source}-${edge.target}': (
        start: geometry.nodes[edge.source]!.endpoint(
          true,
          rects[edge.source]!,
          vertical: vertical,
        ),
        end: geometry.nodes[edge.target]!.endpoint(
          false,
          rects[edge.target]!,
          vertical: vertical,
        ),
      ),
  };
  @override
  void paint(Canvas canvas, Size size) {
    final points = endpoints;
    final ordered = [...edges]
      ..sort(
        (a, b) =>
            (disabled.contains(a.source) || disabled.contains(a.target) ? 0 : 1)
                .compareTo(
                  disabled.contains(b.source) || disabled.contains(b.target)
                      ? 0
                      : 1,
                ),
      );
    for (final edge in ordered) {
      final endpoints = points['${edge.source}-${edge.target}']!;
      final a = vertical
              ? Offset(endpoints.start.dy, endpoints.start.dx)
              : endpoints.start,
          b = vertical
              ? Offset(endpoints.end.dy, endpoints.end.dx)
              : endpoints.end;
      canvas.save();
      if (vertical) {
        canvas.rotate(math.pi / 2);
        canvas.scale(1, -1);
      }
      final color =
          disabled.contains(edge.source) || disabled.contains(edge.target)
          ? colors.placeholder.withValues(alpha: .4)
          : colors.placeholder;
      final path = Path()..moveTo(a.dx, a.dy);
      if ((b.dy - a.dy).abs() <= 2) {
        path.lineTo(b.dx - 8, b.dy);
      } else {
        final radius = math.min(8.0, (b.dy - a.dy).abs() / 2),
            sign = b.dy >= a.dy ? 1.0 : -1.0;
        final mid = b.dx - 32;
        path
          ..lineTo(mid - radius, a.dy)
          ..quadraticBezierTo(mid, a.dy, mid, a.dy + sign * radius)
          ..lineTo(mid, b.dy - sign * radius)
          ..quadraticBezierTo(mid, b.dy, mid + radius, b.dy)
          ..lineTo(b.dx - 8, b.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.save();
      canvas.translate(b.dx - 8, b.dy - 4);
      canvas.drawPath(
        Path()
          ..moveTo(0, 1.5)
          ..quadraticBezierTo(0, 0, 1.5, 0)
          ..quadraticBezierTo(3.5, 1, 5.8, 3.2)
          ..quadraticBezierTo(6.5, 4, 5.8, 4.8)
          ..quadraticBezierTo(3.5, 7, 1.5, 8)
          ..quadraticBezierTo(0, 8, 0, 6.5)
          ..close(),
        Paint()..color = color,
      );
      canvas.restore();
      canvas.restore();
      if (edge.label != null) {
        final text = TextPainter(
          text: TextSpan(
            text: edge.label,
            style: TextStyle(color: colors.text, fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(
          canvas,
          Offset(
            (endpoints.start.dx + endpoints.end.dx - text.width) / 2,
            (endpoints.start.dy + endpoints.end.dy) / 2 - 16,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlowPainter old) => true;
}

enum SteyFlowAnchorType { start, end, both }

/// Marks a real child render box as an incoming/outgoing anchor. Native
/// coordinate conversion includes outside margins and transforms exactly once.
class SteyFlowAnchor extends StatelessWidget {
  const SteyFlowAnchor({
    super.key,
    this.type = SteyFlowAnchorType.both,
    required this.child,
  });
  final SteyFlowAnchorType type;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AnchorScope>();
    if (scope == null) {
      throw FlutterError('SteyFlowAnchor requires a SteyFlowNode.');
    }
    return _FlowAnchorBox(entry: scope.entry, type: type, child: child);
  }
}

class _FlowAnchorBox extends SingleChildRenderObjectWidget {
  const _FlowAnchorBox({
    required this.entry,
    required this.type,
    required super.child,
  });
  final _NodeGeometry entry;
  final SteyFlowAnchorType type;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFlowAnchor(entry, type);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFlowAnchor renderObject,
  ) => renderObject.update(entry, type);
}

class _FlowGeometry extends ChangeNotifier {
  final rects = <String, Rect>{};
  final diagramKey = GlobalKey();
  final nodes = <String, _NodeGeometry>{};
  bool disposed = false;
  void changed() {
    if (!disposed) notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  Offset local(RenderBox box, Offset offset) {
    final diagram = diagramKey.currentContext!.findRenderObject()! as RenderBox;
    return diagram.globalToLocal(box.localToGlobal(offset));
  }
}

class _NodeGeometry {
  _NodeGeometry(this.geometry);
  final _FlowGeometry geometry;
  final key = GlobalKey();
  final anchors = <_RenderFlowAnchor>{};
  Offset endpoint(bool outgoing, Rect fallback, {bool vertical = false}) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return vertical
          ? (outgoing ? fallback.bottomCenter : fallback.topCenter)
          : (outgoing ? fallback.centerRight : fallback.centerLeft);
    }
    final edge = geometry.local(
      box,
      vertical
          ? Offset(box.size.width / 2, outgoing ? box.size.height : 0)
          : Offset(outgoing ? box.size.width : 0, box.size.height / 2),
    );
    if (vertical) return edge;
    final type = outgoing ? SteyFlowAnchorType.start : SteyFlowAnchorType.end;
    for (final anchor in anchors.toList().reversed) {
      if (anchor.attached &&
          anchor.hasSize &&
          (anchor.type == type || anchor.type == SteyFlowAnchorType.both)) {
        return Offset(
          edge.dx,
          geometry.local(anchor, anchor.size.center(Offset.zero)).dy,
        );
      }
    }
    return edge;
  }
}

class _AnchorScope extends InheritedWidget {
  const _AnchorScope({required this.entry, required super.child});
  final _NodeGeometry entry;
  @override
  bool updateShouldNotify(_AnchorScope oldWidget) => entry != oldWidget.entry;
}

class _RenderFlowAnchor extends RenderProxyBox {
  _RenderFlowAnchor(this.entry, this.type);
  _NodeGeometry entry;
  SteyFlowAnchorType type;
  void update(_NodeGeometry next, SteyFlowAnchorType value) {
    if (entry == next && type == value) return;
    entry.anchors.remove(this);
    entry = next;
    type = value;
    if (attached) entry.anchors.add(this);
    entry.geometry.changed();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    entry.anchors.add(this);
    entry.geometry.changed();
  }

  @override
  void detach() {
    entry.anchors.remove(this);
    entry.geometry.changed();
    super.detach();
  }

  @override
  void performLayout() {
    super.performLayout();
    entry.geometry.changed();
  }
}
