import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: SteyTheme.material(Brightness.light),
      home: Scaffold(
        body: Directionality(
          textDirection: direction,
          child: Center(child: child),
        ),
      ),
    );

void main() {
  testWidgets(
    'Default icon size follows the font while an explicit size is retained',
    (tester) async {
      for (final size in SteySize.values) {
        await tester.pumpWidget(
          host(
            SteyButton(
              onPressed: () {},
              size: size,
              icon: const Icon(Icons.add),
              child: const Text('Save'),
            ),
          ),
        );
        expect(
          tester.getSize(find.byIcon(Icons.add)),
          Size.square(size.fontSize),
        );
      }
    },
  );
  testWidgets(
    'Text baselines agree with and without icons while icons stay centered',
    (tester) async {
      for (final size in SteySize.values) {
        for (final variant in [
          SteyButtonVariant.secondary,
          SteyButtonVariant.primary,
        ]) {
          await tester.pumpWidget(
            host(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SteyButton(
                    onPressed: () {},
                    size: size,
                    variant: variant,
                    child: const Text('Save', key: ValueKey('plain')),
                  ),
                  SteyButton(
                    onPressed: () {},
                    size: size,
                    variant: variant,
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                      key: ValueKey('leading'),
                    ),
                    child: const Text('Save', key: ValueKey('label')),
                  ),
                ],
              ),
            ),
          );
          final buttons = find.byType(TextButton);
          final plain = tester.getRect(buttons.at(0)),
              withIcon = tester.getRect(buttons.at(1));
          final plainText = tester.getRect(find.byKey(const ValueKey('plain')));
          final label = tester.getRect(find.byKey(const ValueKey('label')));
          final icon = tester.getRect(find.byKey(const ValueKey('leading')));
          final lift = size == SteySize.xs || size == SteySize.sm ? .5 : 1.0;
          expect(plain.height, size.height);
          expect(withIcon.height, size.height);
          expect(plainText.center.dy - plain.center.dy, closeTo(-lift, .01));
          expect(label.center.dy - withIcon.center.dy, closeTo(-lift, .01));
          expect(icon.center.dy, closeTo(withIcon.center.dy, .01));
          expect(icon.left - withIcon.left, size.padding - 2);
          expect(withIcon.right - label.right, closeTo(size.padding, .01));
          final gap = variant == SteyButtonVariant.primary
              ? 6
              : size == SteySize.xs || size == SteySize.sm
              ? 4
              : size == SteySize.lg
              ? 8
              : 6;
          expect(label.left - icon.right, gap);
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Empty conditional content keeps symmetric icon-only geometry', (
    tester,
  ) async {
    for (final child in [
      const Text(''),
      const Text.rich(TextSpan(text: '')),
      const SizedBox.shrink(),
    ]) {
      await tester.pumpWidget(
        host(
          SteyButton(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16, key: ValueKey('leading')),
            semanticLabel: 'Add',
            child: child,
          ),
        ),
      );
      final button = tester.getRect(find.byType(TextButton));
      final icon = tester.getRect(find.byKey(const ValueKey('leading')));
      expect(button.width, 40);
      expect(icon.center, button.center);
      expect(find.bySemanticsLabel('Add'), findsOneWidget);
    }
  });

  testWidgets('Compact shapes preserve size and centered icons in every size', (
    tester,
  ) async {
    for (final shape in [SteyButtonShape.square, SteyButtonShape.circle]) {
      for (final size in SteySize.values) {
        await tester.pumpWidget(
          host(
            SteyButton(
              onPressed: () {},
              shape: shape,
              size: size,
              icon: const Icon(Icons.add, size: 16, key: ValueKey('leading')),
              semanticLabel: 'Add',
              child: const SizedBox.shrink(),
            ),
          ),
        );
        final button = tester.getRect(find.byType(TextButton));
        expect(
          button.size,
          Size.square(size == SteySize.xs ? 14 : size.height),
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('leading'))).center,
          button.center,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
    'Loading stays centered and inert, and RTL preserves physical CSS padding',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        host(
          SteyButton(
            onPressed: () => calls++,
            loading: true,
            child: const Text('Save'),
          ),
        ),
      );
      expect(
        tester.getRect(find.byType(SteyLoader)).center.dy,
        tester.getRect(find.byType(TextButton)).center.dy,
      );
      await tester.tap(find.byType(TextButton));
      expect(calls, 0);
      await tester.pumpWidget(
        host(
          SteyButton(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            child: const Text('Save'),
          ),
          direction: TextDirection.rtl,
        ),
      );
      final button = tester.getRect(find.byType(TextButton));
      expect(tester.getRect(find.text('Save')).left - button.left, 10);
      expect(button.right - tester.getRect(find.byIcon(Icons.add)).right, 12);
      expect(tester.takeException(), isNull);
    },
  );
}
