import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  double width = 280,
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

void main() {
  testWidgets(
    'helper without label retains the upstream empty-label grid gap',
    (t) async {
      await ready(t, host(const SteyInput(description: 'Helper')));
      final root = t.getRect(find.byType(SteyInput)),
          input = t.getRect(find.byType(TextField));
      expect(input.top - root.top, 29);
      expect(find.byType(SteyLabel), findsOneWidget);
    },
  );

  testWidgets(
    'all sizes keep exact outer height and compact text line metrics',
    (t) async {
      for (final size in SteySize.values) {
        await ready(
          t,
          host(
            SteyInput(
              size: size,
              semanticLabel: 'Name',
              placeholder: 'Project name',
            ),
          ),
        );
        expect(t.getSize(find.byType(TextField)).height, size.height);
        final editor = t.getRect(find.byType(EditableText)),
            box = t.getRect(find.byType(TextField));
        final line = size.fontSize == 12 ? 16 : 21;
        expect(editor.top - box.top, closeTo((size.height - line) / 2, .1));

        expect(field(t).style!.fontSize, size.fontSize);
        expect(
          field(t).strutStyle!.height,
          size.fontSize == 12 ? 16 / 12 : 1.5,
        );
        expect(t.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'uncontrolled default is initial only and survives parent updates',
    (t) async {
      await ready(t, host(const SteyInput(defaultValue: 'start')));
      await t.enterText(find.byType(TextField), 'edited');
      await ready(
        t,
        host(const SteyInput(defaultValue: 'other', size: SteySize.sm)),
      );
      expect(field(t).controller!.text, 'edited');
    },
  );
  testWidgets(
    'controlled value updates parent and frozen values restore without extra callbacks',
    (t) async {
      var value = 'a', calls = 0;
      await ready(
        t,
        host(
          StatefulBuilder(
            builder: (_, set) => SteyInput(
              value: value,
              onChanged: (v) => set(() {
                value = v;
                calls++;
              }),
            ),
          ),
        ),
      );
      await t.enterText(find.byType(TextField), 'new');
      await t.pump();
      expect(value, 'new');
      expect(field(t).controller!.text, 'new');
      expect(calls, 1);
      await ready(
        t,
        host(SteyInput(value: 'fixed', onChanged: (_) => calls++)),
      );
      await t.enterText(find.byType(TextField), 'ignored');
      await t.pumpAndSettle();
      expect(field(t).controller!.text, 'fixed');
      expect(calls, 2);
    },
  );
  testWidgets(
    'external controlled changes clamp selection and are not input notifications',
    (t) async {
      var calls = 0;
      await ready(
        t,
        host(SteyInput(value: 'long value', onChanged: (_) => calls++)),
      );
      field(t).controller!.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 10,
      );
      await ready(t, host(SteyInput(value: 'x', onChanged: (_) => calls++)));
      expect(field(t).controller!.selection.extentOffset, 1);
      expect(calls, 0);
    },
  );
  testWidgets(
    'controller ownership transitions preserve text and never dispose caller objects',
    (t) async {
      final a = TextEditingController(text: 'external'),
          b = TextEditingController(text: 'second');
      await ready(t, host(const SteyInput(defaultValue: 'internal')));
      await ready(t, host(SteyInput(controller: a)));
      expect(field(t).controller, a);
      await ready(t, host(SteyInput(controller: b)));
      a.text = 'alive';
      await ready(t, host(const SteyInput()));
      expect(field(t).controller!.text, 'second');
      await t.pumpWidget(const SizedBox.shrink());
      b.text = 'alive';
      a.dispose();
      b.dispose();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'external focus changes replace listeners and owned focus is disposed safely',
    (t) async {
      final a = FocusNode(), b = FocusNode();
      await ready(t, host(SteyInput(label: 'Name', focusNode: a)));
      await t.tap(find.text('Name'));
      await t.pump();
      expect(a.hasFocus, true);
      await ready(t, host(SteyInput(label: 'Name', focusNode: b)));
      await t.tap(find.text('Name'));
      await t.pump();
      expect(b.hasFocus, true);
      await ready(t, host(const SteyInput(label: 'Name')));
      await t.tap(find.text('Name'));
      await t.pump();
      expect(field(t).focusNode!.hasFocus, true);
      await t.pumpWidget(const SizedBox.shrink());
      a.dispose();
      b.dispose();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'disabled label does not request focus and disabled text uses inactive color',
    (t) async {
      await ready(
        t,
        host(
          const SteyInput(label: 'Name', enabled: false, defaultValue: 'text'),
        ),
      );
      await t.tap(find.text('Name'));
      await t.pump();
      expect(field(t).focusNode!.hasFocus, false);
      expect(
        field(t).style!.color,
        const SteyColors(Brightness.light).inactive,
      );
    },
  );
  testWidgets('read-only can focus and select but ignores editing actions', (
    t,
  ) async {
    var calls = 0;
    await ready(
      t,
      host(
        SteyInput(
          label: 'Name',
          defaultValue: 'text',
          readOnly: true,
          onChanged: (_) => calls++,
        ),
      ),
    );
    await t.tap(find.text('Name'));
    await t.pump();
    expect(field(t).focusNode!.hasFocus, true);
    await t.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(field(t).controller!.text, 'text');
    expect(field(t).readOnly, true);
    expect(calls, 0);
  });
  testWidgets(
    'required name, invalid state and helper priority remain on a single editor',
    (t) async {
      final semantics = t.ensureSemantics();
      await ready(
        t,
        host(
          const SteyInput(
            label: 'Name',
            semanticLabel: 'Project',
            required: true,
            description: 'Helper',
            error: 'Invalid',
          ),
        ),
      );
      final nodes = find.semantics.byFlag(SemanticsFlag.isTextField).evaluate();
      expect(nodes.length, 1);
      final data = nodes.single.getSemanticsData();
      expect(data.label, 'Project');
      expect(data.hint, 'Invalid');
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(find.text('Helper'), findsNothing);
      semantics.dispose();
    },
  );
  testWidgets('optional label and tooltip stay separate from editor name', (
    t,
  ) async {
    await ready(
      t,
      host(
        const SteyInput(label: 'Name', required: false, labelTooltip: 'Help'),
      ),
    );
    expect(find.text('Name (optional)'), findsOneWidget);
    expect(find.bySemanticsLabel('More information'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('More information'));
    await t.pumpAndSettle();
    expect(find.text('Help'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('formatters precede value aliases and Enter submission', (
    t,
  ) async {
    final log = <String>[];
    await ready(
      t,
      host(
        SteyInput(
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => log.add('change:$v'),
          onValueChange: (v) => log.add('value:$v'),
          onSubmitted: (v) => log.add('submit:$v'),
        ),
      ),
    );
    await t.enterText(find.byType(TextField), 'a12');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(log, ['change:12', 'value:12', 'submit:12']);
  });
  testWidgets(
    'focus ring changes without implicit Material border transitions',
    (t) async {
      await ready(t, host(const SteyInput(label: 'Name')));
      final painter = find
          .ancestor(
            of: find.byType(TextField),
            matching: find.byType(CustomPaint),
          )
          .first;
      final before = t.widget<CustomPaint>(painter).foregroundPainter;
      await t.tap(find.text('Name'));
      await t.pump();
      expect(
        t
            .widget<CustomPaint>(painter)
            .foregroundPainter!
            .shouldRepaint(before!),
        true,
      );
      expect(field(t).decoration!.focusedBorder, InputBorder.none);
    },
  );
  testWidgets('prefix and suffix keep independent action and editor content', (
    t,
  ) async {
    var calls = 0;
    await ready(
      t,
      host(
        SteyInput(
          defaultValue: 'value',
          prefix: const Icon(Icons.search, size: 16),
          suffix: SteyButton(
            semanticLabel: 'Suffix',
            onPressed: () => calls++,
            child: const Text('Go'),
          ),
        ),
      ),
    );
    await t.tap(find.bySemanticsLabel('Suffix'));
    await t.pump();
    expect(calls, 1);
    expect(field(t).controller!.text, 'value');
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'InputArea uses two fixed rows while legacy Textarea retains four',
    (t) async {
      await ready(t, host(const SteyInputArea()));
      expect(field(t).minLines, 2);
      expect(field(t).maxLines, 2);
      final two = t.getSize(find.byType(TextField)).height;
      await ready(t, host(const SteyTextarea()));
      expect(field(t).maxLines, 4);
      expect(t.getSize(find.byType(TextField)).height, greaterThan(two));
    },
  );
  testWidgets(
    'auto-resize grows and shrinks with value and clamps maximum rows',
    (t) async {
      await ready(
        t,
        host(const SteyInputArea(autoResize: true, minRows: 1, maxRows: 3)),
      );
      final base = t.getSize(find.byType(TextField)).height;
      await t.enterText(find.byType(TextField), 'one\ntwo\nthree\nfour');
      await t.pumpAndSettle();
      final clamped = t.getSize(find.byType(TextField)).height;
      expect(clamped, greaterThan(base));
      await t.enterText(
        find.byType(TextField),
        'one\ntwo\nthree\nfour\nfive\nsix',
      );
      await t.pumpAndSettle();
      expect(t.getSize(find.byType(TextField)).height, clamped);
      await t.enterText(find.byType(TextField), 'one');
      await t.pumpAndSettle();
      expect(t.getSize(find.byType(TextField)).height, base);
    },
  );
  testWidgets('auto-resize rewraps on width change and respects minimum rows', (
    t,
  ) async {
    Widget view(double width) => host(
      const SteyInputArea(
        defaultValue:
            'A long sentence that must wrap several times in a narrow input.',
        autoResize: true,
        minRows: 2,
      ),
      width: width,
    );
    await ready(t, view(400));
    final wide = t.getSize(find.byType(TextField)).height;
    await ready(t, view(110));
    expect(t.getSize(find.byType(TextField)).height, greaterThan(wide));
  });
  testWidgets('auto-resize mode changes retain text and restore fixed rows', (
    t,
  ) async {
    await ready(t, host(const SteyInputArea(autoResize: true)));
    await t.enterText(find.byType(TextField), 'one\ntwo\nthree');
    await t.pumpAndSettle();
    await ready(t, host(const SteyInputArea(autoResize: false, maxLines: 2)));
    expect(field(t).controller!.text, 'one\ntwo\nthree');
    expect(field(t).maxLines, 2);
  });
  testWidgets('RTL and text scale retain content without layout exceptions', (
    t,
  ) async {
    for (final size in SteySize.values) {
      await ready(
        t,
        host(
          SteyInput(size: size, label: 'الاسم', defaultValue: 'مرحبا بالعالم'),
          width: 160,
          rtl: true,
          scale: 2,
        ),
      );
      expect(t.takeException(), isNull);
      expect(field(t).controller!.text, 'مرحبا بالعالم');
    }
  });
}
