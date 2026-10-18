import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/collapsible_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets(
    'Japanese controls retain/discard text and cancel requested changes',
    (t) async {
      await t.pumpWidget(host(const CollapsibleExample()));
      await t.tap(find.text('詳細設定'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'cache-v1');
      await t.tap(find.text('詳細設定'));
      await t.pumpAndSettle();
      await t.tap(find.text('詳細設定'));
      await t.pumpAndSettle();
      expect(find.text('cache-v1'), findsOneWidget);
      await t.tap(find.text('開閉要求を取り消す'));
      await t.pump();
      await t.tap(find.text('詳細設定'));
      await t.pumpAndSettle();
      expect(find.text('開閉要求：4回・表示中'), findsOneWidget);
      await t.tap(find.text('開閉要求を取り消す'));
      await t.pump();
      await t.tap(find.text('閉じても内容を保持'));
      await t.pump();
      await t.tap(find.text('詳細設定'));
      await t.pumpAndSettle();
      await t.tap(find.text('外から開く'));
      await t.pumpAndSettle();
      expect(find.text('cache-v1'), findsNothing);
      await t.tap(find.text('ボタン型の起点'));
      await t.pumpAndSettle();
      await t.tap(find.text('詳細設定'));
      await t.pumpAndSettle();
      expect(find.text('開閉要求：6回・非表示'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('comparison sample preserves RTL and resets lazy child state', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: CollapsibleSample({'input': 'true', 'controlled': 'true'}),
        ),
      ),
    );
    await t.tap(find.text('Details'));
    await t.pumpAndSettle();
    expect(
      Directionality.of(t.element(find.byType(SteyCollapsibleRoot))),
      TextDirection.rtl,
    );
    await t.tap(find.text('Inner count: 0'));
    await t.pump();
    await t.tap(find.text('Details'));
    await t.pumpAndSettle();
    await t.tap(find.text('Details'));
    await t.pumpAndSettle();
    expect(find.text('Inner count: 0'), findsOneWidget);
    expect(find.text('Inner count: 1'), findsNothing);
    expect(find.bySemanticsLabel('Change calls: 3'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
