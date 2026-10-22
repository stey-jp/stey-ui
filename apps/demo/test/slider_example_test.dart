import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/slider_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets(
    'Japanese slider example toggles range, small, decimal, gap, disabled, RTL and cancel',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(child: SliderExample()),
          ),
        ),
      );
      for (final name in [
        '範囲を選択',
        '小さいサイズ',
        '小数を選択',
        'つまみの間隔を確保',
        '右から左へ',
        '変更を取り消す',
      ]) {
        await t.tap(find.text(name));
        await t.pump();
      }
      final slider = t.widget<SteySlider>(find.byType(SteySlider));
      expect(slider.isRange, true);
      expect(slider.size, SteySliderSize.sm);
      expect(slider.effectiveStep, .5);
      expect(slider.minStepsBetweenValues, 10);
      expect(
        Directionality.of(t.element(find.byType(SteySlider))),
        TextDirection.rtl,
      );
      await t.tap(find.text('無効にする'));
      await t.pump();
      expect(t.widget<SteySlider>(find.byType(SteySlider)).disabled, true);
      await t.tap(find.text('スライダーの次の操作'));
      await t.pump();
      expect(find.text('次の操作：1回'), findsOneWidget);
      await t.tap(find.text('値をリセット'));
      await t.pump();
      expect(find.text('変更：0回・確定：0回'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'isolated controlled and uncontrolled samples expose range values and neighboring action',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: Center(
              child: SliderSample({'values': '25,75', 'uncontrolled': 'true'}),
            ),
          ),
        ),
      );
      expect(t.widget<SteySlider>(find.byType(SteySlider)).controlled, false);
      await t.tap(find.text('After slider'));
      await t.pump();
      expect(find.textContaining('"calls":1'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
