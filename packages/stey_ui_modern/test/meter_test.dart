import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child, {bool rtl = false, bool reduced = false}) =>
    MaterialApp(
      theme: SteyTheme.material(Brightness.light),
      home: Scaffold(
        body: Center(
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: SizedBox(width: 320, child: child),
            ),
          ),
        ),
      ),
    );
double fill(WidgetTester t) => t
    .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .widthFactor!;

void main() {
  testWidgets(
    'default geometry, typography, brand fill and numerical semantics',
    (t) async {
      await t.pumpWidget(host(const SteyMeter(value: 65, label: 'Usage')));
      expect(t.getSize(find.byType(SteyMeter)), const Size(320, 32));
      expect(fill(t), .65);
      expect(t.widget<Text>(find.text('Usage')).style!.fontSize, 12);
      expect(t.widget<Text>(find.text('65%')).style!.fontSize, 13);
      expect(
        t.widget<Text>(find.text('65%')).style!.fontWeight,
        FontWeight.w500,
      );
      final data = t
          .getSemantics(find.bySemanticsLabel('Usage'))
          .getSemanticsData();
      expect(data.role, ui.SemanticsRole.progressBar);
      expect(
        (data.value, data.minValue, data.maxValue, data.hint),
        ('65.0', '0.0', '100.0', '65%'),
      );
      final c = SteyTheme.colorsOf(t.element(find.byType(SteyMeter)));
      expect(
        t.widgetList<ColoredBox>(find.byType(ColoredBox)).map((w) => w.color),
        containsAll([c.fill, c.brand]),
      );
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'finite boundaries, offset and negative ranges clamp both number and fill',
    (t) async {
      for (final row in <(double, double, double, double, double)>[
        (-10, 0, 100, 0, 0),
        (150, 0, 100, 100, 1),
        (50, 20, 80, 50, .5),
        (15, 20, 80, 20, 0),
        (85, 20, 80, 80, 1),
        (-30, -100, 0, -30, .7),
      ]) {
        await t.pumpWidget(
          host(
            SteyMeter(
              key: ValueKey(row),
              value: row.$1,
              min: row.$2,
              max: row.$3,
              label: 'Usage',
            ),
          ),
        );
        expect(fill(t), closeTo(row.$5, .000001));
        expect(
          t
              .getSemantics(find.bySemanticsLabel('Usage'))
              .getSemanticsData()
              .value,
          '${row.$4}',
        );
      }
    },
  );
  testWidgets(
    'NaN and positive/negative infinity are finite at rendering and semantics',
    (t) async {
      for (final row in [
        (double.nan, 20.0, 0.0),
        (double.infinity, 80.0, 1.0),
        (double.negativeInfinity, 20.0, 0.0),
      ]) {
        await t.pumpWidget(
          host(
            SteyMeter(
              key: ValueKey(row),
              value: row.$1,
              min: 20,
              max: 80,
              label: 'Usage',
            ),
          ),
        );
        expect(fill(t), row.$3);
        expect(
          t
              .getSemantics(find.bySemanticsLabel('Usage'))
              .getSemanticsData()
              .value,
          '${row.$2}',
        );
        expect(t.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'custom value wins hidden numeric text and leaves accessible computed value',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyMeter(
            value: 65,
            label: 'Usage',
            customValue: '650 / 1,000',
            showValue: false,
          ),
        ),
      );
      expect(find.text('650 / 1,000'), findsOneWidget);
      expect(find.text('65%'), findsNothing);
      expect(
        t.getSemantics(find.bySemanticsLabel('Usage')).getSemanticsData().hint,
        '65%',
      );
    },
  );
  testWidgets(
    'empty custom value uses showValue and hiding still retains the label and hint',
    (t) async {
      await t.pumpWidget(
        host(const SteyMeter(value: 65, label: 'Usage', customValue: '')),
      );
      expect(find.text('65%'), findsOneWidget);
      await t.pumpWidget(
        host(
          const SteyMeter(
            value: 65,
            label: 'Usage',
            customValue: '',
            showValue: false,
          ),
        ),
      );
      expect(find.text('65%'), findsNothing);
      expect(find.text('Usage'), findsOneWidget);
      expect(
        t.getSemantics(find.bySemanticsLabel('Usage')).getSemanticsData().hint,
        '65%',
      );
    },
  );
  testWidgets(
    'locale percentage, decimal and currency format the clamped raw number',
    (t) async {
      await t.pumpWidget(
        host(const SteyMeter(value: 65, label: 'Usage', locale: 'de_DE')),
      );
      expect(
        find.text(NumberFormat.percentPattern('de_DE').format(.65)),
        findsOneWidget,
      );
      await t.pumpWidget(
        host(
          SteyMeter(
            value: 150,
            label: 'Usage',
            format: NumberFormat('0.0', 'en_US'),
          ),
        ),
      );
      expect(find.text('100.0'), findsOneWidget);
      await t.pumpWidget(
        host(
          SteyMeter(
            value: 65.25,
            label: 'Usage',
            format: NumberFormat.currency(
              locale: 'en_US',
              symbol: r'$',
              name: 'USD',
            ),
          ),
        ),
      );
      expect(find.text(r'$65.25'), findsOneWidget);
    },
  );
  testWidgets(
    'accessible text callback sees formatted clamped number and raw input',
    (t) async {
      (String, double)? args;
      await t.pumpWidget(
        host(
          SteyMeter(
            value: 150,
            label: 'Usage',
            getAriaValueText: (formatted, raw) {
              args = (formatted, raw);
              return 'Storage: $formatted';
            },
          ),
        ),
      );
      expect(args, ('100%', 150));
      final data = t
          .getSemantics(find.bySemanticsLabel('Usage'))
          .getSemanticsData();
      expect(data.value, '100.0');
      expect(data.hint, 'Storage: 100%');
    },
  );
  testWidgets(
    'value updates have 300ms CSS ease-out width and immediate numeric text',
    (t) async {
      await t.pumpWidget(host(const SteyMeter(value: 0, label: 'Usage')));
      await t.pumpWidget(host(const SteyMeter(value: 100, label: 'Usage')));
      expect(find.text('100%'), findsOneWidget);
      expect(fill(t), 0);
      await t.pump(const Duration(milliseconds: 150));
      expect(fill(t), closeTo(const Cubic(0, 0, .2, 1).transform(.5), .0001));
      await t.pump(const Duration(milliseconds: 150));
      expect(fill(t), 1);
    },
  );
  testWidgets(
    'interruption starts from the rendered fraction and range changes animate',
    (t) async {
      await t.pumpWidget(host(const SteyMeter(value: 0, label: 'Usage')));
      await t.pumpWidget(host(const SteyMeter(value: 100, label: 'Usage')));
      await t.pump(const Duration(milliseconds: 100));
      final before = fill(t);
      await t.pumpWidget(
        host(const SteyMeter(value: 50, min: 20, max: 80, label: 'Usage')),
      );
      expect(fill(t), closeTo(before, .0001));
      await t.pumpAndSettle();
      expect(fill(t), .5);
    },
  );
  testWidgets(
    'reduced motion preference does not skip width transition and disposal cancels ticker',
    (t) async {
      await t.pumpWidget(
        host(const SteyMeter(value: 0, label: 'Usage'), reduced: true),
      );
      await t.pumpWidget(
        host(const SteyMeter(value: 100, label: 'Usage'), reduced: true),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(fill(t), inExclusiveRange(0, 1));
      await t.pumpWidget(const SizedBox.shrink());
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'native colors and tone compatibility preserve explicit override priority',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyMeter(
            value: 65,
            label: 'Usage',
            tone: SteyTone.danger,
            trackColor: Colors.yellow,
          ),
        ),
      );
      final c = SteyTheme.colorsOf(t.element(find.byType(SteyMeter)));
      expect(
        t.widgetList<ColoredBox>(find.byType(ColoredBox)).map((w) => w.color),
        containsAll([Colors.yellow, c.dangerText]),
      );
      await t.pumpWidget(
        host(
          const SteyMeter(
            value: 65,
            label: 'Usage',
            tone: SteyTone.danger,
            color: Colors.green,
          ),
        ),
      );
      expect(
        t.widgetList<ColoredBox>(find.byType(ColoredBox)).map((w) => w.color),
        contains(Colors.green),
      );
    },
  );
  testWidgets(
    'narrow long labels, RTL, large text and optional legacy label do not overflow',
    (t) async {
      await t.pumpWidget(
        host(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const SizedBox(
              width: 160,
              child: SteyMeter(
                value: 65,
                label: 'Total storage usage across the entire project',
                customValue: '650 / 1,000 GB',
              ),
            ),
          ),
          rtl: true,
        ),
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(host(const SteyMeter(value: 65)));
      expect(find.text('65%'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  const capture = String.fromEnvironment('STEY_METER_CAPTURE_DIR');
  if (capture.isNotEmpty) {
    testWidgets('capture controlled meter transition phases', (t) async {
      final out = Directory(capture)..createSync(recursive: true);
      await t.runAsync(() async {
        final loader = FontLoader('packages/stey_ui_modern/Inter');
        for (final name in ['Regular', 'Medium']) {
          final bytes = File(
            'packages/stey_ui_modern/assets/fonts/Inter-$name.ttf',
          ).readAsBytesSync();
          loader.addFont(Future.value(ByteData.sublistView(bytes)));
        }
        await loader.load();
      });
      final rows = <Map<String, Object?>>[];
      for (final mode in ['light', 'dark']) {
        for (final direction in ['ltr', 'rtl']) {
          await t.pumpWidget(const SizedBox.shrink());
          final boundary = GlobalKey();
          Widget sample(double value) => MaterialApp(
            theme: SteyTheme.material(
              mode == 'dark' ? Brightness.dark : Brightness.light,
            ),
            home: Scaffold(
              body: Center(
                child: Directionality(
                  textDirection: direction == 'rtl'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: RepaintBoundary(
                    key: boundary,
                    child: ColoredBox(
                      color: SteyColors(
                        mode == 'dark' ? Brightness.dark : Brightness.light,
                      ).base,
                      child: SizedBox(
                        width: 320,
                        height: 120,
                        child: Center(
                          child: SteyMeter(
                            value: value,
                            label: 'Storage used',
                            locale: 'en_US',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pumpWidget(sample(25));
          await t.pump();
          await t.pumpWidget(sample(75));
          var previous = 0;
          for (final ms in [0, 75, 150, 225, 300]) {
            await t.pump(Duration(milliseconds: ms - previous));
            previous = ms;
            final file = '$mode-$direction-$ms.png';
            await t.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              File('${out.path}/$file')
                  .writeAsBytesSync(bytes!.buffer.asUint8List());
            });
            rows.add({
              'mode': mode,
              'direction': direction,
              'ms': ms,
              'file': file,
              'fraction': fill(t),
            });
          }
        }
      }
      File('${out.path}/frames.json').writeAsStringSync(jsonEncode(rows));
    });
  }
}
