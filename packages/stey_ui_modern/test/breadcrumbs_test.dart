import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  double width = 600,
  double viewport = 1200,
  double scale = 1,
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: SteyTheme.material(brightness),
  home: SteyTheme(
    brightness: brightness,
    child: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(
          size: Size(viewport, 900),
          textScaler: TextScaler.linear(scale),
        ),
        child: Directionality(
          textDirection: direction,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  ),
);
Widget trail({
  bool loading = false,
  bool icon = false,
  Widget? extra,
  SteyBreadcrumbsSize size = SteyBreadcrumbsSize.base,
}) => SteyBreadcrumbs(
  size: size,
  children: [
    SteyBreadcrumbsLink(
      href: Uri.parse('#account'),
      onPressed: () {},
      child: const Text('Account'),
    ),
    const SteyBreadcrumbsSeparator(),
    SteyBreadcrumbsLink(
      href: Uri.parse('#projects'),
      onPressed: () {},
      child: const Text('Projects'),
    ),
    const SteyBreadcrumbsSeparator(),
    SteyBreadcrumbsCurrent(
      loading: loading,
      icon: icon ? const SizedBox(width: 16, height: 16) : null,
      child: const Text('Current resource'),
    ),
    ?extra,
  ],
);
Finder copy() => find.bySemanticsLabel('Copy');
bool copied(WidgetTester t) =>
    (t
                    .widget<CustomPaint>(
                      find.descendant(
                        of: copy(),
                        matching: find.byWidgetPredicate(
                          (w) =>
                              w is CustomPaint &&
                              w.painter.runtimeType.toString() == '_CopyIcon',
                        ),
                      ),
                    )
                    .painter
                as dynamic)
            .checked
        as bool;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> writes;
  setUp(() {
    writes = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          writes.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
  });
  tearDown(
    () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  testWidgets(
    'two sizes use 48/40 height, right margin, 24px separator and 4/2 gaps',
    (t) async {
      for (final size in SteyBreadcrumbsSize.values) {
        await t.pumpWidget(host(trail(size: size)));
        expect(
          t.getSize(find.byType(SteyBreadcrumbs)).height,
          size == SteyBreadcrumbsSize.sm ? 40 : 48,
        );
        expect(
          t.getSize(find.byType(SteyBreadcrumbsSeparator).first),
          const Size.square(24),
        );
        expect(
          t.getTopLeft(find.byType(SteyBreadcrumbsSeparator).first).dx -
              t.getTopRight(find.byType(SteyBreadcrumbsLink).first).dx,
          size == SteyBreadcrumbsSize.sm ? 2 : 4,
        );
        final p = t.renderObject<RenderParagraph>(find.text('Account'));
        expect(
          p.text.style!.height,
          size == SteyBreadcrumbsSize.sm ? 1 / .85 : 1.5,
        );
        expect(
          p.text.style!.fontSize,
          size == SteyBreadcrumbsSize.sm ? 13 : 14,
        );
        final nav = find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.role == SemanticsRole.navigation,
        );
        expect(
          t.getSemantics(nav).getSemanticsData().role,
          SemanticsRole.navigation,
        );
        expect(t.getSize(nav).width, 584);
      }
    },
  );
  testWidgets(
    'mobile uses viewport boundary 640 and keeps parent/current/extras in order',
    (t) async {
      await t.pumpWidget(
        host(trail(extra: const Text('Extra')), viewport: 639, width: 500),
      );
      expect(find.text('Account'), findsNothing);
      expect(find.text('...'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Current resource'), findsOneWidget);
      expect(
        t.getTopLeft(find.text('Extra')).dx,
        greaterThan(t.getTopLeft(find.text('Current resource')).dx),
      );
      await t.pumpWidget(host(trail(), viewport: 640, width: 220));
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('...'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'one and two crumbs never produce mobile ellipsis and no implicit separator for parts',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyBreadcrumbs(
            children: [SteyBreadcrumbsCurrent(child: Text('Only'))],
          ),
          viewport: 320,
        ),
      );
      expect(find.text('...'), findsNothing);
      expect(find.byType(SteyBreadcrumbsSeparator), findsNothing);
      await t.pumpWidget(
        host(
          SteyBreadcrumbs(
            items: [
              SteyBreadcrumb('Home', onPressed: () {}),
              const SteyBreadcrumb('Current'),
            ],
          ),
          viewport: 320,
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(SteyBreadcrumbsSeparator), findsOneWidget);
    },
  );
  testWidgets(
    'only current text shrinks, preserves full semantic name, ancestors keep natural widths',
    (t) async {
      await t.pumpWidget(host(trail(), width: 420));
      final width = t.getSize(find.byType(SteyBreadcrumbsLink).first).width;
      await t.pumpWidget(host(trail(), width: 230));
      expect(t.getSize(find.byType(SteyBreadcrumbsLink).first).width, width);
      final p = t.renderObject<RenderParagraph>(find.text('Current resource'));
      expect(p.didExceedMaxLines, true);
      expect(
        t.getSemantics(find.text('Current resource')).label,
        'Current resource',
      );
      expect(
        t.getSemantics(find.text('Current resource')).getSemanticsData().hint,
        'Current page',
      );
      await t.pumpWidget(host(trail(icon: true), width: 80));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'links expose actual URLs and a single Tab target, Enter activates, Space does not',
    (t) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var calls = 0;
      await t.pumpWidget(
        host(
          SteyBreadcrumbs(
            children: [
              SteyBreadcrumbsLink(
                focusNode: node,
                href: Uri.parse('/account'),
                onPressed: () => calls++,
                child: const Text('Account'),
              ),
            ],
          ),
        ),
      );
      final data = t.getSemantics(find.text('Account')).getSemanticsData();
      expect(data.linkUrl, Uri.parse('/account'));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(node.hasFocus, true);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(calls, 1);
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(calls, 1);
      await t.tap(find.text('Account'));
      await t.pump();
      expect(calls, 2);
    },
  );
  testWidgets(
    'clipboard is mounted and focusable while transparent; focus reveals it in 150ms',
    (t) async {
      await t.pumpWidget(
        host(trail(extra: const SteyBreadcrumbsClipboard(text: 'raw'))),
      );
      final fade = find.descendant(
        of: find.byType(SteyBreadcrumbsClipboard),
        matching: find.byType(FadeTransition),
      );
      final glyph = find.descendant(
        of: find.byType(SteyBreadcrumbsClipboard),
        matching: find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_CopyIcon',
        ),
      );
      expect(t.getSize(glyph), const Size.square(12));
      expect(t.widget<FadeTransition>(fade).opacity.value, 0);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.pump(const Duration(milliseconds: 75));
      expect(t.widget<FadeTransition>(fade).opacity.value, greaterThan(0));
      await t.pump(const Duration(milliseconds: 75));
      expect(t.widget<FadeTransition>(fade).opacity.value, 1);
      await t.sendKeyDownEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(writes, isEmpty);
      await t.sendKeyUpEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(writes, ['raw']);
      expect(copied(t), true);
      await t.pump(const Duration(milliseconds: 1999));
      expect(copied(t), true);
      await t.pump(const Duration(milliseconds: 1));
      expect(copied(t), false);
    },
  );
  testWidgets('repeat copies renew two seconds; empty text does nothing', (
    t,
  ) async {
    await t.pumpWidget(
      host(trail(extra: const SteyBreadcrumbsClipboard(text: '\t日本語\r\n'))),
    );
    await t.tap(copy());
    await t.pump();
    expect(writes, ['\t日本語\r\n']);
    await t.pump(const Duration(milliseconds: 1200));
    await t.tap(copy());
    await t.pump();
    await t.pump(const Duration(milliseconds: 1999));
    expect(copied(t), true);
    await t.pump(const Duration(milliseconds: 1));
    expect(copied(t), false);
    await t.pumpWidget(
      host(trail(extra: const SteyBreadcrumbsClipboard(text: ''))),
    );
    await t.tap(copy());
    await t.pump();
    expect(writes.length, 2);
  });
  testWidgets(
    'only the most recent async attempt can set feedback or call handlers',
    (t) async {
      final requests = <Completer<Object?>>[];
      var calls = 0, errors = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) {
          if (call.method != 'Clipboard.setData') return Future.value();
          final c = Completer<Object?>();
          requests.add(c);
          return c.future;
        },
      );
      await t.pumpWidget(
        host(
          trail(
            extra: SteyBreadcrumbsClipboard(
              text: 'raw',
              onCopied: () => calls++,
              onCopyError: (_) => errors++,
            ),
          ),
        ),
      );
      await t.tap(copy());
      await t.pump();
      await t.tap(copy());
      await t.pump();
      requests[1].complete();
      await t.pump();
      await t.pump();
      expect(copied(t), true);
      expect(calls, 1);
      requests[0].completeError(PlatformException(code: 'denied'));
      await t.pump();
      expect(errors, 0);
      expect(copied(t), true);
      await t.pump(const Duration(seconds: 2));
      expect(copied(t), false);
    },
  );
  testWidgets(
    'newest failure clears feedback and disposal ignores pending completion',
    (t) async {
      var errors = 0;
      await t.pumpWidget(
        host(
          trail(
            extra: SteyBreadcrumbsClipboard(
              text: 'raw',
              onCopyError: (_) => errors++,
            ),
          ),
        ),
      );
      await t.tap(copy());
      await t.pump();
      expect(copied(t), true);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'denied');
          }
          return null;
        },
      );
      await t.tap(copy());
      await t.pump();
      expect(copied(t), false);
      expect(errors, 1);
      final pending = Completer<Object?>();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) => call.method == 'Clipboard.setData'
            ? pending.future
            : Future.value(),
      );
      await t.tap(copy());
      await t.pump();
      await t.pumpWidget(const SizedBox());
      pending.complete();
      await t.pump();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'loading current reserves 125px, hides title and renders an 8px skeleton',
    (t) async {
      await t.pumpWidget(host(trail(loading: true, icon: true)));
      expect(find.text('Current resource'), findsNothing);
      expect(t.getSize(find.byType(SteyBreadcrumbsCurrent)).width, 125);
      final paints = find.descendant(
        of: find.byType(SteyBreadcrumbsCurrent),
        matching: find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_Shimmer',
        ),
      );
      expect(t.getSize(paints).height, 8);
      final first = t.getSize(paints).width;
      await t.pump(const Duration(seconds: 1));
      expect(t.getSize(paints).width, first);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'RTL keeps physical right margin and nonmirrored separator; narrow 2x and themes',
    (t) async {
      for (final b in Brightness.values) {
        await t.pumpWidget(
          host(
            trail(icon: true),
            width: 320,
            viewport: 390,
            scale: 2,
            brightness: b,
            direction: TextDirection.rtl,
          ),
        );
        final nav = find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.role == SemanticsRole.navigation,
        );
        expect(t.getTopRight(nav).dx, 304);
        expect(find.text('Account'), findsNothing);
        expect(
          t.getTopLeft(find.text('Projects')).dx,
          greaterThan(t.getTopLeft(find.text('Current resource')).dx),
        );
        expect(t.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'empty trail retains size, extras survive mobile reduction and loading switches cleanly',
    (t) async {
      await t.pumpWidget(host(const SteyBreadcrumbs()));
      expect(t.getSize(find.byType(SteyBreadcrumbs)).height, 48);
      await t.pumpWidget(
        host(
          trail(
            loading: true,
            extra: const SteyBreadcrumbsClipboard(text: 'raw'),
          ),
          viewport: 390,
        ),
      );
      await t.pump(const Duration(milliseconds: 50));
      expect(copy(), findsOneWidget);
      await t.pumpWidget(
        host(
          trail(extra: const SteyBreadcrumbsClipboard(text: 'raw')),
          viewport: 390,
        ),
      );
      await t.pump();
      expect(find.text('Current resource'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
