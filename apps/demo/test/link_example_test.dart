import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';
import 'package:stey_ui_demo/link_example.dart';

Widget host() => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: const Scaffold(body: SingleChildScrollView(child: LinkExample())),
);
void main() {
  testWidgets(
    'Japanese variant disabled and navigation controls remain usable',
    (t) async {
      await t.pumpWidget(host());
      await t.tap(find.bySemanticsLabel(RegExp(r'リンクの種類を変更$')));
      await t.pump();
      expect(
        t.widgetList<SteyLink>(find.byType(SteyLink)).first.variant,
        SteyLinkVariant.current,
      );
      await t.tap(find.text('リンクの表示と操作を確認する'));
      await t.pump();
      expect(find.text('リンクの操作：1回'), findsOneWidget);
      await t.tap(find.text('リンクを無効にする'));
      await t.pump();
      await t.tap(find.text('リンクの表示と操作を確認する'));
      await t.pump();
      expect(find.text('リンクの操作：1回'), findsOneWidget);
    },
  );
  testWidgets(
    'Japanese external narrow RTL scaling controls preserve neighbor',
    (t) async {
      await t.pumpWidget(host());
      for (final label in ['外部アイコンを表示', '幅を狭くする', '右から左へ']) {
        await t.tap(find.text(label));
        await t.pump();
      }
      await t.tap(find.bySemanticsLabel(RegExp(r'文字の拡大率を変更$')));
      await t.pump();
      expect(find.byType(SteyLinkExternalIcon), findsOneWidget);
      await t.tap(find.text('リンクの次の操作'));
      await t.pump();
      expect(find.text('次の操作：1回'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
