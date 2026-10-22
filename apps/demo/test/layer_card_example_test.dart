import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/layer_card_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets(
    'Japanese layered card controls preserve actions and toggle long RTL content',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(child: LayerCardExample()),
          ),
        ),
      );
      await t.tap(find.text('カード内の操作'));
      await t.pump();
      expect(find.text('カード内の操作：1回'), findsOneWidget);
      for (final label in ['長い内容', '右から左へ', 'フッターを表示']) {
        await t.tap(find.text(label));
        await t.pump();
      }
      expect(find.text('最終更新：たった今'), findsNothing);
      expect(
        Directionality.of(t.element(find.byType(SteyLayerCardPrimary))),
        TextDirection.rtl,
      );
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'isolated surface and layered samples render without duplicate preview frames',
    (t) async {
      for (final q in [
        {'kind': 'surface', 'layout': 'simple', 'padding': '16'},
        {'layout': 'layered', 'footer': 'true', 'multiple': 'true'},
      ]) {
        await t.pumpWidget(
          MaterialApp(
            theme: SteyTheme.material(Brightness.dark),
            home: Scaffold(body: Center(child: LayerCardSample(q))),
          ),
        );
        expect(find.text('Get started with Kumo'), findsOneWidget);
        expect(t.takeException(), isNull);
      }
    },
  );
}
