import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  Alignment alignment = Alignment.center,
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: SteyTheme.material(brightness),
  home: SteyTheme(
    brightness: brightness,
    child: Scaffold(
      body: Directionality(
        textDirection: direction,
        child: Align(alignment: alignment, child: child),
      ),
    ),
  ),
);

Future<void> open(
  WidgetTester tester,
  List<SteyMenuItem> items, {
  Alignment alignment = Alignment.center,
  TextDirection direction = TextDirection.ltr,
  MenuController? controller,
}) async {
  await tester.pumpWidget(
    host(
      SteyDropdownMenu(
        items: items,
        controller: controller,
        child: const Text('Actions'),
      ),
      alignment: alignment,
      direction: direction,
    ),
  );
  await tester.tap(find.text('Actions'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Action closes the menu, disabled items are inert, focus returns to trigger',
    (tester) async {
      var count = 0;
      await open(tester, [
        SteyMenuItem('Edit', onPressed: () => count++),
        SteyMenuItem('Disabled', disabled: true, onPressed: () => count++),
        SteyMenuItem('Delete', destructive: true, onPressed: () => count++),
      ]);
      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();
      expect(count, 0);
      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(count, 1);
      expect(find.text('Edit'), findsNothing);
      final trigger = tester.widget<SteyButton>(find.byType(SteyButton));
      expect(trigger.focusNode!.hasFocus, isTrue);
    },
  );

  testWidgets(
    'Groups and separators are noninteractive and icons align sibling labels',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester, [
        SteyMenuGroup(
          'Project',
          children: [
            SteyMenuItem('Copy', icon: Icons.copy, onPressed: () {}),
            SteyMenuItem('Move', onPressed: () {}),
          ],
        ),
        const SteyMenuSeparator(),
        SteyMenuItem(
          'More',
          children: [SteyMenuItem('Nested', onPressed: () {})],
        ),
      ]);
      expect(
        tester.getTopLeft(find.text('Copy')).dx,
        tester.getTopLeft(find.text('Move')).dx,
      );
      expect(
        tester.getTopLeft(find.text('Project')).dx,
        tester.getTopLeft(find.text('Move')).dx,
      );
      expect(
        tester.getTopLeft(find.text('More')).dx,
        tester.getTopLeft(find.text('Move')).dx,
      );
      expect(
        find.semantics.byPredicate(
          (n) => n.getSemanticsData().role == SemanticsRole.menu,
        ),
        findsOneWidget,
      );
      expect(
        find.semantics.byPredicate(
          (n) =>
              !n.isMergedIntoParent &&
              n.getSemanticsData().role == SemanticsRole.menuItem,
        ),
        findsNWidgets(3),
      );
      expect(find.bySemanticsLabel('Copy'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('An icon in a closed submenu does not inset the parent popup', (
    tester,
  ) async {
    await open(tester, [
      SteyMenuItem('First', onPressed: () {}),
      SteyMenuItem(
        'More',
        children: [
          SteyMenuItem('With icon', icon: Icons.copy, onPressed: () {}),
          SteyMenuItem('Plain', onPressed: () {}),
        ],
      ),
    ]);
    final rootButton = tester.getRect(find.byType(MenuItemButton).first);
    expect(tester.getTopLeft(find.text('First')).dx - rootButton.left, 8);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('With icon'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('With icon')).dx,
      tester.getTopLeft(find.text('Plain')).dx,
    );
  });

  testWidgets('Nested submenu selection runs once and closes all menus', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var child = 0, parent = 0;
    await open(tester, [
      SteyMenuItem(
        'More',
        icon: Icons.settings,
        onPressed: () => parent++,
        children: [
          SteyMenuItem(
            'Nested',
            leading: const Icon(Icons.copy, color: Colors.red),
            onPressed: () => child++,
          ),
        ],
      ),
    ]);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(parent, 0);
    expect(
      find.semantics.byPredicate(
        (n) =>
            !n.isMergedIntoParent &&
            n.getSemanticsData().role == SemanticsRole.menu,
      ),
      findsNWidgets(2),
    );
    await tester.tap(find.text('Nested'));
    await tester.pumpAndSettle();
    expect([parent, child], [0, 1]);
    expect(find.text('Nested'), findsNothing);
    expect(find.text('More'), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'Nested controlled selection stays open and Escape closes one level',
    (tester) async {
      var checked = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SteyDropdownMenu(
              items: [
                SteyMenuItem(
                  'More',
                  children: [
                    SteyMenuCheckboxItem(
                      'Nested choice',
                      value: checked,
                      closeOnActivate: false,
                      onChanged: (value) => setState(() => checked = value),
                    ),
                  ],
                ),
              ],
              child: const Text('Actions'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nested choice'));
      await tester.pumpAndSettle();
      expect(checked, isTrue);
      expect(find.text('Nested choice'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Nested choice'), findsNothing);
      expect(find.text('More'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.text('More'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Checkbox and radio values stay controlled and announce their states',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var checked = false;
      var plan = 'free';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SteyDropdownMenu(
              items: [
                SteyMenuCheckboxItem(
                  'Alerts',
                  value: checked,
                  closeOnActivate: false,
                  onChanged: (value) => setState(() => checked = value),
                ),
                const SteyMenuSeparator(),
                SteyMenuRadioItem(
                  'Free',
                  value: 'free',
                  groupValue: plan,
                  closeOnActivate: false,
                  onChanged: (value) => setState(() => plan = value),
                ),
                SteyMenuRadioItem(
                  'Pro',
                  value: 'pro',
                  groupValue: plan,
                  closeOnActivate: false,
                  onChanged: (value) => setState(() => plan = value),
                ),
              ],
              child: const Text('Actions'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();
      expect(checked, isTrue);
      expect(find.text('Alerts'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.text('Alerts'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
      await tester.tap(find.text('Pro'));
      await tester.pumpAndSettle();
      expect(plan, 'pro');
      expect(
        tester
            .getSemantics(find.text('Pro'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
      expect(
        tester
            .getSemantics(find.text('Free'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isFalse,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'Keyboard skips disabled rows and supports End, Home and typeahead',
    (tester) async {
      final controller = MenuController();
      var chosen = '';
      await open(tester, [
        SteyMenuItem('Alpha', onPressed: () => chosen = 'a'),
        const SteyMenuItem('Disabled', disabled: true),
        SteyMenuItem('Beta', onPressed: () => chosen = 'b'),
        SteyMenuItem('Bravo', onPressed: () => chosen = 'br'),
      ], controller: controller);
      final nodes = tester
          .widgetList<MenuItemButton>(find.byType(MenuItemButton))
          .map((b) => b.focusNode!)
          .toList();
      nodes.first.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[2].hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(nodes.last.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(nodes.first.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB, character: 'b');
      await tester.pump();
      expect(nodes[2].hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB, character: 'b');
      await tester.pump();
      expect(nodes.last.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, 'br');
      expect(controller.isOpen, isFalse);
    },
  );

  testWidgets('Arrow keys open at first/last row and Escape returns focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SteyDropdownMenu(
          items: [
            SteyMenuItem('First', onPressed: () {}),
            SteyMenuItem('Last', onPressed: () {}),
          ],
          child: const Text('Actions'),
        ),
      ),
    );
    final trigger = tester.widget<SteyButton>(find.byType(SteyButton));
    trigger.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    var buttons = tester
        .widgetList<MenuItemButton>(find.byType(MenuItemButton))
        .toList();
    expect(buttons.last.focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    expect(trigger.focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    buttons = tester
        .widgetList<MenuItemButton>(find.byType(MenuItemButton))
        .toList();
    expect(buttons.first.focusNode!.hasFocus, isTrue);
  });

  testWidgets('Native submenu follows keyboard arrows in LTR and RTL', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(const SizedBox());
      await open(tester, [
        SteyMenuItem(
          'More',
          children: [SteyMenuItem('Nested', onPressed: () {})],
        ),
      ], direction: direction);
      tester
          .widget<MenuItemButton>(find.widgetWithText(MenuItemButton, 'More'))
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(
        direction == TextDirection.ltr
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowLeft,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();
      expect(find.text('Nested'), findsOneWidget, reason: direction.name);
      await tester.sendKeyEvent(
        direction == TextDirection.ltr
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight,
      );
      await tester.pumpAndSettle();
      expect(find.text('Nested'), findsNothing);
      expect(find.text('More'), findsOneWidget);
    }
  });

  testWidgets('Outside tap and system Back close without leaving the route', (
    tester,
  ) async {
    final controller = MenuController();
    await open(tester, [
      SteyMenuItem('Edit', onPressed: () {}),
    ], controller: controller);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    controller.open();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.text('Actions'), findsOneWidget);
  });

  testWidgets('Root gap and submenu top alignment match Kumo spacing', (
    tester,
  ) async {
    await open(tester, [
      SteyMenuItem('Edit', onPressed: () {}),
      SteyMenuItem(
        'More',
        children: [SteyMenuItem('Nested', onPressed: () {})],
      ),
    ]);
    final trigger = tester.getRect(find.byType(SteyButton));
    final first = tester.getRect(find.byType(MenuItemButton).first);
    expect(first.top - 6 - trigger.bottom, 8);
    final parent = tester.getRect(find.widgetWithText(MenuItemButton, 'More'));
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    final nested = tester.getRect(find.byType(MenuItemButton).last);
    expect(nested.top, parent.top);
    expect(nested.left - 6 - parent.right, 2);
  });

  testWidgets('Explicit popup width fills every row without shrinking labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SteyDropdownMenu(
          width: 224,
          items: [
            SteyMenuItem('複製', onPressed: () {}),
            SteyMenuItem('編集', icon: Icons.edit, onPressed: () {}),
          ],
          child: const Text('Actions'),
        ),
      ),
    );
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    for (final row in find.byType(MenuItemButton).evaluate()) {
      expect(tester.getSize(find.byWidget(row.widget)).width, 212);
    }
    expect(tester.getSize(find.text('複製')).width, greaterThan(20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Popup and flipped submenu remain within narrow safe bounds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, [
      SteyMenuItem(
        'More',
        children: [SteyMenuItem('Nested long label', onPressed: () {})],
      ),
    ], alignment: Alignment.bottomRight);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    for (final finder in [
      find.widgetWithText(MenuItemButton, 'More'),
      find.widgetWithText(MenuItemButton, 'Nested long label'),
    ]) {
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
      expect(rect.bottom, lessThanOrEqualTo(640));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Disabled triggers do not open and custom leading widgets keep their style',
    (tester) async {
      final controller = MenuController();
      await tester.pumpWidget(
        host(
          SteyDropdownMenu(
            disabled: true,
            controller: controller,
            items: [SteyMenuItem('Edit', onPressed: () {})],
            child: const Text('Actions'),
          ),
        ),
      );
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      await open(tester, [
        SteyMenuItem(
          'Custom',
          leading: const Icon(
            Icons.copy,
            key: ValueKey('custom'),
            color: Colors.red,
          ),
          onPressed: () {},
        ),
      ]);
      expect(
        tester.widget<Icon>(find.byKey(const ValueKey('custom'))).color,
        Colors.red,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('custom'))),
        const Size(16, 16),
      );
    },
  );
}
