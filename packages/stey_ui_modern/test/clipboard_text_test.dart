import 'dart:async';
import 'dart:ui' show PointerDeviceKind, SemanticsRole, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  double width = 280,
  double scale = 1,
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  bool reduce = false,
}) => MaterialApp(
  theme: SteyTheme.material(brightness),
  home: SteyTheme(
    brightness: brightness,
    child: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduce,
        ),
        child: Directionality(
          textDirection: direction,
          child: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  ),
);
Finder button() => find.bySemanticsLabel('Copy to clipboard');
Finder popup(SemanticsRole role) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      (role == SemanticsRole.tooltip
          ? w.properties.tooltip == 'Copy it'
          : w.properties.role == role),
);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> writes;
  setUp(() {
    writes = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          writes.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
  });
  tearDown(
    () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  testWidgets(
    'Only the copy button writes raw explicit values and announces for 1500ms',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var calls = 0;
      for (final value in ['', '\tcomplete\r\n日本語\n', 'namespace-id']) {
        await tester.pumpWidget(
          host(
            SteyClipboardText(
              'visible-id',
              textToCopy: value,
              onCopied: () => calls++,
            ),
          ),
        );
        await tester.tap(find.text('visible-id'));
        await tester.pump();
        expect(writes.length, calls);
        await tester.tap(button());
        await tester.pump();
        expect(writes.last, value);
        expect(find.text('visible-id'), findsOneWidget);
        expect(button(), findsOneWidget);
        expect(find.bySemanticsLabel('Copied'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1499));
        expect(find.bySemanticsLabel('Copied'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1));
        expect(find.bySemanticsLabel('Copied'), findsNothing);
        await tester.pumpAndSettle();
      }
      expect(calls, 3);
      semantics.dispose();
    },
  );

  testWidgets(
    'Default value and repeated success reset after the last completion',
    (tester) async {
      await tester.pumpWidget(host(const SteyClipboardText('raw-value')));
      await tester.tap(button());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.tap(button());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.bySemanticsLabel('Copied'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Copied')).rect.width,
        greaterThan(0),
      );
      await tester.pump(const Duration(milliseconds: 499));
      expect(find.bySemanticsLabel('Copied'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.bySemanticsLabel('Copied'), findsNothing);
      expect(writes, ['raw-value', 'raw-value']);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Failures do not announce success or cancel previous successful feedback',
    (tester) async {
      final errors = <Object>[];
      var calls = 0;
      await tester.pumpWidget(
        host(
          SteyClipboardText(
            'id',
            onCopied: () => calls++,
            onCopyError: errors.add,
          ),
        ),
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (_) async => throw PlatformException(code: 'denied'),
      );
      await tester.tap(button());
      await tester.pump();
      expect(errors.length, 1);
      expect(calls, 0);
      expect(find.bySemanticsLabel('Copied'), findsNothing);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (_) async => null,
      );
      await tester.tap(button());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (_) async => throw PlatformException(code: 'denied'),
      );
      await tester.tap(button());
      await tester.pump();
      expect(calls, 1);
      expect(errors.length, 2);
      expect(find.bySemanticsLabel('Copied'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.bySemanticsLabel('Copied'), findsNothing);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Overlapping writes follow completion ordering and renew only on success',
    (tester) async {
      final requests = <Completer<Object?>>[];
      var calls = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) {
          if (call.method != 'Clipboard.setData') return Future.value();
          final request = Completer<Object?>();
          requests.add(request);
          return request.future;
        },
      );
      await tester.pumpWidget(
        host(SteyClipboardText('id', onCopied: () => calls++)),
      );
      await tester.tap(button());
      await tester.pump();
      await tester.tap(button());
      await tester.pump();
      requests[1].complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      requests[0].complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.bySemanticsLabel('Copied'), findsOneWidget);
      expect(calls, 2);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.bySemanticsLabel('Copied'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Disposal cancels timers and ignores a pending clipboard completion',
    (tester) async {
      final request = Completer<Object?>();
      var calls = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (_) => request.future,
      );
      await tester.pumpWidget(
        host(
          SteyClipboardText(
            'id',
            tooltip: const SteyClipboardTooltip(),
            onCopied: () => calls++,
          ),
        ),
      );
      await tester.tap(button());
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      request.complete();
      await tester.pump();
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Hover waits 600ms, keyboard focus opens immediately, Escape closes tooltip',
    (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.pumpWidget(
        host(
          const SteyClipboardText(
            'id',
            tooltip: SteyClipboardTooltip(text: 'Copy it'),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(button()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 599));
      expect(popup(SemanticsRole.tooltip), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.text('Copy it'), findsOneWidget);
      expect(tester.getSemantics(popup(SemanticsRole.tooltip)).label, isEmpty);
      expect(tester.getSemantics(button()).getSemanticsData().tooltip, isEmpty);
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(popup(SemanticsRole.tooltip), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(popup(SemanticsRole.tooltip), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(popup(SemanticsRole.tooltip), findsNothing);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'One anchored toast is retained and bumped on repeat, then expires',
    (tester) async {
      await tester.pumpWidget(
        host(
          const SteyClipboardText(
            'id',
            tooltip: SteyClipboardTooltip(copiedText: 'Done'),
          ),
        ),
      );
      await tester.tap(button());
      await tester.pumpAndSettle();
      expect(popup(SemanticsRole.status), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(button());
      await tester.pump();
      expect(popup(SemanticsRole.status), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('Done'), findsOneWidget);
      final scales = tester
          .widgetList<Transform>(find.byType(Transform))
          .map((w) => w.transform.entry(0, 0));
      expect(scales.any((v) => v > 1), isTrue);
      await tester.pump(const Duration(milliseconds: 1379));
      expect(popup(SemanticsRole.status), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(popup(SemanticsRole.status), findsNothing);
      await tester.pumpAndSettle();
    },
  );

  for (final side in SteyClipboardSide.values) {
    testWidgets('Popup side ${side.name} stays anchored with 8px offset', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SteyClipboardText('id', tooltip: SteyClipboardTooltip(side: side)),
        ),
      );
      await tester.tap(button());
      await tester.pumpAndSettle();
      final a = tester.getRect(button()),
          p = tester.getRect(find.text('Copied'));
      switch (side) {
        case SteyClipboardSide.top:
          expect(a.top - p.bottom - 6, closeTo(8, .01));
        case SteyClipboardSide.bottom:
          expect(p.top - 6 - a.bottom, closeTo(8, .01));
        case SteyClipboardSide.left:
          expect(a.left - p.right - 12, closeTo(8, .01));
        case SteyClipboardSide.right:
          expect(p.left - 12 - a.right, closeTo(8, .01));
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'Tab skips displayed text, Enter repeats and Space activates on release',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SteyClipboardText('id'),
              SteyButton(onPressed: () {}, child: const Text('Next')),
            ],
          ),
        ),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('id'))
            .flagsCollection
            .isFocused,
        Tristate.none,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(writes.length, 1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(writes.length, 1);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(writes.length, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(writes.length, 2);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(writes.length, 2);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );

  testWidgets('Top popup flips near the viewport edge and stays inside it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SteyTheme.material(Brightness.light),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              width: 180,
              child: SteyClipboardText('id', tooltip: SteyClipboardTooltip()),
            ),
          ),
        ),
      ),
    );
    await tester.tap(button());
    await tester.pumpAndSettle();
    final a = tester.getRect(button()), p = tester.getRect(find.text('Copied'));
    expect(p.top - 6 - a.bottom, closeTo(8, .01));
    expect(p.right + 12, lessThanOrEqualTo(795));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Success popup follows a scrolling anchor without renewing its timer',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scroll,
              child: const Column(
                children: [
                  SizedBox(height: 300),
                  SizedBox(
                    width: 280,
                    child: SteyClipboardText(
                      'id',
                      tooltip: SteyClipboardTooltip(),
                    ),
                  ),
                  SizedBox(height: 700),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(button());
      await tester.pumpAndSettle();
      final before = tester.getRect(find.text('Copied'));
      scroll.jumpTo(100);
      await tester.pump();
      await tester.pump();
      expect(
        tester.getRect(find.text('Copied')).top,
        closeTo(before.top - 100, .01),
      );
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();
      expect(popup(SemanticsRole.status), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'All sizes/themes/RTL at 2x retain bounded text and copy raw content',
    (tester) async {
      for (final size in SteyClipboardSize.values) {
        for (final brightness in Brightness.values) {
          for (final direction in TextDirection.values) {
            await tester.pumpWidget(
              host(
                SteyClipboardText('namespace-' * 20, size: size),
                width: 160,
                scale: 2,
                direction: direction,
                brightness: brightness,
              ),
            );
            final field = tester.getSize(find.byType(SteyClipboardText));
            expect(field.width, 160);
            expect(
              field.height,
              size == SteyClipboardSize.sm
                  ? 26
                  : size == SteyClipboardSize.base
                  ? 36
                  : 40,
            );
            final text = tester.widget<Text>(find.text('namespace-' * 20));
            expect(text.overflow, TextOverflow.ellipsis);
            expect(
              text.style?.fontSize,
              size == SteyClipboardSize.sm ? 12 : 13,
            );
            await tester.tap(button());
            await tester.pump();
            expect(writes.last, 'namespace-' * 20);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          }
        }
      }
    },
  );

  testWidgets(
    '200ms slide still runs with reduced motion; field width is stable',
    (tester) async {
      await tester.pumpWidget(
        host(const SteyClipboardText('id'), reduce: true),
      );
      final before = tester.getRect(button());
      await tester.tap(button());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((w) => w.opacity);
      expect(opacities.any((v) => v > 0 && v < 1), isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getRect(button()), before);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Tooltip can be removed and restored during active feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const SteyClipboardText('id', tooltip: SteyClipboardTooltip())),
    );
    await tester.tap(button());
    await tester.pumpAndSettle();
    expect(popup(SemanticsRole.status), findsOneWidget);
    await tester.pumpWidget(host(const SteyClipboardText('id')));
    await tester.pump();
    expect(popup(SemanticsRole.status), findsNothing);
    expect(find.bySemanticsLabel('Copied'), findsOneWidget);
    await tester.pumpWidget(
      host(const SteyClipboardText('id', tooltip: SteyClipboardTooltip())),
    );
    await tester.pump();
    expect(popup(SemanticsRole.status), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
