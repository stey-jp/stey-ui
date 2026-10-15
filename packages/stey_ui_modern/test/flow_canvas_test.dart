import 'dart:ui' show SemanticsAction, SemanticsRole;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

const first = ValueKey('first');
Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: Center(child: child)),
);
Finder viewport() => find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == '_FlowCanvasViewport',
);
Widget diagram({
  ValueChanged<({bool x, bool y})>? overflow,
  VoidCallback? onPressed,
  double width = 600,
  double height = 400,
  double viewWidth = 300,
  double viewHeight = 200,
  bool canvas = true,
}) => SizedBox(
  width: viewWidth,
  child: SteyFlow.composed(
    canvas: canvas,
    viewportHeight: viewHeight,
    padding: const EdgeInsets.all(16),
    onOverflowChange: overflow,
    children: [
      SteyFlowNode(
        'a',
        SizedBox(
          width: width,
          height: height,
          child: Align(
            alignment: Alignment.topLeft,
            child: onPressed == null
                ? const Text('First', key: first)
                : SteyButton(
                    onPressed: onPressed,
                    child: const Text('First', key: first),
                  ),
          ),
        ),
        custom: true,
      ),
    ],
  ),
);
Future<void> wheel(WidgetTester tester, Offset delta) async {
  await tester.sendEventToBinding(
    PointerScrollEvent(
      position: tester.getTopLeft(viewport()) + const Offset(8, 8),
      scrollDelta: delta,
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('Trackpad pans without scaling and leaves node gestures alone', (
    t,
  ) async {
    await t.pumpWidget(host(diagram()));
    await t.pumpAndSettle();
    final origin = t.getTopLeft(find.byKey(first)),
        size = t.getSize(find.byKey(first));
    final trackpad = await t.createGesture(kind: PointerDeviceKind.trackpad);
    await trackpad.panZoomStart(
      t.getTopLeft(viewport()) + const Offset(250, 8),
    );
    await trackpad.panZoomUpdate(
      t.getTopLeft(viewport()) + const Offset(250, 8),
      pan: const Offset(-40, -20),
      scale: 2,
    );
    await trackpad.panZoomUpdate(
      t.getTopLeft(viewport()) + const Offset(250, 8),
      pan: const Offset(-60, -30),
      scale: 2,
    );
    await trackpad.panZoomEnd();
    await t.pumpAndSettle();
    expect(t.getTopLeft(find.byKey(first)).dx, lessThan(origin.dx - 30));
    expect(t.getSize(find.byKey(first)), size);
    final stopped = t.getTopLeft(find.byKey(first));
    await trackpad.panZoomStart(stopped + const Offset(100, 40));
    await trackpad.panZoomUpdate(
      stopped + const Offset(100, 40),
      pan: const Offset(-50, 0),
    );
    await trackpad.panZoomEnd();
    await t.pumpAndSettle();
    expect(t.getTopLeft(find.byKey(first)), stopped);
  });

  testWidgets('Fitting canvas leaves wheel scrolling to the surrounding page', (
    t,
  ) async {
    final scroll = ScrollController();
    await t.pumpWidget(
      host(
        SingleChildScrollView(
          controller: scroll,
          child: Column(
            children: [
              diagram(width: 80, height: 40),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await wheel(t, const Offset(0, 80));
    expect(scroll.offset, greaterThan(0));
    await t.pumpWidget(const SizedBox());
    scroll.dispose();
  });

  testWidgets(
    'Native semantic scroll actions move content and retain its list',
    (t) async {
      final semantics = t.ensureSemantics();
      await t.pumpWidget(host(diagram()));
      await t.pumpAndSettle();
      final origin = t.getTopLeft(find.byKey(first));
      final node = t.getSemantics(viewport());
      t
          .renderObject(viewport())
          .owner!
          .semanticsOwner!
          .performAction(node.id, SemanticsAction.scrollLeft);
      await t.pumpAndSettle();
      expect(t.getTopLeft(find.byKey(first)).dx, origin.dx - 240);
      expect(
        find.semantics.byPredicate(
          (n) =>
              !n.isMergedIntoParent &&
              n.getSemanticsData().role == SemanticsRole.list,
        ),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'Wheel uses independent deltas, clamps both edges and never zooms',
    (t) async {
      final states = <({bool x, bool y})>[];
      await t.pumpWidget(host(diagram(overflow: states.add)));
      await t.pumpAndSettle();
      expect(states, [(x: true, y: true)]);
      final origin = t.getTopLeft(find.byKey(first)),
          size = t.getSize(find.byKey(first));
      await wheel(t, const Offset(40, 60));
      expect(t.getTopLeft(find.byKey(first)), origin - const Offset(40, 60));
      await wheel(t, const Offset(10000, 10000));
      expect(t.getTopLeft(find.byKey(first)), origin - const Offset(332, 232));
      await wheel(t, const Offset(-10000, -10000));
      expect(t.getTopLeft(find.byKey(first)), origin);
      expect(t.getSize(find.byKey(first)), size);
      expect(states, hasLength(1));
    },
  );

  testWidgets('Horizontal overflow does not reinterpret a vertical wheel', (
    t,
  ) async {
    await t.pumpWidget(host(diagram(height: 40)));
    await t.pumpAndSettle();
    final origin = t.getTopLeft(find.byKey(first));
    await wheel(t, const Offset(0, 100));
    expect(t.getTopLeft(find.byKey(first)), origin);
    await wheel(t, const Offset(100, 0));
    expect(t.getTopLeft(find.byKey(first)), origin - const Offset(100, 0));
  });

  testWidgets('Background drags pan with mouse and touch without inertia', (
    t,
  ) async {
    for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
      await t.pumpWidget(host(diagram()));
      await t.pumpAndSettle();
      await wheel(t, const Offset(-10000, -10000));
      final origin = t.getTopLeft(find.byKey(first));
      final gesture = await t.startGesture(
        t.getTopLeft(viewport()) + const Offset(250, 8),
        kind: kind,
      );
      await gesture.moveBy(const Offset(-40, 0));
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.up();
      await t.pumpAndSettle();
      expect(t.getTopLeft(find.byKey(first)).dx, lessThan(origin.dx - 30));
      final stopped = t.getTopLeft(find.byKey(first));
      await t.pump(const Duration(seconds: 1));
      expect(t.getTopLeft(find.byKey(first)), stopped);
    }
  });

  testWidgets(
    'Node drags leave canvas still and node buttons remain clickable',
    (t) async {
      var calls = 0;
      await t.pumpWidget(host(diagram(onPressed: () => calls++)));
      await t.pumpAndSettle();
      final origin = t.getTopLeft(find.byKey(first));
      await t.dragFrom(origin + const Offset(100, 40), const Offset(-50, -30));
      await t.pumpAndSettle();
      expect(t.getTopLeft(find.byKey(first)), origin);
      await t.tap(find.byKey(first));
      expect(calls, 1);
    },
  );

  testWidgets('Content shrinking and viewport resizing clamp and notify once', (
    t,
  ) async {
    final states = <({bool x, bool y})>[];
    late StateSetter update;
    var width = 600.0, viewWidth = 300.0;
    await t.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return diagram(
              width: width,
              viewWidth: viewWidth,
              height: 40,
              overflow: states.add,
            );
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    await wheel(t, const Offset(10000, 0));
    update(() => width = 350);
    await t.pumpAndSettle();
    expect(
      t.getTopLeft(find.byKey(first)).dx,
      t.getTopLeft(viewport()).dx + 16 - 82,
    );
    update(() => viewWidth = 500);
    await t.pumpAndSettle();
    expect(states, [(x: true, y: false), (x: false, y: false)]);
    expect(
      t.getTopLeft(find.byKey(first)).dx,
      t.getTopLeft(viewport()).dx + 75,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Fitting diagrams center horizontally and retain natural height',
    (t) async {
      await t.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: SteyFlow.composed(
              padding: const EdgeInsets.all(16),
              children: const [
                SteyFlowNode(
                  'a',
                  SizedBox(key: first, width: 80, height: 40),
                  custom: true,
                ),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.getSize(viewport()), const Size(300, 72));
      expect(
        t.getTopLeft(find.byKey(first)) - t.getTopLeft(viewport()),
        const Offset(110, 16),
      );
      expect(find.byType(InteractiveViewer), findsNothing);
    },
  );

  testWidgets('No canvas bypasses gestures, viewport and overflow callbacks', (
    t,
  ) async {
    final states = <({bool x, bool y})>[];
    await t.pumpWidget(host(diagram(canvas: false, overflow: states.add)));
    await t.pumpAndSettle();
    expect(viewport(), findsNothing);
    expect(states, isEmpty);
    expect(t.getSize(find.byType(SteyFlow)).height, 432);
  });

  testWidgets(
    'Pointer cancellation ends drag and preserves later interaction',
    (t) async {
      await t.pumpWidget(host(diagram()));
      await t.pumpAndSettle();
      final drag = await t.startGesture(
        t.getTopLeft(viewport()) + const Offset(260, 8),
      );
      await drag.moveBy(const Offset(-50, 0));
      await drag.cancel();
      await t.pumpAndSettle();
      final stopped = t.getTopLeft(find.byKey(first));
      await wheel(t, const Offset(10, 0));
      expect(t.getTopLeft(find.byKey(first)), stopped - const Offset(10, 0));
      expect(t.takeException(), isNull);
    },
  );
}
