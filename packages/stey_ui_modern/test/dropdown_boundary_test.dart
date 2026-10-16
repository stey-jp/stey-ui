import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class BoundaryHost extends StatefulWidget {
  const BoundaryHost({super.key, required this.direction});
  final TextDirection direction;
  @override
  State<BoundaryHost> createState() => BoundaryHostState();
}

class BoundaryHostState extends State<BoundaryHost> {
  final menu = MenuController(), scroll = ScrollController();
  Rect? boundary = const Rect.fromLTWH(120, 100, 560, 600);
  EdgeInsets padding = const EdgeInsets.fromLTRB(40, 10, 20, 30);
  Offset translation = Offset.zero;
  bool checked = true;
  bool sticky = false;
  final changes = <bool>[];
  void update(VoidCallback callback) => setState(callback);
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: widget.direction,
    child: SingleChildScrollView(
      controller: scroll,
      child: SizedBox(
        height: 1600,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 382),
            child: Transform.translate(
              offset: translation,
              child: SteyDropdownMenu(
                controller: menu,
                width: 224,
                collisionBoundary: boundary,
                collisionPadding: padding,
                sticky: sticky,
                onOpenChanged: changes.add,
                items: [
                  SteyMenuItem(
                    'Move',
                    children: [
                      SteyMenuItem(
                        'More',
                        children: [SteyMenuItem('Deep', onPressed: () {})],
                      ),
                      for (var i = 0; i < 20; i++)
                        SteyMenuItem('Account $i', onPressed: () {}),
                    ],
                  ),
                  SteyMenuCheckboxItem(
                    'Alerts',
                    value: checked,
                    closeOnActivate: false,
                    onChanged: (value) => update(() => checked = value),
                  ),
                  for (var i = 0; i < 20; i++)
                    SteyMenuItem('Action $i', onPressed: () {}),
                ],
                child: const Text('Actions'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<BoundaryHostState> mount(
  WidgetTester tester,
  TextDirection direction,
) async {
  tester.view.physicalSize = const Size(800, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey<BoundaryHostState>();
  await tester.pumpWidget(
    MaterialApp(
      theme: SteyTheme.material(Brightness.light),
      home: SteyTheme(
        brightness: Brightness.light,
        child: Scaffold(
          body: BoundaryHost(key: key, direction: direction),
        ),
      ),
    ),
  );
  key.currentState!.menu.open();
  await tester.pumpAndSettle();
  return key.currentState!;
}

Finder row(String text) => find.widgetWithText(MenuItemButton, text);
List<Rect> surfaces(WidgetTester tester) => find
    .byType(SingleChildScrollView)
    .evaluate()
    .skip(1)
    .map((e) => tester.getRect(find.byWidget(e.widget)))
    .toList();
Future<void> openChild(WidgetTester tester, TextDirection direction) async {
  tester.widget<MenuItemButton>(row('Move')).focusNode!.requestFocus();
  await tester.pump();
  await tester.sendKeyEvent(
    direction == TextDirection.ltr
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft,
  );
  await tester.pumpAndSettle();
  expect(
    tester.widget<MenuItemButton>(row('More')).focusNode!.hasPrimaryFocus,
    isTrue,
  );
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'Keyboard reveals focused rows inside a short sticky menu $direction',
      (tester) async {
        final host = await mount(tester, direction);
        host.update(() {
          host.sticky = true;
          host.boundary = const Rect.fromLTWH(120, 300, 560, 200);
        });
        await tester.pumpAndSettle();
        tester.widget<MenuItemButton>(row('Move')).focusNode!.requestFocus();
        await tester.pumpAndSettle();
        for (final key in [LogicalKeyboardKey.end, LogicalKeyboardKey.home]) {
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          final label = key == LogicalKeyboardKey.end ? 'Action 19' : 'Move';
          final item = tester.getRect(row(label)),
              popup = surfaces(tester).single;
          expect(item.top, greaterThanOrEqualTo(popup.top));
          expect(item.bottom, lessThanOrEqualTo(popup.bottom));
          expect(
            tester
                .widget<MenuItemButton>(row(label))
                .focusNode!
                .hasPrimaryFocus,
            isTrue,
          );
          expect(host.scroll.offset, 0);
          expect(host.menu.isOpen, isTrue);
        }
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Explicit width is preserved in a narrower boundary $direction',
      (tester) async {
        final host = await mount(tester, direction);
        host.update(
          () => host.boundary = const Rect.fromLTWH(120, 100, 200, 600),
        );
        await tester.pumpAndSettle();
        await openChild(tester, direction);
        for (final sticky in [false, true]) {
          host.update(() => host.sticky = sticky);
          await tester.pumpAndSettle();
          expect(surfaces(tester), hasLength(2));
          for (final popup in surfaces(tester)) {
            expect(popup.width, 224);
          }
        }
        expect(host.changes, [true]);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Sticky root and long child use the complete boundary $direction',
      (tester) async {
        final host = await mount(tester, direction);
        host.update(() => host.sticky = true);
        await tester.pumpAndSettle();
        await openChild(tester, direction);
        for (final popup in surfaces(tester)) {
          expect(popup.top, 110);
          expect(popup.bottom, 670);
          expect(popup.left, greaterThanOrEqualTo(160));
          expect(popup.right, lessThanOrEqualTo(660));
        }
        expect(host.changes, [true]);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Sticky retains two levels after vertical and horizontal clipping $direction',
      (tester) async {
        final host = await mount(tester, direction);
        host.update(() {
          host.sticky = true;
          host.boundary = null;
          host.padding = const EdgeInsets.all(5);
        });
        await tester.pumpAndSettle();
        await openChild(tester, direction);
        final focus = FocusManager.instance.primaryFocus;
        host.scroll.jumpTo(700);
        host.update(() => host.translation = const Offset(-600, 0));
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, same(focus));
        expect(surfaces(tester), hasLength(2));
        for (final popup in surfaces(tester)) {
          expect(popup.left, greaterThanOrEqualTo(5));
          expect(popup.top, greaterThanOrEqualTo(5));
          expect(popup.right, lessThanOrEqualTo(795));
          expect(popup.bottom, lessThanOrEqualTo(795));
        }
        expect(host.changes, [true]);
        final origin = Offset(
          surfaces(tester).first.left,
          tester.getRect(find.byType(SteyButton)).center.dy,
        );
        await tester.tapAt(const Offset(780, 780));
        await tester.pump();
        final transition =
            tester
                    .widgetList<Opacity>(find.byType(Opacity))
                    .firstWhere((widget) => widget.child is Transform)
                    .child!
                as Transform;
        expect(transition.origin, origin);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Sticky changes preserve primary focus, selection and open levels $direction',
      (tester) async {
        final host = await mount(tester, direction);
        host.update(() {
          host.boundary = null;
          host.padding = const EdgeInsets.all(5);
          host.checked = false;
        });
        await tester.pumpAndSettle();
        await openChild(tester, direction);
        final focus = FocusManager.instance.primaryFocus;
        host.scroll.jumpTo(700);
        await tester.pumpAndSettle();
        final attached = surfaces(tester).first;
        expect(attached.top, lessThan(0));
        host.update(() => host.sticky = true);
        await tester.pumpAndSettle();
        expect(surfaces(tester).first.top, 5);
        host.update(() => host.sticky = false);
        await tester.pumpAndSettle();
        expect(surfaces(tester).first, attached);
        expect(surfaces(tester), hasLength(2));
        expect(FocusManager.instance.primaryFocus, same(focus));
        expect(host.checked, isFalse);
        expect(host.changes, [true]);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('Sticky resizes above the software keyboard $direction', (
      tester,
    ) async {
      final host = await mount(tester, direction);
      host.update(() {
        host.sticky = true;
        host.boundary = null;
        host.padding = const EdgeInsets.all(5);
      });
      await tester.pumpAndSettle();
      await openChild(tester, direction);
      final focus = FocusManager.instance.primaryFocus;
      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(surfaces(tester), hasLength(2));
      for (final popup in surfaces(tester)) {
        expect(popup.top, 5);
        expect(popup.bottom, 395);
      }
      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(host.changes, [true]);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'Boundary and physical padding constrain root and child $direction',
      (tester) async {
        await mount(tester, direction);
        final root = surfaces(tester).single;
        expect(root.left, greaterThanOrEqualTo(160));
        expect(root.right, lessThanOrEqualTo(660));
        expect(root.top, 110);
        expect(root.bottom, 374); // Larger side is above the trigger: 382 - 8.
        await openChild(tester, direction);
        final child = surfaces(tester).last;
        expect(child.left, greaterThanOrEqualTo(160));
        expect(child.right, lessThanOrEqualTo(660));
        expect(child.top, greaterThanOrEqualTo(110));
        expect(child.bottom, lessThanOrEqualTo(670));
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Changing a boundary retains nested focus and open state $direction',
      (tester) async {
        final host = await mount(tester, direction);
        await openChild(tester, direction);
        final focus = FocusManager.instance.primaryFocus;
        host.update(
          () => host.boundary = const Rect.fromLTWH(160, 140, 480, 520),
        );
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, same(focus));
        expect(surfaces(tester), hasLength(2));
        expect(host.changes, [true]);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Fully clipped anchor stays attached and recovers on scroll $direction',
      (tester) async {
        final host = await mount(tester, direction);
        host.update(() {
          host.boundary = null;
          host.padding = const EdgeInsets.all(5);
        });
        await tester.pumpAndSettle();
        await openChild(tester, direction);
        final focus = FocusManager.instance.primaryFocus;
        final initial = surfaces(tester).first;
        for (final offset in [400.0, 450.0, 700.0]) {
          host.scroll.jumpTo(offset);
          await tester.pumpAndSettle();
          final anchor = tester.getRect(find.byType(SteyButton));
          final popup = surfaces(tester).first;
          expect(popup.top, anchor.bottom + 8);
          expect(popup.height, lessThanOrEqualTo(790));
          expect(host.menu.isOpen, isTrue);
          expect(FocusManager.instance.primaryFocus, same(focus));
          expect(host.changes, [true]);
          expect(surfaces(tester), hasLength(2));
          if (offset == 700) {
            expect(
              surfaces(tester).last.top,
              tester.getRect(row('Move')).bottom,
            );
          }
        }
        host.scroll.jumpTo(0);
        await tester.pumpAndSettle();
        expect(surfaces(tester).first, initial);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Horizontal shift cannot detach from a fully clipped anchor $direction',
      (tester) async {
        final host = await mount(tester, direction);
        host.update(() {
          host.boundary = null;
          host.translation = const Offset(-600, 0);
        });
        await tester.pumpAndSettle();
        final anchor = tester.getRect(find.byType(SteyButton));
        expect(surfaces(tester).single.left, anchor.right);
        expect(host.changes, [true]);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
