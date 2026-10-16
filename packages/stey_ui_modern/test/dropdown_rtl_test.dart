import 'dart:io';
import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

import 'dropdown_test.dart' show host;

Future<void> showMenu(
  WidgetTester tester,
  List<SteyMenuItem> items, {
  TextDirection direction = TextDirection.rtl,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    host(
      MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: SteyDropdownMenu(
          width: 224,
          items: items,
          child: const Text('Actions'),
        ),
      ),
      direction: direction,
    ),
  );
  await tester.tap(find.text('Actions'));
  await tester.pumpAndSettle();
}

Rect row(WidgetTester tester, String text) =>
    tester.getRect(find.widgetWithText(MenuItemButton, text));

void main() {
  setUpAll(() async {
    final font = FontLoader('packages/stey_ui_modern/Inter');
    final root = Directory('packages/stey_ui_modern/assets/fonts').existsSync()
        ? 'packages/stey_ui_modern/assets/fonts'
        : 'assets/fonts';
    font.addFont(
      Future.value(
        ByteData.sublistView(File('$root/Inter-Regular.ttf').readAsBytesSync()),
      ),
    );
    font.addFont(
      Future.value(
        ByteData.sublistView(
          File('$root/Inter-SemiBold.ttf').readAsBytesSync(),
        ),
      ),
    );
    await font.load();
  });

  testWidgets('Physical inset and group padding stay on the left in RTL', (
    tester,
  ) async {
    await showMenu(tester, [
      SteyMenuGroup(
        'Project',
        children: [
          SteyMenuItem('Icon', icon: Icons.copy, onPressed: () {}),
          SteyMenuItem('Plain', onPressed: () {}),
          SteyMenuItem('Explicit', inset: true, onPressed: () {}),
        ],
      ),
    ]);
    final bounds = row(tester, 'Plain');
    for (final label in ['Project', 'Plain', 'Explicit']) {
      expect(
        bounds.right - tester.getRect(find.text(label)).right,
        closeTo(8, .001),
      );
    }
    final button = tester.widget<MenuItemButton>(
      find.widgetWithText(MenuItemButton, 'Explicit'),
    );
    expect(
      button.style!.padding!.resolve({})!.resolve(TextDirection.rtl),
      const EdgeInsets.fromLTRB(32, 6, 8, 6),
    );
    expect(
      row(tester, 'Icon').right - tester.getRect(find.byIcon(Icons.copy)).right,
      8,
    );
    expect(
      tester.getRect(find.byIcon(Icons.copy)).left -
          tester.getRect(find.text('Icon')).right,
      8,
    );
  });

  testWidgets(
    'Checked mark stays in the physical left slot in both directions',
    (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(const SizedBox());
        await showMenu(tester, [
          SteyMenuCheckboxItem('Alerts', value: true, onChanged: (_) {}),
        ], direction: direction);
        final bounds = row(tester, 'Alerts'),
            check = tester.getRect(find.byIcon(Icons.check));
        expect(check.left - bounds.left, 9);
        expect(check.width, 12);
        expect(check.center.dy, bounds.center.dy);
        if (direction == TextDirection.rtl) {
          expect(bounds.right - tester.getRect(find.text('Alerts')).right, 8);
        } else {
          expect(tester.getRect(find.text('Alerts')).left - bounds.left, 32);
        }
      }
    },
  );

  testWidgets(
    'Shortcut and radio indicator follow physical auto margins in each direction',
    (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(const SizedBox());
        await showMenu(tester, [
          SteyMenuItem('Edit', shortcut: '⌘E', onPressed: () {}),
          SteyMenuRadioItem(
            'Production',
            value: 1,
            groupValue: 1,
            onChanged: (_) {},
          ),
        ], direction: direction);
        final edit = tester.getRect(find.text('Edit')),
            shortcut = tester.getRect(find.text('⌘E')),
            check = tester.getRect(find.byIcon(Icons.check)),
            production = tester.getRect(find.text('Production'));
        if (direction == TextDirection.rtl) {
          expect(edit.left - shortcut.right, 8);
          expect(production.left - check.right, 8);
          expect(row(tester, 'Edit').right - edit.right, 8);
        } else {
          expect(row(tester, 'Edit').right - shortcut.right, 8);
          expect(row(tester, 'Production').right - check.right, 8);
        }
      }
    },
  );

  testWidgets(
    'Selected ordinary items keep the indicator adjacent rather than auto aligning',
    (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(const SizedBox());
        await showMenu(tester, [
          SteyMenuItem('Selected', checked: true, onPressed: () {}),
        ], direction: direction);
        final text = tester.getRect(find.text('Selected')),
            indicator = tester.getRect(find.byIcon(Icons.check));
        expect(
          direction == TextDirection.ltr
              ? indicator.left - text.right
              : text.left - indicator.right,
          8,
        );
      }
    },
  );

  testWidgets(
    'RTL submenu keeps the right caret and opens with the left arrow',
    (tester) async {
      await showMenu(tester, [
        SteyMenuItem(
          'More',
          children: [SteyMenuItem('Nested', onPressed: () {})],
        ),
      ]);
      final parent = tester.widget<MenuItemButton>(
        find.widgetWithText(MenuItemButton, 'More'),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(
        tester.getRect(find.text('More')).left -
            tester.getRect(find.byIcon(Icons.chevron_right)).right,
        8,
      );
      parent.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Nested'), findsOneWidget);
      expect(row(tester, 'Nested').right, lessThan(row(tester, 'More').left));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Nested'), findsNothing);
      expect(parent.focusNode!.hasFocus, isTrue);
    },
  );

  testWidgets(
    'RTL controlled selection keeps labels and semantic states after rebuilding',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var alerts = true, selected = 1, changes = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, setState) => SteyDropdownMenu(
              width: 224,
              items: [
                SteyMenuCheckboxItem(
                  'Alerts',
                  value: alerts,
                  closeOnActivate: false,
                  onChanged: (v) => setState(() {
                    alerts = v;
                    changes++;
                  }),
                ),
                for (final id in [1, 2])
                  SteyMenuRadioItem(
                    'Plan $id',
                    value: id,
                    groupValue: selected,
                    closeOnActivate: false,
                    onChanged: (v) => setState(() {
                      selected = v;
                      changes++;
                    }),
                  ),
              ],
              child: const Text('Actions'),
            ),
          ),
          direction: TextDirection.rtl,
        ),
      );
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan 2'));
      await tester.pumpAndSettle();
      expect([alerts, selected, changes], [false, 2, 2]);
      expect(
        tester
            .getSemantics(find.text('Alerts'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isFalse,
      );
      expect(
        tester
            .getSemantics(find.text('Plan 2'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
      expect(
        tester.getRect(find.text('Plan 2')).left -
            tester.getRect(find.byIcon(Icons.check)).right,
        8,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'Scaled long RTL labels preserve child direction and fit the row',
    (tester) async {
      const childKey = ValueKey('rich-label');
      await showMenu(tester, [
        SteyMenuItem(
          'Long',
          shortcut: '⌘E',
          child: const Text(
            'Long content that should stay inside the menu',
            key: childKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onPressed: () {},
        ),
      ], textScaler: const TextScaler.linear(2));
      expect(
        Directionality.of(tester.element(find.byKey(childKey))),
        TextDirection.rtl,
      );
      final bounds = tester.getRect(find.byType(MenuItemButton)),
          text = tester.getRect(find.byKey(childKey));
      expect(text.left, greaterThanOrEqualTo(bounds.left));
      expect(text.right, lessThanOrEqualTo(bounds.right));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'RTL return key closes a pointer submenu even while focus is still on its parent',
    (tester) async {
      await showMenu(tester, [
        SteyMenuItem(
          'More',
          children: [SteyMenuItem('Nested', onPressed: () {})],
        ),
      ]);
      final parent = tester.widget<MenuItemButton>(
        find.widgetWithText(MenuItemButton, 'More'),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      parent.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Nested'), findsNothing);
      expect(find.text('More'), findsOneWidget);
      expect(parent.focusNode!.hasFocus, isTrue);
    },
  );
}
