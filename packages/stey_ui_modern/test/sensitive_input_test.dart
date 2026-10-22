import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child, {double width = 320, bool rtl = false}) =>
    MaterialApp(
      theme: SteyTheme.material(Brightness.light),
      home: Scaffold(
        body: Center(
          child: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 32,
                children: [
                  child,
                  TextButton(onPressed: () {}, child: const Text('After')),
                ],
              ),
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
Future<void> reveal(WidgetTester t) async {
  await t.tap(find.bySemanticsLabel('Sensitive value, masked.'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'nonempty secrets use eight constant bullets and exclude editable semantics',
    (t) async {
      final semantics = t.ensureSemantics();
      await ready(
        t,
        host(const SteySensitiveInput(defaultValue: 'private_value')),
      );
      expect(find.text('••••••••'), findsOneWidget);
      expect(find.semantics.byFlag(SemanticsFlag.isTextField), findsNothing);
      expect(
        find.semantics.byLabel('Sensitive value, masked.'),
        findsOneWidget,
      );
      expect(find.semantics.byLabel(RegExp('private_value')), findsNothing);
      expect(field(t).readOnly, true);
      expect(field(t).focusNode!.skipTraversal, true);
      semantics.dispose();
    },
  );
  testWidgets('four sizes keep exact height and inherited text metrics', (
    t,
  ) async {
    for (final size in SteySize.values) {
      await ready(
        t,
        host(SteySensitiveInput(size: size, defaultValue: 'secret')),
      );
      expect(t.getSize(find.byType(TextField)).height, size.height);
      expect(field(t).style!.fontSize, size.fontSize);
      expect(t.takeException(), isNull);
    }
  });
  testWidgets(
    'click reveal and Escape preserve controller selection and focus recovery',
    (t) async {
      final controller = TextEditingController(text: 'secret123');
      await ready(t, host(SteySensitiveInput(controller: controller)));
      controller.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 5,
      );
      await reveal(t);
      expect(field(t).obscureText, false);
      expect(field(t).focusNode!.hasFocus, true);
      expect(
        controller.selection,
        const TextSelection(baseOffset: 2, extentOffset: 5),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(field(t).obscureText, true);
      expect(controller.text, 'secret123');
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(field(t).obscureText, false);
      expect(field(t).focusNode!.hasFocus, true);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      expect(field(t).obscureText, false);
      await t.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
  testWidgets('label focuses masked editor without revealing it', (t) async {
    await ready(
      t,
      host(const SteySensitiveInput(label: 'Token', defaultValue: 'secret')),
    );
    await t.tap(find.text('Token'));
    await t.pumpAndSettle();
    expect(field(t).focusNode!.hasFocus, true);
    expect(field(t).obscureText, true);
    expect(find.text('Click to reveal'), findsOneWidget);
  });
  testWidgets('read only reveal does not focus the editor or permit changes', (
    t,
  ) async {
    await ready(
      t,
      host(const SteySensitiveInput(defaultValue: 'secret', readOnly: true)),
    );
    await reveal(t);
    expect(field(t).readOnly, true);
    expect(field(t).focusNode!.hasFocus, false);
    expect(field(t).controller!.text, 'secret');
  });
  testWidgets(
    'empty starts as password, typing reveals and clear retains revealed mode',
    (t) async {
      var calls = 0;
      await ready(t, host(SteySensitiveInput(onValueChange: (_) => calls++)));
      expect(field(t).obscureText, true);
      expect(field(t).readOnly, false);
      await t.enterText(find.byType(TextField), 'typed');
      await t.pumpAndSettle();
      expect(field(t).obscureText, false);
      expect(calls, 1);
      await t.enterText(find.byType(TextField), '');
      await t.pumpAndSettle();
      expect(field(t).obscureText, false);
      expect(calls, 2);
    },
  );
  testWidgets(
    'read-only reveal survives delayed blur from a previously focused masked editor',
    (t) async {
      await ready(
        t,
        host(const SteySensitiveInput(defaultValue: 'secret', readOnly: true)),
      );
      field(t).focusNode!.requestFocus();
      await t.pumpAndSettle();
      await reveal(t);
      expect(field(t).obscureText, false);
        field(t).focusNode!.requestFocus();
        await t.pumpAndSettle();
        field(t).focusNode!.unfocus();
        await t.pumpAndSettle();
        expect(field(t).obscureText, false);
      await t.tap(find.byType(TextField));
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.keyX);
      await t.pump();
      expect(field(t).controller!.text, 'secret');
      expect(field(t).readOnly, true);
    },
  );
  testWidgets('blur of the active editor masks again and preserves value', (
    t,
  ) async {
    await ready(t, host(const SteySensitiveInput(defaultValue: 'secret')));
    await reveal(t);
    await t.tap(find.text('After'));
    field(t).focusNode!.unfocus();
    await t.pumpAndSettle();
    expect(field(t).obscureText, true);
    expect(field(t).controller!.text, 'secret');
  });
  testWidgets(
    'empty external updates expose the eye without silently masking',
    (t) async {
      final c = TextEditingController(text: 'secret');
      await ready(t, host(SteySensitiveInput(controller: c)));
      c.text = '';
      await t.pumpAndSettle();
      expect(field(t).readOnly, false);
      c.text = 'new';
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('Reveal value'));
      await t.pumpAndSettle();
      expect(field(t).obscureText, false);
      expect(c.text, 'new');
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );
  testWidgets(
    'controlled frozen edits restore once and report attempted value',
    (t) async {
      var calls = 0;
      await ready(
        t,
        host(SteySensitiveInput(value: 'fixed', onValueChange: (_) => calls++)),
      );
      await reveal(t);
      await t.enterText(find.byType(TextField), 'attempt');
      await t.pumpAndSettle();
      expect(field(t).controller!.text, 'fixed');
      expect(calls, 1);
    },
  );
  testWidgets('uncontrolled default is initial only across size updates', (
    t,
  ) async {
    await ready(t, host(const SteySensitiveInput(defaultValue: 'first')));
    await reveal(t);
    await t.enterText(find.byType(TextField), 'kept');
    await t.pump();
    await ready(
      t,
      host(const SteySensitiveInput(defaultValue: 'other', size: SteySize.lg)),
    );
    expect(field(t).controller!.text, 'kept');
  });
  testWidgets(
    'controller and focus ownership can change without disposing caller objects',
    (t) async {
      final a = TextEditingController(text: 'first'),
          b = TextEditingController(text: 'next'),
          f = FocusNode();
      await ready(t, host(SteySensitiveInput(controller: a, focusNode: f)));
      await ready(t, host(SteySensitiveInput(controller: b, focusNode: f)));
      await ready(t, host(SteySensitiveInput(focusNode: f)));
      expect(field(t).controller!.text, 'next');
      await t.pumpWidget(const SizedBox.shrink());
      a.text = 'alive';
      b.text = 'alive';
      f.requestFocus();
      a.dispose();
      b.dispose();
      f.dispose();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'copy tab accepts pointer hits above the field, copies while masked and resets after two seconds',
    (t) async {
      final copied = <String>[];
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied.add((call.arguments as Map)['text'] as String);
            }
            return null;
          });
      await ready(
        t,
        host(
          SteySensitiveInput(defaultValue: 'copy_me', onCopy: () => calls++),
        ),
      );
      final copy = find.bySemanticsLabel('Copy');
      expect(
        t.getRect(copy).bottom,
        lessThan(t.getRect(find.byType(TextField)).top),
      );
      await t.tap(copy);
      await t.pump();
      expect(copied, ['copy_me']);
      expect(calls, 1);
      expect(field(t).obscureText, true);
      expect(find.bySemanticsLabel('Copied'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 1999));
      expect(find.bySemanticsLabel('Copied'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 2));
      expect(find.bySemanticsLabel('Copy'), findsOneWidget);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    },
  );
  testWidgets(
    'copy focus retains revealed mode, including subsequent leave as upstream input-only blur',
    (t) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
      await ready(t, host(const SteySensitiveInput(defaultValue: 'secret')));
      await reveal(t);
      await t.tap(find.bySemanticsLabel('Copy'));
      await t.pumpAndSettle();
      expect(field(t).obscureText, false);
      await t.tap(find.text('After'));
      await t.pumpAndSettle();
      expect(field(t).obscureText, false);
      await t.pumpWidget(const SizedBox.shrink());
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    },
  );
  testWidgets('copy failure never reports success', (t) async {
    var success = 0, errors = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'denied');
          }
          return null;
        });
    await ready(
      t,
      host(
        SteySensitiveInput(
          defaultValue: 'secret',
          onCopy: () => success++,
          onCopyError: (_) => errors++,
        ),
      ),
    );
    await t.tap(find.bySemanticsLabel('Copy'));
    await t.pumpAndSettle();
    expect(success, 0);
    expect(errors, 1);
    expect(find.bySemanticsLabel('Copied'), findsNothing);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  testWidgets(
    'late clipboard attempts cannot replace the latest feedback or notify after disposal',
    (t) async {
      final pending = <Completer<Object?>>[];
      var copies = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) {
            if (call.method != 'Clipboard.setData') return Future.value(null);
            final c = Completer<Object?>();
            pending.add(c);
            return c.future;
          });
      await ready(
        t,
        host(
          SteySensitiveInput(defaultValue: 'secret', onCopy: () => copies++),
        ),
      );
      await t.tap(find.bySemanticsLabel('Copy'));
      await t.pump();
      await t.tap(find.bySemanticsLabel('Copy'));
      await t.pump();
      pending.last.complete(null);
      await t.pump();
      expect(copies, 1);
      pending.first.complete(null);
      await t.pump();
      expect(copies, 1);
      await t.tap(find.bySemanticsLabel('Copied'));
      await t.pump();
      await t.pumpWidget(const SizedBox.shrink());
      pending.last.complete(null);
      await t.pump();
      expect(copies, 1);
      expect(t.takeException(), isNull);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    },
  );
  testWidgets('keyboard activates copy and hide actions independently', (
    t,
  ) async {
    var copies = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    await ready(
      t,
      host(SteySensitiveInput(defaultValue: 'secret', onCopy: () => copies++)),
    );
    await reveal(t);
    await t.tap(find.bySemanticsLabel('Copy'));
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pump();
    expect(copies, 2);
    await t.tap(find.bySemanticsLabel('Hide value'));
    await t.pumpAndSettle();
    expect(field(t).obscureText, true);
    await t.pumpWidget(const SizedBox.shrink());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  testWidgets('disabled prevents reveal and removes copy controls', (t) async {
    await ready(
      t,
      host(const SteySensitiveInput(defaultValue: 'secret', enabled: false)),
    );
    expect(field(t).enabled, false);
    expect(find.bySemanticsLabel('Copy'), findsNothing);
    await t.tap(
      find.bySemanticsLabel('Sensitive value, masked.'),
      warnIfMissed: false,
    );
    await t.pump();
    expect(field(t).obscureText, true);
  });
  testWidgets('helper and error are only wrapped when label is provided', (
    t,
  ) async {
    await ready(
      t,
      host(const SteySensitiveInput(description: 'Help', error: 'Invalid')),
    );
    expect(find.byType(SteyField), findsNothing);
    expect(find.text('Invalid'), findsNothing);
    await ready(
      t,
      host(
        const SteySensitiveInput(
          label: 'Key',
          description: 'Help',
          error: 'Invalid',
          required: false,
        ),
      ),
    );
    expect(find.text('Key (optional)'), findsOneWidget);
    expect(find.text('Invalid'), findsOneWidget);
    expect(find.text('Help'), findsNothing);
  });
  testWidgets(
    'revealed editor keeps explicit name and required/invalid semantic state',
    (t) async {
      final semantics = t.ensureSemantics();
      await ready(
        t,
        host(
          const SteySensitiveInput(
            defaultValue: 'secret',
            semanticLabel: 'Private key',
            error: 'Invalid',
            required: true,
          ),
        ),
      );
      await reveal(t);
      final node = find.semantics
          .byFlag(SemanticsFlag.isTextField)
          .evaluate()
          .single;
      expect(node.label, 'Private key');
      expect(
        node.getSemanticsData().validationResult,
        SemanticsValidationResult.invalid,
      );
      expect(find.semantics.byFlag(SemanticsFlag.isRequired), findsOneWidget);
      semantics.dispose();
    },
  );
  testWidgets('RTL and narrow hosts retain bounded mask and editor layout', (
    t,
  ) async {
    for (final rtl in [false, true]) {
      await t.pumpWidget(const SizedBox.shrink());
      await ready(
        t,
        host(
          const SteySensitiveInput(defaultValue: 'a very long secret'),
          width: 160,
          rtl: rtl,
        ),
      );
      expect(t.getSize(find.byType(TextField)).width, 160);
      await reveal(t);
      expect(t.takeException(), isNull);
    }
  });
}
