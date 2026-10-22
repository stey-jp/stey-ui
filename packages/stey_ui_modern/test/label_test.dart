import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  Brightness mode = Brightness.light,
  bool japanese = false,
  double width = 280,
}) => MaterialApp(
  theme: SteyTheme.material(mode),
  home: Builder(
    builder: (context) => Localizations.override(
      context: context,
      locale: japanese ? const Locale('ja') : const Locale('en'),
      child: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);
TextStyle style(WidgetTester t, String text) =>
    DefaultTextStyle.of(t.element(find.text(text))).style;
void main() {
  testWidgets(
    'standalone label uses 14px medium and separate optional content with 4px gap',
    (t) async {
      await t.pumpWidget(host(const SteyLabel('Name', showOptional: true)));
      expect(style(t, 'Name').fontSize, 14);
      expect(style(t, 'Name').fontWeight, FontWeight.w500);
      expect(style(t, '(optional)').fontWeight, FontWeight.w400);
      expect(
        t.getTopLeft(find.text('(optional)')).dx -
            t.getTopRight(find.text('Name')).dx,
        4,
      );
      expect(find.text('Name (optional)'), findsNothing);
    },
  );
  testWidgets(
    'asContent inherits font size weight line height and color in both themes',
    (t) async {
      for (final mode in Brightness.values) {
        await t.pumpWidget(
          host(
            DefaultTextStyle.merge(
              style: const TextStyle(
                fontSize: 20,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
              child: const SteyLabel(
                'Name',
                asContent: true,
                showOptional: true,
              ),
            ),
            mode: mode,
          ),
        );
        await t.pumpAndSettle();
        expect(style(t, 'Name').fontSize, 20);
        expect(style(t, 'Name').fontWeight, FontWeight.w600);
        expect(style(t, 'Name').height, 1.6);
        expect(style(t, 'Name').color, Colors.red);
        expect(style(t, '(optional)').color, SteyColors(mode).subtle);
      }
    },
  );
  testWidgets(
    'locale defaults differ from explicit values and rich optional content',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyLabel('名前', showOptional: true, tooltip: 'Help'),
          japanese: true,
        ),
      );
      expect(find.text('（任意）'), findsOneWidget);
      expect(find.bySemanticsLabel('詳しい情報'), findsOneWidget);
      await t.pumpWidget(
        host(
          const SteyLabel(
            '名前',
            showOptional: true,
            optionalLabel: '(optional)',
            tooltip: 'Help',
            tooltipAriaLabel: 'More information',
          ),
          japanese: true,
        ),
      );
      expect(find.text('(optional)'), findsOneWidget);
      expect(find.bySemanticsLabel('More information'), findsOneWidget);
      await t.pumpWidget(
        host(
          const SteyLabel.rich(
            Text.rich(
              TextSpan(
                text: 'Name',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            showOptional: true,
            optionalContent: Text('(your choice)'),
          ),
        ),
      );
      expect(find.text('(your choice)'), findsOneWidget);
      expect(find.text('(optional)'), findsNothing);
    },
  );
  testWidgets(
    'required false remains optional while required true adds no asterisk; empty tooltip omitted',
    (t) async {
      await t.pumpWidget(
        host(const SteyLabel('Name', required: false, tooltip: '')),
      );
      expect(find.text('(optional)'), findsOneWidget);
      expect(find.byType(SteyButton), findsNothing);
      await t.pumpWidget(host(const SteyLabel('Name', required: true)));
      expect(find.text('*'), findsNothing);
      expect(find.text('(optional)'), findsNothing);
    },
  );
  testWidgets(
    'main and optional label focus the editor once; information does not focus editor',
    (t) async {
      final focus = FocusNode();
      var calls = 0;
      await t.pumpWidget(
        host(
          Column(
            children: [
              SteyLabel(
                'Name',
                showOptional: true,
                tooltip: 'Help',
                controlFocusNode: focus,
                onTap: () => calls++,
              ),
              TextField(focusNode: focus),
            ],
          ),
        ),
      );
      await t.tap(find.text('Name'));
      await t.pump();
      expect(focus.hasFocus, true);
      expect(calls, 1);
      focus.unfocus();
      await t.pump();
      await t.tap(find.text('(optional)'));
      await t.pump();
      expect(focus.hasFocus, true);
      expect(calls, 2);
      focus.unfocus();
      await t.pump();
      await t.tap(find.bySemanticsLabel('More information'));
      await t.pumpAndSettle();
      expect(focus.hasFocus, false);
      expect(calls, 2);
      expect(find.text('Help'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      focus.dispose();
    },
  );
  testWidgets(
    'mouse waits 600ms then shows and leaves with native transition',
    (t) async {
      await t.pumpWidget(
        host(const SteyLabel('Name', tooltip: 'Helpful context')),
      );
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(t.getCenter(find.byType(SteyButton)));
      await t.pump(const Duration(milliseconds: 599));
      expect(find.text('Helpful context'), findsNothing);
      await t.pump(const Duration(milliseconds: 1));
      await t.pumpAndSettle();
      expect(find.text('Helpful context'), findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await t.pumpAndSettle();
      expect(find.text('Helpful context'), findsNothing);
      await mouse.removePointer();
    },
  );
  testWidgets(
    'Tab focus shows help; Escape retains focus; neighbor remains usable',
    (t) async {
      var calls = 0;
      await t.pumpWidget(
        host(
          Column(
            children: [
              const SteyLabel('Name', tooltip: 'Helpful context'),
              SteyButton(onPressed: () => calls++, child: const Text('Next')),
            ],
          ),
        ),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      expect(find.text('Helpful context'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.text('Helpful context'), findsNothing);
      final infoFocus = Focus.of(
        t.element(find.bySemanticsLabel('More information')),
      );
      expect(infoFocus.hasFocus, true);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(calls, 1);
    },
  );
  testWidgets(
    'hovered help stays readable while the pointer crosses onto its popup',
    (t) async {
      await t.pumpWidget(
        host(const SteyLabel('Name', tooltip: 'Helpful context')),
      );
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(t.getCenter(find.byType(SteyButton)));
      await t.pump(const Duration(milliseconds: 600));
      await t.pumpAndSettle();
      await mouse.moveTo(t.getCenter(find.text('Helpful context')));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Helpful context'), findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await t.pumpAndSettle();
      expect(find.text('Helpful context'), findsNothing);
      await mouse.removePointer();
    },
  );
  testWidgets(
    'touch and keyboard activation preserve legacy help access and rich content',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyLabel(
            'Name',
            tooltipContent: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Helpful context'), Text('More details')],
            ),
            tooltipSemanticLabel: 'Helpful context. More details',
          ),
        ),
      );
      await t.tap(find.bySemanticsLabel('More information'));
      await t.pumpAndSettle();
      expect(find.text('More details'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(find.text('Helpful context'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('RTL and 200percent keep optional ordering and word minimum', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: SteyLabel('Project name', showOptional: true),
          ),
        ),
        width: 120,
      ),
    );
    expect(
      t.getTopLeft(find.text('(optional)')).dx,
      lessThan(t.getTopLeft(find.text('Project name')).dx),
    );
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'excluding label text semantics also excludes optional but keeps information action',
    (t) async {
      final semantics = t.ensureSemantics();
      await t.pumpWidget(
        host(
          const SteyLabel(
            'Name',
            showOptional: true,
            tooltip: 'Help',
            excludeTextSemantics: true,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Name'), findsNothing);
      expect(find.bySemanticsLabel('(optional)'), findsNothing);
      expect(find.bySemanticsLabel('More information'), findsOneWidget);
      semantics.dispose();
    },
  );
  testWidgets(
    'arbitrary layout child is never queried for intrinsic dimensions',
    (t) async {
      await t.pumpWidget(
        host(
          SteyLabel.rich(
            LayoutBuilder(builder: (_, constraints) => const Text('Name')),
          ),
        ),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'open help follows its scrolling anchor and removal disposes the overlay',
    (t) async {
      final scroll = ScrollController();
      await t.pumpWidget(
        host(
          SizedBox(
            height: 400,
            child: SingleChildScrollView(
              controller: scroll,
              child: const Column(
                children: [
                  SizedBox(height: 200),
                  SteyLabel('Name', tooltip: 'Helpful context'),
                  SizedBox(height: 800),
                ],
              ),
            ),
          ),
        ),
      );
      await t.tap(find.bySemanticsLabel('More information'));
      await t.pumpAndSettle();
      final before = t.getTopLeft(find.text('Helpful context'));
      scroll.jumpTo(80);
      await t.pump();
      await t.pump();
      expect(
        t.getTopLeft(find.text('Helpful context')).dy,
        closeTo(before.dy - 80, 1),
      );
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(find.text('Helpful context'), findsNothing);
      expect(t.takeException(), isNull);
      scroll.dispose();
    },
  );
  testWidgets(
    'rich optional text shrinks and wraps inside a 220px RTL host at 200percent',
    (t) async {
      await t.pumpWidget(
        host(
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SteyLabel.rich(
                Text('名前'),
                showOptional: true,
                optionalContent: Text('（入力を省略できます）'),
                tooltip: 'Help',
              ),
            ),
          ),
          width: 220,
        ),
      );
      final label = t.getRect(find.byType(SteyLabel));
      for (final finder in [
        find.text('名前'),
        find.text('（入力を省略できます）'),
        find.byType(SteyButton),
      ]) {
        final child = t.getRect(finder);
        expect(child.left, greaterThanOrEqualTo(label.left - .01));
        expect(child.right, lessThanOrEqualTo(label.right + .01));
      }
      expect(t.takeException(), isNull);
    },
  );
}
