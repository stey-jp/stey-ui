import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/banner_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets(
    'Japanese banner controls preserve actions, loading, dismissal and restore',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: const [Locale('ja')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(child: BannerExample()),
          ),
        ),
      );
      await tester.ensureVisible(find.text('詳細を確認'));
      await tester.tap(find.text('詳細を確認'));
      await tester.pump();
      expect(find.text('操作回数：1'), findsOneWidget);
      await tester.tap(find.text('処理中'));
      await tester.pump();
      expect(
        tester
            .widget<TextButton>(
              find.ancestor(
                of: find.text('詳細を確認'),
                matching: find.byType(TextButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('処理中'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('操作を無効化'));
      await tester.pump();
      expect(
        tester
            .widget<TextButton>(
              find.ancestor(
                of: find.text('詳細を確認'),
                matching: find.byType(TextButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('操作を無効化'));
      await tester.pumpAndSettle();
      final size = tester.widget<SteySelect<SteyBannerSize>>(
        find.byWidgetPredicate((w) => w is SteySelect && w.label == '表示サイズ'),
      );
      size.onChanged!(SteyBannerSize.sm);
      await tester.pumpAndSettle();
      await tester.tap(find.text('リンクを表示'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('詳細を確認'));
      await tester.pump();
      expect(find.text('操作回数：2'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('通知を閉じる'));
      await tester.pump();
      expect(find.text('通知を再表示'), findsOneWidget);
      await tester.tap(find.text('通知を再表示'));
      await tester.pump();
      expect(find.text('更新があります'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('comparison fixture preserves RTL and counts a native action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SteyTheme.material(Brightness.light),
        home: const Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: BannerSample({'bannerSize': 'sm'}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(SteyBanner))),
      TextDirection.rtl,
    );
    await tester.tap(find.text('Details'));
    await tester.pump();
    expect(find.bySemanticsLabel('Action calls: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
