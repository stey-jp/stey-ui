import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

import 'dropdown_test.dart' show host;

List<Opacity> surfaces(WidgetTester tester) => tester
    .widgetList<Opacity>(find.byType(Opacity))
    .where((widget) => widget.child is Transform)
    .toList();

Future<MenuController> setup(
  WidgetTester tester, {
  ValueChanged<bool>? onOpenChanged,
  VoidCallback? action,
  bool reduceMotion = false,
  Alignment alignment = Alignment.center,
  TextDirection direction = TextDirection.ltr,
}) async {
  final controller = MenuController();
  await tester.pumpWidget(
    host(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: SteyDropdownMenu(
          controller: controller,
          width: 224,
          onOpenChanged: onOpenChanged,
          items: [
            SteyMenuItem('Edit', onPressed: action ?? () {}),
            SteyMenuItem(
              'More',
              children: [SteyMenuItem('Nested', onPressed: action ?? () {})],
            ),
          ],
          child: const Text('Actions'),
        ),
      ),
      alignment: alignment,
      direction: direction,
    ),
  );
  return controller;
}

void main() {
  testWidgets(
    'Pointer scales and fades the entire surface for 150ms in both directions',
    (tester) async {
      final events = <bool>[];
      final controller = await setup(tester, onOpenChanged: events.add);
      await tester.tap(find.text('Actions'));
      await tester.pump();
      expect(surfaces(tester).single.opacity, 0);
      final transform = surfaces(tester).single.child! as Transform;
      expect(transform.transform.storage[0], closeTo(.95, .0001));
      await tester.pump(const Duration(milliseconds: 75));
      expect(
        surfaces(tester).single.opacity,
        closeTo(Curves.fastOutSlowIn.transform(.5), .0001),
      );
      await tester.pump(const Duration(milliseconds: 75));
      expect(surfaces(tester).single.opacity, 1);
      expect(controller.isOpen, isTrue);
      await tester.tap(find.text('Actions'));
      await tester.pump();
      expect(find.text('Edit'), findsOneWidget);
      expect(controller.isOpen, isTrue);
      expect(events, [true, false]);
      await tester.pump(const Duration(milliseconds: 75));
      expect(
        surfaces(tester).single.opacity,
        closeTo(1 - Curves.fastOutSlowIn.transform(.5), .0001),
      );
      await tester.pump(const Duration(milliseconds: 75));
      expect(surfaces(tester).single.opacity, 0);
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Edit'), findsNothing);
      expect(controller.isOpen, isFalse);
    },
  );

  testWidgets(
    'Closing content is mounted but cannot be selected or focused or announced',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var actions = 0;
      await setup(tester, action: () => actions++);
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.text('Edit'));
      await tester.tap(find.text('Edit'));
      await tester.pump();
      expect(actions, 1);
      expect(find.text('Edit'), findsOneWidget);
      expect(
        find.semantics.byPredicate(
          (node) => !node.isMergedIntoParent && node.label == 'Edit',
        ),
        findsNothing,
      );
      expect(
        tester.widget<SteyButton>(find.byType(SteyButton)).focusNode!.hasFocus,
        isTrue,
      );
      await tester.tapAt(rect.center);
      await tester.pumpAndSettle();
      expect(actions, 1);
      semantics.dispose();
    },
  );

  testWidgets(
    'A trigger can reverse closing without a stale completion hiding the reopened menu',
    (tester) async {
      final controller = await setup(tester);
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actions'));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(surfaces(tester).single.opacity, 1);
      expect(find.text('Edit'), findsOneWidget);
    },
  );

  testWidgets(
    'Keyboard Enter and Space skip motion, ArrowDown animates, Escape dismisses instantly',
    (tester) async {
      await setup(tester);
      final trigger = tester.widget<SteyButton>(find.byType(SteyButton));
      for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
        trigger.focusNode!.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(surfaces(tester).single.opacity, 1, reason: key.keyLabel);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(find.text('Edit'), findsNothing);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(surfaces(tester).single.opacity, 0);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MenuItemButton>(find.widgetWithText(MenuItemButton, 'Edit'))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(find.text('Edit'), findsNothing);
    },
  );

  testWidgets(
    'Nested surfaces animate with their parent and are all inert while closing',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await setup(tester);
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pump();
      await tester.pump();
      expect(surfaces(tester).map((s) => s.opacity), [1, 0]);
      await tester.pump(const Duration(milliseconds: 75));
      expect(surfaces(tester).last.opacity, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actions'));
      await tester.pump();
      expect(find.text('Nested'), findsOneWidget);
      expect(
        find.semantics.byPredicate(
          (node) => !node.isMergedIntoParent && node.label == 'Nested',
        ),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(find.text('Nested'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'Programmatic close is instant and disposal cancels outstanding transitions',
    (tester) async {
      final controller = await setup(tester);
      controller.open();
      await tester.pumpAndSettle();
      controller.close();
      await tester.pump();
      expect(find.text('Edit'), findsNothing);
      controller.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Explicit reduced motion does not shorten the requested transition',
    (tester) async {
      await setup(tester, reduceMotion: true);
      await tester.tap(find.text('Actions'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(
        surfaces(tester).single.opacity,
        closeTo(Curves.fastOutSlowIn.transform(.5), .0001),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Flipped and RTL root surfaces grow from the centered anchor', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(const SizedBox());
      await setup(
        tester,
        direction: direction,
        alignment: Alignment.bottomCenter,
      );
      final trigger = tester.getRect(find.byType(SteyButton));
      await tester.tap(find.text('Actions'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      final transform = surfaces(tester).single.child! as Transform;
      expect(transform.origin!.dy, trigger.top);
      expect(transform.origin!.dx, trigger.center.dx);
      await tester.pumpAndSettle();
    }
  });
  testWidgets(
    'An open-change callback can reopen without a stale close request winning',
    (tester) async {
      late MenuController controller;
      controller = await setup(
        tester,
        onOpenChanged: (value) {
          if (!value) controller.open();
        },
      );
      controller.open();
      await tester.pumpAndSettle();
      controller.close();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(surfaces(tester).single.opacity, 1);
      expect(find.text('Edit'), findsOneWidget);
    },
  );
  testWidgets(
    'Pointer-opened menus receive Escape without requiring an item click',
    (tester) async {
      await setup(tester);
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Nested'), findsNothing);
      expect(find.text('More'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('More'), findsNothing);
    },
  );
  testWidgets(
    'Click cancels a pending hover timer rather than restarting submenu motion',
    (tester) async {
      await setup(tester);
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('More')));
      await tester.pump(const Duration(milliseconds: 50));
      await mouse.down(tester.getCenter(find.text('More')));
      await mouse.up();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(
        surfaces(tester).last.opacity,
        closeTo(Curves.fastOutSlowIn.transform(.5), .0001),
      );
      await tester.pump(const Duration(milliseconds: 75));
      expect(surfaces(tester).last.opacity, 1);
      await mouse.removePointer();
    },
  );
}
