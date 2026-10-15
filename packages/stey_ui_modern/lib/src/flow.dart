import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'button.dart';
import 'theme.dart';
import 'messages.dart';

class SteyFlowNode {
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
  });
  final List<SteyFlowNode> nodes;
  final List<SteyFlowEdge> edges;
  final double nodeWidth, nodeHeight, gap, verticalGap;
  final bool interactive;
  final EdgeInsetsGeometry padding;
  @override
  State<SteyFlow> createState() => _SteyFlowState();
}

class _SteyFlowState extends State<SteyFlow> {
  final geometry = _FlowGeometry();
  @override
  void dispose() {
    geometry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = widget.nodes, edges = widget.edges;
    final nodeWidth = widget.nodeWidth, nodeHeight = widget.nodeHeight;
    final gap = widget.gap, verticalGap = widget.verticalGap;
    final padding = widget.padding.resolve(Directionality.of(context));
    final depth = {for (final n in nodes) n.id: 0};
    if (depth.length != nodes.length) {
      throw ArgumentError('Flow node IDs must be unique');
    }
    geometry.nodes.removeWhere((id, _) => !depth.containsKey(id));
    for (final node in nodes) {
      geometry.nodes.putIfAbsent(node.id, () => _NodeGeometry(geometry));
    }
    for (final e in edges) {
      if (!depth.containsKey(e.source) || !depth.containsKey(e.target)) {
        throw ArgumentError('Unknown flow node');
      }
    }
    for (var i = 0; i < nodes.length; i++) {
      var changed = false;
      for (final e in edges) {
        if (depth[e.target]! <= depth[e.source]!) {
          depth[e.target] = depth[e.source]! + 1;
          changed = true;
        }
      }
      if (!changed) break;
      if (i == nodes.length - 1) throw ArgumentError('Flow must be acyclic');
    }
    final maxDepth = depth.values.fold(0, math.max);
    final columns = [
      for (var d = 0; d <= maxDepth; d++)
        nodes.where((n) => depth[n.id] == d).toList(),
    ];
    final columnWidths = [
      for (final column in columns)
        column.fold(0.0, (v, n) => math.max(v, n.width ?? nodeWidth)),
    ];
    final columnHeights = [
      for (final column in columns)
        column.fold(0.0, (v, n) => v + (n.height ?? nodeHeight)) +
            math.max(0, column.length - 1) * verticalGap,
    ];
    final width =
            columnWidths.fold(0.0, (a, b) => a + b) +
            maxDepth * gap +
            padding.horizontal,
        height = columnHeights.fold(0.0, math.max) + padding.vertical;
    final rects = <String, Rect>{};
    var x = padding.left;
    for (var d = 0; d < columns.length; d++) {
      final column = columns[d];
      var y = padding.top;
      for (var i = 0; i < column.length; i++) {
        final node = column[i],
            margin = column[i].margin.resolve(Directionality.of(context));
        rects[column[i].id] = Rect.fromLTWH(
          x + margin.left,
          y + margin.top,
          node.width ?? nodeWidth,
          node.height ?? nodeHeight,
        );
        y += (node.height ?? nodeHeight) + verticalGap;
      }
      x += columnWidths[d] + gap;
    }
    final c = SteyTheme.colorsOf(context);
    final diagram = SizedBox(
      key: geometry.diagramKey,
      width: width,
      height: height,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.list,
        label: SteyMessages.of(context).flow(nodes.length, edges.length),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FlowPainter(
                  geometry,
                  rects,
                  edges,
                  nodes.where((n) => n.disabled).map((n) => n.id).toSet(),
                  c,
                ),
              ),
            ),
            for (final n in nodes)
              Positioned.fromRect(
                rect: rects[n.id]!,
                child: Semantics(
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
                              color: c.base,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(color: c.line, spreadRadius: 1),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .1),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: n.child,
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return SizedBox(
      height: height,
      child: widget.interactive
          ? InteractiveViewer(
              constrained: false,
              minScale: .3,
              maxScale: 3,
              child: diagram,
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: diagram,
            ),
    );
  }
}

class _FlowPainter extends CustomPainter {
  _FlowPainter(
    this.geometry,
    this.rects,
    this.edges,
    this.disabled,
    this.colors,
  ) : super(repaint: geometry);
  final _FlowGeometry geometry;
  final Map<String, Rect> rects;
  final List<SteyFlowEdge> edges;
  final Set<String> disabled;
  final SteyColors colors;
  Map<String, ({Offset start, Offset end})> get endpoints => {
    for (final edge in edges)
      '${edge.source}-${edge.target}': (
        start: geometry.nodes[edge.source]!.endpoint(true, rects[edge.source]!),
        end: geometry.nodes[edge.target]!.endpoint(false, rects[edge.target]!),
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
      final a = points['${edge.source}-${edge.target}']!.start,
          b = points['${edge.source}-${edge.target}']!.end;
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
          Offset((a.dx + b.dx - text.width) / 2, (a.dy + b.dy) / 2 - 16),
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
  Offset endpoint(bool outgoing, Rect fallback) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return outgoing ? fallback.centerRight : fallback.centerLeft;
    }
    final edge = geometry.local(
      box,
      Offset(outgoing ? box.size.width : 0, box.size.height / 2),
    );
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
