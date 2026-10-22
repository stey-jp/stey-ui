import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/tabs_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets(
    'Japanese controls switch tabs variants, rich labels and activation',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(child: TabsExample()),
          ),
        ),
      );
      await t.pumpAndSettle();
      for (final label in [
        '小さいサイズ',
        '下線で表示',
        'フォーカスで選択',
        'タブを増やす',
        '右から左へ',
        '非制御モード',
        '分析を無効にする',
        '図形付きラベル',
      ]) {
        await t.tap(find.text(label));
        await t.pumpAndSettle();
      }
      final widget = t.widget<SteyTabs>(find.byType(SteyTabs));
      expect(widget.value, isNull);
      expect(widget.tabs.length, 8);
      expect(widget.activateOnFocus, true);
      expect(widget.variant, SteyTabsVariant.underline);
      expect(widget.size, SteySize.sm);
      await t.tap(find.text('タブの次の操作'));
      await t.pumpAndSettle();
      expect(find.text('次の操作：1回'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'isolated uncontrolled sample reflects tab selection and adjacent button',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: Center(child: TabsSample({'uncontrolled': 'true'})),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('Overview'));
      await t.sendKeyEvent(LogicalKeyboardKey.end);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(
        find.textContaining('"value":"settings","calls":1'),
        findsOneWidget,
      );
      await t.tap(find.text('After tabs'));
      await t.pump();
      expect(find.textContaining('"after":1'), findsOneWidget);
    },
  );
}
