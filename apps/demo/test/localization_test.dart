import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/gallery.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget japaneseHost(Widget child) => MaterialApp(
  locale: const Locale('ja'),
  supportedLocales: const [Locale('ja')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('Japanese search selects a component and preserves interaction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SteyGallery());
    await tester.pump();
    await tester.pump();
    expect(find.text('操作プレビュー'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).first, 'チェック');
    await tester.pump();
    await tester.tap(find.text('チェックボックス'));
    await tester.pump();
    expect(find.text('アクセス分析を有効にする'), findsOneWidget);
    final checkbox = find.byType(SteyCheckbox).first;
    expect(tester.widget<SteyCheckbox>(checkbox).value, isFalse);
    await tester.tap(find.text('アクセス分析を有効にする'));
    await tester.pump();
    expect(tester.widget<SteyCheckbox>(checkbox).value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Japanese locale reaches calendar, copy feedback and dialog', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      japaneseHost(
        Builder(
          builder: (context) => Column(
            children: [
              SteyDatePicker(
                initialMonth: DateTime(2026, 10),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                label: '日付を選択',
              ),
              const SteyClipboardText('account_123'),
              SteyButton(
                onPressed: () => SteyDialog.show(
                  context,
                  title: '編集',
                  child: const SteyInput(label: '名前'),
                ),
                child: const Text('開く'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2026年10月'), findsOneWidget);
    final context = tester.element(find.byType(SteyDatePicker));
    expect(
      find.bySemanticsLabel(MaterialLocalizations.of(context).nextMonthTooltip),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('account_123をコピー'));
    await tester.pump();
    expect(find.bySemanticsLabel('コピーしました'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('ダイアログを閉じる'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('ダイアログを閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('編集'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
