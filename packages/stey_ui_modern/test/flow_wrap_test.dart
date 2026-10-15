import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: Center(child: child)),
);
dynamic painter(WidgetTester t) => t
    .widget<CustomPaint>(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_FlowPainter',
      ),
    )
    .painter;
Rect rect(WidgetTester t, String id) => (painter(t).rects as Map)[id] as Rect;
const longText = 'Review access permissions before saving changes';

void main() {
  testWidgets(
    'Maximum width includes padding and keeps short content natural',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyFlow.composed(
            canvas: false,
            padding: EdgeInsets.zero,
            children: [
              SteyFlowNode('short', Text('Hi'), maxWidth: 120),
              SteyFlowNode('long', Text(longText), maxWidth: 120),
            ],
          ),
        ),
      );
      expect(rect(t, 'short').width, lessThan(120));
      expect(rect(t, 'short').height, 37);
      expect(rect(t, 'long').width, 120);
      expect(rect(t, 'long').height, greaterThan(37));
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Cap overrides explicit/global widths while fixed height is retained',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyFlow(
            nodeWidth: 200,
            nodeHeight: 60,
            canvas: false,
            padding: EdgeInsets.zero,
            nodes: [
              SteyFlowNode('a', Text('A'), width: 180, maxWidth: 120),
              SteyFlowNode('b', Text('B'), maxWidth: 80),
            ],
            edges: [SteyFlowEdge('a', 'b')],
          ),
        ),
      );
      expect(rect(t, 'a').size, const Size(120, 60));
      expect(rect(t, 'b').size, const Size(80, 60));
      expect(rect(t, 'b').left, 184);
    },
  );

  testWidgets('Wrapped height moves vertical successors and measured anchors', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const SteyFlow.composed(
          canvas: false,
          padding: EdgeInsets.zero,
          orientation: SteyFlowOrientation.vertical,
          children: [
            SteyFlowNode(
              'a',
              SteyFlowAnchor(child: Text(longText)),
              maxWidth: 120,
            ),
            SteyFlowNode('b', Text('Next')),
          ],
        ),
      ),
    );
    expect(rect(t, 'b').top, rect(t, 'a').bottom + 64);
    final e = (painter(t).endpoints as Map)['a-b'];
    expect(e.start, rect(t, 'a').bottomCenter);
    expect(e.end, rect(t, 'b').topCenter);
  });

  testWidgets(
    'Host-driven cap resizes both ways without replacing child state',
    (t) async {
      var cap = 120.0, calls = 0;
      late StateSetter update;
      final control = StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(longText),
            SteyButton(onPressed: () => calls++, child: const Text('Count')),
          ],
        ),
      );
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SteyFlow.composed(
                canvas: false,
                padding: EdgeInsets.zero,
                children: [
                  SteyFlowNode('a', control, maxWidth: cap),
                  const SteyFlowNode('b', Text('Next')),
                ],
              );
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      final narrow = rect(t, 'a');
      await t.tap(find.text('Count'));
      expect(calls, 1);
      update(() => cap = 240);
      await t.pumpAndSettle();
      expect(rect(t, 'a').width, 240);
      expect(rect(t, 'a').height, lessThan(narrow.height));
      expect(rect(t, 'b').left, 304);
      await t.tap(find.text('Count'));
      expect(calls, 2);
      update(() => cap = 120);
      await t.pumpAndSettle();
      expect(rect(t, 'a').size, narrow.size);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Uncapped nodes preserve natural sizing in a narrow canvas', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const SizedBox(
          width: 160,
          child: SteyFlow.composed(
            children: [SteyFlowNode('a', Text(longText))],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(rect(t, 'a').width, greaterThan(160));
    expect(rect(t, 'a').height, 37);
  });

  testWidgets('Custom children are capped without intrinsic measurements', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        SteyFlow.composed(
          canvas: false,
          padding: EdgeInsets.zero,
          children: [
            SteyFlowNode(
              'a',
              LayoutBuilder(
                builder: (context, c) => SizedBox(
                  width: c.hasBoundedWidth ? c.maxWidth : 300,
                  height: 40,
                  child: const Text('Custom'),
                ),
              ),
              custom: true,
              maxWidth: 140,
            ),
          ],
        ),
      ),
    );
    expect(rect(t, 'a').size, const Size(140, 40));
    expect(t.takeException(), isNull);
  });

  testWidgets('Wrapping follows text scaling and logical direction', (t) async {
    for (final direction in TextDirection.values) {
      await t.pumpWidget(
        host(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Directionality(
              textDirection: direction,
              child: const SteyFlow.composed(
                canvas: false,
                padding: EdgeInsetsDirectional.only(start: 12, end: 8),
                children: [SteyFlowNode('a', Text(longText), maxWidth: 160)],
              ),
            ),
          ),
        ),
      );
      expect(rect(t, 'a').width, 160);
      expect(rect(t, 'a').height, greaterThan(58));
      expect(rect(t, 'a').left, direction == TextDirection.ltr ? 12 : 8);
      expect(t.takeException(), isNull);
    }
  });
}
