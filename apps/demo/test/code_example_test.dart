import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/code_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets(
    'Japanese controls change the highlighted preview and preserve plain code',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const Scaffold(
            body: SingleChildScrollView(child: CodeExample()),
          ),
        ),
      );
      await tester.tap(find.text('行番号'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SteyCodeHighlighted>(find.byType(SteyCodeHighlighted))
            .showLineNumbers,
        false,
      );
      await tester.tap(find.text('構文強調'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SteyCodeHighlighting>(find.byType(SteyCodeHighlighting))
            .highlighter,
        isNull,
      );
      await tester.tap(find.text('枠なし'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SteyCodeHighlighted>(find.byType(SteyCodeHighlighted))
            .variant,
        SteyCodeHighlightedVariant.plain,
      );
      await tester.tap(find.text('javascript'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('python'));
      await tester.tap(find.text('python'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SteyCodeHighlighted>(find.byType(SteyCodeHighlighted))
            .code,
        codeSamples['python'],
      );
      expect(find.byType(SteyCodeBlock), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
