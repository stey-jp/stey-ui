import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/clipboard_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets(
    'English comparison fixture preserves the surrounding RTL direction',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: clipboardSample(const {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(SteyClipboardText));
      expect(Localizations.localeOf(context).languageCode, 'en');
      expect(Directionality.of(context), TextDirection.rtl);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Japanese clipboard controls change copy value, length, size and tooltip',
    (tester) async {
      final writes = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            writes.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(child: ClipboardExample()),
          ),
        ),
      );
      await tester.ensureVisible(find.bySemanticsLabel('テキストをコピー'));
      await tester.tap(find.bySemanticsLabel('テキストをコピー'));
      await tester.pump();
      expect(writes, ['account_complete_12345']);
      expect(find.text('コピーしました。 コピー回数：1'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.ensureVisible(find.text('別の値をコピー'));
      await tester.tap(find.text('別の値をコピー'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('長い文字列'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ツールチップと通知'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.bySemanticsLabel('テキストをコピー'));
      await tester.tap(find.bySemanticsLabel('テキストをコピー'));
      await tester.pump();
      expect(writes.last, startsWith('account_12345 / namespace-'));
      expect(
        tester
            .widget<SteyClipboardText>(find.byType(SteyClipboardText))
            .tooltip,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
