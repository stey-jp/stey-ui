import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/inline_copy_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets(
    'Japanese inline controls switch group/rich/disabled and cancel clipboard IO',
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
            body: SingleChildScrollView(child: InlineCopyExample()),
          ),
        ),
      );
      await tester.tap(find.text('行グループ'));
      await tester.pumpAndSettle();
      expect(find.byType(SteyInlineCopyGroup), findsOneWidget);
      await tester.tap(find.text('装飾付きの表示'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SteyInlineCopyText>(find.byType(SteyInlineCopyText))
            .child,
        isNotNull,
      );
      await tester.tap(find.text('無効'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SteyInlineCopyText>(find.byType(SteyInlineCopyText))
            .disabled,
        isTrue,
      );
      await tester.tap(find.text('無効'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('コピー前に中止'));
      await tester.pumpAndSettle();
      final target = find
          .descendant(
            of: find.byType(SteyInlineCopyText),
            matching: find.byType(GestureDetector),
          )
          .first;
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      expect(find.textContaining('コピー前に処理を中止しました。'), findsOneWidget);
      await tester.ensureVisible(find.text('コピー前に中止'));
      await tester.tap(find.text('コピー前に中止'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
      expect(writes, ['account_complete_12345']);
      expect(find.textContaining('コピー回数：1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
