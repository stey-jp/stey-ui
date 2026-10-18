import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  double width = 320,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
  bool reduce = false,
}) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: SteyTheme(
    brightness: Brightness.light,
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduce,
            ),
            child: Directionality(textDirection: direction, child: child),
          ),
        ),
      ),
    ),
  ),
);

Widget parts({
  Widget? trigger,
  Widget? content,
  bool keep = false,
  bool bare = false,
}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Align(
      alignment: AlignmentDirectional.centerStart,
      child:
          trigger ??
          const SteyCollapsibleDefaultTrigger(child: Text('Details')),
    ),
    if (bare)
      SteyCollapsiblePanel(
        keepMounted: keep,
        child: content ?? const Text('Content'),
      )
    else
      SteyCollapsibleDefaultPanel(
        keepMounted: keep,
        child: content ?? const SizedBox(key: Key('content'), height: 80),
      ),
  ],
);

void main() {
  testWidgets(
    'lazy panel identifier exists on the opening zero-opacity frame',
    (t) async {
      await t.pumpWidget(
        host(
          SteyCollapsibleRoot(panelIdentifier: 'zero-frame', child: parts()),
        ),
      );
      await t.tap(find.text('Details'));
      await t.pump();
      final panel = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.identifier == 'zero-frame',
      );
      expect(t.getSemantics(panel).getSemanticsData().identifier, 'zero-frame');
      await t.pump(const Duration(milliseconds: 1));
      expect(
        t.getSemantics(find.text('Details')).getSemanticsData().controlsNodes,
        {'zero-frame'},
      );
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'uncontrolled default is lazy and reports cancellable trigger reason',
    (t) async {
      final changes = <bool>[];
      SteyCollapsibleChangeDetails? details;
      await t.pumpWidget(
        host(
          SteyCollapsibleRoot(
            onOpenChange: (v, d) {
              changes.add(v);
              details = d;
            },
            child: parts(),
          ),
        ),
      );
      expect(find.byKey(const Key('content')), findsNothing);
      await t.tap(find.text('Details'));
      await t.pumpAndSettle();
      expect(changes, [true]);
      expect(details!.reason, SteyCollapsibleChangeReason.triggerPress);
      expect(find.byKey(const Key('content')), findsOneWidget);
      await t.tap(find.text('Details'));
      await t.pump();
      expect(find.byKey(const Key('content')), findsOneWidget);
      await t.pump(const Duration(milliseconds: 101));
      expect(find.byKey(const Key('content')), findsNothing);
      expect(changes, [true, false]);
    },
  );
  testWidgets(
    'controlled state waits for owner and external changes emit no event',
    (t) async {
      var open = false;
      var calls = 0;
      late StateSetter change;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) {
              change = set;
              return SteyCollapsibleRoot(
                open: open,
                onOpenChange: (_, _) => calls++,
                child: parts(),
              );
            },
          ),
        ),
      );
      await t.tap(find.text('Details'));
      await t.pumpAndSettle();
      expect(calls, 1);
      expect(find.byKey(const Key('content')), findsNothing);
      change(() => open = true);
      await t.pumpAndSettle();
      expect(calls, 1);
      expect(find.byKey(const Key('content')), findsOneWidget);
    },
  );
  testWidgets(
    'cancel keeps uncontrolled value and shared triggers synchronized',
    (t) async {
      var cancel = true;
      await t.pumpWidget(
        host(
          SteyCollapsibleRoot(
            onOpenChange: (_, d) {
              if (cancel) d.cancel();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                parts(),
                const SteyCollapsibleTrigger(child: Text('Other')),
              ],
            ),
          ),
        ),
      );
      await t.tap(find.text('Details'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('content')), findsNothing);
      cancel = false;
      await t.tap(find.text('Other'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('content')), findsOneWidget);
      expect(
        t.getSemantics(find.text('Details')).flagsCollection.isExpanded,
        Tristate.isTrue,
      );
      expect(
        t.getSemantics(find.text('Other')).flagsCollection.isExpanded,
        Tristate.isTrue,
      );
    },
  );
  testWidgets('Root disabled inherits but explicit false can override', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        SteyCollapsibleRoot(
          disabled: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              parts(),
              const SteyCollapsibleTrigger(
                disabled: false,
                child: Text('Override'),
              ),
            ],
          ),
        ),
      ),
    );
    await t.tap(find.text('Details'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('content')), findsNothing);
    await t.tap(find.text('Override'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('content')), findsOneWidget);
  });
  testWidgets(
    'native Enter keydown repeats and Space activates only on keyup',
    (t) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var calls = 0;
      await t.pumpWidget(
        host(
          SteyCollapsibleRoot(
            onOpenChange: (_, _) => calls++,
            child: parts(
              trigger: SteyCollapsibleDefaultTrigger(
                focusNode: focus,
                child: const Text('Details'),
              ),
            ),
          ),
        ),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(focus.hasFocus, true);
      await t.sendKeyDownEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(calls, 0);
      await t.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      expect(calls, 0);
      await t.sendKeyUpEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      expect(calls, 1);
      await t.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(calls, 2);
      await t.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(calls, 3);
      await t.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(calls, 3);
    },
  );
  testWidgets(
    'Space is disarmed on focus loss and disabled controls do not activate',
    (t) async {
      final a = FocusNode(), b = FocusNode();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      var disabled = false;
      var calls = 0;
      late StateSetter change;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) {
              change = set;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SteyCollapsibleRoot(
                    disabled: disabled,
                    onOpenChange: (_, _) => calls++,
                    child: parts(
                      trigger: SteyCollapsibleDefaultTrigger(
                        focusNode: a,
                        child: const Text('Details'),
                      ),
                    ),
                  ),
                  TextButton(
                    focusNode: b,
                    onPressed: () {},
                    child: const Text('After'),
                  ),
                ],
              );
            },
          ),
        ),
      );
      a.requestFocus();
      await t.pump();
      await t.sendKeyDownEvent(LogicalKeyboardKey.space);
      b.requestFocus();
      await t.pump();
      a.requestFocus();
      await t.pump();
      await t.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(calls, 0);
      await t.sendKeyDownEvent(LogicalKeyboardKey.space);
      change(() => disabled = true);
      await t.pump();
      await t.sendKeyUpEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      expect(calls, 0);
    },
  );
  testWidgets('custom builder supplies a single native button activation', (
    t,
  ) async {
    var calls = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await t.pumpWidget(
      host(
        SteyCollapsibleRoot(
          onOpenChange: (_, _) => calls++,
          child: parts(
            trigger: SteyCollapsibleTrigger(
              focusNode: focus,
              builder: (context, data) => SteyButton(
                focusNode: data.focusNode,
                onPressed: data.onPressed,
                child: Text(data.open ? 'Close' : 'Details'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(focus.hasFocus, true);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(calls, 1);
    await t.sendKeyDownEvent(LogicalKeyboardKey.space);
    await t.pump();
    expect(calls, 1);
    await t.sendKeyUpEvent(LogicalKeyboardKey.space);
    await t.pumpAndSettle();
    expect(calls, 2);
  });
  testWidgets(
    'keepMounted retains input state and hides closed focus/semantics',
    (t) async {
      await t.pumpWidget(
        host(
          SteyCollapsibleRoot(
            defaultOpen: true,
            child: parts(keep: true, content: const TextField()),
          ),
        ),
      );
      await t.enterText(find.byType(TextField), 'Retained');
      await t.tap(find.text('Details'));
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextField, skipOffstage: false), findsOneWidget);
      await t.tap(find.text('Details'));
      await t.pumpAndSettle();
      expect(find.text('Retained'), findsOneWidget);
    },
  );
  testWidgets(
    'lazy unmount resets internal input state after close completes',
    (t) async {
      await t.pumpWidget(
        host(
          SteyCollapsibleRoot(
            defaultOpen: true,
            child: parts(content: const TextField()),
          ),
        ),
      );
      await t.enterText(find.byType(TextField), 'Gone');
      await t.tap(find.text('Details'));
      await t.pump();
      expect(find.byType(TextField), findsOneWidget);
      await t.pump(const Duration(milliseconds: 101));
      expect(find.byType(TextField, skipOffstage: false), findsNothing);
      await t.tap(find.text('Details'));
      await t.pumpAndSettle();
      expect(find.text('Gone'), findsNothing);
    },
  );
  testWidgets(
    '100ms height/fade use ease-out both ways and ignore motion reduction',
    (t) async {
      await t.pumpWidget(
        host(SteyCollapsibleRoot(child: parts()), reduce: true),
      );
      await t.tap(find.text('Details'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      final ease = const Cubic(0, 0, .2, 1).transform(.5);
      final opacity = find.descendant(
        of: find.byType(SteyCollapsibleDefaultPanel),
        matching: find.byType(Opacity),
      );
      expect(t.widget<Opacity>(opacity).opacity, closeTo(ease, .001));
      expect(
        t.getSize(find.byType(SteyCollapsibleDefaultPanel)).height,
        closeTo(104 * ease, .1),
      );
      expect(t.getSize(find.byKey(const Key('content'))), const Size(298, 80));
      await t.pump(const Duration(milliseconds: 50));
      expect(t.getSize(find.byType(SteyCollapsibleDefaultPanel)).height, 104);
      await t.tap(find.text('Details'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      expect(t.widget<Opacity>(opacity).opacity, closeTo(1 - ease, .001));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('content')), findsNothing);
    },
  );
  testWidgets(
    'initial open has no intro and reversal keeps the same child state',
    (t) async {
      await t.pumpWidget(
        host(
          SteyCollapsibleRoot(
            defaultOpen: true,
            child: parts(content: const TextField()),
          ),
        ),
      );
      expect(
        t
            .widget<Opacity>(
              find.descendant(
                of: find.byType(SteyCollapsibleDefaultPanel),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        1,
      );
      await t.enterText(find.byType(TextField), 'Still here');
      await t.tap(find.text('Details'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 40));
      await t.tap(find.text('Details'));
      await t.pumpAndSettle();
      expect(find.text('Still here'), findsOneWidget);
    },
  );
  testWidgets(
    'closing freezes measured height while content remains naturally sized',
    (t) async {
      var open = true;
      var height = 80.0;
      late StateSetter change;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) {
              change = set;
              return SteyCollapsibleRoot(
                open: open,
                child: parts(
                  content: SizedBox(key: const Key('body'), height: height),
                ),
              );
            },
          ),
        ),
      );
      change(() => open = false);
      await t.pump();
      await t.pump(const Duration(milliseconds: 30));
      final before = t.getSize(find.byType(SteyCollapsibleDefaultPanel)).height;
      change(() => height = 200);
      await t.pump();
      expect(
        t.getSize(find.byType(SteyCollapsibleDefaultPanel)).height,
        before,
      );
      expect(t.getSize(find.byKey(const Key('body'))), const Size(298, 200));
      await t.pumpAndSettle();
      change(() => open = true);
      await t.pumpAndSettle();
      expect(t.getSize(find.byType(SteyCollapsibleDefaultPanel)).height, 224);
    },
  );
  testWidgets('bare Panel closes immediately without default styling', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        SteyCollapsibleRoot(
          defaultOpen: true,
          child: parts(bare: true, content: const SizedBox(height: 80)),
        ),
      ),
    );
    expect(t.getSize(find.byType(SteyCollapsiblePanel)).height, 80);
    await t.tap(find.text('Details'));
    await t.pump();
    expect(t.getSize(find.byType(SteyCollapsiblePanel)).height, 0);
    expect(t.takeException(), isNull);
  });
  testWidgets('programmatic close restores focus and removes inner traversal', (
    t,
  ) async {
    final trigger = FocusNode(), input = FocusNode();
    addTearDown(trigger.dispose);
    addTearDown(input.dispose);
    var open = true;
    late StateSetter change;
    await t.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, set) {
            change = set;
            return SteyCollapsibleRoot(
              open: open,
              child: parts(
                keep: true,
                trigger: SteyCollapsibleDefaultTrigger(
                  focusNode: trigger,
                  child: const Text('Details'),
                ),
                content: TextField(focusNode: input),
              ),
            );
          },
        ),
      ),
    );
    input.requestFocus();
    await t.pump();
    expect(input.hasFocus, true);
    change(() => open = false);
    await t.pumpAndSettle();
    expect(trigger.hasFocus, true);
    expect(input.hasFocus, false);
  });
  testWidgets(
    'panel relation is present only when open, nested roots are independent',
    (t) async {
      await t.pumpWidget(
        host(
          SteyCollapsibleRoot(
            panelIdentifier: 'outer',
            defaultOpen: true,
            child: parts(
              content: SteyCollapsibleRoot(
                panelIdentifier: 'inner',
                child: parts(
                  trigger: const SteyCollapsibleTrigger(child: Text('Inner')),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      final outer = t.getSemantics(find.text('Details')).getSemanticsData();
      expect(outer.controlsNodes, {'outer'});
      expect(
        t.getSemantics(find.text('Inner')).getSemanticsData().controlsNodes,
        isNull,
      );
      await t.tap(find.text('Inner'));
      await t.pumpAndSettle();
      expect(
        t.getSemantics(find.text('Inner')).getSemanticsData().controlsNodes,
        {'inner'},
      );
      await t.tap(find.text('Details'));
      await t.pumpAndSettle();
      expect(
        t.getSemantics(find.text('Details')).getSemanticsData().controlsNodes,
        isNull,
      );
    },
  );
  testWidgets(
    'default typography, physical left border, child gap and long RTL at 2x',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyCollapsibleRoot(
            defaultOpen: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SteyCollapsibleDefaultTrigger(child: Text('Details')),
                SteyCollapsibleDefaultPanel(
                  children: [
                    SizedBox(key: Key('a'), height: 20),
                    SizedBox(key: Key('b'), height: 30),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      final style = t
          .renderObject<RenderParagraph>(find.text('Details'))
          .text
          .style!;
      expect(style.fontSize, 14);
      expect(style.height, 1.5);
      expect(style.fontWeight, FontWeight.w500);
      expect(
        t.getTopLeft(find.byKey(const Key('b'))).dy -
            t.getBottomLeft(find.byKey(const Key('a'))).dy,
        16,
      );
      expect(
        t.getTopLeft(find.byKey(const Key('a'))).dx -
            t.getTopLeft(find.byType(SteyCollapsibleDefaultPanel)).dx,
        18,
      );
      await t.pumpWidget(
        host(
          SteyCollapsibleRoot(
            defaultOpen: true,
            child: parts(
              trigger: const SteyCollapsibleDefaultTrigger(
                child: Text('詳しい設定を表示してプロジェクトのアクセス権限を確認します'),
              ),
            ),
          ),
          direction: TextDirection.rtl,
          scale: 2,
        ),
      );
      final border =
          t
                  .widgetList<DecoratedBox>(
                    find.descendant(
                      of: find.byType(SteyCollapsibleDefaultPanel),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .first
                  .decoration
              as BoxDecoration;
      expect((border.border! as Border).left.width, 2);
      expect((border.border! as Border).right.width, 0);
      expect(t.takeException(), isNull);
    },
  );
}
