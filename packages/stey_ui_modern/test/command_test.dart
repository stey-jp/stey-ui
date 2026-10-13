import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: SteyTheme(
    brightness: Brightness.light,
    child: Scaffold(
      body: Center(child: SizedBox(width: 500, child: child)),
    ),
  ),
);

void main() {
  testWidgets(
    'Palette groups, skips disabled results, and selects with new-tab intent',
    (tester) async {
      final selections = <String>[];
      await tester.pumpWidget(
        host(
          SteyCommandPalette(
            commands: [
              SteyCommand(
                'Workers',
                () => selections.add('workers'),
                group: 'Compute',
              ),
              SteyCommand(
                'Disabled',
                () => selections.add('disabled'),
                disabled: true,
                group: 'Compute',
              ),
              SteyCommand(
                'Pages',
                () => selections.add('pages'),
                group: 'Storage',
                onSelect: (newTab) => selections.add('pages:$newTab'),
              ),
            ],
            footer: const Text('↑↓ Navigate · Enter Select'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Compute'), findsOneWidget);
      expect(find.text('Storage'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(selections, ['pages:true']);
      await tester.enterText(find.byType(TextField), 'work');
      await tester.pump();
      expect(find.text('Pages'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(selections, ['pages:true', 'workers']);
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pump();
      expect(find.text('No results found'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(selections.length, 2);
    },
  );

  testWidgets(
    'Controlled query and loading preserve the panel and prevent selection',
    (tester) async {
      final controller = TextEditingController(text: 'Pages');
      var selected = 0;
      final command = SteyCommand('Pages', () => selected++);
      await tester.pumpWidget(
        host(
          SteyCommandPalette(
            commands: [command],
            controller: controller,
            loading: true,
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(selected, 0);
      expect(find.byType(SteyLoader), findsOneWidget);
      await tester.pumpWidget(
        host(SteyCommandPalette(commands: [command], controller: controller)),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(selected, 1);
      expect(controller.text, 'Pages');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'Highlight ranges merge overlaps without losing selectable text',
    (tester) async {
      await tester.pumpWidget(
        host(
          const SteyHighlightedText(
            'Workers',
            highlights: [(0, 2), (2, 4), (5, 6), (99, 100)],
          ),
        ),
      );
      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.textSpan!.toPlainText(), 'Workers');
      expect((text.textSpan! as TextSpan).children!.length, 1);
    },
  );

  testWidgets(
    'Palette dialog closes on Escape and retains normal focus navigation',
    (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => SteyButton(
              onPressed: () => SteyCommandPalette.show(
                context,
                commands: [SteyCommand('Pages', () {})],
              ),
              child: const Text('Open palette'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open palette'));
      await tester.pumpAndSettle();
      expect(find.byType(SteyCommandPalette), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SteyCommandPalette), findsNothing);
    },
  );
}
