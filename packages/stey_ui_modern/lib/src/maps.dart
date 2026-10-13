import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'button.dart';
import 'theme.dart';
import 'messages.dart';

enum SteyMapProjection { equirectangular, mercator }

class SteyMapMarker {
  const SteyMapMarker({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.value = 1,
    this.color,
  });
  final String id, name;
  final double latitude, longitude, value;
  final Color? color;
}

class SteyMapFeature {
  const SteyMapFeature({
    required this.id,
    required this.name,
    required this.polygons,
    this.value = 0,
  });
  final String id, name;

  /// Each polygon consists of an outer ring followed by zero or more holes.
  final List<List<List<Offset>>> polygons;
  final double value;
  static List<SteyMapFeature> fromGeoJson(
    Map<String, dynamic> json, {
    String nameProperty = 'name',
    String valueProperty = 'value',
  }) {
    return (json['features'] as List).map((raw) {
      final feature = raw as Map<String, dynamic>,
          geometry = feature['geometry'] as Map<String, dynamic>;
      final props = feature['properties'] as Map<String, dynamic>? ?? {};
      final coordinates = geometry['coordinates'] as List;
      final List parts = switch (geometry['type']) {
        'Polygon' => [coordinates],
        'MultiPolygon' => coordinates,
        _ => throw ArgumentError('Only Polygon and MultiPolygon are supported'),
      };
      final polygons = parts
          .map(
            (polygon) => (polygon as List)
                .map(
                  (ring) => (ring as List).map((p) {
                    final pair = p as List;
                    return Offset(
                      (pair[0] as num).toDouble(),
                      (pair[1] as num).toDouble(),
                    );
                  }).toList(),
                )
                .toList(),
          )
          .toList();
      final name = '${props[nameProperty] ?? feature['id'] ?? 'Region'}';
      return SteyMapFeature(
        id: '${feature['id'] ?? name}',
        name: name,
        polygons: polygons,
        value: (props[valueProperty] as num? ?? 0).toDouble(),
      );
    }).toList();
  }
}

class SteyBubbleMap extends StatelessWidget {
  const SteyBubbleMap({
    super.key,
    this.features = const [],
    required this.markers,
    this.height = 280,
    this.projection = SteyMapProjection.equirectangular,
    this.onMarkerClick,
    this.label = 'Map locations',
  });
  final List<SteyMapFeature> features;
  final List<SteyMapMarker> markers;
  final double height;
  final SteyMapProjection projection;
  final ValueChanged<SteyMapMarker>? onMarkerClick;
  final String label;
  @override
  Widget build(BuildContext context) => _NativeMap(
    features: features,
    markers: markers,
    height: height,
    projection: projection,
    onMarkerClick: onMarkerClick,
    label: label,
  );
}

class SteyChoroplethMap extends StatelessWidget {
  const SteyChoroplethMap({
    super.key,
    required this.features,
    this.height = 280,
    this.projection = SteyMapProjection.equirectangular,
    this.onFeatureClick,
    this.label = 'Regional values',
  });
  final List<SteyMapFeature> features;
  final double height;
  final SteyMapProjection projection;
  final ValueChanged<SteyMapFeature>? onFeatureClick;
  final String label;
  @override
  Widget build(BuildContext context) => _NativeMap(
    features: features,
    markers: const [],
    height: height,
    projection: projection,
    onFeatureClick: onFeatureClick,
    label: label,
    choropleth: true,
  );
}

Offset _project(Offset location, Size size, SteyMapProjection projection) {
  final latitude = location.dy.clamp(-85.0, 85.0) * math.pi / 180;
  final y = projection == SteyMapProjection.mercator
      ? (1 - math.log(math.tan(math.pi / 4 + latitude / 2)) / math.pi) / 2
      : (90 - location.dy) / 180;
  return Offset((location.dx + 180) / 360 * size.width, y * size.height);
}

