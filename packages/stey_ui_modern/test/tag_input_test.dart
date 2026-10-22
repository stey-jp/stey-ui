import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child, {double width = 360}) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);
Finder get editor => find.byType(TextField);
TextEditingController controller(WidgetTester t) =>
    t.widget<TextField>(editor).controller!;
Future<void> key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pump();
}

void main() {
  testWidgets('uncontrolled splits, trims, deduplicates and preserves case', (
    t,
  ) async {
    List<String>? accepted;
    await t.pumpWidget(
      host(
        SteyTagInput(
          defaultValue: const ['one'],
          onValueChange: (v) => accepted = v,
        ),
      ),
    );
    await t.enterText(editor, 'one, two,Two,,  ');
    await key(t, LogicalKeyboardKey.enter);
    expect(accepted, ['one', 'two', 'Two']);
    expect(controller(t).text, '');
    expect(find.text('two'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
  });
  for (final trigger in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.comma,
    LogicalKeyboardKey.tab,
  ]) {
    testWidgets('${trigger.keyLabel} commits and retains focus', (t) async {
      List<String>? next;
      await t.pumpWidget(host(SteyTagInput(onValueChange: (v) => next = v)));
      await t.enterText(editor, 'one');
      await key(t, trigger);
      expect(next, ['one']);
      expect(t.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
    });
  }
  testWidgets('validation sees accepted prefix and retains failing tail', (
    t,
  ) async {
    final seen = <List<String>>[];
    List<String>? next;
    await t.pumpWidget(
      host(
        SteyTagInput(
          defaultValue: const ['first@x'],
          validateValue: (v, accepted) {
            seen.add(accepted);
            return v.contains('@');
          },
          onValueChange: (v) => next = v,
        ),
      ),
    );
    await t.enterText(editor, 'good@x,bad,later@x');
    await key(t, LogicalKeyboardKey.enter);
    expect(next, ['first@x', 'good@x']);
    expect(seen, [
      ['first@x'],
      ['first@x', 'good@x'],
    ]);
    expect(controller(t).text, 'bad, later@x');
    expect(find.text('"bad" is not valid.'), findsOneWidget);
    await t.enterText(editor, 'fixed@x');
    await t.pump();
    expect(find.text('"bad" is not valid.'), findsNothing);
  });
  testWidgets(
    'duplicates are skipped before limit; limit precedes validation',
    (t) async {
      var validations = 0;
      List<String>? next;
      await t.pumpWidget(
        host(
          SteyTagInput(
            defaultValue: const ['one'],
            maxValues: 1,
            validateValue: (v, values) {
              validations++;
              return false;
            },
            onValueChange: (v) => next = v,
          ),
        ),
      );
      await t.enterText(editor, 'one,two,three');
      await key(t, LogicalKeyboardKey.enter);
      expect(next, ['one']);
      expect(validations, 0);
      expect(controller(t).text, 'two, three');
      expect(find.text('Limit of 1 tags reached.'), findsOneWidget);
    },
  );
  testWidgets('controlled rejection clears draft but retains supplied tags', (
    t,
  ) async {
    final calls = <List<String>>[];
    await t.pumpWidget(
      host(SteyTagInput(value: const ['one'], onValueChange: calls.add)),
    );
    await t.enterText(editor, 'two');
    await key(t, LogicalKeyboardKey.enter);
    expect(calls.single, ['one', 'two']);
    expect(controller(t).text, '');
    expect(find.text('two'), findsNothing);
    await key(t, LogicalKeyboardKey.backspace);
    expect(calls.last, []);
    expect(find.text('one'), findsOneWidget);
  });
  testWidgets(
    'empty Backspace removes last tag and empty array still notifies',
    (t) async {
      final calls = <List<String>>[];
      await t.pumpWidget(
        host(
          SteyTagInput(
            defaultValue: const ['one', 'two'],
            onValueChange: calls.add,
          ),
        ),
      );
      await t.tap(editor);
      await key(t, LogicalKeyboardKey.backspace);
      expect(calls.last, ['one']);
      await key(t, LogicalKeyboardKey.backspace);
      await key(t, LogicalKeyboardKey.backspace);
      expect(calls.last, []);
      expect(calls.length, 3);
    },
  );
  testWidgets('active IME conversion does not commit Enter comma or Tab', (
    t,
  ) async {
    final calls = <List<String>>[];
    await t.pumpWidget(host(SteyTagInput(onValueChange: calls.add)));
    await t.tap(editor);
    await t.showKeyboard(editor);
    t.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'にほんご',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange(start: 0, end: 4),
      ),
    );
    await t.pump();
    await key(t, LogicalKeyboardKey.enter);
    await key(t, LogicalKeyboardKey.comma);
    expect(calls, isEmpty);
    expect(controller(t).text, 'にほんご');
    // Verify Tab does not intercept IME confirmation; native traversal is separate.
    final outer = t
        .widgetList<Focus>(find.byType(Focus))
        .firstWhere(
          (w) =>
              w.onKeyEvent != null &&
              w.focusNode?.skipTraversal == true &&
              w.focusNode?.canRequestFocus == false,
        );
    expect(
      outer.onKeyEvent!(
        outer.focusNode!,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.tab,
          logicalKey: LogicalKeyboardKey.tab,
          timeStamp: Duration.zero,
        ),
      ),
      KeyEventResult.ignored,
    );
    controller(t).value = controller(t).value
        .copyWith(composing: TextRange.empty);
    await key(t, LogicalKeyboardKey.enter);
    expect(calls.last, ['にほんご']);
  });
  testWidgets('blur commits, and cancellation suppresses it', (t) async {
    final nextFocus = FocusNode();
    addTearDown(nextFocus.dispose);
    var cancel = false;
    final calls = <List<String>>[];
    await t.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SteyTagInput(onValueChange: calls.add, onBlur: () => !cancel),
            TextButton(
              focusNode: nextFocus,
              onPressed: () {},
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
    await t.enterText(editor, 'one');
    nextFocus.requestFocus();
    await t.pump();
    expect(calls.last, ['one']);
    cancel = true;
    await t.enterText(editor, 'two');
    nextFocus.requestFocus();
    await t.pump();
    expect(calls.length, 1);
    expect(controller(t).text, 'two');
  });
  testWidgets('custom key handler cancels default commit', (t) async {
    final calls = <List<String>>[];
    await t.pumpWidget(
      host(
        SteyTagInput(
          onValueChange: calls.add,
          onKeyEvent: (_) => KeyEventResult.handled,
        ),
      ),
    );
    await t.enterText(editor, 'one');
    await key(t, LogicalKeyboardKey.enter);
    expect(calls, isEmpty);
    expect(controller(t).text, 'one');
  });
  testWidgets('remove deletes all matching values and retains input draft', (
    t,
  ) async {
    List<String>? next;
    await t.pumpWidget(
      host(
        SteyTagInput(
          value: const ['one', 'two'],
          onValueChange: (v) => next = v,
        ),
      ),
    );
    await t.enterText(editor, 'draft');
    await t.tap(
      find.bySemanticsLabel('Remove one'),
      kind: PointerDeviceKind.mouse,
    );
    await t.pump();
    expect(next, ['two']);
    expect(controller(t).text, 'draft');
    expect(t.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
  });
  for (final readOnly in [false, true]) {
    testWidgets(
      readOnly
          ? 'readOnly is focusable and cannot mutate'
          : 'disabled cannot mutate',
      (t) async {
        final calls = <List<String>>[];
        await t.pumpWidget(
          host(
            SteyTagInput(
              defaultValue: const ['one'],
              enabled: readOnly,
              readOnly: readOnly,
              onValueChange: calls.add,
            ),
          ),
        );
        final button = t.widget<SteyButton>(find.byType(SteyButton));
        expect(button.onPressed, isNull);
        await t.tap(editor);
        await key(t, LogicalKeyboardKey.backspace);
        await key(t, LogicalKeyboardKey.enter);
        expect(calls, isEmpty);
        expect(find.text('one'), findsOneWidget);
        if (readOnly) {
          expect(t.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
        }
      },
    );
  }
  testWidgets('translated validation labels and external error precedence', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        SteyTagInput(
          defaultValue: const ['uno'],
          error: 'External',
          validateValue: (v, a) => false,
          labels: SteyTagInputLabels(
            input: 'Etiquetas',
            removeValue: (v) => 'Eliminar $v',
            invalidValue: (v) => '$v no es valido.',
          ),
        ),
      ),
    );
    await t.enterText(editor, 'dos');
    await key(t, LogicalKeyboardKey.enter);
    expect(find.text('External'), findsOneWidget);
    expect(find.text('dos no es valido.'), findsNothing);
    expect(find.bySemanticsLabel('Eliminar uno'), findsOneWidget);
  });
  testWidgets('label focuses editor and description alone creates Field', (
    t,
  ) async {
    await t.pumpWidget(
      host(const SteyTagInput(label: 'People', description: 'Help')),
    );
    await t.tap(find.text('People'));
    await t.pump();
    expect(t.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
    await t.pumpWidget(host(const SteyTagInput(description: 'Help')));
    expect(find.text('Help'), findsOneWidget);
  });
  testWidgets('long chips wrap without overflow in RTL and narrow host', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: SteyTagInput(
            defaultValue: [
              'one',
              'an-extremely-long-tag-that-must-truncate',
              'three',
            ],
          ),
        ),
        width: 160,
      ),
    );
    expect(t.takeException(), isNull);
    final sizes = t.getSize(find.byType(SteyTagInput));
    expect(sizes.width, 160);
    expect(sizes.height, greaterThan(60));
  });
  testWidgets(
    'replacing external focus keeps draft and disposes only owned nodes',
    (t) async {
      final a = FocusNode(), b = FocusNode();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      await t.pumpWidget(host(SteyTagInput(focusNode: a)));
      await t.enterText(editor, 'draft');
      await t.pumpWidget(host(SteyTagInput(focusNode: b)));
      expect(controller(t).text, 'draft');
      await t.pumpWidget(const SizedBox());
      expect(() => a.requestFocus(), returnsNormally);
      expect(() => b.requestFocus(), returnsNormally);
    },
  );
  for (final sample in [
    ('alice', 5, 5, ', bob', ['alice', 'bob']),
    ('alXXce', 2, 4, 'i, bob, al', ['ali', 'bob', 'alce']),
    ('', 0, 0, ' one\n two,one ', ['one', 'two']),
  ]) {
    testWidgets('native clipboard merges draft at selection ${sample.$1}', (
      t,
    ) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async =>
                call.method == 'Clipboard.getData' ? {'text': sample.$4} : null,
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      List<String>? next;
      await t.pumpWidget(host(SteyTagInput(onValueChange: (v) => next = v)));
      await t.enterText(editor, sample.$1);
      controller(t).selection = TextSelection(
        baseOffset: sample.$2,
        extentOffset: sample.$3,
      );
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyV);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pump();
      expect(next, sample.$5);
      expect(controller(t).text, '');
    });
  }
  testWidgets('plain clipboard text stays draft; paste can be cancelled', (
    t,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async =>
              call.method == 'Clipboard.getData' ? {'text': 'ce'} : null,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    var cancel = false;
    final calls = <List<String>>[];
    await t.pumpWidget(
      host(SteyTagInput(onValueChange: calls.add, onPaste: (_) => !cancel)),
    );
    await t.enterText(editor, 'ali');
    Actions.invoke(
      t.element(find.byType(EditableText)),
      const PasteTextIntent(SelectionChangedCause.keyboard),
    );
    await t.pump();
    expect(controller(t).text, 'alice');
    expect(calls, isEmpty);
    cancel = true;
    Actions.invoke(
      t.element(find.byType(EditableText)),
      const PasteTextIntent(SelectionChangedCause.keyboard),
    );
    await t.pump();
    expect(controller(t).text, 'alice');
  });
  testWidgets('editor accessible name excludes neighboring tag text', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      host(
        const SteyTagInput(defaultValue: ['one', 'two'], semanticLabel: 'Tags'),
      ),
    );
    expect(t.getSemantics(editor).getSemanticsData().label, 'Tags');
    expect(find.bySemanticsLabel('Remove one'), findsOneWidget);
    semantics.dispose();
  });
  testWidgets('empty Enter and software done do not commit tags', (t) async {
    final calls = <List<String>>[];
    await t.pumpWidget(host(SteyTagInput(onValueChange: calls.add)));
    await t.tap(editor);
    await key(t, LogicalKeyboardKey.enter);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(calls, isEmpty);
  });
  testWidgets('initial route focus does not send an empty commit', (t) async {
    final next = FocusNode();
    addTearDown(next.dispose);
    final calls = <List<String>>[];
    await t.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SteyTagInput(onValueChange: calls.add),
            TextButton(
              focusNode: next,
              onPressed: () {},
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
    next.requestFocus();
    await t.pump();
    expect(calls, isEmpty);
    await t.tap(editor);
    next.requestFocus();
    await t.pump();
    expect(calls, [[]]);
  });
  testWidgets('pending clipboard result is ignored after disposal', (t) async {
    final pending = Completer<Map<String, dynamic>>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async =>
              call.method == 'Clipboard.getData' ? pending.future : null,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final calls = <List<String>>[];
    await t.pumpWidget(host(SteyTagInput(onValueChange: calls.add)));
    await t.tap(editor);
    Actions.invoke(
      t.element(find.byType(EditableText)),
      const PasteTextIntent(SelectionChangedCause.keyboard),
    );
    await t.pumpWidget(const SizedBox());
    pending.complete({'text': 'one,two'});
    await t.pump();
    expect(calls, isEmpty);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'latest clipboard attempt wins and edited draft cancels pending paste',
    (t) async {
      final pending = <Completer<Map<String, dynamic>>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method != 'Clipboard.getData') return null;
            final p = Completer<Map<String, dynamic>>();
            pending.add(p);
            return p.future;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final calls = <List<String>>[];
      await t.pumpWidget(host(SteyTagInput(onValueChange: calls.add)));
      await t.tap(editor);
      void paste() => Actions.invoke(
        t.element(find.byType(EditableText)),
        const PasteTextIntent(SelectionChangedCause.keyboard),
      );
      paste();
      paste();
      await t.pump();
      pending[1].complete({'text': 'two,three'});
      await t.pump();
      pending[0].complete({'text': 'old,discarded'});
      await t.pump();
      expect(calls, [
        ['two', 'three'],
      ]);
      paste();
      await t.pump();
      await t.enterText(editor, 'new draft');
      pending[2].complete({'text': 'old,discarded'});
      await t.pump();
      expect(controller(t).text, 'new draft');
      expect(calls.length, 1);
    },
  );
}
