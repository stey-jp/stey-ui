import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';
import 'package:stey_ui_demo/label_example.dart';

Widget host() => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: const Scaffold(body: SingleChildScrollView(child: LabelExample())),
);
void main() {
  testWidgets(
    'Japanese optional rich and inherited content retain editor focus association',
    (t) async {
      await t.pumpWidget(host());
      for (final label in ['任意の表示', '装飾付きの内容', '親の文字スタイルを継承']) {
        await t.tap(find.text(label));
        await t.pump();
      }
      final preview = t.widget<SteyLabel>(
        find.byWidgetPredicate(
          (w) => w is SteyLabel && w.controlFocusNode != null,
        ),
      );
      expect(preview.showOptional, true);
      expect(preview.asContent, true);
      expect(preview.child, isNotNull);
      await t.tap(find.text('プロジェクト名').first);
      await t.pump();
      expect(preview.controlFocusNode!.hasFocus, true);
      expect(find.text('（入力を省略可）'), findsOneWidget);
    },
  );
  testWidgets(
    'Japanese help narrow RTL and scale controls keep neighbor usable',
    (t) async {
      await t.pumpWidget(host());
      for (final label in ['幅を狭くする', '右から左へ']) {
        await t.tap(find.text(label));
        await t.pump();
      }
      await t.tap(find.bySemanticsLabel(RegExp(r'文字の拡大率を変更$')));
      await t.pump();
      await t.ensureVisible(find.text('ラベルの次の操作'));
      await t.tap(find.text('ラベルの次の操作'));
      await t.pump();
      expect(find.text('次の操作：1回'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
