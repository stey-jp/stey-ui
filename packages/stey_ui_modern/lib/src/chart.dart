import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'display.dart';
import 'theme.dart';
import 'messages.dart';

/// Native chart primitives. ECharts options are intentionally not accepted.
class SteyChartPoint {
  const SteyChartPoint(this.x, this.y);
  final double x, y;
}

class SteyChartSeries {
  const SteyChartSeries({
    required this.name,
    required this.points,
    required this.color,
  });
  final String name;
  final List<SteyChartPoint> points;
  final Color color;
}

class SteyChartThreshold {
  const SteyChartThreshold(this.value, this.label, this.color);
  final double value;
  final String label;
  final Color color;
}

enum SteyChartType { line, bar }

class SteyChartLegend extends StatelessWidget {
  const SteyChartLegend({
    super.key,
    required this.series,
    this.hidden = const {},
    this.onToggle,
  });
  final List<SteyChartSeries> series;
  final Set<String> hidden;
  final ValueChanged<String>? onToggle;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 8,
    children: series
        .map(
          (s) => Semantics(
            label: s.name,
            selected: !hidden.contains(s.name),
            child: SteyButton(
              variant: SteyButtonVariant.ghost,
              size: SteySize.sm,
              onPressed: onToggle == null ? null : () => onToggle!(s.name),
              icon: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: s.color.withValues(
                    alpha: hidden.contains(s.name) ? 0.3 : 1,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              child: Text(s.name),
            ),
          ),
        )
        .toList(),
  );
}

class SteyTimeseriesChart extends StatefulWidget {
  const SteyTimeseriesChart({
    super.key,
    required this.series,
    this.height = 260,
    this.type = SteyChartType.line,
    this.thresholds = const [],
    this.loading = false,
    this.xFormatter,
    this.valueFormatter,
    this.onPointSelected,
    this.label = 'Time series chart',
    this.showLegend = true,
  });
  final List<SteyChartSeries> series;
  final double height;
  final SteyChartType type;
  final List<SteyChartThreshold> thresholds;
  final bool loading, showLegend;
  final String Function(double)? xFormatter, valueFormatter;
  final void Function(String, SteyChartPoint)? onPointSelected;
  final String label;
  @override
  State<SteyTimeseriesChart> createState() => _SteyTimeseriesChartState();
}

