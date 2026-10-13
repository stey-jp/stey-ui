import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'button.dart';
import 'theme.dart';

class SteyFlowNode {
  const SteyFlowNode(
    this.id,
    this.child, {
    this.disabled = false,
    this.onPressed,
  });
  final String id;
  final Widget child;
  final bool disabled;
  final VoidCallback? onPressed;
}

class SteyFlowEdge {
  const SteyFlowEdge(this.source, this.target, {this.label});
  final String source, target;
  final String? label;
}

class SteyFlow extends StatelessWidget {
  const SteyFlow({
    super.key,
    required this.nodes,
    required this.edges,
    this.nodeWidth = 160,
    this.nodeHeight = 44,
    this.gap = 80,
    this.verticalGap = 24,
    this.interactive = true,
  });
  final List<SteyFlowNode> nodes;
  final List<SteyFlowEdge> edges;
  final double nodeWidth, nodeHeight, gap, verticalGap;
  final bool interactive;
  @override
  Widget build(BuildContext context) {
    final depth = {for (final n in nodes) n.id: 0};
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
    final rows = columns.fold(1, (m, c) => math.max(m, c.length));
    final width = (maxDepth + 1) * nodeWidth + maxDepth * gap + 32,
        height = rows * nodeHeight + (rows - 1) * verticalGap + 32;
    final rects = <String, Rect>{};
    for (var d = 0; d < columns.length; d++) {
      final column = columns[d];
      final columnHeight =
          column.length * nodeHeight +
          math.max(0, column.length - 1) * verticalGap;
      for (var i = 0; i < column.length; i++) {
        rects[column[i].id] = Rect.fromLTWH(
          16 + d * (nodeWidth + gap),
          (height - columnHeight) / 2 + i * (nodeHeight + verticalGap),
          nodeWidth,
          nodeHeight,
        );
      }
    }
    final c = SteyTheme.colorsOf(context);
    final diagram = SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FlowPainter(
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
                label: n.id,
                enabled: !n.disabled,
                child: SteyButton(
                  onPressed: n.disabled ? null : n.onPressed,
                  child: n.child,
                ),
              ),
            ),
        ],
      ),
    );
    return Semantics(
      label:
          'Flow diagram with ${nodes.length} nodes and ${edges.length} connections',
      child: SizedBox(
        height: height,
        child: interactive
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
      ),
    );
  }
}

class _FlowPainter extends CustomPainter {
  _FlowPainter(this.rects, this.edges, this.disabled, this.colors);
  final Map<String, Rect> rects;
  final List<SteyFlowEdge> edges;
  final Set<String> disabled;
  final SteyColors colors;
  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final a = rects[edge.source]!.centerRight,
          b = rects[edge.target]!.centerLeft;
      final color =
          disabled.contains(edge.source) || disabled.contains(edge.target)
          ? colors.hairline
          : colors.subtle;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo((a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawPath(
        Path()
          ..moveTo(b.dx - 5, b.dy - 3)
          ..lineTo(b.dx, b.dy)
          ..lineTo(b.dx - 5, b.dy + 3),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
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
