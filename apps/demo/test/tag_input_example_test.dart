import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

import 'package:stey_ui_demo/tag_input_example.dart';

void main() {
  Widget host() => MaterialApp(
    locale: const Locale('ja'),
    supportedLocales: const [Locale('ja')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: SteyTheme.material(Brightness.light),
    home: const Scaffold(body: SingleChildScrollView(child: TagInputExample())),
  );
  testWidgets('Japanese demo adds and removes tags', (t) async {
    await t.pumpWidget(host());
    await t.enterText(find.byType(TextField), '日本語');
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(find.textContaining('確定済み：production、staging、日本語'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('日本語を削除'));
    await t.pump();
    expect(find.text('日本語'), findsNothing);
  });
  testWidgets('Japanese limit and validation feedback retain rejected draft', (
    t,
  ) async {
    await t.pumpWidget(host());
    await t.tap(find.text('上限3個'));
    await t.pump();
    await t.enterText(find.byType(TextField), 'third,fourth');
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(find.text('タグは3個までです。'), findsOneWidget);
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      'fourth',
    );
  });
  testWidgets('Japanese readOnly disables removal while preserving tags', (
    t,
  ) async {
    await t.pumpWidget(host());
    await t.tap(find.text('読み取り専用'));
    await t.pump();
    expect(t.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    final buttons = t
        .widgetList<SteyButton>(find.byType(SteyButton))
        .where((b) => b.semanticLabel?.endsWith('を削除') == true);
    expect(buttons.every((b) => b.onPressed == null), isTrue);
  });
}
