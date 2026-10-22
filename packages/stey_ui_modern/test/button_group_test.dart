import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: SteyTheme.material(Brightness.light),
      home: Scaffold(
        body: Center(
          child: Directionality(textDirection: direction, child: child),
        ),
      ),
    );
BorderRadius radius(WidgetTester tester, String label) {
  final button = tester.widget<TextButton>(
    find.widgetWithText(TextButton, label),
  );
  return (button.style!.shape!.resolve({})! as RoundedRectangleBorder)
      .borderRadius
      .resolve(TextDirection.ltr);
}

void main() {
  testWidgets(
    'One pixel seams and only the two outside corners remain rounded',
    (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          host(
            SteyButtonGroup(
              semanticLabel: 'Actions',
              children: [
                for (final text in ['One', 'Two', 'Three'])
                  SteyButton(onPressed: () {}, child: Text(text)),
              ],
            ),
            direction: direction,
          ),
        );
        final boxes = [
          for (final text in ['One', 'Two', 'Three'])
            tester.getRect(find.widgetWithText(TextButton, text)),
        ];
        if (direction == TextDirection.ltr) {
          expect(boxes[1].left, boxes[0].right - 1);
          expect(boxes[2].left, boxes[1].right - 1);
          expect(radius(tester, 'One').topLeft.x, greaterThan(0));
          expect(radius(tester, 'One').topRight, Radius.zero);
          expect(radius(tester, 'Three').topRight.x, greaterThan(0));
        } else {
          expect(boxes[1].right, boxes[0].left + 1);
          expect(boxes[2].right, boxes[1].left + 1);
          expect(radius(tester, 'One').topRight.x, greaterThan(0));
          expect(radius(tester, 'One').topLeft, Radius.zero);
          expect(radius(tester, 'Three').topLeft.x, greaterThan(0));
        }
        expect(radius(tester, 'Two'), BorderRadius.zero);
        expect(
          tester.getSize(find.byType(SteyButtonGroup)).width,
          boxes.fold(0.0, (v, r) => v + r.width) - 2,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Single, empty, and vertical groups preserve their outer shape', (
    tester,
  ) async {
    await tester.pumpWidget(host(const SteyButtonGroup(children: [])));
    expect(tester.getSize(find.byType(SteyButtonGroup)), Size.zero);
    await tester.pumpWidget(
      host(
        SteyButtonGroup(
          children: [SteyButton(onPressed: () {}, child: const Text('One'))],
        ),
      ),
    );
    expect(radius(tester, 'One').topLeft.x, greaterThan(0));
    expect(radius(tester, 'One').topRight.x, greaterThan(0));
    await tester.pumpWidget(
      host(
        SteyButtonGroup(
          vertical: true,
          children: [
            SteyButton(onPressed: () {}, child: const Text('One')),
            SteyButton(onPressed: () {}, child: const Text('Longer two')),
          ],
        ),
      ),
    );
    final a = tester.getRect(find.widgetWithText(TextButton, 'One')),
        b = tester.getRect(find.widgetWithText(TextButton, 'Longer two'));
    expect(b.top, a.bottom - 1);
    expect(a.width, b.width);
    expect(radius(tester, 'One').bottomLeft, Radius.zero);
    expect(radius(tester, 'Longer two').topRight, Radius.zero);
  });

  testWidgets(
    'Tooltip keeps logical position while inline link retains no button chrome',
    (tester) async {
      await tester.pumpWidget(
        host(
          SteyButtonGroup(
            children: [
              Tooltip(
                message: 'First action',
                child: SteyButton(onPressed: () {}, child: const Text('One')),
              ),
              SteyLink(onPressed: () {}, child: const Text('Two')),
              SteyButton(onPressed: () {}, child: const Text('Three')),
            ],
          ),
        ),
      );
      expect(radius(tester, 'One').topRight, Radius.zero);
      expect(find.widgetWithText(TextButton, 'Two'), findsNothing);
      expect(tester.getSize(find.text('Two')).height, lessThan(36));
      expect(radius(tester, 'Three').topLeft, Radius.zero);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Focused child paints above the shared seam and Tab order is unchanged',
    (tester) async {
      final first = FocusNode(), last = FocusNode();
      var one = 0, two = 0;
      await tester.pumpWidget(
        host(
          SteyButtonGroup(
            children: [
              SteyButton(
                focusNode: first,
                onPressed: () => one++,
                child: const Text('One'),
              ),
              SteyButton(
                focusNode: last,
                onPressed: () => two++,
                child: const Text('Two'),
              ),
            ],
          ),
        ),
      );
      first.requestFocus();
      await tester.pump();
      final shared =
          tester.getRect(find.widgetWithText(TextButton, 'Two')).centerLeft +
          const Offset(.25, 0);
      await tester.tapAt(shared);
      await tester.pump();
      expect(one, 1);
      expect(two, 0);
      first.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(last.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(two, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      first.dispose();
      last.dispose();
    },
  );

  testWidgets('Disabled and loading controls remain inert inside a group', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        SteyButtonGroup(
          children: [
            const SteyButton(child: Text('Disabled')),
            SteyButton(
              onPressed: () => calls++,
              loading: true,
              child: const Text('Loading'),
            ),
            SteyButton(onPressed: () => calls++, child: const Text('Ready')),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Disabled'));
    await tester.tap(find.text('Loading'));
    expect(calls, 0);
    await tester.tap(find.text('Ready'));
    expect(calls, 1);
  });
}
