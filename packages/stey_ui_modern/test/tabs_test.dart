import 'dart:ui' show PointerDeviceKind, SemanticsRole;
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

const tabs = [
  SteyTab('a', 'Overview'),
  SteyTab('b', 'Analytics'),
  SteyTab('c', 'Settings'),
];
Widget host(
  Widget child, {
  double width = 600,
  bool rtl = false,
  bool reduced = false,
}) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(
    body: Center(
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);
Finder tab(String label) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.properties.role == SemanticsRole.tab &&
      w.properties.label == label,
);
FocusNode node(WidgetTester t, String label) => t
    .widget<Focus>(
      find.ancestor(of: tab(label), matching: find.byType(Focus)).first,
    )
    .focusNode!;
Rect indicator(WidgetTester t) =>
    t.getRect(find.byKey(const ValueKey('stey-tabs-indicator')));
Future<void> ready(WidgetTester t, Widget w) async {
  await t.pumpWidget(w);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'missing initial uncontrolled value falls back once; controlled missing stays empty',
    (t) async {
      var calls = 0;
      await ready(
        t,
        host(
          SteyTabs(
            tabs: tabs,
            selectedValue: 'missing',
            onChanged: (_) => calls++,
          ),
        ),
      );
      expect(t.widget<Semantics>(tab('Overview')).properties.selected, true);
      expect(calls, 1);
      await ready(t, host(const SteyTabs(tabs: tabs, value: 'missing')));
      expect(find.byKey(const ValueKey('stey-tabs-indicator')), findsNothing);
    },
  );
  testWidgets(
    'measured base/small segmented and underline geometry and tablist roles',
    (t) async {
      for (final variant in SteyTabsVariant.values) {
        for (final size in [SteySize.base, SteySize.sm]) {
          await ready(
            t,
            host(
              SteyTabs(
                key: ValueKey((variant, size)),
                tabs: tabs,
                variant: variant,
                size: size,
              ),
            ),
          );
          expect(
            t.getSize(find.byType(SteyTabs)).height,
            variant == SteyTabsVariant.segmented
                ? (size == SteySize.sm ? 26 : 36)
                : (size == SteySize.sm ? 26 : 30),
          );
          expect(
            t.getSize(tab('Overview')).height,
            variant == SteyTabsVariant.segmented
                ? (size == SteySize.sm ? 22 : 32)
                : (size == SteySize.sm ? 20 : 24),
          );
          final bar = t.widget<Semantics>(
            find.byWidgetPredicate(
              (w) =>
                  w is Semantics && w.properties.role == SemanticsRole.tabBar,
            ),
          );
          expect(bar.properties.label, 'Tabs');
          expect(
            indicator(t).height,
            variant == SteyTabsVariant.segmented
                ? t.getSize(tab('Overview')).height
                : 2,
          );
        }
      }
    },
  );
  testWidgets('manual default moves focus only and Enter/Space commit once', (
    t,
  ) async {
    var value = 'a', calls = 0;
    await ready(
      t,
      host(
        StatefulBuilder(
          builder: (context, set) => SteyTabs(
            tabs: tabs,
            value: value,
            onChanged: (v) => set(() {
              value = v;
              calls++;
            }),
          ),
        ),
      ),
    );
    await t.tap(tab('Overview'));
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump();
    expect(node(t, 'Analytics').hasFocus, true);
    expect(value, 'a');
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(value, 'b');
    expect(calls, 1);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump();
    await t.sendKeyDownEvent(LogicalKeyboardKey.space);
    expect(value, 'b');
    await t.sendKeyUpEvent(LogicalKeyboardKey.space);
    await t.pumpAndSettle();
    expect(value, 'c');
    expect(calls, 2);
  });
  testWidgets(
    'activateOnFocus selects arrow destination without duplicate pointer callbacks',
    (t) async {
      var value = 'a', calls = 0;
      await ready(
        t,
        host(
          StatefulBuilder(
            builder: (context, set) => SteyTabs(
              tabs: tabs,
              value: value,
              activateOnFocus: true,
              onValueChange: (v) => set(() {
                value = v;
                calls++;
              }),
            ),
          ),
        ),
      );
      await t.tap(tab('Overview'));
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pumpAndSettle();
      expect(value, 'b');
      expect(calls, 1);
      await t.tap(tab('Settings'));
      await t.pumpAndSettle();
      expect(value, 'c');
      expect(calls, 2);
    },
  );
  testWidgets(
    'disabled extension is skipped and all-disabled lists remain inert',
    (t) async {
      await ready(
        t,
        host(
          const SteyTabs(
            tabs: [
              SteyTab('a', 'Overview'),
              SteyTab('b', 'Analytics', disabled: true),
              SteyTab('c', 'Settings'),
            ],
          ),
        ),
      );
      await t.tap(tab('Overview'));
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(node(t, 'Settings').hasFocus, true);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(node(t, 'Overview').hasFocus, true);
      await ready(
        t,
        host(const SteyTabs(tabs: [SteyTab('a', 'Overview', disabled: true)])),
      );
      await t.tap(tab('Overview'));
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'RTL arrows reverse, Home/End wrap and vertical/modifier keys do not select',
    (t) async {
      await ready(t, host(const SteyTabs(tabs: tabs), rtl: true));
      await t.tap(tab('Overview'));
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(node(t, 'Settings').hasFocus, true);
      await t.sendKeyEvent(LogicalKeyboardKey.home);
      await t.pump();
      expect(node(t, 'Overview').hasFocus, true);
      await t.sendKeyEvent(LogicalKeyboardKey.end);
      await t.pump();
      expect(node(t, 'Settings').hasFocus, true);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pump();
      expect(node(t, 'Settings').hasFocus, true);
    },
  );
  testWidgets(
    'controlled frozen and callback-free values remain selected until updated',
    (t) async {
      var calls = 0;
      await ready(
        t,
        host(SteyTabs(tabs: tabs, value: 'a', onChanged: (_) => calls++)),
      );
      await t.tap(tab('Analytics'));
      await t.pumpAndSettle();
      expect(calls, 1);
      expect(t.widget<Semantics>(tab('Overview')).properties.selected, true);
      await ready(t, host(const SteyTabs(tabs: tabs, value: 'c')));
      expect(t.widget<Semantics>(tab('Settings')).properties.selected, true);
      await t.tap(tab('Overview'));
      await t.pumpAndSettle();
      expect(t.widget<Semantics>(tab('Settings')).properties.selected, true);
    },
  );
  testWidgets(
    'uncontrolled default is retained and missing selection falls back',
    (t) async {
      var calls = 0;
      Widget view(List<SteyTab> list, String initial) => host(
        SteyTabs(tabs: list, selectedValue: initial, onChanged: (_) => calls++),
      );
      await ready(t, view(tabs, 'b'));
      await t.tap(tab('Settings'));
      await t.pumpAndSettle();
      expect(calls, 1);
      await ready(t, view(tabs, 'a'));
      expect(t.widget<Semantics>(tab('Settings')).properties.selected, true);
      await ready(t, view(tabs.take(2).toList(), 'b'));
      expect(t.widget<Semantics>(tab('Overview')).properties.selected, true);
      expect(calls, 2);
    },
  );
  testWidgets(
    'roving focus survives external value changes while focus stays inside',
    (t) async {
      await ready(t, host(const SteyTabs(tabs: tabs, value: 'a')));
      await t.tap(tab('Overview'));
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      await ready(t, host(const SteyTabs(tabs: tabs, value: 'c')));
      expect(node(t, 'Analytics').hasFocus, true);
      expect(node(t, 'Overview').skipTraversal, true);
      expect(node(t, 'Analytics').skipTraversal, false);
    },
  );
  testWidgets(
    'empty tabs render nothing and repopulating resets uncontrolled selection',
    (t) async {
      await ready(t, host(const SteyTabs(tabs: tabs, selectedValue: 'b')));
      await ready(t, host(const SteyTabs()));
      expect(find.byKey(const ValueKey('stey-tabs-indicator')), findsNothing);
      await ready(t, host(const SteyTabs(tabs: tabs)));
      expect(t.widget<Semantics>(tab('Overview')).properties.selected, true);
    },
  );
  testWidgets(
    'tab semantic names, selected state and one traversal stop are exposed',
    (t) async {
      await ready(
        t,
        host(
          const SteyTabs(
            tabs: [
              SteyTab('a', 'Overview', semanticLabel: 'Summary'),
              SteyTab('b', 'Analytics'),
            ],
          ),
        ),
      );
      expect(t.widget<Semantics>(tab('Summary')).properties.selected, true);
      expect(t.widget<Semantics>(tab('Summary')).properties.focused, false);
      expect(t.widget<Semantics>(tab('Analytics')).properties.focused, isNull);
    },
  );
  testWidgets(
    'rich label size changes are measured and update active indicator',
    (t) async {
      Widget view(double width) => host(
        SteyTabs(
          tabs: [
            SteyTab('a', 'Overview', child: SizedBox(width: width, height: 16)),
          ],
        ),
      );
      await ready(t, view(30));
      final before = indicator(t).width;
      await ready(t, view(80));
      expect(indicator(t).width - before, 50);
    },
  );
  testWidgets(
    'overflow controls scroll without selecting and resize removes controls',
    (t) async {
      t.view.physicalSize = const Size(2000, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final long = [for (var i = 0; i < 8; i++) SteyTab('$i', 'Tab number $i')];
      var calls = 0;
      Widget view(double width) => host(
        SteyTabs(tabs: long, onChanged: (_) => calls++),
        width: width,
      );
      await ready(t, view(160));
      expect(find.bySemanticsLabel('Scroll tabs right'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Scroll tabs right'));
      await t.pumpAndSettle();
      expect(calls, 0);
      final controller = t
          .widget<SingleChildScrollView>(
            find.descendant(
              of: find.byType(SteyTabs),
              matching: find.byType(SingleChildScrollView),
            ),
          )
          .controller!;
      expect(controller.offset, greaterThan(0));
      await ready(t, view(1600));
      expect(find.semantics.byLabel('Scroll tabs right'), findsNothing);
    },
  );
  testWidgets('mouse movement beyond3px scrolls and suppresses the click', (
    t,
  ) async {
    var calls = 0;
    await ready(
      t,
      host(
        SteyTabs(
          tabs: [for (var i = 0; i < 8; i++) SteyTab('$i', 'Tab number $i')],
          onChanged: (_) => calls++,
        ),
        width: 160,
      ),
    );
    final g = await t.startGesture(
      t.getCenter(tab('Tab number 0')),
      kind: PointerDeviceKind.mouse,
    );
    await g.moveBy(const Offset(-5, 0));
    await g.up();
    await t.pumpAndSettle();
    expect(calls, 0);
    final controller = t
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    expect(controller.offset, closeTo(5, .1));
  });
  testWidgets('keyboard End reveals overflowing tab before manual activation', (
    t,
  ) async {
    final items = [for (var i = 0; i < 8; i++) SteyTab('$i', 'Tab number $i')];
    await ready(t, host(SteyTabs(tabs: items), width: 160));
    await t.tap(tab('Tab number 0'));
    await t.sendKeyEvent(LogicalKeyboardKey.end);
    await t.pumpAndSettle();
    expect(node(t, 'Tab number 7').hasFocus, true);
    expect(t.widget<Semantics>(tab('Tab number 0')).properties.selected, true);
    expect(
      t
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!
          .offset,
      greaterThan(0),
    );
  });
  testWidgets(
    'indicator follows200ms CSS curve and interrupted movement starts in place',
    (t) async {
      Widget view(String value) => host(SteyTabs(tabs: tabs, value: value));
      await ready(t, view('a'));
      final start = indicator(t), end = t.getRect(tab('Settings'));
      await t.pumpWidget(view('c'));
      await t.pump();
      expect(indicator(t).left, closeTo(start.left, .01));
      await t.pump(const Duration(milliseconds: 100));
      final halfway = indicator(t);
      expect(
        halfway.left,
        closeTo(
          Rect.lerp(start, end, Curves.fastOutSlowIn.transform(.5))!.left,
          .1,
        ),
      );
      await t.pumpWidget(view('b'));
      await t.pump();
      expect(indicator(t).left, closeTo(halfway.left, .1));
      await t.pumpAndSettle();
      expect(indicator(t).left, closeTo(t.getRect(tab('Analytics')).left, .1));
    },
  );
  testWidgets(
    'motion reduction does not skip indicator transition and disposal stops ticker',
    (t) async {
      t.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await ready(
        t,
        host(const SteyTabs(tabs: tabs, value: 'a'), reduced: true),
      );
      final start = indicator(t);
      await t.pumpWidget(
        host(const SteyTabs(tabs: tabs, value: 'c'), reduced: true),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(indicator(t).left, greaterThan(start.left));
      expect(indicator(t).left, lessThan(t.getRect(tab('Settings')).left));
      await t.pumpWidget(const SizedBox.shrink());
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'focused removed tabs dispose cleanly and preserve remaining focus nodes',
    (t) async {
      await ready(t, host(const SteyTabs(tabs: tabs)));
      await t.tap(tab('Analytics'));
      await t.pump();
      await ready(t, host(SteyTabs(tabs: [tabs.first, tabs.last])));
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'current selection is not notified repeatedly by click or held Enter',
    (t) async {
      var calls = 0;
      await ready(t, host(SteyTabs(tabs: tabs, onChanged: (_) => calls++)));
      await t.tap(tab('Overview'));
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(calls, 0);
    },
  );

  testWidgets('RTL overflow controls scroll in their physical direction', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await ready(
      t,
      host(
        SteyTabs(
          tabs: [for (var i = 0; i < 8; i++) SteyTab('$i', 'Long tab $i')],
          labels: const SteyTabsLabels(scrollStart: 'Left', scrollEnd: 'Right'),
        ),
        width: 160,
        rtl: true,
      ),
    );
    final scroll = t.state<ScrollableState>(find.byType(Scrollable));
    expect(scroll.position.pixels, 0);
    expect(find.semantics.byLabel('Left'), findsOne);
    expect(find.semantics.byLabel('Right'), findsNothing);
    await t.tap(find.bySemanticsLabel('Left'));
    await t.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(0));
    expect(find.semantics.byLabel('Right'), findsOne);
    await t.tap(find.bySemanticsLabel('Right'));
    await t.pumpAndSettle();
    expect(scroll.position.pixels, 0);
    expect(t.widget<Semantics>(tab('Long tab 0')).properties.selected, true);
    semantics.dispose();
  });

  const capture = String.fromEnvironment('STEY_TABS_CAPTURE_DIR');
  if (capture.isNotEmpty) {
    testWidgets('capture controlled tab indicator transition phases', (
      t,
    ) async {
      final out = Directory(capture)..createSync(recursive: true);
      await t.runAsync(() async {
        final loader = FontLoader('packages/stey_ui_modern/Inter');
        for (final name in ['Regular', 'Medium']) {
          loader.addFont(
            Future.value(
              ByteData.sublistView(
                File('packages/stey_ui_modern/assets/fonts/Inter-$name.ttf')
                    .readAsBytesSync(),
              ),
            ),
          );
        }
        await loader.load();
      });
      final rows = <Map<String, Object?>>[];
      for (final mode in ['light', 'dark']) {
        for (final direction in ['ltr', 'rtl']) {
          for (final variant in SteyTabsVariant.values) {
            await t.pumpWidget(const SizedBox.shrink());
            final boundary = GlobalKey(),
                brightness = mode == 'dark'
                    ? Brightness.dark
                    : Brightness.light;
            Widget sample(String value) => MaterialApp(
              theme: SteyTheme.material(brightness),
              home: Scaffold(
                body: Center(
                  child: Directionality(
                    textDirection: direction == 'rtl'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: RepaintBoundary(
                      key: boundary,
                      child: ColoredBox(
                        color: SteyColors(brightness).base,
                        child: SizedBox(
                          width: 340,
                          height:
                              (variant == SteyTabsVariant.segmented ? 36 : 30) +
                              20,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: SteyTabs(
                              tabs: const [
                                SteyTab('overview', 'Overview'),
                                SteyTab('analytics', 'Analytics'),
                                SteyTab('settings', 'Settings'),
                              ],
                              value: value,
                              variant: variant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await t.pumpWidget(sample('overview'));
            await t.pumpAndSettle();
            await t.pumpWidget(sample('settings'));
            var previous = 0;
            for (final ms in [0, 50, 100, 150, 200]) {
              await t.pump(Duration(milliseconds: ms - previous));
              previous = ms;
              final frame = t.getRect(find.byType(SteyTabs)),
                  r = indicator(t),
                  file = '$mode-$direction-${variant.name}-$ms.png';
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
                'variant': variant.name,
                'ms': ms,
                'file': file,
                'rect': {
                  'x': r.left - frame.left,
                  'y': r.top - frame.top,
                  'width': r.width,
                  'height': r.height,
                },
              });
            }
          }
        }
      }
      File('${out.path}/frames.json').writeAsStringSync(jsonEncode(rows));
    });
  }
}

