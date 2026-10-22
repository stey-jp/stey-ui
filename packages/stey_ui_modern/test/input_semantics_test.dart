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
    await tester.enterText(find.byType(TextField), 'example');
    await tester.pump();
    expect(find.semantics.byLabel('Hide value'), findsOneWidget);
    semantics.dispose();
  });
  testWidgets(
    'Required field announces error and hides its helper description',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const SteyTheme(
            brightness: Brightness.light,
            child: Scaffold(
              body: SteyInput(
                label: 'Project',
                required: true,
                description: 'Choose a unique name',
                error: 'Name is already taken',
              ),
            ),
          ),
        ),
      );
      final field = find.semantics
          .byFlag(SemanticsFlag.isTextField)
          .evaluate()
          .single;
      expect(field.label, 'Project');
      expect(field.hint, 'Name is already taken');
      expect(find.semantics.byFlag(SemanticsFlag.isRequired), findsOneWidget);
      expect(find.text('Choose a unique name'), findsNothing);
      expect(find.text('Name is already taken'), findsOneWidget);
      expect(find.text('Project *'), findsNothing);
      semantics.dispose();
    },
  );
  testWidgets(
    'Optional indicator is explicit and tooltip has one action name',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: SteyTheme.material(Brightness.light),
          home: const SteyTheme(
            brightness: Brightness.light,
            child: Scaffold(
              body: Column(
                children: [
                  SteyField(label: 'Default field', child: SizedBox()),
                  SteyField(
                    label: 'Optional field',
                    required: false,
                    labelTooltip: 'You may leave this blank',
                    child: SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Default field'), findsOneWidget);
      expect(find.text('Default field (optional)'), findsNothing);
      expect(find.text('Optional field (optional)'), findsOneWidget);
      expect(find.semantics.byLabel('More information'), findsOneWidget);
      semantics.dispose();
    },
  );
}
