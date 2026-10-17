import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

import 'dropdown_test.dart' show host;

Finder row(String label) => find.widgetWithText(MenuItemButton, label);
FocusNode node(WidgetTester tester, String label) =>
    tester.widget<MenuItemButton>(row(label)).focusNode ??
    tester
        .widget<Focus>(
          find.ancestor(of: row(label), matching: find.byType(Focus)).first,
        )
        .focusNode!;
Future<void> press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  String? character,
}) async {
  await tester.sendKeyEvent(key, character: character);
  await tester.pump();
}

Future<MenuController> setup(
  WidgetTester tester,
  TextDirection direction,
  List<SteyMenuItem> items,
) async {
  final controller = MenuController();
  await tester.pumpWidget(
    host(
      SteyDropdownMenu(
        controller: controller,
        items: items,
        child: const Text('Actions'),
      ),
      direction: direction,
    ),
  );
  controller.open();
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'Disabled rows receive focus with disabled semantics and cannot activate $direction',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var actions = 0;
        final controller = await setup(tester, direction, [
          SteyMenuItem('Alpha', onPressed: () {}),
          SteyMenuItem('Disabled', disabled: true, onPressed: () => actions++),
          SteyMenuItem('Beta', onPressed: () {}),
        ]);
        node(tester, 'Alpha').requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.arrowDown);
        expect(node(tester, 'Disabled').hasPrimaryFocus, isTrue);
        final flags = tester
            .getSemantics(row('Disabled'))
            .getSemanticsData()
            .flagsCollection;
        expect(flags.isEnabled, Tristate.isFalse);
        expect(flags.isFocused, Tristate.isTrue);
        expect(
          tester.widget<MenuItemButton>(row('Disabled')).onPressed,
          isNull,
        );
        await press(tester, LogicalKeyboardKey.enter);
        await press(tester, LogicalKeyboardKey.space);
        await tester.tap(row('Disabled'));
        await tester.pump();
        expect(actions, 0);
        expect(controller.isOpen, isTrue);
        await press(tester, LogicalKeyboardKey.arrowDown);
        expect(node(tester, 'Beta').hasPrimaryFocus, isTrue);
        await press(tester, LogicalKeyboardKey.arrowUp);
        expect(node(tester, 'Disabled').hasPrimaryFocus, isTrue);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
    testWidgets(
      'Home End and typeahead can focus disabled edges and typed controls $direction',
      (tester) async {
        var actions = 0;
        final controller = await setup(tester, direction, [
          SteyMenuCheckboxItem(
            'Blocked check',
            value: true,
            disabled: true,
            onChanged: (_) => actions++,
          ),
          SteyMenuRadioItem(
            'Blocked radio',
            value: 1,
            groupValue: 1,
            disabled: true,
            onChanged: (_) => actions++,
          ),
          SteyMenuItem(
            'Blocked submenu',
            disabled: true,
            children: [SteyMenuItem('Nested', onPressed: () => actions++)],
          ),
        ]);
        node(tester, 'Blocked radio').requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.home);
        expect(node(tester, 'Blocked check').hasPrimaryFocus, isTrue);
        await press(tester, LogicalKeyboardKey.space);
        await press(tester, LogicalKeyboardKey.end);
        expect(node(tester, 'Blocked submenu').hasPrimaryFocus, isTrue);
        await press(
          tester,
          direction == TextDirection.ltr
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft,
        );
        expect(find.text('Nested'), findsNothing);
        await press(tester, LogicalKeyboardKey.enter);
        expect(actions, 0);
        expect(controller.isOpen, isTrue);
      },
    );
    testWidgets(
      'Space continues search until 500ms and then activates the same item $direction',
      (tester) async {
        var value = true;
        await setup(tester, direction, [
          SteyMenuItem('Alpha', onPressed: () {}),
          SteyMenuCheckboxItem(
            'Receive alerts',
            value: value,
            closeOnActivate: false,
            onChanged: (v) => value = v,
          ),
        ]);
        node(tester, 'Alpha').requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.keyR, character: 'r');
        expect(node(tester, 'Receive alerts').hasPrimaryFocus, isTrue);
        await press(tester, LogicalKeyboardKey.space, character: ' ');
        expect(value, isTrue);
        await tester.pump(const Duration(milliseconds: 499));
        await press(tester, LogicalKeyboardKey.space, character: ' ');
        expect(value, isTrue);
        await tester.pump(const Duration(milliseconds: 501));
        await press(tester, LogicalKeyboardKey.space, character: ' ');
        expect(value, isFalse);
      },
    );
    testWidgets(
      'An enabled initial Space activates without starting a search session $direction',
      (tester) async {
        var actions = 0;
        await setup(tester, direction, [
          SteyMenuItem(
            'Alpha',
            closeOnActivate: false,
            onPressed: () => actions++,
          ),
          SteyMenuItem('Receive alerts', onPressed: () {}),
        ]);
        node(tester, 'Alpha').requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.space, character: ' ');
        expect(actions, 1);
        await press(tester, LogicalKeyboardKey.space, character: ' ');
        expect(actions, 2);
        await press(tester, LogicalKeyboardKey.keyR, character: 'r');
        expect(node(tester, 'Receive alerts').hasPrimaryFocus, isTrue);
      },
    );
    testWidgets(
      'Space on a disabled row starts an inert search session $direction',
      (tester) async {
        await setup(tester, direction, [
          const SteyMenuItem('Unavailable', disabled: true),
          SteyMenuItem('Receive alerts', onPressed: () {}),
        ]);
        node(tester, 'Unavailable').requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.space, character: ' ');
        await press(tester, LogicalKeyboardKey.keyR, character: 'r');
        expect(node(tester, 'Unavailable').hasPrimaryFocus, isTrue);
        await press(tester, LogicalKeyboardKey.keyR, character: 'r');
        expect(node(tester, 'Receive alerts').hasPrimaryFocus, isTrue);
      },
    );
    testWidgets(
      'Multiword search stays anchored to the initial search index $direction',
      (tester) async {
        await setup(tester, direction, [
          SteyMenuItem('Other', onPressed: () {}),
          SteyMenuItem('New folder', onPressed: () {}),
          SteyMenuItem('New file', onPressed: () {}),
        ]);
        node(tester, 'Other').requestFocus();
        await tester.pump();
        for (final pair in [
          (LogicalKeyboardKey.keyN, 'n'),
          (LogicalKeyboardKey.keyE, 'e'),
          (LogicalKeyboardKey.keyW, 'w'),
          (LogicalKeyboardKey.space, ' '),
          (LogicalKeyboardKey.keyF, 'f'),
          (LogicalKeyboardKey.keyI, 'i'),
        ]) {
          await press(tester, pair.$1, character: pair.$2);
        }
        expect(node(tester, 'New file').hasPrimaryFocus, isTrue);
      },
    );
    testWidgets(
      'An unmatched character resets search so Space can activate $direction',
      (tester) async {
        var actions = 0;
        await setup(tester, direction, [
          SteyMenuItem(
            'Alpha',
            closeOnActivate: false,
            onPressed: () => actions++,
          ),
        ]);
        node(tester, 'Alpha').requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.keyZ, character: 'z');
        await press(tester, LogicalKeyboardKey.space, character: ' ');
        expect(actions, 1);
      },
    );
    testWidgets(
      'Double initials and disabled search results follow the same matching rules $direction',
      (tester) async {
        await setup(tester, direction, [
          SteyMenuItem('Other', onPressed: () {}),
          SteyMenuItem('Aaron', onPressed: () {}),
          SteyMenuItem('Abel', onPressed: () {}),
          const SteyMenuItem('Unavailable', disabled: true),
        ]);
        node(tester, 'Other').requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.keyA, character: 'a');
        await press(tester, LogicalKeyboardKey.keyA, character: 'a');
        expect(node(tester, 'Aaron').hasPrimaryFocus, isTrue);
        await tester.pump(const Duration(milliseconds: 501));
        await press(tester, LogicalKeyboardKey.keyU, character: 'u');
        expect(node(tester, 'Unavailable').hasPrimaryFocus, isTrue);
      },
    );
    testWidgets(
      'A search Space keyup cannot activate after its timer expires $direction',
      (tester) async {
        var actions = 0;
        await setup(tester, direction, [
          SteyMenuItem(
            'Alpha',
            closeOnActivate: false,
            onPressed: () => actions++,
          ),
        ]);
        node(tester, 'Alpha').requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.keyA, character: 'a');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.space, character: ' ');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(actions, 0);
        await press(tester, LogicalKeyboardKey.space, character: ' ');
        expect(actions, 1);
      },
    );
    testWidgets(
      'Child semantics exist from the first opening frame $direction',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await setup(tester, direction, [
          SteyMenuItem(
            'Move',
            children: [SteyMenuItem('Personal', onPressed: () {})],
          ),
        ]);
        node(tester, 'Move').requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(
          direction == TextDirection.ltr
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft,
        );
        await tester.pump();
        expect(find.bySemanticsLabel('Personal'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(node(tester, 'Personal').hasPrimaryFocus, isTrue);
        semantics.dispose();
      },
    );
    testWidgets(
      'Keyboard child focus clears the parent search and supports nested search $direction',
      (tester) async {
        var actions = 0;
        final controller = await setup(tester, direction, [
          SteyMenuItem(
            'Move',
            children: [
              SteyMenuItem('Personal account', onPressed: () {}),
              SteyMenuItem(
                'More',
                children: [
                  SteyMenuItem('New folder', onPressed: () => actions++),
                ],
              ),
            ],
          ),
        ]);
        final forward = direction == TextDirection.ltr
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowLeft;
        final back = direction == TextDirection.ltr
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight;
        node(tester, 'Move').requestFocus();
        await tester.pump();
        await press(tester, LogicalKeyboardKey.keyM, character: 'm');
        await press(tester, forward);
        await tester.pumpAndSettle();
        expect(node(tester, 'Personal account').hasPrimaryFocus, isTrue);
        FocusScope.of(tester.element(find.byType(SteyDropdownMenu)))
            .requestFocus();
        await tester.pump();
        expect(node(tester, 'Personal account').hasPrimaryFocus, isTrue);
        await press(tester, back);
        await tester.pumpAndSettle();
        await press(tester, LogicalKeyboardKey.space, character: ' ');
        await tester.pumpAndSettle();
        expect(node(tester, 'Personal account').hasPrimaryFocus, isTrue);
        await press(tester, LogicalKeyboardKey.keyM, character: 'm');
        await press(tester, forward);
        await tester.pumpAndSettle();
        expect(node(tester, 'New folder').hasPrimaryFocus, isTrue);
        await press(tester, LogicalKeyboardKey.keyN, character: 'n');
        await press(tester, LogicalKeyboardKey.space, character: ' ');
        expect(actions, 0);
        expect(controller.isOpen, isTrue);
        await press(tester, LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(actions, 1);
        expect(controller.isOpen, isFalse);
      },
    );
    testWidgets(
      'Changing a focused disabled item to enabled preserves the focus target $direction',
      (tester) async {
        var disabled = true, actions = 0;
        late StateSetter update;
        final controller = MenuController();
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return SteyDropdownMenu(
                  controller: controller,
                  items: [
                    SteyMenuItem(
                      'Mutable',
                      disabled: disabled,
                      closeOnActivate: false,
                      onPressed: () => actions++,
                    ),
                  ],
                  child: const Text('Actions'),
                );
              },
            ),
            direction: direction,
          ),
        );
        controller.open();
        await tester.pumpAndSettle();
        node(tester, 'Mutable').requestFocus();
        await tester.pump();
        final focus = node(tester, 'Mutable');
        update(() => disabled = false);
        await tester.pumpAndSettle();
        expect(node(tester, 'Mutable'), same(focus));
        expect(focus.hasPrimaryFocus, isTrue);
        await press(tester, LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(actions, 1);
        update(() => disabled = true);
        await tester.pumpAndSettle();
        expect(node(tester, 'Mutable'), same(focus));
        expect(focus.hasPrimaryFocus, isTrue);
        await press(tester, LogicalKeyboardKey.space);
        expect(actions, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
