import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/loader_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets(
    'Japanese preset/custom/color/RTL and skeleton recreation controls',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(child: LoaderExample()),
          ),
        ),
      );
      t
          .widget<SteySelect<SteyLoaderSize>>(
            find.byType(SteySelect<SteyLoaderSize>),
          )
          .onChanged!(SteyLoaderSize.lg);
      await t.pump();
      expect(t.widget<SteyLoader>(find.byType(SteyLoader)).size, 32);
      await t.tap(find.text('任意サイズ（45px）'));
      await t.pump();
      expect(t.widget<SteyLoader>(find.byType(SteyLoader)).size, 45);
      await t.tap(find.text('色を変更'));
      await t.pump();
      expect(t.widget<SteyLoader>(find.byType(SteyLoader)).color, isNotNull);
      await t.tap(find.text('右から左へ'));
      await t.pump();
      expect(
        Directionality.of(t.element(find.byType(SteyLoader))),
        TextDirection.rtl,
      );
      await t.tap(find.text('スケルトンを再作成'));
      await t.pump();
      expect(find.text('再作成：1回'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
