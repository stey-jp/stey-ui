import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/breadcrumbs_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
void main() {
  testWidgets(
    'Japanese controls update breadcrumbs size/loading/direction and native callbacks',
    (t) async {
      String? raw;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              raw = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await t.pumpWidget(host(const BreadcrumbsExample()));
      await t.tap(find.text('プロジェクト'));
      await t.pump();
      await t.tap(find.bySemanticsLabel('Copy'));
      await t.pump();
      expect(raw, 'https://example.com/projects/settings');
      expect(find.text('移動操作：1回・コピー：1回'), findsOneWidget);
      await t.tap(find.text('読み込み中'));
      await t.pump();
      expect(
        t
            .widget<SteyBreadcrumbsCurrent>(find.byType(SteyBreadcrumbsCurrent))
            .loading,
        true,
      );
      await t.tap(find.text('読み込み中'));
      await t.pump();
      await t.tap(find.text('右から左へ'));
      await t.pump();
      expect(
        Directionality.of(t.element(find.byType(SteyBreadcrumbsCurrent))),
        TextDirection.rtl,
      );
      t
          .widget<SteySelect<SteyBreadcrumbsSize>>(
            find.byType(SteySelect<SteyBreadcrumbsSize>),
          )
          .onChanged!(SteyBreadcrumbsSize.sm);
      await t.pump();
      expect(
        t.widget<SteyBreadcrumbs>(find.byType(SteyBreadcrumbs)).size,
        SteyBreadcrumbsSize.sm,
      );
      await t.tap(find.text('コピーを表示'));
      await t.pump();
      expect(find.byType(SteyBreadcrumbsClipboard), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'comparison fixture retains mobile extras and counts link activation',
    (t) async {
      await t.pumpWidget(
        host(
          const MediaQuery(
            data: MediaQueryData(size: Size(390, 900)),
            child: BreadcrumbsSample({'extra': 'true'}),
          ),
        ),
      );
      expect(find.text('Account'), findsNothing);
      expect(find.text('Extra'), findsOneWidget);
      await t.tap(find.text('Projects'));
      await t.pump();
      expect(
        find.bySemanticsLabel('Link calls: 1; Copy calls: 0'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
