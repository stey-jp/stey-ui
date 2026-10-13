import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: SteyTheme(
    brightness: Brightness.light,
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets(
    'Resize handle clamps drag width and collapses below the minimum',
    (tester) async {
      final widths = <double>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 240,
            child: SteySidebar(
              width: 240,
              minWidth: 200,
              maxWidth: 300,
              resizable: true,
              items: const [SteySidebarItem('home', 'Home', icon: Icons.home)],
              selected: 'home',
              onSelected: (_) {},
              onWidthChanged: widths.add,
            ),
          ),
        ),
      );
      final handle = find.bySemanticsLabel('Resize sidebar');
      final semantics = tester.ensureSemantics();
      await tester.pump();
      await tester.drag(handle, const Offset(100, 0));
      await tester.pump();
      expect(tester.getSize(find.byType(SteySidebar)).width, 300);
      await tester.drag(handle, const Offset(-180, 0));
      await tester.pump();
      expect(tester.getSize(find.byType(SteySidebar)).width, 57);
      await tester.drag(handle, const Offset(180, 0));
      await tester.pump();
      expect(
        tester.getSize(find.byType(SteySidebar)).width,
        greaterThanOrEqualTo(200),
      );
      expect(widths.every((width) => width >= 200 && width <= 300), isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'Resize keyboard supports bounds, collapse, and reversed right-side arrows',
    (tester) async {
      final semantics = tester.ensureSemantics();
      for (final side in SteySidebarSide.values) {
        await tester.pumpWidget(
          host(
            SizedBox(
              height: 240,
              child: SteySidebar(
                key: ValueKey(side),
                width: 240,
                minWidth: 200,
                maxWidth: 300,
                side: side,
                resizable: true,
                items: const [],
                selected: '',
                onSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.tap(find.bySemanticsLabel('Resize sidebar'));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        expect(tester.getSize(find.byType(SteySidebar)).width, 300);
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        expect(tester.getSize(find.byType(SteySidebar)).width, 57);
        final grow = side == SteySidebarSide.left
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowLeft;
        final shrink = side == SteySidebarSide.left
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight;
        await tester.sendKeyEvent(grow);
        await tester.pump();
        expect(tester.getSize(find.byType(SteySidebar)).width, 200);
        await tester.sendKeyEvent(grow);
        await tester.pump();
        expect(tester.getSize(find.byType(SteySidebar)).width, 210);
        await tester.sendKeyEvent(shrink);
        await tester.sendKeyEvent(shrink);
        await tester.pump();
        expect(tester.getSize(find.byType(SteySidebar)).width, 57);
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'Sliding views keep entered text and exclude inactive focus and semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final focusA = FocusNode(), focusB = FocusNode();
      var active = 'account';
      late void Function(String) select;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              select = (value) => setState(() => active = value);
              return SizedBox(
                width: 260,
                height: 200,
                child: SteySidebarSlidingViews(
                  activeKey: active,
                  views: [
                    SteySidebarSlidingView(
                      value: 'account',
                      child: TextField(
                        focusNode: focusA,
                        decoration: const InputDecoration(
                          labelText: 'Account name',
                        ),
                      ),
                    ),
                    SteySidebarSlidingView(
                      value: 'zone',
                      child: TextField(
                        focusNode: focusB,
                        decoration: const InputDecoration(
                          labelText: 'Zone name',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'Retained account');
      select('zone');
      await tester.pump();
      expect(focusA.hasFocus, isFalse);
      focusA.requestFocus();
      await tester.pump();
      expect(focusA.hasFocus, isFalse);
      expect(find.semantics.byLabel('Account name'), findsNothing);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'example.com');
      select('account');
      await tester.pumpAndSettle();
      expect(find.text('Retained account'), findsOneWidget);
      expect(find.semantics.byLabel('Zone name'), findsNothing);
      focusA.dispose();
      focusB.dispose();
      semantics.dispose();
    },
  );
}
