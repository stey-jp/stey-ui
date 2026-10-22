import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';
import 'package:stey_ui_demo/text_example.dart';

Widget host() => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: const Scaffold(body: SingleChildScrollView(child: TextExample())),
);
void main() {
  testWidgets(
    'Japanese typography controls change variant size and heading separately',
    (t) async {
      await t.pumpWidget(host());
      for (final label in ['文字の種類を変更', '文字サイズを変更', '見出しレベルを変更']) {
        await t.tap(find.bySemanticsLabel(RegExp('$label\$')));
        await t.pump();
      }
      final preview = t.widgetList<SteyText>(find.byType(SteyText)).first;
      expect(preview.variant, SteyTextVariant.secondary);
      expect(preview.size, SteyTextSize.lg);
      expect(preview.headingLevel, 1);
    },
  );
  testWidgets(
    'Japanese rich truncation RTL and scaling controls retain neighbor action',
    (t) async {
      await t.pumpWidget(host());
      for (final label in ['本文を中太にする', '長文を省略', '幅を狭くする', '右から左へ', '一部を強調する']) {
        await t.tap(find.text(label));
        await t.pump();
      }
      await t.tap(find.bySemanticsLabel(RegExp('拡大率を変更\$')));
      await t.pump();
      final preview = t.widgetList<SteyText>(find.byType(SteyText)).first;
      expect(preview.bold, true);
      expect(preview.truncate, true);
      expect(preview.textSpan, isNotNull);
      await t.tap(find.text('文字の次の操作'));
      await t.pump();
      expect(find.text('次の操作：1回'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
