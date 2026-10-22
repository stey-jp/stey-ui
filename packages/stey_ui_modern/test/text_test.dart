import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  Brightness mode = Brightness.light,
  double width = 280,
  TextStyle style = const TextStyle(fontSize: 14, height: 1.5),
  double scale = 1,
}) => MaterialApp(
  theme: SteyTheme.material(mode),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: DefaultTextStyle.merge(
          style: style,
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: child,
          ),
        ),
      ),
    ),
  ),
);
Finder get text =>
    find.descendant(of: find.byType(SteyText), matching: find.byType(Text));
TextStyle resolved(WidgetTester t) => t.widget<Text>(text).style!;
void main() {
  testWidgets(
    'all body variants resolve four sizes and inherit computed line height',
    (t) async {
      for (final variant in [
        SteyTextVariant.body,
        SteyTextVariant.secondary,
        SteyTextVariant.success,
        SteyTextVariant.error,
      ]) {
        for (final (size, px) in [
          (SteyTextSize.xs, 12.0),
          (SteyTextSize.sm, 13.0),
          (SteyTextSize.base, 14.0),
          (SteyTextSize.lg, 16.0),
        ]) {
          await t.pumpWidget(
            host(
              SteyText('Content', variant: variant, size: size),
              style: const TextStyle(fontSize: 18, height: 2),
            ),
          );
          final s = resolved(t);
          expect(s.fontSize, px);
          expect(s.height! * s.fontSize!, 36);
          expect(s.fontWeight, FontWeight.w400);
        }
      }
    },
  );
  testWidgets('heading styles have their own sizes and line heights', (
    t,
  ) async {
    for (final (variant, size, px, line) in [
      (SteyTextVariant.heading, SteyTextSize.base, 16.0, 24.0),
      (SteyTextVariant.heading, SteyTextSize.lg, 20.0, 28.0),
      (SteyTextVariant.heading1, SteyTextSize.base, 30.0, 36.0),
      (SteyTextVariant.heading2, SteyTextSize.base, 24.0, 32.0),
      (SteyTextVariant.heading3, SteyTextSize.base, 16.0, 24.0),
    ]) {
      await t.pumpWidget(
        host(
          SteyText('Heading', variant: variant, size: size),
          style: const TextStyle(fontSize: 40, height: 2),
        ),
      );
      final s = resolved(t);
      expect(s.fontSize, px);
      expect(s.fontSize! * s.height!, line);
      expect(s.fontWeight, FontWeight.w600);
    }
  });
  testWidgets('monospace optical sizing ignores unsupported small sizes', (
    t,
  ) async {
    for (final variant in [
      SteyTextVariant.mono,
      SteyTextVariant.monoSecondary,
    ]) {
      for (final size in SteyTextSize.values) {
        await t.pumpWidget(
          host(
            SteyText('const n = 1', variant: variant, size: size, bold: true),
          ),
        );
        final s = resolved(t);
        expect(s.fontSize, size == SteyTextSize.lg ? 14 : 13);
        expect(s.height! * s.fontSize!, 21);
        expect(s.fontWeight, FontWeight.w400);
        expect(s.fontFamily, 'packages/stey_ui_modern/SteyCodeMono');
      }
    }
  });
  testWidgets('semantic headings are independent of visual style', (t) async {
    final h = t.ensureSemantics();
    try {
      await t.pumpWidget(
        host(const SteyText('Decoration', variant: SteyTextVariant.heading)),
      );
      expect(t.getSemantics(text).getSemanticsData().headingLevel, 0);
      for (var level = 1; level <= 6; level++) {
        await t.pumpWidget(
          host(
            SteyText(
              'Outline',
              variant: SteyTextVariant.body,
              headingLevel: level,
            ),
          ),
        );
        expect(t.getSemantics(text).getSemanticsData().headingLevel, level);
      }
      await t.pumpWidget(
        host(
          const SteyText(
            'Decoration',
            variant: SteyTextVariant.heading1,
            headingLevel: 0,
          ),
        ),
      );
      expect(t.getSemantics(text).getSemanticsData().headingLevel, 0);
    } finally {
      h.dispose();
    }
  });
  testWidgets(
    'legacy heading and subtle remain compatible; explicit variant wins',
    (t) async {
      for (final (level, px) in [(1, 30.0), (2, 24.0), (3, 20.0), (4, 16.0)]) {
        await t.pumpWidget(
          host(SteyText('Legacy', heading: level, subtle: true)),
        );
        expect(resolved(t).fontSize, px);
        expect(resolved(t).height, 1.5);
        expect(resolved(t).fontWeight, FontWeight.w600);
      }
      await t.pumpWidget(
        host(
          const SteyText(
            'Explicit',
            heading: 1,
            subtle: true,
            variant: SteyTextVariant.body,
          ),
        ),
      );
      expect(resolved(t).fontSize, 14);
      expect(resolved(t).color, const SteyColors(Brightness.light).text);
    },
  );
  testWidgets('colors follow semantic tokens in both themes', (t) async {
    for (final mode in Brightness.values) {
      final c = SteyColors(mode);
      for (final (variant, color) in [
        (SteyTextVariant.body, c.text),
        (SteyTextVariant.secondary, c.subtle),
        (SteyTextVariant.success, c.link),
        (SteyTextVariant.error, c.danger),
        (SteyTextVariant.monoSecondary, c.subtle),
      ]) {
        await t.pumpWidget(
          host(SteyText('Color', variant: variant), mode: mode),
        );
        await t.pumpAndSettle();
        expect(resolved(t).color, color);
      }
    }
  });
  testWidgets('copy bold is medium; unspecified weight and tracking inherit', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const SteyText('Copy', variant: SteyTextVariant.body),
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w600,
          letterSpacing: .2,
        ),
      ),
    );
    expect(resolved(t).fontWeight, FontWeight.w600);
    expect(resolved(t).letterSpacing, .2);
    await t.pumpWidget(
      host(const SteyText('Copy', variant: SteyTextVariant.body, bold: true)),
    );
    expect(resolved(t).fontWeight, FontWeight.w500);
  });
  testWidgets('truncation retains full semantic label and one line', (t) async {
    const value = 'A very long piece of content that cannot fit';
    final h = t.ensureSemantics();
    try {
      await t.pumpWidget(
        host(const SteyText(value, truncate: true), width: 80),
      );
      final w = t.widget<Text>(text);
      expect(w.maxLines, 1);
      expect(w.softWrap, false);
      expect(w.overflow, TextOverflow.ellipsis);
      expect(t.getSemantics(text).getSemanticsData().label, value);
      expect(t.takeException(), isNull);
    } finally {
      h.dispose();
    }
  });
  testWidgets('untruncated text wraps and scales without fixed height', (
    t,
  ) async {
    const widget = SteyText('Workers process requests across the network');
    await t.pumpWidget(host(widget, width: 120));
    final normal = t.getSize(text).height;
    await t.pumpWidget(host(widget, width: 120, scale: 2));
    expect(t.getSize(text).height, greaterThan(normal));
    expect(t.takeException(), isNull);
  });
  testWidgets('rich text styles and semantic override remain intact', (
    t,
  ) async {
    final h = t.ensureSemantics();
    try {
      await t.pumpWidget(
        host(
          const SteyText.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Hello '),
                TextSpan(
                  text: 'world',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            semanticLabel: 'Greeting',
          ),
        ),
      );
      expect(t.widget<Text>(text).textSpan!.toPlainText(), 'Hello world');
      expect(t.getSemantics(text).getSemanticsData().label, 'Greeting');
    } finally {
      h.dispose();
    }
  });
  testWidgets('RTL and empty content lay out without overflow', (t) async {
    await t.pumpWidget(
      host(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: SteyText('مرحبا Workers', truncate: true),
        ),
        width: 100,
      ),
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(host(const SteyText('')));
    expect(t.takeException(), isNull);
    expect(t.getSize(find.byType(SteyText)).height, 0);
  });
}
