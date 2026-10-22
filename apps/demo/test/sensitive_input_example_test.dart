import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/sensitive_input_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  locale: const Locale('ja'),
  supportedLocales: const [Locale('ja'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
void main() {
  testWidgets(
    'Japanese demo reveals, edits and hides without exposing a second copy of the value',
    (t) async {
      await t.pumpWidget(host(const SensitiveInputExample()));
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('APIトークン、非表示。'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '秘密の値');
      await t.pump();
      expect(find.text('文字数：4文字／変更：1回／コピー：0回'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == '秘密の値'),
        findsNothing,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(t.widget<TextField>(find.byType(TextField)).obscureText, true);
      for (final name in ['エラーを表示', '右から左へ', '任意項目を表示', '制御モード']) {
        await t.tap(find.text(name));
        await t.pumpAndSettle();
      }
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        '秘密の値',
      );
      expect(find.text('この値は使用できません。'), findsOneWidget);
    },
  );
  testWidgets(
    'Japanese copy callback and reset/empty/disabled/neighbor controls work',
    (t) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
      await t.pumpWidget(host(const SensitiveInputExample()));
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('コピー'));
      await t.pumpAndSettle();
      expect(find.text('文字数：15文字／変更：0回／コピー：1回'), findsOneWidget);
      await t.tap(find.text('空欄にする'));
      await t.pumpAndSettle();
      expect(t.widget<TextField>(find.byType(TextField)).controller!.text, '');
      await t.tap(find.text('サンプル値を再設定'));
      await t.pumpAndSettle();
      await t.tap(find.text('入力を無効にする'));
      await t.pumpAndSettle();
      expect(t.widget<TextField>(find.byType(TextField)).enabled, false);
      await t.tap(find.text('入力欄の次の操作'));
      await t.pump();
      expect(find.text('次の操作：1回'), findsOneWidget);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    },
  );
  testWidgets(
    'isolated frozen sample reports rejected edits with a private locale override',
    (t) async {
      await t.pumpWidget(
        host(const SensitiveInputSample({'frozen': 'true', 'value': 'fixed'})),
      );
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('Sensitive value, masked.'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'attempt');
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        'fixed',
      );
      expect(find.textContaining('"calls":1'), findsOneWidget);
    },
  );
}
