import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/input_group_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
void main() {
  testWidgets('Japanese group switches modes without losing edited text', (
    t,
  ) async {
    await t.pumpWidget(host(const InputGroupExample()));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'ワーカー');
    await t.pump();
    for (var i = 0; i < 3; i++) {
      await t.tap(find.bySemanticsLabel('枠の形式を変更'));
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        'ワーカー',
      );
    }
    expect(find.text('入力値：ワーカー'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('Japanese clear, disabled, error and neighboring action work', (
    t,
  ) async {
    await t.pumpWidget(host(const InputGroupExample()));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('入力を消去'));
    await t.pumpAndSettle();
    expect(find.text('入力値：未入力'), findsOneWidget);
    for (final name in ['エラーを表示', '入力を無効にする']) {
      await t.tap(find.text(name));
      await t.pumpAndSettle();
    }
    expect(t.widget<TextField>(find.byType(TextField)).enabled, false);
    expect(find.text('この名前は使用できません。'), findsOneWidget);
    await t.tap(find.text('入力欄の次の操作'));
    await t.pump();
    expect(find.text('次の操作：1回'), findsOneWidget);
  });
  testWidgets('isolated hybrid reports clear and action separately', (t) async {
    await t.pumpWidget(host(const InputGroupSample({'layout': 'hybrid'})));
    await t.pumpAndSettle();
    await t.tap(find.text('Go'));
    await t.pump();
    expect(find.textContaining('"actions":1'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Clear'));
    await t.pumpAndSettle();
    expect(t.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(find.textContaining('"clears":1'), findsOneWidget);
    expect(find.textContaining('"calls":0'), findsOneWidget);
  });
}
