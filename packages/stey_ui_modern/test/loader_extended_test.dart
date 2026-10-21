import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: SteyTheme.material(brightness),
      home: SteyTheme(
        brightness: brightness,
        child: Scaffold(body: Center(child: child)),
      ),
    );
Finder skeletonPaint() => find.byWidgetPredicate(
  (w) =>
      w is CustomPaint &&
      w.painter.runtimeType.toString() == '_SkeletonPainter',
);
void main() {
  testWidgets('named presets, custom dimensions and status semantics', (
    t,
  ) async {
    for (final size in SteyLoaderSize.values) {
      await t.pumpWidget(
        host(SteyLoader.preset(size: size, label: 'Loading projects')),
      );
      expect(t.getSize(find.byType(SteyLoader)), Size.square(size.pixels));
      expect(
        t.getSemantics(find.byType(SteyLoader)).getSemanticsData().role,
        ui.SemanticsRole.status,
      );
    }
    await t.pumpWidget(host(const SteyLoader(size: 45)));
    expect(t.getSize(find.byType(SteyLoader)), const Size.square(45));
    await t.pumpWidget(host(const SteyLoader(size: 0)));
    expect(t.getSize(find.byType(SteyLoader)), Size.zero);
  });
  testWidgets(
    'inherited and explicit alpha colors update without restarting the animation',
    (t) async {
      await t.pumpWidget(
        host(
          const DefaultTextStyle(
            style: TextStyle(color: Colors.red),
            child: SteyLoader(),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 750));
      final f = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_LoaderPainter',
      );
      final dynamic before = t.widget<CustomPaint>(f).painter;
      expect(before.color, Colors.red);
      await t.pumpWidget(
        host(
          const DefaultTextStyle(
            style: TextStyle(color: Colors.red),
            child: SteyLoader(color: Color(0x800000ff)),
          ),
        ),
      );
      final dynamic after = t.widget<CustomPaint>(f).painter;
      expect(after.color, const Color(0x800000ff));
      expect(after.time, before.time);
    },
  );
  testWidgets(
    'fixed percentage skeleton, thickness, radius and block centering',
    (t) async {
      await t.pumpWidget(
        host(
          const SizedBox(
            width: 120,
            child: SteySkeletonLine(
              minWidth: 60,
              maxWidth: 60,
              minDelay: 0,
              maxDelay: 0,
              blockHeight: 40,
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.getSize(skeletonPaint()), const Size(72, 8));
      expect(
        t.getTopLeft(skeletonPaint()).dx,
        t.getTopLeft(find.byType(SteySkeletonLine)).dx,
      );
      expect(
        t.getCenter(skeletonPaint()).dy,
        t.getCenter(find.byType(SteySkeletonLine)).dy,
      );
      expect(
        t
            .widget<ClipRRect>(
              find.descendant(
                of: find.byType(SteySkeletonLine),
                matching: find.byType(ClipRRect),
              ),
            )
            .borderRadius,
        BorderRadius.circular(2),
      );
    },
  );
  testWidgets(
    'random width is retained on rebuild and regenerated only when random parameters change',
    (t) async {
      Widget sample(int a, int b, double block) => host(
        SizedBox(
          width: 200,
          child: SteySkeletonLine(minWidth: a, maxWidth: b, blockHeight: block),
        ),
      );
      await t.pumpWidget(sample(30, 100, 30));
      final w = t.getSize(skeletonPaint()).width;
      expect(w, inInclusiveRange(60, 200));
      await t.pumpWidget(sample(30, 100, 40));
      expect(t.getSize(skeletonPaint()).width, w);
      await t.pumpWidget(sample(75, 75, 40));
      expect(t.getSize(skeletonPaint()).width, 150);
    },
  );
  testWidgets('fixed delay, ease-in-out loop, parameter reset and disposal', (
    t,
  ) async {
    Widget sample(double delay) => host(
      const SizedBox(
        width: 120,
        child: SteySkeletonLine(
          minWidth: 100,
          maxWidth: 100,
          minDuration: 1.5,
          maxDuration: 1.5,
          minDelay: .5,
          maxDelay: .5,
        ),
      ),
    );
    await t.pumpWidget(sample(.5));
    await t.pump(const Duration(milliseconds: 499));
    expect(
      (t.widget<CustomPaint>(skeletonPaint()).painter as dynamic).value,
      0,
    );
    await t.pump(const Duration(milliseconds: 1));
    await t.pump();
    await t.pump(const Duration(milliseconds: 750));
    expect(
      (t.widget<CustomPaint>(skeletonPaint()).painter as dynamic).value,
      closeTo(.5, .001),
    );
    await t.pump(const Duration(milliseconds: 750));
    expect(
      (t.widget<CustomPaint>(skeletonPaint()).painter as dynamic).value,
      closeTo(0, .001),
    );
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'skeleton explicit width/height aliases and RTL preserve physical geometry',
    (t) async {
      await t.pumpWidget(
        host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 200,
              child: SteySkeletonLine(
                width: 100,
                height: 14,
                minDelay: 0,
                maxDelay: 0,
              ),
            ),
          ),
        ),
      );
      expect(t.getSize(skeletonPaint()), const Size(100, 14));
      expect(
        t.getTopRight(skeletonPaint()).dx,
        t.getTopRight(find.byType(SteySkeletonLine)).dx,
      );
    },
  );
  testWidgets('skeleton is decorative and keeps moving with reduced motion', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SizedBox(
            width: 120,
            child: SteySkeletonLine(
              minWidth: 100,
              maxWidth: 100,
              minDuration: 1.5,
              maxDuration: 1.5,
              minDelay: 0,
              maxDelay: 0,
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 750));
    expect(
      (t.widget<CustomPaint>(skeletonPaint()).painter as dynamic).value,
      closeTo(.5, .001),
    );
    expect(t.getSemantics(find.byType(SteySkeletonLine)).label, isEmpty);
  });
  const capture = String.fromEnvironment('STEY_LOADER_CAPTURE_DIR');
  if (capture.isNotEmpty) {
    testWidgets('export deterministic native timeline frames', (t) async {
      final out = Directory(capture)..createSync(recursive: true);
      final rows = <Map<String, Object>>[];
      final times = [0, 375, 750, 1125, 1499, 1500, 2000, 3000, 5999, 6000];
      for (final brightness in Brightness.values) {
        for (final size in [16.0, 24.0, 32.0, 45.0]) {
          final key = GlobalKey();
          await t.pumpWidget(
            host(
              RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 160,
                  height: 96,
                  child: ColoredBox(
                    color: SteyColors(brightness).base,
                    child: Center(
                      child: SteyLoader(
                        size: size,
                        color: SteyColors(brightness).text,
                      ),
                    ),
                  ),
                ),
              ),
              brightness: brightness,
            ),
          );
          await t.pump();
          var last = 0;
          for (final ms in times) {
            await t.pump(Duration(milliseconds: ms - last));
            last = ms;
            final name = 'spinner-${brightness.name}-${size.toInt()}-$ms.png';
            await t.runAsync(() async {
              final boundary =
                  key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary;
              final img = await boundary.toImage();
              final data = await img.toByteData(format: ui.ImageByteFormat.png);
              await File('${out.path}/$name')
                  .writeAsBytes(data!.buffer.asUint8List());
              img.dispose();
            });
            rows.add({
              'mode': brightness.name,
              'size': size,
              'ms': ms,
              'file': name,
            });
          }
          await t.pumpWidget(const SizedBox());
        }
      }
      // A deterministic skeleton uses equal parameter bounds and zero delay.
      for (final brightness in Brightness.values) {
        final key = GlobalKey();
        await t.pumpWidget(
          host(
            RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 160,
                height: 96,
                child: ColoredBox(
                  color: SteyColors(brightness).base,
                  child: const Center(
                    child: SizedBox(
                      width: 120,
                      child: SteySkeletonLine(
                        minWidth: 60,
                        maxWidth: 60,
                        minDuration: 1.5,
                        maxDuration: 1.5,
                        minDelay: 0,
                        maxDelay: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            brightness: brightness,
          ),
        );
        await t.pump();
        var last = 0;
        for (final ms in [0, 375, 750, 1125, 1500]) {
          await t.pump(Duration(milliseconds: ms - last));
          last = ms;
          final name = 'skeleton-${brightness.name}-$ms.png';
          await t.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final img = await boundary.toImage();
            final data = await img.toByteData(format: ui.ImageByteFormat.png);
            await File('${out.path}/$name')
                .writeAsBytes(data!.buffer.asUint8List());
            img.dispose();
          });
          rows.add({
            'mode': brightness.name,
            'kind': 'skeleton',
            'ms': ms,
            'file': name,
          });
        }
        await t.pumpWidget(const SizedBox());
      }
      File('${out.path}/frames.json').writeAsStringSync(jsonEncode(rows));
    });
  }
}
