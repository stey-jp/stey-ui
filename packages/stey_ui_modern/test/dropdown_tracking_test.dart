import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class TrackingHost extends StatefulWidget {
  const TrackingHost({super.key, this.direction = TextDirection.ltr});
  final TextDirection direction;
  @override
  State<TrackingHost> createState() => TrackingHostState();
}

class TrackingHostState extends State<TrackingHost> {
  final controller = MenuController(), scroll = ScrollController();
  final changes = <bool>[];
  Offset shift = Offset.zero;
  int extra = 0;
  void move(Offset value) => setState(() => shift = value);
  void setExtra(int value) => setState(() => extra = value);
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: SteyTheme.material(Brightness.light),
    home: SteyTheme(
      brightness: Brightness.light,
      child: Scaffold(
        body: Directionality(
          textDirection: widget.direction,
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              controller: scroll,
              child: SizedBox(
                height: box.maxHeight * 2,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: box.maxHeight / 2 - 18),
                    child: Transform.translate(
                      offset: shift,
                      child: SteyDropdownMenu(
                        width: 224,
                        controller: controller,
                        onOpenChanged: changes.add,
                        items: [
                          SteyMenuItem('Edit', onPressed: () {}),
                          SteyMenuItem(
                            'Move',
                            children: [
                              SteyMenuItem('Nested', onPressed: () {}),
                              SteyMenuItem(
                                'More',
                                children: [
                                  SteyMenuItem('Deep', onPressed: () {}),
                                ],
                              ),
                              for (var i = 0; i < extra; i++)
                                SteyMenuItem('Extra $i', onPressed: () {}),
                            ],
                          ),
                        ],
                        child: const Text('Actions'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Finder row(String label) => find.widgetWithText(MenuItemButton, label);
Rect popup(WidgetTester tester, String first, String last) => Rect.fromLTRB(
  tester.getRect(row(first)).left - 6,
  tester.getRect(row(first)).top - 6,
  tester.getRect(row(last)).right + 6,
  tester.getRect(row(last)).bottom + 6,
);

Future<TrackingHostState> open(
  WidgetTester tester,
  TextDirection direction, {
  bool deep = false,
}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey<TrackingHostState>();
  await tester.pumpWidget(TrackingHost(key: key, direction: direction));
  await tester.tap(find.text('Actions'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Move'));
  await tester.pumpAndSettle();
  if (deep) {
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
  }
  return key.currentState!;
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      '$direction resize keeps open menus and resolves new collisions',
      (tester) async {
        final state = await open(tester, direction);
        tester.view.physicalSize = const Size(320, 600);
        await tester.pumpAndSettle();
        expect(state.controller.isOpen, isTrue);
        expect(state.changes, [true]);
        final parent = tester.getRect(row('Move')),
            child = popup(tester, 'Nested', 'More');
        expect(child.top - parent.bottom, 8);
        expect(child.left, greaterThanOrEqualTo(5));
        expect(child.right, lessThanOrEqualTo(315));
        expect(child.bottom, lessThanOrEqualTo(595));
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '$direction paint translation follows through three levels without reopening',
      (tester) async {
        final state = await open(tester, direction, deep: true);
        final idleCallbacks = tester.binding.transientCallbackCount;
        final before = tester.getRect(row('Deep'));
        state.move(const Offset(20, -80));
        await tester.pumpAndSettle();
        expect(tester.getRect(row('Deep')).top - before.top, -80);
        expect(tester.getRect(row('Deep')).left - before.left, 20);
        expect(state.changes, [true]);
        expect(state.controller.isOpen, isTrue);
        expect(tester.binding.hasScheduledFrame, isFalse);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, idleCallbacks);
      },
    );
    testWidgets(
      '$direction animated ancestor scroll keeps root and nested anchors connected',
      (tester) async {
        final state = await open(tester, direction, deep: true);
        final before = tester.getRect(row('Deep'));
        final animation = state.scroll.animateTo(
          120,
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
        );
        await tester.pumpAndSettle();
        await animation;
        expect(state.controller.isOpen, isTrue);
        expect(state.changes, [true]);
        expect(tester.getRect(row('Deep')).top - before.top, -120);
        expect(tester.binding.hasScheduledFrame, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Deep'), findsNothing);
        expect(find.text('Nested'), findsOneWidget);
      },
    );
  }
  testWidgets('An external post-frame close during resize is not lost', (
    tester,
  ) async {
    final state = await open(tester, TextDirection.ltr);
    tester.view.physicalSize = const Size(320, 600);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => state.controller.close(),
    );
    await tester.pumpAndSettle();
    expect(state.controller.isOpen, isFalse);
    expect(state.changes, [true, false]);
  });
  testWidgets('Resize during animated ancestor scrolling retains the menu', (
    tester,
  ) async {
    final state = await open(tester, TextDirection.ltr, deep: true);
    final animation = state.scroll.animateTo(
      120,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    tester.view.physicalSize = const Size(320, 600);
    await tester.pumpAndSettle();
    await animation;
    expect(state.controller.isOpen, isTrue);
    expect(state.changes, [true]);
    expect(find.text('Deep'), findsOneWidget);
  });
  testWidgets('Software keyboard insets constrain every open surface', (
    tester,
  ) async {
    final state = await open(tester, TextDirection.ltr);
    state.setExtra(20);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(state.controller.isOpen, isTrue);
    expect(
      tester
          .getRect(
            find
                .ancestor(
                  of: row('Nested'),
                  matching: find.byType(SingleChildScrollView),
                )
                .first,
          )
          .bottom,
      lessThanOrEqualTo(595),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('External controller close still works during an active scroll', (
    tester,
  ) async {
    final state = await open(tester, TextDirection.ltr);
    final animation = state.scroll.animateTo(
      120,
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    state.controller.close();
    await tester.pumpAndSettle();
    await animation;
    expect(state.controller.isOpen, isFalse);
    expect(state.changes, [true, false]);
    expect(find.text('Nested'), findsNothing);
  });
  testWidgets(
    'Changed child count reflows the open surface while retaining its state',
    (tester) async {
      final state = await open(tester, TextDirection.ltr);
      state.setExtra(5);
      await tester.pumpAndSettle();
      expect(find.text('Extra 4'), findsOneWidget);
      expect(state.changes, [true]);
      final rect = popup(tester, 'Nested', 'Extra 4');
      expect(rect.height, 243);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );
  testWidgets(
    'Disposal cancels pending tracking without scheduling idle frames',
    (tester) async {
      await open(tester, TextDirection.ltr, deep: true);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
