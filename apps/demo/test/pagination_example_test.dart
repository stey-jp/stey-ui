import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/pagination_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets(
    'Japanese example toggles unknown/simple/dropdown/empty/RTL and counts navigation',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(child: PaginationExample()),
          ),
        ),
      );
      final next = find.ancestor(
        of: find.bySemanticsLabel('Next page'),
        matching: find.byType(TextButton),
      );
      await t.tap(next);
      await t.pump();
      expect(find.text('現在のページ：4・移動操作：1回'), findsOneWidget);
      await t.tap(find.text('総件数が不明'));
      await t.pump();
      expect(find.byType(TextField), findsNothing);
      await t.tap(find.text('総件数が不明'));
      await t.pump();
      await t.tap(find.text('ページを選択'));
      await t.pump();
      expect(find.byType(SteySelect<int>), findsNWidgets(2));
      await t.tap(find.text('検索結果なし'));
      await t.pump();
      expect(find.text('現在のページ：1・移動操作：1回'), findsOneWidget);
      await t.tap(find.text('右から左へ'));
      await t.pump();
      expect(
        Directionality.of(t.element(find.byType(SteyPagination))),
        TextDirection.rtl,
      );
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'comparison sample renders English labels and updates callbacks',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: Center(
              child: PaginationSample({'page': '3', 'total': '100'}),
            ),
          ),
        ),
      );
      await t.tap(
        find.ancestor(
          of: find.bySemanticsLabel('Next page'),
          matching: find.byType(TextButton),
        ),
      );
      await t.pump();
      expect(find.bySemanticsLabel('Page: 4; Calls: 1'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