class _NativeMap extends StatelessWidget {
  const _NativeMap({
    required this.features,
    required this.markers,
    required this.height,
    required this.projection,
    required this.label,
    this.onMarkerClick,
    this.onFeatureClick,
    this.choropleth = false,
  });
  final List<SteyMapFeature> features;
  final List<SteyMapMarker> markers;
  final double height;
  final SteyMapProjection projection;
  final String label;
  final bool choropleth;
  final ValueChanged<SteyMapMarker>? onMarkerClick;
  final ValueChanged<SteyMapFeature>? onFeatureClick;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, height);
        final painter = _MapPainter(features, projection, c, choropleth);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: label,
              child: GestureDetector(
                onTapUp: onFeatureClick == null
                    ? null
                    : (event) {
                        for (final feature in features.reversed) {
                          if (painter
                              .path(feature, size)
                              .contains(event.localPosition)) {
                            onFeatureClick!(feature);
                            break;
                          }
                        }
                      },
                child: SizedBox(
                  height: height,
                  child: Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(painter: painter)),
                      for (final marker in markers)
                        Builder(
                          builder: (context) {
                            final point = _project(
                              Offset(marker.longitude, marker.latitude),
                              size,
                              projection,
                            );
                            final radius =
                                (4 + math.sqrt(math.max(0, marker.value)))
                                    .clamp(5.0, 18.0);
                            return Positioned(
                              left: point.dx - 22,
                              top: point.dy - 22,
                              width: 44,
                              height: 44,
                              child: Tooltip(
                                message: '${marker.name}: ${marker.value}',
                                child: Semantics(
                                  label: '${marker.name}: ${marker.value}',
                                  child: GestureDetector(
                                    onTap: onMarkerClick == null
                                        ? null
                                        : () => onMarkerClick!(marker),
                                    child: Center(
                                      child: Container(
                                        width: radius * 2,
                                        height: radius * 2,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: (marker.color ?? c.brand)
                                              .withValues(alpha: .6),
                                          border: Border.all(
                                            color: marker.color ?? c.brand,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final feature in features)
                  if (onFeatureClick != null)
                    SteyButton(
                      size: SteySize.sm,
                      variant: SteyButtonVariant.ghost,
                      onPressed: () => onFeatureClick!(feature),
                      child: Text('${feature.name}: ${feature.value}'),
                    ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.features, this.projection, this.colors, this.choropleth);
  final List<SteyMapFeature> features;
  final SteyMapProjection projection;
  final SteyColors colors;
  final bool choropleth;
  Path path(SteyMapFeature feature, Size size) {
    final result = Path()..fillType = PathFillType.evenOdd;
    for (final polygon in feature.polygons) {
      for (final ring in polygon) {
        for (var i = 0; i < ring.length; i++) {
          final p = _project(ring[i], size, projection);
          if (i == 0) {
            result.moveTo(p.dx, p.dy);
          } else {
            result.lineTo(p.dx, p.dy);
          }
        }
        result.close();
      }
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.recessed);
    final maxValue = features.fold(1.0, (m, f) => math.max(m, f.value));
    for (final feature in features) {
      final shape = path(feature, size);
      canvas.drawPath(
        shape,
        Paint()
          ..color = choropleth
              ? Color.lerp(
                  colors.tint,
                  colors.brand,
                  (feature.value / maxValue).clamp(0.0, 1.0),
                )!
              : colors.fill,
      );
      canvas.drawPath(
        shape,
        Paint()
          ..color = colors.base
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}

class SteyGlobeMap extends StatefulWidget {
  const SteyGlobeMap({
    super.key,
    required this.markers,
    this.size = 280,
    this.onMarkerClick,
    this.rotation = 0,
  });
  final List<SteyMapMarker> markers;
  final double size, rotation;
  final ValueChanged<SteyMapMarker>? onMarkerClick;
  @override
  State<SteyGlobeMap> createState() => _SteyGlobeMapState();
}

class _SteyGlobeMapState extends State<SteyGlobeMap> {
  late double rotation = widget.rotation;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context), r = widget.size / 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onHorizontalDragUpdate: (event) =>
              setState(() => rotation += event.delta.dx / r),
          child: SizedBox.square(
            dimension: widget.size,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _GlobePainter(c))),
                for (final marker in widget.markers)
                  Builder(
                    builder: (context) {
                      final lat = marker.latitude * math.pi / 180,
                          lon = marker.longitude * math.pi / 180 + rotation;
                      if (math.cos(lat) * math.cos(lon) < 0) {
                        return const SizedBox.shrink();
                      }
                      final point = Offset(
                        r + r * .92 * math.cos(lat) * math.sin(lon),
                        r - r * .92 * math.sin(lat),
                      );
                      return Positioned(
                        left: point.dx - 22,
                        top: point.dy - 22,
                        width: 44,
                        height: 44,
                        child: Tooltip(
                          message: marker.name,
                          child: SteyButton(
                            onPressed: widget.onMarkerClick == null
                                ? null
                                : () => widget.onMarkerClick!(marker),
                            semanticLabel: marker.name,
                            shape: SteyButtonShape.circle,
                            variant: SteyButtonVariant.ghost,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: marker.color ?? c.brand,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            SteyButton(
              onPressed: () => setState(() => rotation -= math.pi / 8),
              semanticLabel: SteyMessages.of(context).rotateGlobeLeft,
              child: const Icon(Icons.chevron_left, size: 16),
            ),
            SteyButton(
              onPressed: () => setState(() => rotation += math.pi / 8),
              semanticLabel: SteyMessages.of(context).rotateGlobeRight,
              child: const Icon(Icons.chevron_right, size: 16),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final marker in widget.markers)
              SteyButton(
                onPressed: widget.onMarkerClick == null
                    ? null
                    : () => widget.onMarkerClick!(marker),
                variant: SteyButtonVariant.ghost,
                child: Text(marker.name),
              ),
          ],
        ),
      ],
    );
  }
}

class _GlobePainter extends CustomPainter {
  _GlobePainter(this.colors);
  final SteyColors colors;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        r = math.min(size.width, size.height) * .46;
    canvas.drawCircle(center, r, Paint()..color = colors.recessed);
    final paint = Paint()
      ..color = colors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r, paint);
    for (final factor in [.25, .5, .75]) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 2 * factor, height: r * 2),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 2, height: r * 2 * factor),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlobePainter old) =>
      colors.brightness != old.colors.brightness;
}
