import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Future<void> showMenu(
  WidgetTester tester, {
  required Size viewport,
  required TextDirection direction,
  int children = 3,
  int before = 2,
  Alignment alignment = Alignment.center,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(
    left: padding.left,
    top: padding.top,
    right: padding.right,
    bottom: padding.bottom,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  await tester.pumpWidget(
    MaterialApp(
      theme: SteyTheme.material(Brightness.light),
      home: SteyTheme(
        brightness: Brightness.light,
        child: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(size: viewport, padding: padding),
            child: Directionality(
              textDirection: direction,
              child: Align(
                alignment: alignment,
                child: SteyDropdownMenu(
                  width: 224,
                  items: [
                    for (var i = 0; i < before; i++)
                      SteyMenuItem('Item $i', onPressed: () {}),
                    SteyMenuItem(
                      'More',
                      children: [
                        for (var i = 0; i < children; i++)
                          SteyMenuItem('Nested $i', onPressed: () {}),
                      ],
                    ),
                  ],
                  child: const Text('Actions'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Actions'));
  await tester.pumpAndSettle();
}

Finder row(String label) => find.widgetWithText(MenuItemButton, label);
Rect surface(WidgetTester tester, String label) =>
    tester.getRect(row(label)).inflate(6);

void main() {
  testWidgets('Root measures rich content before choosing the available side', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: SteyTheme.material(Brightness.light),
        home: SteyTheme(
          brightness: Brightness.light,
          child: Scaffold(
            body: Align(
              alignment: const Alignment(0, .6),
              child: SteyDropdownMenu(
                items: [
                  SteyMenuItem(
                    'Rich content',
                    child: const SizedBox(width: 100, height: 300),
                    onPressed: () {},
                  ),
                ],
                child: const Text('Actions'),
              ),
            ),
          ),
        ),
      ),
    );
    final trigger = tester.getRect(find.byType(SteyButton));
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    final popup = tester.getRect(find.byType(SingleChildScrollView));
    expect(popup.height, greaterThan(300));
    expect(trigger.top - popup.bottom, 8);
    expect(tester.takeException(), isNull);
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'Edge $direction submenu reverses sideways before trying below',
      (tester) async {
        await showMenu(
          tester,
          viewport: const Size(800, 800),
          direction: direction,
          alignment: direction == TextDirection.ltr
              ? Alignment.centerRight
              : Alignment.centerLeft,
        );
        final anchor = tester.getRect(row('More'));
        await tester.tap(find.text('More'));
        await tester.pumpAndSettle();
        final popup = surface(tester, 'Nested 0');
        expect(popup.top, anchor.top - 6);
        expect(
          direction == TextDirection.ltr
              ? anchor.left - popup.right
              : popup.left - anchor.right,
          2,
        );
      },
    );

    testWidgets('Narrow $direction submenu falls below with an 8px gap', (
      tester,
    ) async {
      await showMenu(
        tester,
        viewport: const Size(320, 800),
        direction: direction,
      );
      final anchor = tester.getRect(row('More'));
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      final popup = surface(tester, 'Nested 0');
      expect(popup.top - anchor.bottom, 8);
      expect(
        direction == TextDirection.ltr ? popup.left : popup.right,
        direction == TextDirection.ltr ? anchor.left : anchor.right,
      );
      await tester.sendKeyEvent(
        direction == TextDirection.ltr
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight,
      );
      await tester.pumpAndSettle();
      expect(find.text('Nested 0'), findsNothing);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('Long narrow $direction submenu falls above', (tester) async {
      await showMenu(
        tester,
        viewport: const Size(320, 800),
        direction: direction,
        children: 10,
      );
      final anchor = tester.getRect(row('More'));
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      final popupTop = surface(tester, 'Nested 0').top;
      final popupBottom = tester.getRect(row('Nested 9')).bottom + 6;
      expect(anchor.top - popupBottom, 8);
      expect(popupTop, greaterThanOrEqualTo(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Wide $direction submenu retains its side and flips alignment',
      (tester) async {
        await showMenu(
          tester,
          viewport: const Size(1200, 600),
          direction: direction,
          children: 10,
        );
        final anchor = tester.getRect(row('More'));
        await tester.tap(find.text('More'));
        await tester.pumpAndSettle();
        final first = surface(tester, 'Nested 0');
        final bottom = tester.getRect(row('Nested 9')).bottom + 6;
        expect(bottom - anchor.bottom, 6);
        expect(first.top, greaterThanOrEqualTo(5));
        expect(
          direction == TextDirection.ltr
              ? first.left - anchor.right
              : anchor.left - first.right,
          2,
        );
      },
    );

    testWidgets(
      'Root $direction scrolls within the chosen side of its trigger',
      (tester) async {
        await showMenu(
          tester,
          viewport: const Size(320, 400),
          direction: direction,
          before: 20,
          alignment: Alignment.topCenter,
        );
        final trigger = tester.getRect(find.byType(SteyButton));
        final scroll = find.byType(SingleChildScrollView).first;
        final box = tester.getRect(scroll);
        expect(box.top - trigger.bottom, 8);
        expect(box.bottom, 395);
        await tester.drag(scroll, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(row('More').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Collision shift respects display padding rather than overlapping it',
    (tester) async {
      await showMenu(
        tester,
        viewport: const Size(320, 800),
        direction: TextDirection.ltr,
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.fromLTRB(20, 30, 25, 40),
      );
      final root = tester.getRect(find.byType(SingleChildScrollView).first);
      expect(root.left, 20);
      expect(root.top, greaterThanOrEqualTo(30));
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      final nested = surface(tester, 'Nested 0');
      expect(nested.left, greaterThanOrEqualTo(20));
      expect(nested.right, lessThanOrEqualTo(295));
    },
  );
}
