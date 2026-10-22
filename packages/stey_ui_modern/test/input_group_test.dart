import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  double width = 600,
  bool rtl = false,
  double scale = 1,
}) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(
    body: Center(
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);
Future<void> ready(WidgetTester t, Widget child) async {
  await t.pumpWidget(child);
  await t.pumpAndSettle();
}

TextField field(WidgetTester t) => t.widget<TextField>(find.byType(TextField));
SteyInputGroupButton action(VoidCallback onPressed) => SteyInputGroupButton(
  variant: SteyButtonVariant.secondary,
  onPressed: onPressed,
  child: const Text('Go'),
);

void main() {
  test('focus mode inspects direct buttons and addons only', () {
    const edit = SteyInputGroupInput();
    expect(
      SteyInputGroup.detectFocusMode([edit]),
      SteyInputGroupFocusMode.container,
    );
    expect(
      SteyInputGroup.detectFocusMode([
        edit,
        const SteyInputGroupButton(child: Text('Go')),
      ]),
      SteyInputGroupFocusMode.container,
    );
    expect(
      SteyInputGroup.detectFocusMode([edit, action(() {})]),
      SteyInputGroupFocusMode.individual,
    );
    expect(
      SteyInputGroup.detectFocusMode([
        const SteyInputGroupAddon(child: Text('+')),
        edit,
        action(() {}),
      ]),
      SteyInputGroupFocusMode.hybrid,
    );
    expect(
      SteyInputGroup.detectFocusMode([
        edit,
        SteyInputGroupAddon(child: action(() {})),
      ]),
      SteyInputGroupFocusMode.container,
    );
  });
  testWidgets('all modes inherit the exact four group heights', (t) async {
    for (final size in SteySize.values) {
      for (final mode in SteyInputGroupFocusMode.values) {
        await ready(
          t,
          host(
            SteyInputGroup(
              size: size,
              children: [
                if (mode == SteyInputGroupFocusMode.hybrid)
                  const SteyInputGroupAddon(child: Icon(Icons.add)),
                const SteyInputGroupInput(),
                if (mode != SteyInputGroupFocusMode.container) action(() {}),
              ],
            ),
          ),
        );
        expect(t.getSize(find.byType(SteyInputGroup)).height, size.height);
        expect(
          t.getSize(find.byType(TextField)).height,
          size.height - (mode == SteyInputGroupFocusMode.hybrid ? 2 : 0),
        );
        if (mode != SteyInputGroupFocusMode.container) {
          expect(t.getSize(find.byType(SteyButton)).height, size.height);
        }
        expect(t.takeException(), isNull);
      }
    }
  });
  testWidgets('joined borders overlap by one pixel', (t) async {
    await ready(
      t,
      host(
        SteyInputGroup(
          children: [action(() {}), const SteyInputGroupInput(), action(() {})],
        ),
      ),
    );
    final buttons = find.byType(SteyButton),
        edit = t.getRect(find.byType(TextField));
    expect(t.getRect(buttons.first).right - edit.left, 1);
    expect(edit.right - t.getRect(buttons.last).left, 1);
    final left = t.widget<TextButton>(find.byType(TextButton).first).style!,
        right = t.widget<TextButton>(find.byType(TextButton).last).style!;
    expect(
      (left.shape!.resolve({})! as RoundedRectangleBorder).borderRadius,
      const BorderRadius.horizontal(left: Radius.circular(8)),
    );
    expect(
      (right.shape!.resolve({})! as RoundedRectangleBorder).borderRadius,
      const BorderRadius.horizontal(right: Radius.circular(8)),
    );
    expect(right.padding!.resolve({})!.resolve(TextDirection.ltr).right, 13);
  });
  testWidgets(
    'addon positions and icon sizes follow group size in both directions',
    (t) async {
      for (final size in SteySize.values) {
        for (final rtl in [false, true]) {
          await ready(
            t,
            host(
              SteyInputGroup(
                size: size,
                children: const [
                  SteyInputGroupAddon(
                    align: SteyInputGroupAlign.end,
                    child: Text('GB'),
                  ),
                  SteyInputGroupInput(),
                  SteyInputGroupAddon(child: Icon(Icons.add)),
                ],
              ),
              rtl: rtl,
            ),
          );
          final icon = t.getRect(find.byType(Icon)),
              edit = t.getRect(find.byType(TextField)),
              end = t.getRect(find.text('GB'));
          expect(icon.width, [10, 13, 18, 20][size.index]);
          expect(rtl ? icon.left >= edit.right : icon.right <= edit.left, true);
          expect(rtl ? end.right <= edit.left : end.left >= edit.right, true);
        }
      }
    },
  );
  testWidgets('container and hybrid addon actions use compact buttons', (
    t,
  ) async {
    for (final size in SteySize.values) {
      for (final hybrid in [false, true]) {
        await ready(
          t,
          host(
            SteyInputGroup(
              size: size,
              children: [
                const SteyInputGroupInput(),
                SteyInputGroupAddon(
                  align: SteyInputGroupAlign.end,
                  child: SteyInputGroupButton(
                    onPressed: () {},
                    child: const Text('Clear'),
                  ),
                ),
                if (hybrid) action(() {}),
              ],
            ),
          ),
        );
        final buttons = t
            .widgetList<SteyButton>(find.byType(SteyButton))
            .toList();
        expect(
          buttons.first.size,
          [SteySize.xs, SteySize.xs, SteySize.sm, SteySize.base][size.index],
        );
        if (hybrid) expect(buttons.last.size, size);
      }
    }
  });
  testWidgets('suffix and label clicks focus the input; button clicks do not', (
    t,
  ) async {
    var calls = 0;
    await ready(
      t,
      host(
        SteyInputGroup(
          label: 'Project',
          children: [
            const SteyInputGroupInput(defaultValue: 'worker'),
            const SteyInputGroupSuffix(child: Text('.workers.dev')),
            action(() => calls++),
          ],
        ),
      ),
    );
    await t.tap(find.text('Project'));
    await t.pump();
    expect(field(t).focusNode!.hasFocus, true);
    await t.tap(find.text('Go'));
    await t.pump();
    expect(calls, 1);
    expect(field(t).focusNode!.hasFocus, false);
    // Individual mode has no shared click surface; test the shared mode separately.
    await ready(
      t,
      host(
        const SteyInputGroup(
          children: [
            SteyInputGroupInput(defaultValue: 'worker'),
            SteyInputGroupSuffix(child: Text('.workers.dev')),
          ],
        ),
      ),
    );
    field(t).focusNode!.unfocus();
    await t.pump();
    await t.tapAt(t.getCenter(find.text('.workers.dev')));
    await t.pump();
    expect(field(t).focusNode!.hasFocus, true);
  });
  testWidgets(
    'emphasis fill shares the joined shape and keeps its inset highlight',
    (t) async {
      await ready(
        t,
        host(
          SteyInputGroup(
            children: [
              const SteyInputGroupInput(),
              SteyInputGroupButton(
                variant: SteyButtonVariant.primary,
                onPressed: () {},
                child: const Text('Go'),
              ),
            ],
          ),
        ),
      );
      final clips = t.widgetList<ClipRRect>(
        find.descendant(
          of: find.byType(SteyButton),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(
        clips.any(
          (c) =>
              c.borderRadius ==
              const BorderRadius.horizontal(right: Radius.circular(8)),
        ),
        true,
      );
      expect(
        find.descendant(
          of: find.byType(SteyButton),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    },
  );
  testWidgets('hybrid reorders standalone actions after the shared zone', (
    t,
  ) async {
    await ready(
      t,
      host(
        SteyInputGroup(
          children: [
            action(() {}),
            const SteyInputGroupAddon(child: Icon(Icons.add)),
            const SteyInputGroupInput(),
          ],
        ),
      ),
    );
    expect(
      t.getRect(find.byType(SteyButton)).left,
      greaterThan(t.getRect(find.byType(TextField)).left),
    );
  });
  testWidgets('hovering an action does not focus its input sibling', (t) async {
    await ready(
      t,
      host(
        SteyInputGroup(children: [const SteyInputGroupInput(), action(() {})]),
      ),
    );
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(t.getCenter(find.byType(SteyButton)));
    await t.pump();
    expect(field(t).focusNode!.hasFocus, false);
    await mouse.removePointer();
  });
  testWidgets('disabled group blocks fields, actions and label focus', (
    t,
  ) async {
    var calls = 0;
    await ready(
      t,
      host(
        SteyInputGroup(
          disabled: true,
          label: 'Project',
          children: [const SteyInputGroupInput(), action(() => calls++)],
        ),
      ),
    );
    expect(field(t).enabled, false);
    expect(t.widget<SteyButton>(find.byType(SteyButton)).onPressed, null);
    await t.tap(find.text('Project'));
    await t.pump();
    expect(field(t).focusNode!.hasFocus, false);
    expect(calls, 0);
  });
  testWidgets(
    'group label, required and validation reach one editable semantic node',
    (t) async {
      final semantics = t.ensureSemantics();
      await ready(
        t,
        host(
          const SteyInputGroup(
            label: 'Project',
            error: 'Unavailable',
            required: true,
            children: [SteyInputGroupInput()],
          ),
        ),
      );
      final edit = find.semantics.byFlag(SemanticsFlag.isTextField);
      expect(edit, findsOneWidget);
      final data = edit.evaluate().single.getSemanticsData();
      expect(data.label, 'Project');
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(find.text('Unavailable'), findsOneWidget);
      semantics.dispose();
    },
  );
  testWidgets('helpers require the group label as in upstream', (t) async {
    await ready(
      t,
      host(
        const SteyInputGroup(
          description: 'Helper',
          error: 'Unavailable',
          children: [SteyInputGroupInput()],
        ),
      ),
    );
    expect(find.byType(SteyField), findsNothing);
    expect(find.text('Helper'), findsNothing);
    expect(find.text('Unavailable'), findsNothing);
  });
  testWidgets(
    'suffix width tracks external controller edits and shrinks again',
    (t) async {
      final c = TextEditingController(text: 'a');
      await ready(
        t,
        host(
          SteyInputGroup(
            children: [
              SteyInputGroupInput(controller: c),
              const SteyInputGroupSuffix(child: Text('.dev')),
            ],
          ),
        ),
      );
      final small = t.getSize(find.byType(TextField)).width;
      c.text = 'abcdefgh';
      await t.pumpAndSettle();
      expect(t.getSize(find.byType(TextField)).width, greaterThan(small));
      c.text = 'a';
      await t.pumpAndSettle();
      expect(t.getSize(find.byType(TextField)).width, small);
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );
  testWidgets('mode transitions preserve uncontrolled text and focus', (
    t,
  ) async {
    final focus = FocusNode();
    Widget group(bool hybrid) => host(
      SteyInputGroup(
        children: [
          if (hybrid) const SteyInputGroupAddon(child: Icon(Icons.add)),
          SteyInputGroupInput(focusNode: focus, defaultValue: 'start'),
          if (hybrid) action(() {}),
        ],
      ),
    );
    await ready(t, group(false));
    await t.enterText(find.byType(TextField), 'kept');
    await ready(t, group(true));
    expect(field(t).controller!.text, 'kept');
    expect(focus.hasFocus, true);
    await ready(t, group(false));
    expect(field(t).controller!.text, 'kept');
    expect(focus.hasFocus, true);
    await t.pumpWidget(const SizedBox.shrink());
    focus.dispose();
  });
  testWidgets(
    'frozen controlled edits restore once with no duplicate notifications',
    (t) async {
      var calls = 0;
      await ready(
        t,
        host(
          SteyInputGroup(
            children: [
              SteyInputGroupInput(
                value: 'fixed',
                onValueChange: (_) => calls++,
              ),
              const SteyInputGroupSuffix(child: Text('.dev')),
            ],
          ),
        ),
      );
      await t.enterText(find.byType(TextField), 'rejected');
      await t.pumpAndSettle();
      expect(field(t).controller!.text, 'fixed');
      expect(calls, 1);
    },
  );
  testWidgets(
    'controller and focus ownership survive replacement and disposal',
    (t) async {
      final a = TextEditingController(text: 'a'),
          b = TextEditingController(text: 'b'),
          focus = FocusNode();
      Widget group(TextEditingController? c) => host(
        SteyInputGroup(
          children: [SteyInputGroupInput(controller: c, focusNode: focus)],
        ),
      );
      await ready(t, group(a));
      await ready(t, group(b));
      await ready(t, group(null));
      expect(field(t).controller!.text, 'b');
      await t.pumpWidget(const SizedBox.shrink());
      a.text = 'alive';
      b.text = 'alive';
      focus.requestFocus();
      a.dispose();
      b.dispose();
      focus.dispose();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('read only retains focus and ignores keyboard editing', (
    t,
  ) async {
    await ready(
      t,
      host(
        const SteyInputGroup(
          children: [
            SteyInputGroupInput(readOnly: true, defaultValue: 'fixed'),
          ],
        ),
      ),
    );
    await t.tap(find.byType(TextField));
    await t.sendKeyEvent(LogicalKeyboardKey.keyX);
    await t.pump();
    expect(field(t).focusNode!.hasFocus, true);
    expect(field(t).controller!.text, 'fixed');
  });
  testWidgets('tooltip string names the compact icon action', (t) async {
    await ready(
      t,
      host(
        SteyInputGroup(
          children: [
            const SteyInputGroupInput(),
            SteyInputGroupAddon(
              child: SteyInputGroupButton(
                tooltip: 'Clear',
                onPressed: () {},
                child: const Icon(Icons.clear),
              ),
            ),
          ],
        ),
      ),
    );
    expect(
      t.widget<SteyButton>(find.byType(SteyButton)).semanticLabel,
      'Clear',
    );
    expect(t.widget<Tooltip>(find.byType(Tooltip)).preferBelow, true);
  });
  testWidgets('narrow long suffix and RTL scaled text remain bounded', (
    t,
  ) async {
    for (final rtl in [false, true]) {
      await ready(
        t,
        host(
          const SteyInputGroup(
            children: [
              SteyInputGroupInput(defaultValue: 'a very long worker name'),
              SteyInputGroupSuffix(child: Text('.workers.dev')),
            ],
          ),
          width: 160,
          rtl: rtl,
          scale: 2,
        ),
      );
      final group = t.getRect(find.byType(SteyInputGroup)),
          edit = t.getRect(find.byType(TextField));
      expect(edit.width, lessThanOrEqualTo(group.width));
      expect(t.takeException(), isNull);
    }
  });
  testWidgets('legacy child/addon/suffix spacing stays compatible', (t) async {
    await ready(
      t,
      host(
        const SteyInputGroup(
          addon: Text('https://'),
          suffix: Text('.com'),
          child: SteyInput(),
        ),
      ),
    );
    final edit = t.getRect(find.byType(SteyInput));
    expect(edit.left - t.getRect(find.text('https://')).right, 8);
    expect(t.getRect(find.text('.com')).left - edit.right, 8);
  });
}
