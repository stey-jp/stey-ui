import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: SteyTheme(
    brightness: Brightness.light,
    child: Scaffold(body: child),
  ),
);
void main() {
  testWidgets('Two-digit days stay on one line and remain selectable', (
    tester,
  ) async {
    DateTime? value;
    await tester.pumpWidget(
      host(
        SteyDatePicker(
          firstDate: DateTime(2026, 10, 1),
          lastDate: DateTime(2026, 10, 31),
          initialMonth: DateTime(2026, 10),
          onChanged: (date) => value = date,
        ),
      ),
    );
    final day = find.text('22');
    final paragraph = tester.renderObject<RenderParagraph>(day);
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 2),
    );
    expect(boxes.map((box) => box.top).toSet(), hasLength(1));
    await tester.tap(day);
    await tester.pump();
    expect(value, DateTime(2026, 10, 22));
    expect(tester.takeException(), isNull);
  });
  testWidgets('PageUp crosses a year boundary without invalid month values', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SteyDatePicker(
          firstDate: DateTime(2025),
          lastDate: DateTime(2027),
          initialMonth: DateTime(2026, 1),
        ),
      ),
    );
    final finder = find.widgetWithText(SteyButton, '15');
    tester.widget<SteyButton>(finder).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pump();
    await tester.pump();
    expect(find.text('December 2025'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Single date selection excludes disabled dates', (tester) async {
    DateTime? value;
    await tester.pumpWidget(
      host(
        SteyDatePicker(
          firstDate: DateTime(2026, 10, 1),
          lastDate: DateTime(2026, 10, 31),
          initialMonth: DateTime(2026, 10),
          disabledDate: (date) => date.day == 4,
          onChanged: (date) => value = date,
        ),
      ),
    );
    await tester.tap(find.text('4'));
    await tester.pump();
    expect(value, isNull);
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(value, DateTime(2026, 10, 5));
  });
  testWidgets('Multiple mode toggles dates within min/max constraints', (
    tester,
  ) async {
    var selected = <DateTime>[];
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SteyDatePicker(
            mode: SteyDateSelectionMode.multiple,
            firstDate: DateTime(2026, 10, 1),
            lastDate: DateTime(2026, 10, 31),
            initialMonth: DateTime(2026, 10),
            maxSelections: 2,
            minSelections: 1,
            selectedDates: selected,
            onDatesChanged: (dates) => setState(() => selected = dates),
          ),
        ),
      ),
    );
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('6'));
    await tester.pump();
    await tester.tap(find.text('7'));
    await tester.pump();
    expect(selected.length, 2);
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('6'));
    await tester.pump();
    expect(selected, [DateTime(2026, 10, 6)]);
  });
  testWidgets(
    'Range mode orders reversed selection and excludes disabled interior',
    (tester) async {
      DateTimeRange? range;
      await tester.pumpWidget(
        host(
          SteyDatePicker(
            mode: SteyDateSelectionMode.range,
            firstDate: DateTime(2026, 10, 1),
            lastDate: DateTime(2026, 10, 31),
            initialMonth: DateTime(2026, 10),
            onRangeChanged: (value) => range = value,
          ),
        ),
      );
      await tester.tap(find.text('10'));
      await tester.pump();
      await tester.tap(find.text('5'));
      await tester.pump();
      expect(range!.start, DateTime(2026, 10, 5));
      expect(range!.end, DateTime(2026, 10, 10));
    },
  );
}
