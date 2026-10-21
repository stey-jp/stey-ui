import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: SteyTheme.material(brightness),
  home: SteyTheme(
    brightness: brightness,
    child: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  ),
);
Finder paint() => find.descendant(
  of: find.byType(SteyBadge),
  matching: find.byWidgetPredicate(
    (w) =>
        w is CustomPaint &&
        w.foregroundPainter?.runtimeType.toString() == '_BadgeBorder',
  ),
);
RenderParagraph label(WidgetTester t) => t.renderObject(find.text('Active'));
void main() {
  testWidgets(
    'all filled variants use semantic foregrounds and background tokens in both themes',
    (t) async {
      for (final brightness in Brightness.values) {
        final c = SteyColors(brightness);
        final expected = <SteyBadgeVariant, (Color, Color)>{
          SteyBadgeVariant.primary: (c.badgeInverted, c.badgeInverseText),
          SteyBadgeVariant.secondary: (c.fill, c.badgeNeutralText),
          SteyBadgeVariant.error: (c.dangerTint, c.dangerText),
          SteyBadgeVariant.warning: (c.warningTint, c.warningText),
          SteyBadgeVariant.success: (c.successTint, c.successText),
          SteyBadgeVariant.info: (c.infoTint, c.link),
          SteyBadgeVariant.destructive: (c.badgeRed, Colors.white),
          SteyBadgeVariant.red: (c.badgeRed, Colors.white),
          SteyBadgeVariant.green: (c.badgeGreen, Colors.white),
          SteyBadgeVariant.orange: (c.badgeOrange, Colors.black),
          SteyBadgeVariant.purple: (c.badgePurple, Colors.white),
          SteyBadgeVariant.teal: (c.badgeTeal, Colors.white),
          SteyBadgeVariant.blue: (c.badgeBlue, Colors.white),
          SteyBadgeVariant.neutral: (c.badgeNeutral, Colors.white),
          SteyBadgeVariant.tealSubtle: (Colors.transparent, c.badgeTealText),
          SteyBadgeVariant.beta: (Colors.transparent, c.link),
          SteyBadgeVariant.outline: (c.base, c.text),
        };
        for (final e in expected.entries) {
          await t.pumpWidget(
            host(
              SteyBadge(variant: e.key, child: const Text('Active')),
              brightness: brightness,
            ),
          );
          final decoration =
              t
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byType(SteyBadge),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration;
          expect(decoration.color, e.value.$1, reason: e.key.name);
          expect(label(t).text.style!.color, e.value.$2, reason: e.key.name);
        }
      }
    },
  );
  testWidgets(
    'base typography, padding and actual border add two pixels only for beta and outline',
    (t) async {
      for (final v in SteyBadgeVariant.values) {
        await t.pumpWidget(
          host(SteyBadge(variant: v, child: const Text('Active'))),
        );
        final p = label(t),
            border =
                v == SteyBadgeVariant.beta || v == SteyBadgeVariant.outline;
        expect(p.text.style!.fontSize, 12);
        expect(p.text.style!.height, 4 / 3);
        expect(p.text.style!.fontWeight, FontWeight.w500);
        expect(t.getSize(find.byType(SteyBadge)).height, border ? 22 : 20);
        expect(
          t.getSize(find.byType(SteyBadge)).width - p.size.width,
          border ? 18 : 16,
        );
      }
    },
  );
  testWidgets(
    'dot appearance ignores filled variant and only four statuses have decorative 7px dots',
    (t) async {
      for (final v in SteyBadgeVariant.values) {
        await t.pumpWidget(
          host(
            SteyBadge(
              variant: v,
              appearance: SteyBadgeAppearance.dot,
              icon: const Text('hidden icon'),
              child: const Text('Active'),
            ),
          ),
        );
        expect(find.text('hidden icon'), findsNothing);
        final supported = [
          SteyBadgeVariant.success,
          SteyBadgeVariant.warning,
          SteyBadgeVariant.error,
          SteyBadgeVariant.neutral,
        ].contains(v);
        final dots = find.descendant(
          of: find.byType(SteyBadge),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        expect(dots, supported ? findsOneWidget : findsNothing);
        if (supported) expect(t.getSize(dots), const Size.square(7));
        expect(
          label(t).text.style!.color,
          const SteyColors(Brightness.light).text,
        );
        expect(
          t.getSize(find.byType(SteyBadge)).width - label(t).size.width,
          supported ? 29 : 16,
        );
      }
    },
  );
  testWidgets(
    'arbitrary icon has a 12px slot, 16px line wrapper and physical left padding6 in both directions',
    (t) async {
      const key = ValueKey('icon');
      for (final direction in TextDirection.values) {
        await t.pumpWidget(
          host(
            const SteyBadge(
              icon: ColoredBox(
                key: key,
                color: Colors.red,
                child: SizedBox.square(dimension: 24),
              ),
              child: Text('Active'),
            ),
            direction: direction,
          ),
        );
        final transformed = t.getRect(find.byKey(key));
        expect(transformed.width, 12);
        expect(transformed.height, 12);
        final badge = t.getRect(find.byType(SteyBadge));
        expect(badge.height, 20);
        expect(badge.width - label(t).size.width, 30);
        expect(
          direction == TextDirection.ltr
              ? transformed.left - badge.left
              : badge.right - transformed.right,
          direction == TextDirection.ltr ? 6 : 8,
        );
      }
    },
  );
  testWidgets(
    'icon wrapper follows enlarged text line height while glyph remains 12px',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyBadge(
            icon: Icon(Icons.check, size: 30),
            child: Text('Active'),
          ),
          scale: 2,
        ),
      );
      expect(t.getSize(find.byType(SteyBadge)).height, 36);
      final icon = t.renderObject<RenderBox>(find.byType(Icon));
      final rect = MatrixUtils.transformRect(
        icon.getTransformTo(null),
        Offset.zero & icon.size,
      );
      expect(rect.width, 12);
      expect(rect.height, 12);
    },
  );
  testWidgets(
    'ancestor hover reveals immediate current-color ring, focus alone does not and exit restores hairline',
    (t) async {
      await t.pumpWidget(
        host(
          SteyBadgeLinkScope(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: const SteyBadge(
                appearance: SteyBadgeAppearance.dot,
                variant: SteyBadgeVariant.success,
                child: Text('Active'),
              ),
            ),
          ),
        ),
      );
      final dynamic idle = t.widget<CustomPaint>(paint()).foregroundPainter;
      expect(idle.color, const SteyColors(Brightness.light).hairline);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(600, 500));
      await mouse.moveTo(const Offset(2, 2));
      await t.pump();
      final dynamic hover = t.widget<CustomPaint>(paint()).foregroundPainter;
      expect(hover.color, const SteyColors(Brightness.light).text);
      expect(hover.outside, true);
      await mouse.moveTo(const Offset(600, 500));
      await t.pump();
      expect(
        (t.widget<CustomPaint>(paint()).foregroundPainter as dynamic).color,
        idle.color,
      );
      await mouse.removePointer();
    },
  );
  testWidgets(
    'beta hover preserves dashed border and adds separate outer ring',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyBadgeLinkScope(
            child: SteyBadge(
              variant: SteyBadgeVariant.beta,
              child: Text('Active'),
            ),
          ),
        ),
      );
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(600, 500));
      await mouse.moveTo(t.getCenter(find.byType(SteyBadge)));
      await t.pump();
      final dynamic border = t.widget<CustomPaint>(paint()).foregroundPainter;
      expect(border.dashed, true);
      expect(border.outside, false);
      expect(border.color, const SteyColors(Brightness.light).brand);
      expect(border.ringColor, const SteyColors(Brightness.light).link);
      await mouse.removePointer();
    },
  );
  testWidgets(
    'plain badge hover has no ring and nested scopes inherit an outer hovered link',
    (t) async {
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(600, 500));
      await t.pumpWidget(host(const SteyBadge(child: Text('Active'))));
      await mouse.moveTo(t.getCenter(find.byType(SteyBadge)));
      await t.pump();
      expect(paint(), findsNothing);
      await mouse.moveTo(const Offset(600, 500));
      await t.pumpWidget(
        host(
          const SteyBadgeLinkScope(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SteyBadgeLinkScope(
                child: SteyBadge(child: Text('Active')),
              ),
            ),
          ),
        ),
      );
      await mouse.moveTo(const Offset(2, 2));
      await t.pump();
      expect(paint(), findsOneWidget);
      await mouse.removePointer();
    },
  );
  testWidgets(
    'native SteyLink integration keeps one link activation and no added badge Tab stop',
    (t) async {
      var calls = 0;
      await t.pumpWidget(
        host(
          SteyLink(
            onPressed: () => calls++,
            child: const SteyBadge(child: Text('Active')),
          ),
        ),
      );
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(600, 500));
      await mouse.moveTo(
        t.getTopLeft(find.byType(SteyLink)) + const Offset(2, 2),
      );
      await t.pump();
      expect(paint(), findsOneWidget);
      await t.tap(find.text('Active'));
      await t.pump();
      expect(calls, 1);
      await mouse.moveTo(const Offset(600, 500));
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(calls, 2);
      expect(paint(), findsNothing);
      await mouse.removePointer();
    },
  );
  testWidgets(
    'long labels stay single-line and intrinsic in a narrow host without RenderFlex errors',
    (t) async {
      await t.pumpWidget(
        host(
          const SizedBox(
            width: 60,
            child: SteyBadge(
              child: Text('Available project with a longer display name'),
            ),
          ),
        ),
      );
      final p = t.renderObject<RenderParagraph>(
        find.text('Available project with a longer display name'),
      );
      expect(p.maxLines, 1);
      expect(p.softWrap, false);
      expect(p.size.width, greaterThan(60));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'empty label has no phantom line but icon or dot retains its height',
    (t) async {
      await t.pumpWidget(host(const SteyBadge(child: Text(''))));
      expect(t.getSize(find.byType(SteyBadge)).height, 4);
      await t.pumpWidget(
        host(
          const SteyBadge(
            variant: SteyBadgeVariant.success,
            appearance: SteyBadgeAppearance.dot,
            child: Text(''),
          ),
        ),
      );
      expect(t.getSize(find.byType(SteyBadge)), const Size(23, 11));
      await t.pumpWidget(
        host(const SteyBadge(icon: Icon(Icons.check), child: Text(''))),
      );
      expect(t.getSize(find.byType(SteyBadge)), const Size(26, 20));
    },
  );
  testWidgets(
    'legacy tone/dot/outline aliases remain usable and explicit variant wins',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyBadge(
            tone: SteyTone.danger,
            dot: true,
            outline: true,
            child: Text('Active'),
          ),
        ),
      );
      expect(t.getSize(find.byType(SteyBadge)).height, 20);
      await t.pumpWidget(
        host(
          const SteyBadge(
            tone: SteyTone.danger,
            variant: SteyBadgeVariant.primary,
            child: Text('Active'),
          ),
        ),
      );
      expect(label(t).text.style!.color, Colors.white);
    },
  );
}
