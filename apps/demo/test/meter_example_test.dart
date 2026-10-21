import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/meter_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets(
    'Japanese meter example changes values, ranges, formatting and direction',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(child: MeterExample()),
          ),
        ),
      );
      await t.tap(find.text('使用量を25に変更'));
      await t.pumpAndSettle();
      expect(find.text('25%'), findsOneWidget);
      expect(t.widget<TextField>(find.byType(TextField)).controller!.text, '25');
      await t.enterText(find.byType(TextField), '12.5');
      await t.pumpAndSettle();
      expect(t.widget<SteyMeter>(find.byType(SteyMeter)).value, 12.5);
      await t.tap(find.text('使用量を25に変更'));
      await t.pumpAndSettle();
      await t.tap(find.text('値域を20〜80に変更'));
      await t.pumpAndSettle();
      expect(t.widget<SteyMeter>(find.byType(SteyMeter)).min, 20);
      await t.tap(find.text('数値を非表示'));
      await t.pumpAndSettle();
      expect(find.text('8%'), findsNothing);
      await t.tap(find.text('独自の表示値'));
      await t.pumpAndSettle();
      expect(find.text('25 / 80 GB'), findsOneWidget);
      for (final name in ['小数の書式', '色を変更', '長いラベル', '右から左へ']) {
        await t.tap(find.text(name));
        await t.pumpAndSettle();
      }
      expect(
        Directionality.of(t.element(find.byType(SteyMeter))),
        TextDirection.rtl,
      );
      await t.tap(find.text('上限を超える値'));
      await t.pumpAndSettle();
      expect(find.text('125 / 80 GB'), findsOneWidget);
      expect(t.widget<SteyMeter>(find.byType(SteyMeter)).clampedValue, 80);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'isolated meter sample updates target and preserves decimal format',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: Center(
              child: MeterSample({
                'value': '25',
                'target': '75',
                'format': 'decimal',
              }),
            ),
          ),
        ),
      );
      expect(find.text('25.0'), findsOneWidget);
      await t.tap(find.text('Change value'));
      await t.pumpAndSettle();
      expect(find.text('75.0'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
