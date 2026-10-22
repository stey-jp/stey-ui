import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/input_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
void main() {
  testWidgets(
    'Japanese input labels localize optional status and help action',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: SteyTheme.material(Brightness.light),
          home: Builder(
            builder: (context) => Localizations.override(
              context: context,
              locale: const Locale('ja'),
              child: const Scaffold(
                body: SteyInput(
                  label: '名前',
                  required: false,
                  labelTooltip: '説明',
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('名前 （任意）'), findsOneWidget);
      expect(find.bySemanticsLabel('詳しい情報'), findsOneWidget);
    },
  );

  testWidgets('Japanese input controls retain value and change area sizing', (
    t,
  ) async {
    await t.pumpWidget(host(const InputExample()));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'プロジェクト');
    await t.pump();
    for (final name in [
      'エラーを表示',
      '制御モード',
      '文字を隠す',
      '複数行を自動調整',
      '右から左へ',
      '任意項目を表示',
    ]) {
      await t.tap(find.text(name));
      await t.pumpAndSettle();
    }
    final fields = t.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.first.controller!.text, 'プロジェクト');
    expect(fields.first.obscureText, true);
    expect(fields.last.minLines, 1);
    expect(fields.last.maxLines, 4);
    expect(find.text('この名前は使用できません。'), findsOneWidget);
    expect(find.text('入力値：（非表示）'), findsOneWidget);
    await t.tap(find.text('入力欄の次の操作'));
    await t.pump();
    expect(find.text('次の操作：1回'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'isolated frozen input reports attempted changes while retaining its value',
    (t) async {
      await t.pumpWidget(
        host(
          const InputSample({
            'controlled': 'true',
            'frozen': 'true',
            'value': 'fixed',
            'area': 'true',
            'auto': 'true',
            'maxRows': '3',
          }),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'attempt');
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        'fixed',
      );
      expect(find.textContaining('"calls":1'), findsOneWidget);
      await t.tap(find.text('After input'));
      await t.pump();
      expect(find.textContaining('"after":1'), findsOneWidget);
    },
  );
}
