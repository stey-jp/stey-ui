import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child, {Brightness mode = Brightness.light}) => MaterialApp(
  theme: SteyTheme.material(mode),
  home: Scaffold(body: Center(child: child)),
);
TextStyle style(WidgetTester t) =>
    DefaultTextStyle.of(t.element(find.text('Docs'))).style;
void main() {
  testWidgets('link inherits typography and has no button padding or role', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      host(
        SteyLink(
          href: Uri.parse('/docs'),
          onPressed: () {},
          child: const Text('Docs'),
        ),
      ),
    );
    expect(find.byType(TextButton), findsNothing);
    expect(t.getSize(find.byType(SteyLink)).height, 21);
    final data = t.getSemantics(find.text('Docs')).getSemanticsData();
    expect(data.flagsCollection.isLink, true);
    expect(data.flagsCollection.isButton, false);
    expect(data.linkUrl, Uri.parse('/docs'));
    semantics.dispose();
  });
  testWidgets(
    'three variants inherit current color and keep link color defensive',
    (t) async {
      for (final variant in SteyLinkVariant.values) {
        await t.pumpWidget(
          host(
            DefaultTextStyle.merge(
              style: const TextStyle(
                color: Colors.red,
                fontSize: 18,
                height: 2,
              ),
              child: SteyLink(
                variant: variant,
                onPressed: () {},
                child: const Text('Docs'),
              ),
            ),
          ),
        );
        expect(
          style(t).color,
          variant == SteyLinkVariant.current
              ? Colors.red
              : const SteyColors(Brightness.light).link,
        );
        expect(style(t).fontSize, 18);
        expect(style(t).height, 2);
        expect(
          style(t).decoration,
          variant == SteyLinkVariant.plain
              ? TextDecoration.none
              : TextDecoration.underline,
        );
      }
    },
  );
  testWidgets(
    'underline opacity and immediate hover colors follow both themes',
    (t) async {
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(0, 0));
      for (final mode in Brightness.values) {
        for (final variant in [SteyLinkVariant.inline, SteyLinkVariant.plain]) {
          await mouse.moveTo(Offset.zero);
          await t.pumpWidget(
            host(
              SteyLink(
                variant: variant,
                onPressed: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('Docs'), Icon(Icons.add)],
                ),
              ),
              mode: mode,
            ),
          );
          await t.pumpAndSettle();
          final c = SteyColors(mode).link;
          expect(
            style(t).decorationColor,
            c.withValues(alpha: mode == Brightness.dark ? .65 : .35),
          );
          await mouse.moveTo(t.getCenter(find.text('Docs')));
          await t.pump();
          expect(
            style(t).color,
            variant == SteyLinkVariant.plain ? c.withValues(alpha: .7) : c,
          );
          expect(style(t).decorationColor, c);
          expect(
            IconTheme.of(t.element(find.byIcon(Icons.add))).color,
            style(t).color,
          );
        }
      }
      await mouse.removePointer();
    },
  );
  testWidgets('pointer and Enter activate once while Space never activates', (
    t,
  ) async {
    var calls = 0;
    await t.pumpWidget(
      host(SteyLink(onPressed: () => calls++, child: const Text('Docs'))),
    );
    await t.tap(find.text('Docs'));
    await t.pump();
    expect(calls, 1);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(calls, 2);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pump();
    expect(calls, 2);
    expect(t.takeException(), isNull);
  });
  testWidgets('Space scrolls the surrounding viewport without activation', (
    t,
  ) async {
    final controller = ScrollController();
    var calls = 0;
    await t.pumpWidget(
      host(
        SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              SteyLink(
                autofocus: true,
                onPressed: () => calls++,
                child: const Text('Docs'),
              ),
              const SizedBox(height: 1800),
            ],
          ),
        ),
      ),
    );
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    expect(calls, 0);
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await t.pumpAndSettle();
    expect(controller.offset, 0);
    expect(calls, 0);
    await t.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('disabled and legacy null callback cannot focus or activate', (
    t,
  ) async {
    var calls = 0;
    final node = FocusNode();
    for (final disabled in [false, true]) {
      await t.pumpWidget(
        host(
          SteyLink(
            focusNode: node,
            disabled: disabled,
            onPressed: disabled ? () => calls++ : null,
            child: const Text('Docs'),
          ),
        ),
      );
      await t.tap(find.text('Docs'));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(calls, 0);
      expect(node.hasFocus, false);
    }
    await t.pumpWidget(const SizedBox());
    node.dispose();
  });
  testWidgets(
    'provider receives href and target; direct callback takes precedence',
    (t) async {
      final events = <String>[];
      for (final direct in [false, true]) {
        await t.pumpWidget(
          host(
            SteyLinkProvider(
              onNavigate: (uri, target) => events.add('$uri $target'),
              child: SteyLink(
                href: Uri.parse('/docs'),
                target: '_blank',
                onPressed: direct ? () => events.add('direct') : null,
                child: const Text('Docs'),
              ),
            ),
          ),
        );
        await t.tap(find.text('Docs'));
        await t.pump();
      }
      expect(events, ['/docs _blank', 'direct']);
    },
  );
  testWidgets('external icon is one em and excluded from the accessible name', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      host(
        DefaultTextStyle.merge(
          style: const TextStyle(fontSize: 20),
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SteyLink(
              onPressed: () {},
              external: true,
              child: const Text('Docs'),
            ),
          ),
        ),
      ),
    );
    expect(t.getSize(find.byType(SteyLinkExternalIcon)), const Size(40, 40));
    expect(t.getSemantics(find.text('Docs')).getSemanticsData().label, 'Docs');
    semantics.dispose();
  });
  testWidgets('narrow RTL link wraps and retains full accessible text', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      host(
        SizedBox(
          width: 120,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SteyLink(
              onPressed: () {},
              external: true,
              child: const Text('Read documentation across the network'),
            ),
          ),
        ),
      ),
    );
    expect(t.getSize(find.byType(SteyLink)).width, 120);
    expect(t.getSize(find.byType(SteyLink)).height, greaterThan(21));
    expect(
      t
          .getSemantics(find.text('Read documentation across the network'))
          .getSemanticsData()
          .label,
      'Read documentation across the network',
    );
    expect(t.takeException(), isNull);
    semantics.dispose();
  });
  testWidgets(
    'custom layout child keeps its own constraints without intrinsic queries',
    (t) async {
      await t.pumpWidget(
        host(
          SizedBox(
            width: 160,
            child: SteyLink(
              onPressed: () {},
              child: LayoutBuilder(
                builder: (context, constraints) => const Text('Docs'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Docs'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('200percent narrow host retains min-content word width', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        SizedBox(
          width: 180,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SteyLink(
              onPressed: () {},
              external: true,
              child: const Text('Read documentation'),
            ),
          ),
        ),
      ),
    );
    expect(t.getSize(find.text('Read documentation')).width, greaterThan(180));
    expect(t.getSize(find.text('Read documentation')).height, 84);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'caller owned focus survives link removal and semantic label replaces content',
    (t) async {
      final semantics = t.ensureSemantics(), node = FocusNode();
      await t.pumpWidget(
        host(
          SteyLink(
            focusNode: node,
            autofocus: true,
            semanticLabel: 'Documentation',
            onPressed: () {},
            child: const Text('Docs'),
          ),
        ),
      );
      await t.pump();
      expect(node.hasFocus, true);
      expect(
        t
            .getSemantics(find.bySemanticsLabel('Documentation'))
            .getSemanticsData()
            .label,
        'Documentation',
      );
      await t.pumpWidget(const SizedBox());
      expect(() => node.requestFocus(), returnsNormally);
      node.dispose();
      semantics.dispose();
    },
  );
}
