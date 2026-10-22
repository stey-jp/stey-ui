import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child, {bool rtl = false}) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(
    body: Center(
      child: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SizedBox(width: 320, child: child),
      ),
    ),
  ),
);
Finder thumbs() => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.slider == true,
);
List<String> texts(WidgetTester t) => [
  for (final e
      in (thumbs().evaluate().toList()..sort(
        (a, b) => ((a.widget as Semantics).properties.sortKey as OrdinalSortKey)
            .order
            .compareTo(
              ((b.widget as Semantics).properties.sortKey as OrdinalSortKey)
                  .order,
            ),
      )))
    t.getSemantics(find.byWidget(e.widget)).getSemanticsData().value,
];
Offset point(
  WidgetTester t,
  double value, {
  double min = 0,
  double max = 100,
  bool rtl = false,
}) {
  final box = t.getRect(find.byType(SteySlider));
  final f = (value - min) / (max - min);
  return Offset(
    box.left + 11 + 298 * (rtl ? 1 - f : f),
    t.getCenter(thumbs().first).dy,
  );
}

void main() {
  testWidgets('implicit focus has no ring; Tab and arrow input show it', (
    t,
  ) async {
    await t.pumpWidget(host(SteySlider(value: 40, onChanged: (_) {})));
    final node = t
        .widget<Focus>(
          find.ancestor(of: thumbs().first, matching: find.byType(Focus)).first,
        )
        .focusNode!;
    Finder ring() => find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.foregroundPainter?.runtimeType.toString() == '_SliderFocusRing',
    );
    node.requestFocus();
    await t.pump();
    expect(ring(), findsNothing);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump();
    expect(ring(), findsOneWidget);
    node.unfocus();
    await t.pump();
    await t.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(ring(), findsOneWidget);
    await t.sendKeyUpEvent(LogicalKeyboardKey.tab);
  });
  testWidgets(
    'base/small edge geometry, visible badges, endpoints and group semantics',
    (t) async {
      for (final size in SteySliderSize.values) {
        await t.pumpWidget(
          host(
            SteySlider(
              value: 0,
              label: 'Volume',
              size: size,
              onChanged: (_) {},
            ),
          ),
        );
        expect(
          t.getSize(thumbs().first),
          Size(16, size == SteySliderSize.sm ? 18 : 26),
        );
        expect(
          t.getCenter(thumbs().first).dx -
              t.getTopLeft(find.byType(SteySlider)).dx,
          11,
        );
        final expected = size == SteySliderSize.sm ? 72.0 : 32 + 16 + 26 / .85;
        expect(t.getSize(find.byType(SteySlider)).height, closeTo(expected, 1));
        expect(find.text('0'), findsNWidgets(2));
        expect(find.text('100'), findsOneWidget);
      }
    },
  );
  testWidgets(
    'pointer change then release commits once with latest snapped value',
    (t) async {
      double value = 40;
      final changes = <double>[], commits = <double>[];
      final reasons = <SteySliderChangeReason>[];
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) => SteySlider(
              value: value,
              label: 'Volume',
              divisions: 10,
              onChanged: (v) {
                changes.add(v);
                set(() => value = v);
              },
              onChangeCommitted: commits.add,
              onValueChange: (_, d) => reasons.add(d.reason),
            ),
          ),
        ),
      );
      final g = await t.startGesture(t.getCenter(thumbs().first));
      await g.moveTo(point(t, 60));
      await t.pump();
      expect(value, 60);
      expect(commits, isEmpty);
      await g.moveTo(point(t, 70));
      await t.pump();
      await g.up();
      await t.pump();
      expect(changes, [60, 70]);
      expect(commits, [70]);
      expect(reasons.every((v) => v == SteySliderChangeReason.drag), true);
    },
  );
  testWidgets(
    'track press snaps from min origin, ties choose the later thumb',
    (t) async {
      final calls = <List<double>>[];
      await t.pumpWidget(
        host(SteySlider.range(values: const [25, 75], onChanged: calls.add)),
      );
      await t.tapAt(point(t, 50));
      await t.pump();
      expect(calls.last, [25, 50]);
      double value = 0;
      await t.pumpWidget(
        host(
          SteySlider(
            value: 0,
            min: -.25,
            max: .75,
            step: .1,
            onChanged: (v) => value = v,
          ),
        ),
      );
      await t.tapAt(point(t, .1, min: -.25, max: .75));
      await t.pump();
      expect(value, closeTo(.15, 1e-10));
    },
  );
  testWidgets(
    'uncontrolled initialization is retained on rebuild and controlled values stay external',
    (t) async {
      await t.pumpWidget(
        host(const SteySlider(defaultValue: 25, label: 'Volume')),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(texts(t), ['26']);
      await t.pumpWidget(
        host(const SteySlider(defaultValue: 75, label: 'Volume')),
      );
      expect(texts(t), ['26']);
      final calls = <double>[];
      await t.pumpWidget(
        host(SteySlider(value: 40, label: 'Volume', onChanged: calls.add)),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(calls.last, 41);
      expect(texts(t), ['40']);
    },
  );
  testWidgets(
    'disabled and legacy null callback block pointers, focus and notifications',
    (t) async {
      var count = 0;
      for (final slider in [
        SteySlider(value: 40, disabled: true, onChanged: (_) => count++),
        const SteySlider(value: 40, onChanged: null),
      ]) {
        await t.pumpWidget(host(slider));
        await t.tapAt(point(t, 80));
        await t.pump();
        expect(count, 0);
        final w = t.widget<Semantics>(thumbs().first);
        expect(w.properties.enabled, false);
        expect(w.properties.onIncrease, isNull);
        expect(
          t
              .widget<Opacity>(
                find.descendant(
                  of: find.byType(SteySlider),
                  matching: find.byType(Opacity),
                ),
              )
              .opacity,
          .5,
        );
      }
    },
  );
  testWidgets(
    'arrows Shift and Page keys commit immediately while boundaries do not notify',
    (t) async {
      double value = 40;
      final commits = <double>[];
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) => SteySlider(
              value: value,
              step: 2,
              largeStep: 15,
              onChanged: (v) => set(() => value = v),
              onChangeCommitted: commits.add,
            ),
          ),
        ),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(value, 42);
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pump();
      expect(value, 57);
      await t.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await t.pump();
      expect(value, 43);
      await t.sendKeyEvent(LogicalKeyboardKey.home);
      await t.pump();
      expect(value, 0);
      final count = commits.length;
      await t.sendKeyEvent(LogicalKeyboardKey.home);
      await t.pump();
      expect(commits.length, count);
      await t.sendKeyEvent(LogicalKeyboardKey.end);
      await t.pump();
      expect(value, 100);
    },
  );
  testWidgets(
    'RTL reverses horizontal arrows and track coordinates, vertical arrows retain meaning',
    (t) async {
      double value = 40;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) => SteySlider(
              value: value,
              onChanged: (v) => set(() => value = v),
            ),
          ),
          rtl: true,
        ),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(value, 39);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pump();
      expect(value, 40);
      await t.tapAt(point(t, 75, rtl: true));
      await t.pump();
      expect(value, 75);
    },
  );
  testWidgets(
    'keyboard range neighbors clamp and minimum distance rejects invalid changes',
    (t) async {
      List<double> values = [25, 75];
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) => SteySlider.range(
              values: values,
              minStepsBetweenValues: 10,
              onChanged: (v) => set(() => values = v),
            ),
          ),
        ),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.end);
      await t.pump();
      expect(values, [65, 75]);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(values, [65, 75]);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.home);
      await t.pump();
      expect(values, [65, 75]);
    },
  );
  testWidgets(
    'push moves neighbors, does not restore them on dragging back, and honors gaps',
    (t) async {
      List<double> values = [25, 50, 75];
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) => SteySlider.range(
              values: values,
              minStepsBetweenValues: 10,
              onChanged: (v) => set(() => values = v),
            ),
          ),
        ),
      );
      final g = await t.startGesture(t.getCenter(thumbs().first));
      await g.moveTo(point(t, 90));
      await t.pump();
      expect(values, [80, 90, 100]);
      await g.moveTo(point(t, 30));
      await t.pump();
      expect(values, [30, 90, 100]);
      await g.up();
    },
  );
  testWidgets(
    'none collision stops at neighbor distance and swap transfers the active thumb',
    (t) async {
      List<double> values = [25, 75];
      Future<void> mount(SteySliderCollision collision) async {
        values = [25, 75];
        await t.pumpWidget(const SizedBox());
        await t.pumpWidget(
          host(
            StatefulBuilder(
              builder: (_, set) => SteySlider.range(
                values: values,
                thumbCollisionBehavior: collision,
                onChanged: (v) => set(() => values = v),
              ),
            ),
          ),
        );
      }

      await mount(SteySliderCollision.none);
      var g = await t.startGesture(t.getCenter(thumbs().first));
      await g.moveTo(point(t, 90));
      await t.pump();
      expect(values, [75, 75]);
      await g.up();
      await mount(SteySliderCollision.swap);
      g = await t.startGesture(t.getCenter(thumbs().first));
      await g.moveTo(point(t, 90));
      await t.pump();
      expect(values, [75, 90]);
      await g.moveTo(point(t, 95));
      await t.pump();
      expect(values, [75, 95]);
      await g.up();
    },
  );
  testWidgets(
    'change cancellation suppresses scalar callback and commit, including swap',
    (t) async {
      var calls = 0, commits = 0;
      await t.pumpWidget(
        host(
          SteySlider.range(
            values: const [25, 75],
            thumbCollisionBehavior: SteySliderCollision.swap,
            onChanged: (_) => calls++,
            onChangeCommitted: (_) => commits++,
            onValueChange: (_, d) => d.cancel(),
          ),
        ),
      );
      final g = await t.startGesture(t.getCenter(thumbs().first));
      await g.moveTo(point(t, 90));
      await t.pump();
      await g.up();
      await t.pump();
      expect(calls, 0);
      expect(commits, 0);
      expect(texts(t), ['25 start range', '75 end range']);
    },
  );
  testWidgets(
    'count changes and disable during drag do not commit a stale range',
    (t) async {
      var commits = 0;
      List<double> values = [25, 75];
      late StateSetter set;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, s) {
              set = s;
              return SteySlider.range(
                values: values,
                onChanged: (v) => s(() => values = v),
                onChangeCommitted: (_) => commits++,
              );
            },
          ),
        ),
      );
      final g = await t.startGesture(t.getCenter(thumbs().first));
      await g.moveTo(point(t, 40));
      await t.pump();
      set(() => values = [50]);
      await t.pump();
      await g.up();
      await t.pump();
      expect(commits, 0);
      expect(thumbs(), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'format, locale, rich label and per-thumb accessible names/text',
    (t) async {
      await t.pumpWidget(
        host(
          SteySlider.range(
            values: const [12.5, 75.5],
            label: null,
            labelWidget: const Text('Price'),
            semanticLabel: 'Prices',
            format: NumberFormat('0.0', 'en_US'),
            getAriaLabel: (i) => i == 0 ? 'Minimum' : 'Maximum',
            getAriaValueText: (text, v, i) => '$text dollars',
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Price'), findsOneWidget);
      expect(find.text('12.5'), findsOneWidget);
      expect(texts(t), ['12.5 dollars', '75.5 dollars']);
      expect(find.bySemanticsLabel('Minimum'), findsOneWidget);
    },
  );
  testWidgets(
    'center and edge-client-only alignment, no label and dynamic sorted values',
    (t) async {
      for (final alignment in SteySliderThumbAlignment.values) {
        await t.pumpWidget(
          host(
            SteySlider.range(
              key: ValueKey(alignment),
              values: const [100, 0],
              label: null,
              thumbAlignment: alignment,
              onChanged: (_) {},
            ),
          ),
        );
        final box = t.getRect(find.byType(SteySlider));
        expect(
          t.getCenter(thumbs().first).dx - box.left,
          alignment == SteySliderThumbAlignment.center ? 3 : 11,
        );
        expect(texts(t), ['0 start range', '100 end range']);
      }
    },
  );
  testWidgets(
    'semantics increase/decrease use the real step and disabled changes remain inert',
    (t) async {
      double value = 25;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) => SteySlider(
              value: value,
              step: .5,
              onChanged: (v) => set(() => value = v),
            ),
          ),
        ),
      );
      final node = t.getSemantics(thumbs().first);
      t
          .renderObject(thumbs().first)
          .owner!
          .semanticsOwner!
          .performAction(node.id, SemanticsAction.increase);
      await t.pump();
      expect(value, 25.5);
      t
          .renderObject(thumbs().first)
          .owner!
          .semanticsOwner!
          .performAction(node.id, SemanticsAction.decrease);
      await t.pump();
      expect(value, 25);
    },
  );
  testWidgets(
    'nearby button receives pointer actions and disposal removes all owned focus nodes',
    (t) async {
      var count = 0;
      await t.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SteySlider(defaultValue: 40),
              TextButton(onPressed: () => count++, child: const Text('After')),
            ],
          ),
        ),
      );
      await t.tap(find.text('After'));
      await t.pump();
      expect(count, 1);
      await t.pumpWidget(const SizedBox());
      expect(t.takeException(), isNull);
    },
  );
}
