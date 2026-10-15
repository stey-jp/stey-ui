import 'package:flutter/material.dart';

import 'dart:ui' show SemanticsRole;

import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: Center(child: child)),
);
Finder painterFinder() => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_FlowPainter',
);
Map points(WidgetTester tester) =>
    (tester.widget<CustomPaint>(painterFinder()).painter as dynamic).endpoints
        as Map;
Offset localCenter(WidgetTester tester, Key key) => tester
    .renderObject<RenderBox>(painterFinder())
    .globalToLocal(tester.getCenter(find.byKey(key)));

void main() {
  testWidgets(
    'Flow announces visible content in list items, without technical IDs',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const SteyFlow(
            interactive: false,
            nodes: [
              SteyFlowNode('internal-a', Text('Visible first')),
              SteyFlowNode(
                'internal-b',
                Text('Visible second'),
                disabled: true,
              ),
            ],
            edges: [SteyFlowEdge('internal-a', 'internal-b')],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Visible first'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('internal-')), findsNothing);
      expect(
        find.semantics.byPredicate(
          (n) =>
              !n.isMergedIntoParent &&
              n.getSemanticsData().role == SemanticsRole.listItem,
        ),
        findsNWidgets(2),
      );
      expect(
        find.semantics.byPredicate(
          (n) =>
              !n.isMergedIntoParent &&
              n.getSemanticsData().role == SemanticsRole.list,
        ),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );
  testWidgets('Positive and negative outside margins are included once', (
    tester,
  ) async {
    for (final margin in [-12.0, -4.0, 0.0, 20.0]) {
      await tester.pumpWidget(
        host(
          SteyFlow(
            interactive: false,
            nodes: [
              SteyFlowNode(
                'source',
                const SteyFlowAnchor(
                  key: ValueKey('anchor'),
                  child: SizedBox(height: 40),
                ),
                custom: true,
                width: 120,
                height: 40,
                margin: EdgeInsets.only(top: margin),
              ),
              const SteyFlowNode('target', Text('Next')),
            ],
            edges: const [SteyFlowEdge('source', 'target')],
          ),
        ),
      );
      final Offset start = points(tester)['source-target'].start;
      expect(
        start.dy,
        closeTo(localCenter(tester, const ValueKey('anchor')).dy, .01),
      );
      expect(start.dy, closeTo(64 + margin + 20, .01));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'Outer and inner margins keep both endpoints on a straight line',
    (tester) async {
      await tester.pumpWidget(
        host(
          SteyFlow(
            interactive: false,
            nodes: [
              const SteyFlowNode(
                'outer',
                SteyFlowAnchor(
                  key: ValueKey('outer'),
                  child: SizedBox(height: 40),
                ),
                custom: true,
                width: 120,
                height: 40,
                margin: EdgeInsets.only(top: -4),
              ),
              SteyFlowNode(
                'inner',
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: const SteyFlowAnchor(
                    key: ValueKey('inner'),
                    child: SizedBox(height: 40),
                  ),
                ),
                custom: true,
                width: 120,
                height: 40,
              ),
            ],
            edges: const [SteyFlowEdge('outer', 'inner')],
          ),
        ),
      );
      final edge = points(tester)['outer-inner'];
      expect(
        edge.start.dy,
        closeTo(localCenter(tester, const ValueKey('outer')).dy, .01),
      );
      expect(
        edge.end.dy,
        closeTo(localCenter(tester, const ValueKey('inner')).dy, .01),
      );
      expect(edge.start.dy, closeTo(edge.end.dy, .01));
    },
  );

  testWidgets('Separate incoming and outgoing anchors resize and unregister', (
    tester,
  ) async {
    var expanded = false, anchor = true;
    late StateSetter update;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SteyFlow(
              interactive: false,
              nodes: [
                const SteyFlowNode('before', Text('Before')),
                SteyFlowNode(
                  'middle',
                  Column(
                    children: [
                      const SteyFlowAnchor(
                        type: SteyFlowAnchorType.end,
                        key: ValueKey('incoming'),
                        child: SizedBox(height: 20),
                      ),
                      SizedBox(height: expanded ? 40 : 8),
                      if (anchor)
                        const SteyFlowAnchor(
                          type: SteyFlowAnchorType.start,
                          key: ValueKey('outgoing'),
                          child: SizedBox(height: 20),
                        ),
                    ],
                  ),
                  custom: true,
                  width: 120,
                  height: expanded ? 100 : 60,
                ),
                const SteyFlowNode('after', Text('After')),
              ],
              edges: const [
                SteyFlowEdge('before', 'middle'),
                SteyFlowEdge('middle', 'after'),
              ],
            );
          },
        ),
      ),
    );
    for (final change in [false, true]) {
      update(() => expanded = change);
      await tester.pump();
      final ends = points(tester);
      expect(
        ends['before-middle'].end.dy,
        closeTo(localCenter(tester, const ValueKey('incoming')).dy, .01),
      );
      expect(
        ends['middle-after'].start.dy,
        closeTo(localCenter(tester, const ValueKey('outgoing')).dy, .01),
      );
    }
    update(() => anchor = false);
    await tester.pump();
    expect(points(tester)['middle-after'].start.dy, closeTo(64 + 50, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Canvas transforms and a shifted ancestor do not change local endpoints',
    (tester) async {
      await tester.pumpWidget(
        host(
          Transform.translate(
            offset: const Offset(17, 23),
            child: Transform.scale(
              scale: .7,
              child: SteyFlow(
                nodes: const [
                  SteyFlowNode(
                    'source',
                    SteyFlowAnchor(
                      key: ValueKey('scaled'),
                      child: SizedBox(height: 40),
                    ),
                    custom: true,
                    width: 120,
                    height: 40,
                    margin: EdgeInsets.only(top: -4),
                  ),
                  SteyFlowNode('target', Text('Next')),
                ],
                edges: const [SteyFlowEdge('source', 'target')],
              ),
            ),
          ),
        ),
      );
      expect(
        points(tester)['source-target'].start.dy,
        closeTo(localCenter(tester, const ValueKey('scaled')).dy, .01),
      );
    },
  );

  testWidgets(
    'Invalid IDs and cycles fail explicitly; anchors require a flow node',
    (tester) async {
      await tester.pumpWidget(
        host(
          const SteyFlow(
            nodes: [
              SteyFlowNode('same', Text('A')),
              SteyFlowNode('same', Text('B')),
            ],
            edges: [],
          ),
        ),
      );
      expect(tester.takeException(), isArgumentError);
      await tester.pumpWidget(
        host(
          const SteyFlow(
            nodes: [SteyFlowNode('a', Text('A'))],
            edges: [SteyFlowEdge('a', 'missing')],
          ),
        ),
      );
      expect(tester.takeException(), isArgumentError);
      await tester.pumpWidget(
        host(
          const SteyFlow(
            nodes: [SteyFlowNode('a', Text('A'))],
            edges: [SteyFlowEdge('a', 'a')],
          ),
        ),
      );
      expect(tester.takeException(), isArgumentError);
      await tester.pumpWidget(
        host(const SteyFlowAnchor(child: Text('Outside'))),
      );
      expect(tester.takeException(), isFlutterError);
    },
  );
}
