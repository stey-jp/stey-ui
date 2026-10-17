import 'dart:async';
import 'dart:ui' show PointerDeviceKind, Tristate, SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  double width = 320,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
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
Finder copyTarget() => find
    .descendant(
      of: find.byType(SteyInlineCopyText),
      matching: find.byType(GestureDetector),
    )
    .first;

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
    'Copies explicit value, keeps text, announces success then resets at 1500ms',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var calls = 0;
      await tester.pumpWidget(
        host(
          SteyInlineCopyText(
            'short-id',
            value: '\tcomplete\r\n日本語\n',
            onCopied: () => calls++,
          ),
        ),
      );
      expect(find.text('short-id'), findsOneWidget);
      expect(find.byType(SteyButton), findsNothing);
      await tester.tap(copyTarget());
      await tester.pump();
      expect(writes, ['\tcomplete\r\n日本語\n']);
      expect(calls, 1);
      expect(find.bySemanticsLabel('Copied'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Copied'))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 1499));
      expect(find.bySemanticsLabel('Copied'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.bySemanticsLabel('Copy to clipboard'), findsOneWidget);
      semantics.dispose();
    },
  );
  testWidgets(
    'Rich display uses required value and localized labels without exposing child controls',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const SteyInlineCopyText.rich(
            Text.rich(
              TextSpan(
                text: 'Visible resource',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
            value: 'actual-id',
            variant: SteyInlineCopyVariant.body,
            bold: true,
            copyActionLabel: 'IDをコピー',
            copiedLabel: 'IDをコピーしました',
          ),
        ),
      );
      await tester.tap(copyTarget());
      await tester.pump();
      expect(writes, ['actual-id']);
      expect(find.bySemanticsLabel('IDをコピーしました'), findsOneWidget);
      semantics.dispose();
    },
  );
  testWidgets('Repeated clicks reset feedback from the last click', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(const SteyInlineCopyText('id')));
    await tester.tap(copyTarget());
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.tap(copyTarget());
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.bySemanticsLabel('Copied'), findsOneWidget);
    expect(writes, hasLength(2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.bySemanticsLabel('Copy to clipboard'), findsOneWidget);
    semantics.dispose();
  });
  testWidgets(
    'Consumer cancellation preserves existing feedback timer and does no IO',
    (tester) async {
      bool cancel = false;
      var attempts = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          SteyInlineCopyText(
            'id',
            onBeforeCopy: () {
              attempts++;
              return !cancel;
            },
          ),
        ),
      );
      await tester.tap(copyTarget());
      await tester.pump(const Duration(milliseconds: 1000));
      cancel = true;
      await tester.tap(copyTarget());
      await tester.pump(const Duration(milliseconds: 500));
      expect(writes, ['id']);
      expect(attempts, 2);
      expect(find.bySemanticsLabel('Copy to clipboard'), findsOneWidget);
      semantics.dispose();
    },
  );
  testWidgets(
    'Failure clears prior feedback, calls error only and cancels its reset',
    (tester) async {
      var fail = false, success = 0;
      final errors = <Object>[];
      final semantics = tester.ensureSemantics();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData' && fail) {
            throw PlatformException(code: 'denied');
          }
          return null;
        },
      );
      await tester.pumpWidget(
        host(
          SteyInlineCopyText(
            'id',
            onCopied: () => success++,
            onCopyError: errors.add,
          ),
        ),
      );
      await tester.tap(copyTarget());
      await tester.pump();
      fail = true;
      await tester.tap(copyTarget());
      await tester.pump();
      expect(success, 1);
      expect(errors, hasLength(1));
      expect(find.bySemanticsLabel('Copy to clipboard'), findsOneWidget);
      semantics.dispose();
    },
  );
  testWidgets(
    'Overlapping requests follow upstream completion order; disposal cancels all timers',
    (tester) async {
      final requests = <Completer<void>>[];
      final completions = <int>[];
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            final c = Completer<void>();
            requests.add(c);
            await c.future;
          }
          return null;
        },
      );
      await tester.pumpWidget(
        host(
          SteyInlineCopyText(
            'id',
            onCopied: () =>
                completions.add(requests.where((r) => r.isCompleted).length),
          ),
        ),
      );
      await tester.tap(copyTarget());
      await tester.tap(copyTarget());
      requests[1].complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      requests[0].complete();
      await tester.pump();
      expect(completions, [1, 2]);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Unmounted pending copy cannot call success or mutate state', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') await pending.future;
        return null;
      },
    );
    await tester.pumpWidget(
      host(SteyInlineCopyText('id', onCopied: () => calls++)),
    );
    await tester.tap(copyTarget());
    await tester.pumpWidget(const SizedBox());
    pending.complete();
    await tester.pump();
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Disabled blocks pointer, semantics and keyboard; enabling preserves focus node',
    (tester) async {
      final semantics = tester.ensureSemantics(), node = FocusNode();
      addTearDown(node.dispose);
      Widget subject(bool disabled) =>
          host(SteyInlineCopyText('id', focusNode: node, disabled: disabled));
      await tester.pumpWidget(subject(true));
      await tester.tap(copyTarget());
      await tester.pump();
      expect(writes, isEmpty);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Copy to clipboard'))
            .flagsCollection
            .isEnabled,
        Tristate.isFalse,
      );
      await tester.pumpWidget(subject(false));
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(writes, ['id']);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );
  testWidgets(
    'Enter acts on keydown, Space only on keyup, leaving focus cancels held Space',
    (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(SteyInlineCopyText('id', focusNode: node)));
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(writes, isEmpty);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(writes, isEmpty);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(writes, ['id']);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(writes, hasLength(2));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(writes, hasLength(2));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      node.unfocus();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(writes, hasLength(2));
    },
  );
  testWidgets(
    'Hover fades in 150ms despite motion reduction; check icon keeps reserved space',
    (tester) async {
      await tester.pumpWidget(
        host(const SteyInlineCopyText('namespace-id'), reduce: true),
      );
      final fade = find.descendant(
        of: find.byType(SteyInlineCopyText),
        matching: find.byType(FadeTransition),
      );
      double opacity() =>
          tester.widget<FadeTransition>(fade.first).opacity.value;
      expect(opacity(), 0);
      final size = tester.getSize(find.byType(SteyInlineCopyText));
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: const Offset(1, 1));
      await pointer.moveTo(tester.getCenter(find.text('namespace-id')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(opacity(), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 75));
      expect(opacity(), 1);
      await tester.tap(copyTarget());
      await tester.pump();
      expect(tester.getSize(find.byType(SteyInlineCopyText)), size);
      await pointer.removePointer();
    },
  );
  testWidgets(
    'Group hover reveals icons without changing secondary text; nested outer groups propagate',
    (tester) async {
      await tester.pumpWidget(
        host(
          SteyInlineCopyGroup(
            child: SizedBox(
              height: 180,
              child: Column(
                children: [
                  const Text('Row area'),
                  const SteyInlineCopyGroup(child: SteyInlineCopyText('id')),
                  SteyButton(
                    onPressed: () {},
                    child: const Text('Other action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: const Offset(1, 1));
      await pointer.moveTo(tester.getCenter(find.text('Row area')));
      await tester.pumpAndSettle();
      final fade = find.descendant(
        of: find.byType(SteyInlineCopyText),
        matching: find.byType(FadeTransition),
      );
      expect(tester.widget<FadeTransition>(fade.first).opacity.value, 1);
      final style = DefaultTextStyle.of(tester.element(find.text('id'))).style;
      expect(style.color, SteyColors(Brightness.light).subtle);
      await pointer.removePointer();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(tester.widget<FadeTransition>(fade.first).opacity.value, 1);
    },
  );
  for (final direction in TextDirection.values) {
    for (final truncate in [false, true]) {
      testWidgets(
        'Narrow scaled $direction truncate=$truncate keeps full copy value',
        (tester) async {
          final text = 'namespace-${'abcdefghij' * 20}';
          await tester.pumpWidget(
            host(
              SteyInlineCopyText(
                text,
                value: 'complete-id',
                truncate: truncate,
              ),
              width: 100,
              scale: 2,
              direction: direction,
            ),
          );
          await tester.tap(copyTarget());
          await tester.pump();
          expect(writes, ['complete-id']);
          expect(tester.takeException(), isNull);
          final label = tester.widget<Text>(find.text(text));
          expect(label.data, text);
        },
      );
    }
  }
  testWidgets(
    'All text variants/sizes render in both themes; mono small sizes stay normalized',
    (tester) async {
      for (final brightness in Brightness.values) {
        for (final variant in SteyInlineCopyVariant.values) {
          for (final size in SteyInlineCopySize.values) {
            await tester.pumpWidget(
              host(
                SteyInlineCopyText(
                  'id',
                  variant: variant,
                  size: size,
                  bold: true,
                ),
                brightness: brightness,
              ),
            );
            final style = DefaultTextStyle.of(tester.element(find.text('id')))
                .style;
            final mono =
                variant == SteyInlineCopyVariant.mono ||
                variant == SteyInlineCopyVariant.monoSecondary;
            expect(style.fontWeight, mono ? FontWeight.w400 : FontWeight.w500);
            if (mono) {
              expect(style.fontSize, size == SteyInlineCopySize.lg ? 14 : 13);
            }
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );
  testWidgets(
    'Legacy inline flag delegates to the native control and retains callback',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        host(SteyClipboardText('id', inline: true, onCopied: () => calls++)),
      );
      expect(find.byType(SteyInlineCopyText), findsOneWidget);
      await tester.tap(copyTarget());
      await tester.pump();
      expect(writes, ['id']);
      expect(calls, 1);
    },
  );
  testWidgets(
    'Accessibility tap owns application focus; the next Tab reaches the row action',
    (tester) async {
      final semantics = tester.ensureSemantics(), node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          SteyInlineCopyGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SteyInlineCopyText('id', focusNode: node),
                SteyButton(onPressed: () {}, child: const Text('Other action')),
              ],
            ),
          ),
        ),
      );
      final target = tester.getSemantics(
        find.bySemanticsLabel('Copy to clipboard'),
      );
      tester
          .renderObject(find.bySemanticsLabel('Copy to clipboard'))
          .owner!
          .semanticsOwner!
          .performAction(target.id, SemanticsAction.tap);
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
      expect(writes, ['id']);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(node.hasFocus, isFalse);
      expect(
        Focus.of(tester.element(find.text('Other action'))).hasFocus,
        isTrue,
      );
      semantics.dispose();
    },
  );
}
