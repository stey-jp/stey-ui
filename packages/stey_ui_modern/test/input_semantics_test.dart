import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets('Input exposes one editable text field with its explicit name', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: SteyTheme.material(Brightness.light),
        home: const SteyTheme(
          brightness: Brightness.light,
          child: Scaffold(
            body: SteyInput(
              semanticLabel: 'Project',
              placeholder: 'Project name',
            ),
          ),
        ),
      ),
    );
    final fields = find.semantics.byFlag(SemanticsFlag.isTextField);
    expect(fields, findsOneWidget);
    expect(fields.evaluate().single.label, 'Project');
    await tester.enterText(find.byType(TextField), 'stey');
    await tester.pump();
    expect(fields.evaluate().single.value, 'stey');
    semantics.dispose();
  });
  testWidgets('Sensitive input retains its separate reveal action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: SteyTheme.material(Brightness.light),
        home: const SteyTheme(
          brightness: Brightness.light,
          child: Scaffold(body: SteySensitiveInput(label: 'API key')),
        ),
      ),
    );
    expect(find.semantics.byFlag(SemanticsFlag.isTextField), findsOneWidget);
    expect(find.semantics.byLabel('API key'), findsWidgets);
    expect(find.semantics.byLabel('Show API key'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Show API key'));
    await tester.pump();
    expect(find.semantics.byLabel('Hide API key'), findsOneWidget);
    semantics.dispose();
  });
}
