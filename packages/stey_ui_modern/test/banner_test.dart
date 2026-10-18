import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  double width = 480,
  double scale = 1,
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: SteyTheme.material(brightness),
  home: SteyTheme(
    brightness: brightness,
    child: Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: width,
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Directionality(textDirection: direction, child: child),
            ),
          ),
        ),
      ),
    ),
  ),
);

RenderParagraph paragraph(WidgetTester tester, String value) =>
    tester.renderObject<RenderParagraph>(find.text(value));

void main() {
  testWidgets(
    'base structured banner has exact spacing, optional icon and inherited action',
    (tester) async {
      await tester.pumpWidget(
        host(
          SteyBanner(
            title: 'Update',
            description: const Text('Review settings'),
            action: SteyBannerAction(
              onPressed: () {},
              child: const Text('Details'),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(SteyBanner)).height,
        closeTo(63.125, .25),
      );
      expect(
        tester.getTopLeft(find.text('Update')).dx -
            tester.getTopLeft(find.byType(SteyBanner)).dx,
        16,
      );
      expect(paragraph(tester, 'Update').text.style!.fontSize, 14);
      expect(
        paragraph(tester, 'Update').text.style!.fontWeight,
        FontWeight.w500,
      );
      expect(paragraph(tester, 'Review settings').text.style!.fontSize, 13);
      expect(tester.getSize(find.byType(TextButton)).height, 26);
      expect(find.byType(Icon), findsNothing);
      expect(tester.getSemantics(find.text('Update')).label, 'Update');
      expect(
        tester.getSemantics(find.text('Review settings')).label,
        'Review settings',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'compact title and description share a line and wrap at a narrow width',
    (tester) async {
      Widget banner() => SteyBanner(
        size: SteyBannerSize.sm,
        title: 'Update',
        description: const Text('Review settings'),
        action: SteyBannerAction(
          onPressed: () {},
          child: const Text('Details'),
        ),
      );
      await tester.pumpWidget(host(banner()));
      expect(tester.getSize(find.byType(TextButton)).height, 20);
      expect(tester.getSize(find.byType(SteyBanner)).height, 36);
      expect(
        tester.getTopLeft(find.text('Update')).dy,
        tester.getTopLeft(find.text('Review settings')).dy,
      );
      await tester.pumpWidget(host(banner(), width: 200));
      expect(
        tester.getTopLeft(find.text('Review settings')).dy,
        greaterThan(tester.getTopLeft(find.text('Update')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'structured content wins over legacy child, text and unused action',
    (tester) async {
      await tester.pumpWidget(
        host(
          const SteyBanner(title: 'Title', text: 'Text', child: Text('Child')),
        ),
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Child'), findsNothing);
      expect(find.text('Text'), findsNothing);
      await tester.pumpWidget(
        host(
          const SteyBanner(
            title: '',
            text: 'Text',
            action: Text('Ignored'),
            child: Text('Child'),
          ),
        ),
      );
      expect(find.text('Child'), findsOneWidget);
      expect(find.text('Text'), findsNothing);
      expect(find.text('Ignored'), findsNothing);
      expect(tester.getSize(find.byType(SteyBanner)).height, 45);
      await tester.pumpWidget(host(const SteyBanner(text: 'Text')));
      expect(find.text('Text'), findsOneWidget);
    },
  );

  testWidgets(
    'description-only structured content gets the one-pixel top inset',
    (tester) async {
      await tester.pumpWidget(
        host(
          const SteyBanner(
            description: Text('Description'),
            icon: Icon(Icons.circle, size: 16),
          ),
        ),
      );
      final top = tester.getTopLeft(find.byType(SteyBanner)).dy;
      expect(tester.getTopLeft(find.text('Description')).dy - top, 13);
      expect(
        tester.getTopLeft(find.byType(Icon)).dy - top,
        closeTo(13.625, .001),
      );
    },
  );

  testWidgets(
    'all variants, sizes and themes use semantic surface/text/icon colors',
    (tester) async {
      for (final brightness in Brightness.values) {
        for (final variant in SteyBannerVariant.values) {
          for (final size in SteyBannerSize.values) {
            final c = SteyColors(brightness);
            await tester.pumpWidget(
              host(
                SteyBanner(
                  title: 'Title',
                  variant: variant,
                  size: size,
                  icon: const Icon(Icons.circle),
                ),
                brightness: brightness,
              ),
            );
            final color = switch (variant) {
              SteyBannerVariant.defaultValue => c.link,
              SteyBannerVariant.alert => c.warningText,
              SteyBannerVariant.error => c.dangerText,
              SteyBannerVariant.secondary => c.text.withValues(alpha: .7),
            };
            expect(paragraph(tester, 'Title').text.style!.color, color);
            final iconColor = IconTheme.of(tester.element(find.byType(Icon)))
                .color;
            expect(iconColor, switch (variant) {
              SteyBannerVariant.defaultValue => c.info,
              SteyBannerVariant.alert => c.warning,
              SteyBannerVariant.error => c.danger,
              SteyBannerVariant.secondary => c.interact,
            });
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );

  testWidgets(
    'legacy success tone and explicit variant precedence remain available',
    (tester) async {
      const c = SteyColors(Brightness.light);
      await tester.pumpWidget(
        host(const SteyBanner(tone: SteyTone.success, child: Text('Success'))),
      );
      expect(paragraph(tester, 'Success').text.style!.color, c.successText);
      expect(find.byType(Icon), findsOneWidget);
      await tester.pumpWidget(
        host(
          const SteyBanner(
            tone: SteyTone.success,
            variant: SteyBannerVariant.error,
            child: Text('Error'),
          ),
        ),
      );
      expect(paragraph(tester, 'Error').text.style!.color, c.dangerText);
    },
  );

  testWidgets('action context updates through wrapped and nested children', (
    tester,
  ) async {
    for (final size in SteyBannerSize.values) {
      await tester.pumpWidget(
        host(
          SteyBanner(
            size: size,
            variant: SteyBannerVariant.error,
            title: 'Title',
            action: Padding(
              padding: EdgeInsets.zero,
              child: SteyBannerAction(
                onPressed: () {},
                variant: SteyBannerActionVariant.secondary,
                child: const Text('Retry'),
              ),
            ),
          ),
        ),
      );
      final b = tester.widget<SteyButton>(find.byType(SteyButton));
      expect(b.size, size == SteyBannerSize.base ? SteySize.sm : SteySize.xs);
      expect(b.foregroundColor, const SteyColors(Brightness.light).dangerText);
    }
    await tester.pumpWidget(
      host(SteyBannerAction(onPressed: () {}, child: const Text('Outside'))),
    );
    expect(
      tester.widget<SteyButton>(find.byType(SteyButton)).size,
      SteySize.sm,
    );
    expect(
      tester.widget<SteyButton>(find.byType(SteyButton)).foregroundColor,
      Colors.white,
    );
  });

  testWidgets(
    'icon-only and multiple actions keep button height, order and callbacks',
    (tester) async {
      int calls = 0;
      await tester.pumpWidget(
        host(
          SteyBanner(
            size: SteyBannerSize.sm,
            title: 'Title',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                SteyBannerAction(
                  onPressed: () => calls++,
                  child: const Text('Details'),
                ),
                SteyBannerAction(
                  onPressed: () => calls += 10,
                  icon: const Icon(Icons.close),
                  variant: SteyBannerActionVariant.ghost,
                  semanticLabel: 'Close',
                ),
              ],
            ),
          ),
        ),
      );
      for (final b in find.byType(TextButton).evaluate()) {
        expect(tester.getSize(find.byWidget(b.widget)).height, 20);
      }
      await tester.tap(find.text('Details'));
      await tester.tap(find.bySemanticsLabel('Close'));
      expect(calls, 11);
    },
  );

  testWidgets(
    'disabled and loading actions do not invoke pointer or keyboard callbacks',
    (tester) async {
      int calls = 0;
      for (final variant in SteyBannerActionVariant.values) {
        for (final loading in [false, true]) {
          await tester.pumpWidget(
            host(
              SteyBanner(
                title: 'Title',
                action: SteyBannerAction(
                  onPressed: loading ? () => calls++ : null,
                  loading: loading,
                  variant: variant,
                  child: const Text('Details'),
                ),
              ),
            ),
          );
          expect(
            tester.widget<TextButton>(find.byType(TextButton)).onPressed,
            isNull,
          );
          await tester.tap(find.text('Details'));
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(calls, 0);
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('native actions preserve focus and Tab/Enter/Space activation', (
    tester,
  ) async {
    int calls = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      host(
        SteyBanner(
          title: 'Title',
          action: SteyBannerAction(
            focusNode: focus,
            onPressed: () => calls++,
            child: const Text('Details'),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls, 1);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(calls, 1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets(
    'compact Link stays inline, has link semantics and activates with Enter',
    (tester) async {
      int calls = 0;
      await tester.pumpWidget(
        host(
          SteyBanner(
            size: SteyBannerSize.sm,
            description: const Text('Review'),
            action: SteyLink(
              href: Uri.parse('#details'),
              onPressed: () => calls++,
              child: const Text('Details'),
            ),
          ),
        ),
      );
      expect(find.byType(TextButton), findsNothing);
      expect(
        tester.getSize(find.byType(SteyBanner)).height,
        closeTo(34.875, .25),
      );
      final link = tester.getSemantics(find.text('Details'));
      expect(link.getSemanticsData().flagsCollection.isLink, isTrue);
      expect(link.getSemanticsData().flagsCollection.isButton, isFalse);
      expect(link.getSemanticsData().linkUrl?.fragment, 'details');
      await tester.tap(find.text('Details'));
      expect(calls, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls, 2);
    },
  );

  testWidgets(
    'compact title-only Link and arbitrary description retain selectable content',
    (tester) async {
      await tester.pumpWidget(
        host(
          SteyBanner(
            size: SteyBannerSize.sm,
            title: 'Title',
            action: SteyLink(onPressed: () {}, child: const Text('Details')),
          ),
        ),
      );
      expect(find.text('Details'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        host(
          SteyBanner(
            size: SteyBannerSize.sm,
            description: const SelectableText('Rich details'),
            action: SteyLink(onPressed: () {}, child: const Text('Details')),
          ),
        ),
      );
      expect(find.byType(SelectableText), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('long content, RTL and 2x text remain operable at 320px', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      for (final size in SteyBannerSize.values) {
        await tester.pumpWidget(
          host(
            SteyBanner(
              size: size,
              title: 'Update available',
              description: const Text(
                'Review access permissions and project settings before saving changes.',
              ),
              icon: const Icon(Icons.info_outline),
              action: SteyBannerAction(
                onPressed: () {},
                child: const Text('Retry'),
              ),
            ),
            width: 320,
            scale: 2,
            direction: direction,
          ),
        );
        expect(tester.takeException(), isNull);
        final body = tester.getRect(find.byType(SteyBanner)),
            action = tester.getRect(find.byType(TextButton));
        expect(action.left, greaterThanOrEqualTo(body.left));
        expect(action.right, lessThanOrEqualTo(body.right));
      }
    }
  });

  testWidgets(
    'dismiss extension invokes callback with a stable accessible action',
    (tester) async {
      int dismissals = 0;
      await tester.pumpWidget(
        host(
          SteyBanner(
            title: 'Title',
            dismissLabel: 'Close notice',
            liveRegion: true,
            onDismiss: () => dismissals++,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Close notice'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close notice'));
      await tester.pump();
      expect(dismissals, 1);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
        findsOneWidget,
      );
    },
  );
}
