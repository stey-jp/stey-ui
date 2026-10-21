import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/badge_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
void main() {
  testWidgets(
    'Japanese controls change variant, dot, icons, direction and link callback',
    (t) async {
      await t.pumpWidget(host(const BadgeExample()));
      t
          .widget<SteySelect<SteyBadgeVariant>>(
            find.byType(SteySelect<SteyBadgeVariant>),
          )
          .onChanged!(SteyBadgeVariant.beta);
      await t.pump();
      expect(
        t.widgetList<SteyBadge>(find.byType(SteyBadge)).first.variant,
        SteyBadgeVariant.beta,
      );
      await t.tap(find.text('アイコンを表示'));
      await t.pump();
      expect(
        t.widgetList<SteyBadge>(find.byType(SteyBadge)).first.icon,
        isNotNull,
      );
      await t.tap(find.text('ドット表示'));
      await t.pump();
      final badge = t.widgetList<SteyBadge>(find.byType(SteyBadge)).first;
      expect(badge.appearance, SteyBadgeAppearance.dot);
      expect(badge.icon, isNull);
      await t.tap(find.text('リンク内に配置'));
      await t.pump();
      await t.tap(find.text('詳細を見る'));
      await t.pump();
      expect(find.text('リンク操作：1回'), findsOneWidget);
      await t.tap(find.text('右から左へ'));
      await t.pump();
      expect(
        Directionality.of(t.element(find.byType(SteyBadge).first)),
        TextDirection.rtl,
      );
      await t.tap(find.text('長いラベル'));
      await t.pump();
      expect(find.text('利用可能なプロジェクトを確認'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'comparison fixture accepts official kebab variant, text scaling and native link interaction',
    (t) async {
      await t.pumpWidget(
        host(
          const BadgeSample({
            'variant': 'teal-subtle',
            'scale': '2',
            'icon': 'true',
            'link': 'true',
          }),
        ),
      );
      expect(
        t.widget<SteyBadge>(find.byType(SteyBadge)).variant,
        SteyBadgeVariant.tealSubtle,
      );
      await t.tap(find.text('Active'));
      await t.pump();
      expect(find.bySemanticsLabel('Link calls: 1'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
