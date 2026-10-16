import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

const description = 'Review access permissions before saving changes';
Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: Center(child: child)),
);
Finder paint() => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_FlowPainter',
);
dynamic painter(WidgetTester t) => t.widget<CustomPaint>(paint()).painter;
Rect rect(WidgetTester t, String id) => (painter(t).rects as Map)[id] as Rect;
Widget diagram({
  double width = 160,
  Key? key,
  SteyFlowOrientation orientation = SteyFlowOrientation.vertical,
  String position = 'middle',
  String text = description,
}) {
  final labels = position == 'only'
      ? ['Process']
      : ['Start', 'Process', 'Review', 'End'];
  final ids = position == 'only'
      ? ['process']
      : ['start', 'process', 'review', 'end'];
  final index = position == 'first'
      ? 0
      : position == 'last'
      ? labels.length - 1
      : 1;
  return SizedBox(
    width: width,
    child: SteyFlow.composed(
      key: key,
      viewportHeight: 500,
      padding: const EdgeInsets.all(16),
      orientation: orientation,
      align: SteyFlowAlign.center,
      children: [
        for (var i = 0; i < labels.length; i++)
          SteyFlowNode(
            ids[i],
            Text(
              position == 'all' || position == 'only' || i == index
                  ? text
                  : labels[i],
            ),
          ),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final local = File('assets/fonts/Inter-Regular.ttf');
    final asset = await local.exists()
        ? local
        : File('packages/stey_ui_modern/assets/fonts/Inter-Regular.ttf');
    final font = FontLoader('packages/stey_ui_modern/Inter')
      ..addFont(asset.readAsBytes().then(ByteData.sublistView));
    await font.load();
  });
  testWidgets(
    'Initial narrow width survives a host resize and resets on remount',
    (t) async {
      var width = 160.0, epoch = 0;
      late StateSetter update;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return diagram(width: width, key: ValueKey(epoch));
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(rect(t, 'process').size, const Size(128, 100));
      update(() => width = 320);
      await t.pumpAndSettle();
      expect(rect(t, 'process').size, const Size(128, 100));
      update(() => epoch++);
      await t.pumpAndSettle();
      expect(rect(t, 'process').size, const Size(288, 58));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Wide initial width survives shrinking and reports horizontal overflow',
    (t) async {
      var width = 320.0;
      late StateSetter update;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return diagram(width: width);
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(rect(t, 'process').size, const Size(288, 58));
      update(() => width = 160);
      await t.pumpAndSettle();
      expect(rect(t, 'process').size, const Size(288, 58));
      expect(t.getSize(find.byType(SteyFlow)).width, 160);
    },
  );
  testWidgets('First, middle and last nodes match official vertical widths', (
    t,
  ) async {
    for (final position in ['only', 'first', 'middle', 'last', 'all']) {
      await t.pumpWidget(
        host(diagram(key: ValueKey(position), position: position)),
      );
      await t.pumpAndSettle();
      final id = position == 'first' || position == 'all'
          ? 'start'
          : position == 'last'
          ? 'end'
          : 'process';
      expect(rect(t, id).size, const Size(128, 100));
    }
  });
  testWidgets(
    'Horizontal layout expands earlier nodes but keeps the last initial width',
    (t) async {
      for (final position in ['first', 'middle', 'last', 'all']) {
        await t.pumpWidget(
          host(
            diagram(
              key: ValueKey(position),
              position: position,
              orientation: SteyFlowOrientation.horizontal,
            ),
          ),
        );
        await t.pumpAndSettle();
        final id = position == 'first' || position == 'all'
            ? 'start'
            : position == 'last'
            ? 'end'
            : 'process';
        expect(rect(t, id).height, position == 'last' ? 100 : 37);
        expect(
          rect(t, id).width,
          position == 'last' ? 128 : closeTo(360.72, .1),
        );
        if (position == 'all') {
          expect(rect(t, 'end').size, const Size(128, 100));
        }
      }
    },
  );
  testWidgets(
    'Content changes use the previous diagram width and move successors',
    (t) async {
      var text = description;
      late StateSetter update;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return diagram(text: text);
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      final before = rect(t, 'review').top;
      update(() => text = 'Check');
      await t.pumpAndSettle();
      expect(rect(t, 'process').height, 37);
      expect(rect(t, 'review').top, lessThan(before));
      update(() => text = description);
      await t.pumpAndSettle();
      expect(rect(t, 'process').width, lessThanOrEqualTo(128));
      expect(rect(t, 'review').top, rect(t, 'process').bottom + 64);
      final e = (painter(t).endpoints as Map)['process-review'];
      expect(e.start, rect(t, 'process').bottomCenter);
    },
  );
  testWidgets('Unbreakable content respects its minimum width', (t) async {
    await t.pumpWidget(
      host(
        diagram(
          width: 80,
          position: 'only',
          text: 'Supercalifragilisticexpialidocious',
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(rect(t, 'process').width, greaterThan(80));
    expect(rect(t, 'process').height, 37);
  });
  testWidgets(
    'Parallel branch order and direction use the measured containing width',
    (t) async {
      for (final vertical in [true, false]) {
        for (final last in [true, false]) {
          final wide = const SteyFlowNode('wide', Text(description));
          final short = const SteyFlowNode('short', Text('Review'));
          await t.pumpWidget(
            host(
              SizedBox(
                width: 160,
                child: SteyFlow.composed(
                  key: ValueKey('$vertical-$last'),
                  padding: const EdgeInsets.all(16),
                  orientation: vertical
                      ? SteyFlowOrientation.vertical
                      : SteyFlowOrientation.horizontal,
                  children: [
                    const SteyFlowNode('start', Text('Start')),
                    SteyFlowParallel(last ? [short, wide] : [wide, short]),
                    const SteyFlowNode('end', Text('End')),
                  ],
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(
            rect(t, 'wide').width,
            vertical && last ? 128 : closeTo(360.72, .1),
          );
          expect(rect(t, 'wide').height, vertical && last ? 100 : 37);
        }
      }
    },
  );
  testWidgets(
    'Long fixed-point expansion continues across frames until settled',
    (t) async {
      await t.pumpWidget(
        host(
          SizedBox(
            width: 160,
            child: SteyFlow.composed(
              padding: const EdgeInsets.all(16),
              children: [
                SteyFlowNode(
                  'a',
                  Text(List.filled(50, 'long description').join(' ')),
                ),
                const SteyFlowNode('b', Text('End')),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(rect(t, 'a').width, greaterThan(1000));
      expect(rect(t, 'a').height, 37);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Unsupported intrinsic children keep native sizing without errors',
    (t) async {
      await t.pumpWidget(
        host(
          SizedBox(
            width: 160,
            child: SteyFlow.composed(
              children: [
                SteyFlowNode(
                  'a',
                  LayoutBuilder(
                    builder: (context, c) =>
                        const SizedBox(width: 300, height: 40),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(rect(t, 'a').width, 324);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Empty trailing groups do not enlarge the measured diagram', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const SteyFlow.composed(
          canvas: false,
          padding: EdgeInsets.zero,
          children: [SteyFlowNode('a', Text('Start')), SteyFlowList([])],
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(t.getSize(paint()).width, rect(t, 'a').right);
  });
}