class _SteyTimeseriesChartState extends State<SteyTimeseriesChart> {
  final Set<String> hidden = {};
  int? selected;
  @override
  Widget build(BuildContext context) {
    final visible = widget.series
        .where((s) => !hidden.contains(s.name) && s.points.isNotEmpty)
        .toList();
    final points = visible.expand((s) => s.points).toList();
    final count = visible.isEmpty ? 0 : visible.first.points.length;
    if (widget.loading) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: SteyLoader(size: 24)),
      );
    }
    if (points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: SteyEmpty(title: SteyMessages.of(context).noData),
      );
    }
    final c = SteyTheme.colorsOf(context);
    final allY = [
      ...points.map((p) => p.y),
      ...widget.thresholds.map((t) => t.value),
      0.0,
    ];
    final minX = points.map((p) => p.x).reduce(math.min),
        maxX = points.map((p) => p.x).reduce(math.max);
    final minY = allY.reduce(math.min), maxY = allY.reduce(math.max);
    final current = selected?.clamp(0, count - 1);
    String value(double n) =>
        widget.valueFormatter?.call(n) ?? n.toStringAsFixed(0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: widget.label,
          value: current == null
              ? SteyMessages.of(context).series(visible.length)
              : visible
                    .where((s) => current < s.points.length)
                    .map((s) => '${s.name}: ${value(s.points[current].y)}')
                    .join(', '),
          child: Focus(
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                  event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                setState(
                  () => selected =
                      ((selected ?? 0) +
                              (event.logicalKey == LogicalKeyboardKey.arrowRight
                                  ? 1
                                  : -1))
                          .clamp(0, count - 1),
                );
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.enter &&
                  current != null) {
                widget.onPointSelected?.call(
                  visible.first.name,
                  visible.first.points[current],
                );
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                void select(Offset position) {
                  final ratio =
                      ((position.dx - 44) / (constraints.maxWidth - 60)).clamp(
                        0.0,
                        1.0,
                      );
                  setState(() => selected = (ratio * (count - 1)).round());
                }

                return MouseRegion(
                  onHover: (event) => select(event.localPosition),
                  onExit: (_) => setState(() => selected = null),
                  child: GestureDetector(
                    onTapDown: (detail) {
                      select(detail.localPosition);
                      if (selected != null) {
                        widget.onPointSelected?.call(
                          visible.first.name,
                          visible.first.points[selected!],
                        );
                      }
                    },
                    onHorizontalDragUpdate: (detail) =>
                        select(detail.localPosition),
                    child: SizedBox(
                      height: widget.height,
                      child: CustomPaint(
                        painter: _TimeseriesPainter(
                          series: visible,
                          type: widget.type,
                          thresholds: widget.thresholds,
                          colors: c,
                          minX: minX,
                          maxX: maxX,
                          minY: minY,
                          maxY: maxY,
                          selected: current,
                          xFormatter: widget.xFormatter,
                          valueFormatter: value,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (current != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 12,
              children: [
                for (final s in visible)
                  if (current < s.points.length)
                    SteyText('${s.name}: ${value(s.points[current].y)}'),
              ],
            ),
          ),
        if (widget.showLegend)
          SteyChartLegend(
            series: widget.series,
            hidden: hidden,
            onToggle: (name) => setState(
              () => hidden.contains(name)
                  ? hidden.remove(name)
                  : hidden.add(name),
            ),
          ),
      ],
    );
  }
}

class SteyChart extends SteyTimeseriesChart {
  const SteyChart({
    super.key,
    required super.series,
    super.height,
    super.type,
    super.thresholds,
    super.loading,
    super.onPointSelected,
    super.label,
    super.showLegend,
    super.xFormatter,
    super.valueFormatter,
  });
}

class _TimeseriesPainter extends CustomPainter {
  _TimeseriesPainter({
    required this.series,
    required this.type,
    required this.thresholds,
    required this.colors,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.selected,
    required this.xFormatter,
    required this.valueFormatter,
  });
  final List<SteyChartSeries> series;
  final SteyChartType type;
  final List<SteyChartThreshold> thresholds;
  final SteyColors colors;
  final double minX, maxX, minY, maxY;
  final int? selected;
  final String Function(double)? xFormatter;
  final String Function(double) valueFormatter;
  void text(Canvas canvas, String value, Offset position, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Inter',
          package: 'stey_ui_modern',
          fontSize: 11,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTRB(44, 12, size.width - 16, size.height - 28);
    double x(double n) =>
        area.left + (n - minX) / (maxX == minX ? 1 : maxX - minX) * area.width;
    double y(double n) =>
        area.bottom -
        (n - minY) / (maxY == minY ? 1 : maxY - minY) * area.height;
    final line = Paint()
      ..color = colors.hairline
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final n = minY + (maxY - minY) * i / 4;
      final yy = y(n);
      canvas.drawLine(Offset(area.left, yy), Offset(area.right, yy), line);
      text(canvas, valueFormatter(n), Offset(0, yy - 7), colors.subtle);
      final xx = minX + (maxX - minX) * i / 4;
      text(
        canvas,
        xFormatter?.call(xx) ?? xx.toStringAsFixed(0),
        Offset(x(xx) - 10, area.bottom + 8),
        colors.subtle,
      );
    }
    canvas.save();
    canvas.clipRect(area.inflate(4));
    for (final threshold in thresholds) {
      final yy = y(threshold.value);
      final paint = Paint()
        ..color = threshold.color
        ..strokeWidth = 1;
      for (double xx = area.left; xx < area.right; xx += 8) {
        canvas.drawLine(
          Offset(xx, yy),
          Offset(math.min(xx + 4, area.right), yy),
          paint,
        );
      }
      text(
        canvas,
        threshold.label,
        Offset(area.left + 4, yy - 15),
        threshold.color,
      );
    }
    for (var s = 0; s < series.length; s++) {
      final item = series[s];
      final paint = Paint()
        ..color = item.color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (var i = 0; i < item.points.length; i++) {
        final point = item.points[i];
        final p = Offset(x(point.x), y(point.y));
        if (type == SteyChartType.line) {
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        } else {
          final width = math.min(
            24.0,
            area.width / math.max(1, item.points.length) / series.length * .65,
          );
          canvas.drawRect(
            Rect.fromLTRB(
              p.dx + s * width - width * series.length / 2,
              math.min(p.dy, y(0)),
              p.dx + (s + 1) * width - width * series.length / 2,
              math.max(p.dy, y(0)),
            ),
            Paint()..color = item.color,
          );
        }
      }
      if (type == SteyChartType.line) canvas.drawPath(path, paint);
      if (selected != null && selected! < item.points.length) {
        final p = item.points[selected!];
        canvas.drawLine(
          Offset(x(p.x), area.top),
          Offset(x(p.x), area.bottom),
          line,
        );
        canvas.drawCircle(
          Offset(x(p.x), y(p.y)),
          4,
          Paint()..color = item.color,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TimeseriesPainter old) => true;
}

class SteySankeyNode {
  const SteySankeyNode(this.id, this.name, {this.color});
  final String id, name;
  final Color? color;
}

class SteySankeyLink {
  const SteySankeyLink(this.source, this.target, this.value);
  final String source, target;
  final double value;
}

class SteySankeyChart extends StatelessWidget {
  const SteySankeyChart({
    super.key,
    required this.nodes,
    required this.links,
    this.height = 260,
    this.onNodeClick,
  });
  final List<SteySankeyNode> nodes;
  final List<SteySankeyLink> links;
  final double height;
  final ValueChanged<SteySankeyNode>? onNodeClick;
  @override
  Widget build(BuildContext context) {
    final ids = nodes.map((n) => n.id).toSet();
    if (links.any(
      (l) => !ids.contains(l.source) || !ids.contains(l.target) || l.value < 0,
    )) {
      throw ArgumentError('Invalid Sankey link');
    }
    final depths = {for (final n in nodes) n.id: 0};
    // Directed acyclic layout; reject cycles rather than hang.
    for (var i = 0; i < nodes.length; i++) {
      var changed = false;
      for (final l in links) {
        if (depths[l.target]! <= depths[l.source]!) {
          depths[l.target] = depths[l.source]! + 1;
          changed = true;
        }
      }
      if (!changed) break;
      if (i == nodes.length - 1) throw ArgumentError('Sankey must be acyclic');
    }
    final c = SteyTheme.colorsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDepth = depths.values.fold(0, math.max);
        final rects = <String, Rect>{};
        for (var depth = 0; depth <= maxDepth; depth++) {
          final column = nodes.where((n) => depths[n.id] == depth).toList();
          for (var i = 0; i < column.length; i++) {
            final x =
                16 +
                depth * (constraints.maxWidth - 160) / math.max(1, maxDepth);
            rects[column[i].id] = Rect.fromLTWH(
              x,
              16 + i * (height - 32) / math.max(1, column.length),
              120,
              36,
            );
          }
        }
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SankeyPainter(rects, links, c.brand),
                ),
              ),
              for (final n in nodes)
                Positioned.fromRect(
                  rect: rects[n.id]!,
                  child: Tooltip(
                    message:
                        '${n.name}: ${links.where((l) => l.source == n.id || l.target == n.id).fold(0.0, (sum, l) => sum + l.value)}',
                    child: SteyButton(
                      onPressed: onNodeClick == null
                          ? null
                          : () => onNodeClick!(n),
                      child: Text(n.name),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SankeyPainter extends CustomPainter {
  _SankeyPainter(this.rects, this.links, this.color);
  final Map<String, Rect> rects;
  final List<SteySankeyLink> links;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = links.fold(1.0, (m, l) => math.max(m, l.value));
    for (final link in links) {
      final a = rects[link.source]!.centerRight,
          b = rects[link.target]!.centerLeft;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo((a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: .2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 16 * link.value / maxValue,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SankeyPainter old) => true;
}
