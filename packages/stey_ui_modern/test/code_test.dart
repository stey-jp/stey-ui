import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: SteyTheme(
    brightness: brightness,
    child: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: Center(child: SizedBox(width: 320, child: child)),
        ),
      ),
    ),
  ),
);

class CountingHighlighter extends SteyCodeHighlighter {
  int calls = 0;
  @override
  TextSpan? highlight(String code, String lang, {required bool dark}) {
    calls++;
    return super.highlight(code, lang, dark: dark);
  }
}

List<Color> colors(InlineSpan span) => [
  ?span.style?.color,
  if (span is TextSpan)
    for (final child in span.children ?? <InlineSpan>[]) ...colors(child),
];

void main() {
  const snippets = {
    'javascript': 'const text = "日本語"; // comment\nconsole.log(text);\n',
    'typescript': 'const count: number = 42;\n',
    'jsx': 'const view = <button disabled={false}>Save</button>;',
    'tsx': 'const view = (name: string) => <h1>{name}</h1>;',
    'json': '{ "name": "Stey", "count": 42 }',
    'jsonc': '{ // comment\n "count": 42\n}',
    'html': '<button type="button">Save</button>',
    'css': '.button { color: #005cc5; }',
    'python': 'def greet(name):\n    return f"Hello, {name}"',
    'yaml': 'name: Stey\nenabled: true',
    'markdown': '# Stey\n**Native** and `code`',
    'graphql': 'query Worker { worker(id: "stey") { name } }',
    'sql': 'SELECT name FROM workers WHERE count = 42;',
    'bash': '# comment\nexport NAME="stey"',
    'shell': '\$ echo "Stey"\nStey',
    'diff': '--- before\n+++ after\n-old\n+new',
    'hcl': 'resource "worker" "stey" { enabled = true }',
    'toml': '[worker]\nname = "stey"\nenabled = true',
  };
  for (final entry in snippets.entries) {
    test('${entry.key} keeps source and emits token colors in both themes', () {
      final engine = SteyCodeHighlighter();
      for (final dark in [false, true]) {
        final span = engine.highlight(entry.value, entry.key, dark: dark);
        expect(span, isNotNull);
        expect(span!.toPlainText(), entry.value);
        expect(colors(span), isNotEmpty);
      }
    });
  }
  test('Aliases are exact, case sensitive, and respect selected languages', () {
    final engine = SteyCodeHighlighter(languages: ['js', 'ts', 'unknown']);
    for (final lang in ['js', 'cjs', 'mjs', 'ts', 'cts', 'mts']) {
      expect(
        engine.highlight('const value = 42;', lang, dark: false),
        isNotNull,
      );
    }
    for (final lang in ['JS', 'mdx', 'rust', 'python']) {
      expect(engine.highlight('text', lang, dark: false), isNull);
    }
    for (final entry in {
      'sh': 'bash',
      'zsh': 'bash',
      'yml': 'yaml',
      'py': 'python',
      'md': 'markdown',
      'gql': 'graphql',
    }.entries) {
      expect(normalizeSteyCodeLanguage(entry.key), entry.value);
    }
  });
  test('Empty, whitespace, CRLF, and tabs survive parsing', () {
    final engine = SteyCodeHighlighter();
    for (final code in ['', '\t const x = "日本語";\r\n\r\n', '  \n\n']) {
      expect(engine.highlight(code, 'js', dark: false)!.toPlainText(), code);
    }
  });
  testWidgets('Numbers are multiline only, excluded from accessible source', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const SteyCodeHighlighted(
          'const a = 1;\nconst b = 2;\n',
          lang: 'js',
          showLineNumbers: true,
        ),
      ),
    );
    expect(find.text('1\n2\n3'), findsOneWidget);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).semanticsLabel,
      'const a = 1;\nconst b = 2;\n',
    );
    expect(
      find.bySemanticsLabel('const a = 1;\nconst b = 2;\n'),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('1\n2\n3'),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<SelectableText>(find.byType(SelectableText))
          .textSpan!
          .toPlainText(),
      'const a = 1;\nconst b = 2;\n',
    );
    await tester.pumpWidget(
      host(
        const SteyCodeHighlighted(
          'const a = 1;',
          lang: 'js',
          showLineNumbers: true,
        ),
      ),
    );
    expect(find.text('1'), findsNothing);
    semantics.dispose();
  });
  testWidgets('Plain variant removes frame and 16px padding', (tester) async {
    await tester.pumpWidget(
      host(const SteyCodeHighlighted('const a = 1;\nconst b = 2;', lang: 'js')),
    );
    final framed = tester.getSize(find.byType(SteyCodeHighlighted));
    await tester.pumpWidget(
      host(
        const SteyCodeHighlighted(
          'const a = 1;\nconst b = 2;',
          lang: 'js',
          variant: SteyCodeHighlightedVariant.plain,
        ),
      ),
    );
    expect(
      framed.height - tester.getSize(find.byType(SteyCodeHighlighted)).height,
      closeTo(34, .01),
    );
  });
  testWidgets(
    'Null scope falls back and changing language/theme invalidates cache',
    (tester) async {
      final highlighter = CountingHighlighter();
      Widget subject({
        SteyCodeHighlighter? engine,
        Brightness brightness = Brightness.light,
        String lang = 'js',
      }) => host(
        SteyCodeHighlighting(
          highlighter: engine,
          child: SteyCodeHighlighted(
            'const a = 1;',
            lang: lang,
            showCopyButton: true,
          ),
        ),
        brightness: brightness,
      );
      await tester.pumpWidget(subject());
      expect(
        colors(
          tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!,
        ).length,
        1,
      );
      await tester.pumpWidget(subject(engine: highlighter));
      expect(highlighter.calls, 1);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(
        location: tester.getCenter(find.byType(SteyCodeHighlighted)),
      );
      await tester.pump();
      expect(highlighter.calls, 1);
      await tester.pumpWidget(
        subject(engine: highlighter, brightness: Brightness.dark),
      );
      expect(highlighter.calls, 2);
      expect(
        colors(
          tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!,
        ),
        contains(const Color(0xffffc799)),
      );
      await tester.pumpWidget(subject(engine: highlighter, lang: 'unknown'));
      expect(highlighter.calls, 3);
      expect(
        colors(
          tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!,
        ).length,
        1,
      );
      await gesture.removePointer();
    },
  );
  testWidgets(
    'Copy preserves original source, label precedence, and two-second feedback',
    (tester) async {
      const source = '\tconst a = "日本語";\r\n\n';
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        host(
          const SteyCodeHighlighting(
            highlighter: null,
            copyLabel: '共有コピー',
            copiedLabel: '共有成功',
            child: SteyCodeHighlighted(
              source,
              lang: 'js',
              showCopyButton: true,
              copyLabel: 'コピー',
              copiedLabel: '完了',
            ),
          ),
        ),
      );
      await tester.tap(find.text('コピー'));
      await tester.pump();
      expect(copied, source);
      expect(find.text('完了'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(find.text('完了'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('コピー'), findsOneWidget);
    },
  );
  testWidgets('Latest clipboard attempt wins and failures are reported', (
    tester,
  ) async {
    final requests = <Completer<void>>[];
    final errors = <Object>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final pending = Completer<void>();
          requests.add(pending);
          return pending.future;
        }
        return;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      host(
        SteyCodeHighlighted(
          'const x = 1;',
          lang: 'js',
          showCopyButton: true,
          onCopyError: errors.add,
        ),
      ),
    );
    await tester.tap(find.text('Copy'));
    await tester.pump();
    await tester.tap(find.text('Copy'));
    await tester.pump();
    requests[1].completeError(PlatformException(code: 'denied'));
    await tester.pump();
    expect(errors, hasLength(1));
    requests[0].complete();
    await tester.pump();
    expect(find.text('Copied!'), findsNothing);
    await tester.tap(find.text('Copy'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    requests[2].complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Narrow, scaled RTL source scrolls without wrapping; numbers stay fixed',
    (tester) async {
      final code = 'const long = "${'abcdefghij' * 30}";\nconst end = 1;';
      await tester.pumpWidget(
        host(
          SteyCodeHighlighted(
            code,
            lang: 'js',
            showLineNumbers: true,
            showCopyButton: true,
            highlightLines: const [-1, 0, 2, 2, 99],
          ),
          scale: 2,
          direction: TextDirection.rtl,
        ),
      );
      final before = tester.getTopLeft(find.text('1\n2'));
      final scroll = find.descendant(
        of: find.byType(SteyCodeHighlighted),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(scroll, const Offset(-180, 0));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('1\n2')), before);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(SteyCodeHighlighted)).height,
        closeTo(118.5, 1),
      );
    },
  );
  testWidgets('Keyboard focus reveals copy and Enter activates it', (
    tester,
  ) async {
    var copies = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') copies++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      host(
        const SteyCodeHighlighted(
          'text',
          lang: 'unknown',
          showCopyButton: true,
        ),
      ),
    );
    for (
      var i = 0;
      i < 3 && !Focus.of(tester.element(find.text('Copy'))).hasFocus;
      i++
    ) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(copies, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Single-line copy follows short code inline within the full frame',
    (tester) async {
      await tester.pumpWidget(
        host(const SteyCodeHighlighted('x', lang: 'js', showCopyButton: true)),
      );
      final frame = tester.getRect(find.byType(SteyCodeHighlighted));
      final button = tester.getRect(find.byType(SteyButton));
      expect(button.right, lessThan(frame.right - 80));
      expect(button.center.dy, closeTo(frame.center.dy, .01));
      expect(frame.height, closeTo(55.125, .01));
    },
  );
  testWidgets('Hover fades for 150ms even with reduced motion enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SteyCodeHighlighted(
            'text',
            lang: 'unknown',
            showCopyButton: true,
          ),
        ),
      ),
    );
    final fade = find.ancestor(
      of: find.byType(SteyButton),
      matching: find.byType(FadeTransition),
    );
    double opacity() => tester.widget<FadeTransition>(fade.first).opacity.value;
    expect(opacity(), 0);
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: const Offset(1, 1));
    await pointer.moveTo(tester.getCenter(find.byType(SteyCodeHighlighted)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(opacity(), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 75));
    expect(opacity(), 1);
    await pointer.moveTo(const Offset(1, 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(opacity(), 0);
    await pointer.removePointer();
  });
}
