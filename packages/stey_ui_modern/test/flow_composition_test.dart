import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: Center(child: child)),
);
SteyFlowNode node(String id, double width, double height) => SteyFlowNode(
  id,
  SizedBox(width: width, height: height, child: Text(id)),
  custom: true,
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
Set<String> edges(WidgetTester t) =>
    (painter(t).endpoints as Map).keys.cast<String>().toSet();

void main() {
  testWidgets(
    'List entry and exit rules connect nested branches and skip adjacent parallels',
    (tester) async {
      await tester.pumpWidget(
        host(
          SteyFlow.composed(
            canvas: false,
            padding: EdgeInsets.zero,
            children: [
              node('a', 20, 20),
              SteyFlowParallel([
                SteyFlowList([node('b', 20, 20), node('c', 20, 20)]),
                node('d', 20, 20),
              ]),
              node('e', 20, 20),
            ],
          ),
        ),
      );
      expect(edges(tester), {'a-b', 'a-d', 'b-c', 'c-e', 'd-e'});
      await tester.pumpWidget(
        host(
          SteyFlow.composed(
            canvas: false,
            padding: EdgeInsets.zero,
            children: [
              SteyFlowParallel([node('a', 20, 20), node('b', 20, 20)]),
              SteyFlowParallel([node('c', 20, 20), node('d', 20, 20)]),
            ],
          ),
        ),
      );
      expect(edges(tester), isEmpty);
      await tester.pumpWidget(
        host(
          const SteyFlow.composed(
            canvas: false,
            padding: EdgeInsets.zero,
            children: [],
          ),
        ),
      );
      expect(edges(tester), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Horizontal start and center match the official 64/16px layout', (
    tester,
  ) async {
    for (final align in SteyFlowAlign.values) {
      await tester.pumpWidget(
        host(
          SteyFlow.composed(
            canvas: false,
            padding: EdgeInsets.zero,
            align: align,
            children: [
              node('a', 40, 20),
              SteyFlowParallel([node('b', 80, 40), node('c', 30, 30)]),
              node('d', 50, 20),
            ],
          ),
        ),
      );
      expect(rect(tester, 'b'), const Rect.fromLTWH(104, 0, 80, 40));
      expect(rect(tester, 'c'), const Rect.fromLTWH(104, 56, 30, 30));
      expect(rect(tester, 'd').left, 248);
      expect(rect(tester, 'a').top, align == SteyFlowAlign.center ? 33 : 0);
      expect(rect(tester, 'd').top, align == SteyFlowAlign.center ? 33 : 0);
    }
  });

  testWidgets('Vertical list and parallel layout swap primary and cross axes', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SteyFlow.composed(
          canvas: false,
          padding: EdgeInsets.zero,
          orientation: SteyFlowOrientation.vertical,
          align: SteyFlowAlign.center,
          children: [
            node('a', 40, 20),
            SteyFlowParallel([node('b', 80, 40), node('c', 30, 30)]),
            node('d', 50, 20),
          ],
        ),
      ),
    );
    expect(rect(tester, 'a'), const Rect.fromLTWH(43, 0, 40, 20));
    expect(rect(tester, 'b'), const Rect.fromLTWH(0, 84, 80, 40));
    expect(rect(tester, 'c'), const Rect.fromLTWH(96, 84, 30, 30));
    expect(rect(tester, 'd'), const Rect.fromLTWH(38, 188, 50, 20));
    final e = (painter(tester).endpoints as Map)['a-b'];
    expect(e.start, rect(tester, 'a').bottomCenter);
    expect(e.end, rect(tester, 'b').topCenter);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'End-aligned parallel branches share their far edge in both orientations',
    (tester) async {
      for (final vertical in [false, true]) {
        await tester.pumpWidget(
          host(
            SteyFlow.composed(
              canvas: false,
              padding: EdgeInsets.zero,
              orientation: vertical
                  ? SteyFlowOrientation.vertical
                  : SteyFlowOrientation.horizontal,
              children: [
                SteyFlowParallel([
                  node('short', 30, 20),
                  SteyFlowList([node('b', 20, 20), node('c', 40, 30)]),
                ], alignEnd: true),
              ],
            ),
          ),
        );
        expect(
          vertical ? rect(tester, 'short').bottom : rect(tester, 'short').right,
          vertical ? rect(tester, 'c').bottom : rect(tester, 'c').right,
        );
      }
    },
  );

  testWidgets(
    'Natural content resize moves downstream nodes without replacing child state',
    (tester) async {
      var value = 'Short';
      late StateSetter update;
      var calls = 0;
      final expanding = StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value),
              SteyButton(onPressed: () => calls++, child: const Text('Count')),
            ],
          );
        },
      );
      await tester.pumpWidget(
        host(
          SteyFlow.composed(
            canvas: false,
            padding: EdgeInsets.zero,
            children: [
              SteyFlowNode('dynamic', expanding, custom: true),
              const SteyFlowNode('after', Text('Next')),
            ],
          ),
        ),
      );
      final before = rect(tester, 'after').left;
      await tester.tap(find.text('Count'));
      expect(calls, 1);
      update(() => value = 'Much longer content that resizes the node');
      await tester.pumpAndSettle();
      expect(rect(tester, 'after').left, greaterThan(before));
      expect(
        rect(tester, 'after').left,
        closeTo(rect(tester, 'dynamic').right + 64, .01),
      );
      await tester.tap(find.text('Count'));
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Empty groups have no entry/exit; nested lists keep their own links',
    (tester) async {
      await tester.pumpWidget(
        host(
          SteyFlow.composed(
            canvas: false,
            padding: EdgeInsets.zero,
            children: [
              node('a', 10, 10),
              const SteyFlowList([]),
              node('b', 10, 10),
              SteyFlowList([node('c', 10, 10), node('d', 10, 10)]),
            ],
          ),
        ),
      );
      expect(edges(tester), {'b-c', 'c-d'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Expanded text and explicit dimensions update the complete frame',
    (tester) async {
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(
          host(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const SteyFlow.composed(
                canvas: false,
                padding: EdgeInsets.zero,
                children: [
                  SteyFlowNode('natural', Text('Content')),
                  SteyFlowNode('fixed', Text('Fixed'), width: 160, height: 60),
                ],
              ),
            ),
          ),
        );
        expect(rect(tester, 'fixed').size, const Size(160, 60));
        expect(rect(tester, 'natural').height, closeTo(21 * scale + 16, .1));
        expect(
          rect(tester, 'fixed').left,
          closeTo(rect(tester, 'natural').right + 64, .01),
        );
      }
    },
  );

  testWidgets('Interactive canvas takes its height from the natural diagram', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SteyFlow.composed(
          children: [
            SteyFlowNode('a', SizedBox(width: 40, height: 120), custom: true),
            SteyFlowNode('b', Text('Next')),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InteractiveViewer)).height, 248);
    expect(tester.takeException(), isNull);
  });
}
