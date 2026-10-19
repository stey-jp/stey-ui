import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  double width = 600,
  double scale = 1,
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  bool reduce = false,
}) => MaterialApp(
  theme: SteyTheme.material(brightness),
  home: SteyTheme(
    brightness: brightness,
    child: Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: width,
            child: Directionality(
              textDirection: direction,
              child: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: reduce,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Finder copyButton() => find.bySemanticsLabel('Copy command');
CustomPainter icon(WidgetTester t) => t
    .widget<CustomPaint>(
      find.descendant(
        of: copyButton(),
        matching: find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_CommandIcon',
        ),
      ),
    )
    .painter!;
bool checked(WidgetTester t) => (icon(t) as dynamic).checked as bool;

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
    'without description title is secondary h2 and no implicit icon',
    (t) async {
      await t.pumpWidget(host(const SteyEmpty(title: 'Nothing here')));
      final paragraph = t.renderObject<RenderParagraph>(
        find.text('Nothing here'),
      );
      expect(paragraph.text.style!.fontSize, 14);
      expect(paragraph.text.style!.fontWeight, FontWeight.w400);
      expect(
        paragraph.text.style!.color,
        const SteyColors(Brightness.light).subtle,
      );
      expect(
        t
            .getSemantics(find.text('Nothing here'))
            .getSemanticsData()
            .headingLevel,
        2,
      );
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(SteyButton), findsNothing);
      expect(t.getSize(find.byType(SteyEmpty)), const Size(600, 151));
    },
  );
  testWidgets(
    'described title is 20px semibold, description is centered with a 10px gap',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyEmpty(
            title: 'No results',
            description: 'Try adjusting your search.',
          ),
        ),
      );
      final title = t.renderObject<RenderParagraph>(find.text('No results'));
      expect(title.text.style!.fontSize, 20);
      expect(title.text.style!.fontWeight, FontWeight.w600);
      expect(title.text.style!.height, 1.4);
      expect(
        t.getTopLeft(find.text('Try adjusting your search.')).dy -
            t.getBottomLeft(find.text('No results')).dy,
        10,
      );
      expect(
        t
            .renderObject<RenderParagraph>(
              find.text('Try adjusting your search.'),
            )
            .textAlign,
        TextAlign.center,
      );
      expect(t.getSize(find.byType(SteyEmpty)).height, 189);
    },
  );
  testWidgets('three sizes match padding/gap/border and theme surfaces', (
    t,
  ) async {
    for (final brightness in Brightness.values) {
      for (final size in SteyEmptySize.values) {
        final index = size.index,
            h = [24.0, 40.0, 48.0][index],
            v = [32.0, 64.0, 80.0][index],
            gap = [16.0, 24.0, 32.0][index];
        await t.pumpWidget(
          host(
            SteyEmpty(
              title: 'Title',
              size: size,
              illustration: const SizedBox(
                key: Key('art'),
                width: 48,
                height: 48,
              ),
              contents: const SizedBox(
                key: Key('action'),
                width: 100,
                height: 36,
              ),
            ),
            brightness: brightness,
          ),
        );
        expect(t.getTopLeft(find.byKey(const Key('art'))).dy, v + 1);
        expect(
          t.getTopLeft(find.text('Title')).dy -
              t.getBottomLeft(find.byKey(const Key('art'))).dy,
          gap,
        );
        expect(
          t.getTopLeft(find.byKey(const Key('action'))).dy -
              t.getBottomLeft(find.text('Title')).dy,
          gap,
        );
        final box = t.widget<Container>(
          find
              .descendant(
                of: find.byType(SteyEmpty),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = box.decoration! as BoxDecoration,
            colors = SteyColors(brightness);
        expect(decoration.color, colors.control);
        expect((decoration.border! as Border).left.color, colors.fill);
        expect(decoration.borderRadius, BorderRadius.circular(12));
        expect(box.padding, EdgeInsets.symmetric(horizontal: h, vertical: v));
      }
    }
  });
  testWidgets(
    'empty strings omit description and command, whitespace is preserved',
    (t) async {
      await t.pumpWidget(
        host(const SteyEmpty(title: '', description: '', commandLine: '')),
      );
      expect(find.byType(SteyButton), findsNothing);
      await t.pumpWidget(
        host(
          const SteyEmpty(
            title: 'Title',
            description: ' ',
            commandLine: '\t \n',
          ),
        ),
      );
      expect(find.byType(SelectionArea), findsOneWidget);
      await t.tap(copyButton());
      await t.pump();
      expect(writes, ['\t \n']);
      await t.pump(const Duration(seconds: 1));
    },
  );
  testWidgets(
    'command is 40px, max 80 percent, scrolls without a scrollbar and copies raw text',
    (t) async {
      final raw = 'flutter create --org stey.jp project${' --option' * 20}';
      await t.pumpWidget(
        host(SteyEmpty(title: 'Install', commandLine: raw), width: 350),
      );
      final command = find
          .ancestor(
            of: copyButton(),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.height == 40,
            ),
          )
          .first;
      expect(t.getSize(command).height, 40);
      expect(t.getSize(command).width, closeTo((350 - 82) * .8, .01));
      final scroller = find.descendant(
        of: find.byType(SteyEmpty),
        matching: find.byType(SingleChildScrollView),
      );
      expect(
        t.widget<SingleChildScrollView>(scroller).scrollDirection,
        Axis.horizontal,
      );
      expect(t.getSize(find.byType(TextButton)), const Size.square(26));
      await t.drag(scroller, const Offset(-80, 0));
      await t.pumpAndSettle();
      await t.tap(copyButton());
      await t.pump();
      expect(writes, [raw]);
      expect(checked(t), true);
      await t.pump(const Duration(milliseconds: 999));
      expect(checked(t), true);
      await t.pump(const Duration(milliseconds: 1));
      expect(checked(t), false);
    },
  );
  testWidgets(
    'selection is not a Tab stop, Enter and Space use the existing native Button',
    (t) async {
      await t.pumpWidget(
        host(const SteyEmpty(title: 'Install', commandLine: 'dart pub get')),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<TextButton>(),
        isNotNull,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(writes, ['dart pub get']);
      await t.sendKeyDownEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(writes.length, 1);
      await t.sendKeyUpEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(writes.length, 2);
      await t.pump(const Duration(seconds: 1));
    },
  );
  testWidgets(
    'latest asynchronous attempt wins and success lasts from its completion',
    (t) async {
      final requests = <Completer<void>>[];
      var calls = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) {
          if (call.method != 'Clipboard.setData') return Future.value();
          final request = Completer<void>();
          requests.add(request);
          return request.future;
        },
      );
      await t.pumpWidget(
        host(
          SteyEmpty(
            title: 'Install',
            commandLine: 'dart pub get',
            onCopied: () => calls++,
          ),
        ),
      );
      await t.tap(copyButton());
      await t.pump();
      await t.tap(copyButton());
      await t.pump();
      requests[1].complete();
      await t.pump();
      await t.pump();
      expect(checked(t), true);
      expect(calls, 1);
      await t.pump(const Duration(milliseconds: 700));
      requests[0].completeError(PlatformException(code: 'denied'));
      await t.pump();
      expect(checked(t), true);
      expect(calls, 1);
      await t.pump(const Duration(milliseconds: 300));
      expect(checked(t), false);
    },
  );
  testWidgets(
    'a failed newest copy clears feedback and reports only the current error',
    (t) async {
      var errors = 0;
      await t.pumpWidget(
        host(
          SteyEmpty(
            title: 'Install',
            commandLine: 'dart pub get',
            onCopyError: (_) => errors++,
          ),
        ),
      );
      await t.tap(copyButton());
      await t.pump();
      expect(checked(t), true);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'denied');
          }
          return null;
        },
      );
      await t.tap(copyButton());
      await t.pump();
      expect(checked(t), false);
      expect(errors, 1);
    },
  );
  testWidgets(
    'changing command preserves feedback but next copy uses the new value',
    (t) async {
      await t.pumpWidget(
        host(const SteyEmpty(title: 'Install', commandLine: 'first')),
      );
      await t.tap(copyButton());
      await t.pump();
      expect(checked(t), true);
      await t.pump(const Duration(milliseconds: 600));
      await t.pumpWidget(
        host(const SteyEmpty(title: 'Install', commandLine: 'second')),
      );
      expect(checked(t), true);
      await t.tap(copyButton());
      await t.pump();
      expect(writes, ['first', 'second']);
      await t.pump(const Duration(milliseconds: 999));
      expect(checked(t), true);
      await t.pump(const Duration(milliseconds: 1));
      expect(checked(t), false);
    },
  );
  testWidgets('pending copy and timer do not update disposed state', (t) async {
    final request = Completer<void>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) => request.future,
    );
    await t.pumpWidget(
      host(const SteyEmpty(title: 'Install', commandLine: 'dart pub get')),
    );
    await t.tap(copyButton());
    await t.pump();
    await t.pumpWidget(const SizedBox());
    request.complete();
    await t.pump();
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'repeated success extends feedback without replaying the bounce',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyEmpty(title: 'Install', commandLine: 'dart pub get'),
          reduce: true,
        ),
      );
      await t.tap(copyButton());
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      final transform = find
          .descendant(of: copyButton(), matching: find.byType(Transform))
          .last;
      expect(
        t.widget<Transform>(transform).transform.storage[0],
        closeTo(1.2, .001),
      );
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(copyButton());
      await t.pump();
      expect(t.widget<Transform>(transform).transform.storage[0], 1);
      await t.pump(const Duration(milliseconds: 999));
      expect(checked(t), true);
      await t.pump(const Duration(milliseconds: 1));
      expect(checked(t), false);
    },
  );
  testWidgets(
    'contents takes precedence over legacy action, icon and illustration are decorative',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyEmpty(
            title: 'Title',
            icon: Icons.inbox,
            action: Text('Legacy'),
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('Legacy'), findsOneWidget);
      await t.pumpWidget(
        host(
          const SteyEmpty(
            title: 'Title',
            icon: Icons.inbox,
            illustration: Icon(Icons.add, semanticLabel: 'Decoration'),
            action: Text('Legacy'),
            contents: Text('Contents'),
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox), findsNothing);
      expect(find.text('Legacy'), findsNothing);
      expect(find.text('Contents'), findsOneWidget);
      expect(find.bySemanticsLabel('Decoration'), findsNothing);
    },
  );
  testWidgets(
    'description has a 560px cap, narrow RTL and 2x remain usable in each size',
    (t) async {
      const description =
          'Review your project settings and permissions before creating the first resource.';
      await t.pumpWidget(
        host(
          const SteyEmpty(title: 'Title', description: description),
          width: 900,
        ),
      );
      expect(t.getSize(find.text(description)).width, lessThanOrEqualTo(560));
      for (final size in SteyEmptySize.values) {
        await t.pumpWidget(
          host(
            SteyEmpty(
              title: 'リソースがまだありません',
              description: description,
              size: size,
              commandLine: 'flutter create ${'name' * 30}',
            ),
            width: 320,
            scale: 2,
            direction: TextDirection.rtl,
          ),
        );
        expect(t.takeException(), isNull);
        expect(t.getSize(copyButton()).width, 26);
      }
    },
  );
}
