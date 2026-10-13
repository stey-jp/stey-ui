import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  Alignment alignment = Alignment.center,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: SteyTheme(
    brightness: Brightness.light,
    child: Scaffold(
      body: Directionality(
        textDirection: direction,
        child: Align(
          alignment: alignment,
          child: SizedBox(width: 280, child: child),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('System back closes the select popup before leaving the route', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SteySelect<String>(
          controlled: false,
          options: {'a': 'Alpha', 'b': 'Beta'},
        ),
      ),
    );
    await tester.tap(find.text('Select an option'));
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsNothing);
    expect(find.text('Select an option'), findsOneWidget);
  });
  testWidgets(
    'Select keyboard opens, skips disabled, commits and restores focus',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final focus = FocusNode();
      final changes = <String?>[];
      await tester.pumpWidget(
        host(
          SteySelect<String>(
            controlled: false,
            label: 'Fruit',
            focusNode: focus,
            onChanged: changes.add,
            entries: const [
              SteySelectOption(value: 'apple', label: 'Apple'),
              SteySelectOption(
                value: 'banana',
                label: 'Banana',
                disabled: true,
              ),
              SteySelectOption(value: 'cherry', label: 'Cherry'),
            ],
          ),
        ),
      );
      expect(find.semantics.byLabel('Fruit'), findsOneWidget);
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(changes, ['cherry']);
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(focus.hasFocus, isTrue);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
    },
  );

  testWidgets(
    'Controlled select preserves the owner value and closes on outside tap',
    (tester) async {
      final changes = <int?>[];
      await tester.pumpWidget(
        host(
          SteySelect<int>(
            value: 1,
            options: const {1: 'First', 2: 'Second'},
            onChanged: changes.add,
            label: 'Mode',
          ),
        ),
      );
      await tester.tap(find.text('First'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      expect(changes, [2]);
      expect(find.text('First'), findsOneWidget);
      await tester.tap(find.text('First'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
    },
  );

  testWidgets(
    'Multiple selection stays open and toggles values in grouped options',
    (tester) async {
      final changes = <List<String>>[];
      await tester.pumpWidget(
        host(
          SteySelect<String>(
            controlled: false,
            multiple: true,
            onValuesChanged: changes.add,
            label: 'Regions',
            entries: const [
              SteySelectGroup(
                label: 'Europe',
                entries: [
                  SteySelectOption(value: 'de', label: 'Germany'),
                  SteySelectOption(value: 'fr', label: 'France'),
                ],
              ),
              SteySelectSeparator(),
              SteySelectOption(value: 'jp', label: 'Japan', disabled: true),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Select an option'));
      await tester.pumpAndSettle();
      expect(find.text('Europe'), findsOneWidget);
      await tester.tap(find.text('Germany'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();
      expect(changes, [
        ['de'],
        ['de', 'fr'],
      ]);
      await tester.tap(find.text('Germany'));
      await tester.pumpAndSettle();
      expect(changes.last, ['fr']);
      await tester.tap(find.text('Japan'));
      await tester.pumpAndSettle();
      expect(changes.last, ['fr']);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Europe'), findsNothing);
      expect(find.text('France'), findsOneWidget);
    },
  );

  testWidgets(
    'Closed typeahead skips disabled and open typeahead only highlights',
    (tester) async {
      final focus = FocusNode();
      final changes = <String?>[];
      await tester.pumpWidget(
        host(
          SteySelect<String>(
            controlled: false,
            focusNode: focus,
            onChanged: changes.add,
            entries: const [
              SteySelectOption(value: 'apple', label: 'Apple', disabled: true),
              SteySelectOption(value: 'apricot', label: 'Apricot'),
              SteySelectOption(value: 'berry', label: 'Berry'),
            ],
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
      await tester.pumpAndSettle();
      expect(changes, ['apricot']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB, character: 'b');
      await tester.pumpAndSettle();
      expect(changes, ['apricot']);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(changes, ['apricot', 'berry']);
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
    },
  );

  testWidgets(
    'Read-only permits browsing while disabled and loading do not open',
    (tester) async {
      for (final state in ['readonly', 'disabled', 'loading']) {
        final changes = <String?>[];
        await tester.pumpWidget(
          host(
            SteySelect<String>(
              value: 'a',
              options: const {'a': 'First', 'b': 'Second'},
              onChanged: changes.add,
              readOnly: state == 'readonly',
              disabled: state == 'disabled',
              loading: state == 'loading',
              label: 'Mode',
            ),
          ),
        );
        await tester.tap(find.byType(SteySelect<String>));
        await tester.pump(const Duration(milliseconds: 200));
        if (state == 'readonly') {
          expect(find.text('Second'), findsOneWidget);
          await tester.tap(find.text('Second'));
          await tester.pump();
        } else {
          expect(find.text('Second'), findsNothing);
        }
        expect(changes, isEmpty);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'Popup flips at the bottom, constrains height and keeps large RTL text',
    (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          host(
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SteySelect<int>(
                controlled: false,
                label: 'Plan',
                entries: [
                  for (var i = 0; i < 15; i++)
                    SteySelectOption(value: i, label: 'Plan $i'),
                ],
              ),
            ),
            alignment: Alignment.bottomCenter,
            direction: direction,
          ),
        );
        final trigger = tester.getRect(find.text('Select an option'));
        await tester.tap(find.text('Select an option'));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.text('Plan 0')).bottom,
          lessThan(trigger.top),
        );
        expect(tester.takeException(), isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Plan 14'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets('Tab closes the popup and continues to the next control', (
    tester,
  ) async {
    final first = FocusNode(), next = FocusNode();
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SteySelect<String>(
              controlled: false,
              focusNode: first,
              options: const {'a': 'Alpha'},
            ),
            SteyButton(
              focusNode: next,
              onPressed: () {},
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
    first.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsNothing);
    expect(next.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    first.dispose();
    next.dispose();
  });
}
