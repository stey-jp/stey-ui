// The deprecated Surface API is intentionally covered for upstream compatibility.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(
  Widget child, {
  bool rtl = false,
  double scale = 1,
  double width = 320,
}) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(
    body: Center(
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);
Finder card() => find.byWidgetPredicate((w) => w is SteyLayerCard);
BoxDecoration decoration(WidgetTester t) =>
    t
            .widget<DecoratedBox>(
              find
                  .descendant(of: card(), matching: find.byType(DecoratedBox))
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  testWidgets(
    'simple card has no implicit content padding; explicit padding sizes the surface',
    (t) async {
      await t.pumpWidget(host(const SteyLayerCard(child: Text('Body'))));
      expect(t.getSize(card()), const Size(320, 21));
      await t.pumpWidget(
        host(
          const SteyLayerCard(padding: EdgeInsets.all(16), child: Text('Body')),
        ),
      );
      expect(t.getSize(card()), const Size(320, 53));
      expect(
        t.getTopLeft(find.text('Body')) - t.getTopLeft(card()),
        const Offset(16, 16),
      );
    },
  );
  testWidgets(
    'layered header, primary gap and footer have CSS negative block margins',
    (t) async {
      await t.pumpWidget(
        host(
          const SteyLayerCard.layers(
            children: [
              SteyLayerCardSecondary(child: Text('Header')),
              SteyLayerCardPrimary(
                children: [Text('Title'), Text('Description')],
              ),
              SteyLayerCardSecondary(child: Text('Footer')),
            ],
          ),
        ),
      );
      final origin = t.getTopLeft(card());
      expect(t.getSize(card()), const Size(320, 156));
      expect(t.getTopLeft(find.text('Header')) - origin, const Offset(16, 8));
      expect(t.getTopLeft(find.text('Title')) - origin, const Offset(16, 53));
      expect(
        t.getTopLeft(find.text('Description')).dy -
            t.getTopLeft(find.text('Title')).dy,
        29,
      );
      expect(t.getTopLeft(find.text('Footer')) - origin, const Offset(16, 127));
    },
  );
  testWidgets('primary right padding stays physical in RTL', (t) async {
    for (final rtl in [false, true]) {
      await t.pumpWidget(
        host(
          const SteyLayerCard(
            child: SteyLayerCardPrimary(child: SizedBox(height: 20)),
          ),
          rtl: rtl,
        ),
      );
      final child = t.getRect(find.byType(SizedBox).last),
          root = t.getRect(card());
      expect(child.left - root.left, 16);
      expect(root.right - child.right, 12);
    }
  });
  testWidgets('only direct sections trigger layered styling', (t) async {
    const section = SteyLayerCardPrimary(child: Text('Body'));
    await t.pumpWidget(host(const SteyLayerCard(child: section)));
    expect(decoration(t).color, const SteyColors(Brightness.light).elevated);
    await t.pumpWidget(
      host(const SteyLayerCard(child: Column(children: [section]))),
    );
    expect(decoration(t).color, const SteyColors(Brightness.light).base);
  });
  testWidgets('plain children in layers retain the single surface layout', (
    t,
  ) async {
    await t.pumpWidget(
      host(const SteyLayerCard.layers(children: [Text('One'), Text('Two')])),
    );
    expect(t.getSize(card()).height, 42);
    expect(decoration(t).color, const SteyColors(Brightness.light).base);
  });
  testWidgets('legacy header/footer match the section composition', (t) async {
    await t.pumpWidget(
      host(
        const SteyLayerCard(
          header: Text('Header'),
          footer: Text('Footer'),
          child: Text('Body'),
        ),
      ),
    );
    final positions = [
      for (final text in ['Header', 'Body', 'Footer'])
        t.getTopLeft(find.text(text)) - t.getTopLeft(card()),
    ];
    final size = t.getSize(card());
    await t.pumpWidget(
      host(
        const SteyLayerCard.layers(
          children: [
            SteyLayerCardSecondary(child: Text('Header')),
            SteyLayerCardPrimary(child: Text('Body')),
            SteyLayerCardSecondary(child: Text('Footer')),
          ],
        ),
      ),
    );
    expect(t.getSize(card()), size);
    expect([
      for (final text in ['Header', 'Body', 'Footer'])
        t.getTopLeft(find.text(text)) - t.getTopLeft(card()),
    ], positions);
  });
  testWidgets('legacy explicit padding applies to each section', (t) async {
    await t.pumpWidget(
      host(
        const SteyLayerCard(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          header: Text('Header'),
          child: Text('Body'),
        ),
      ),
    );
    final origin = t.getTopLeft(card());
    expect(t.getTopLeft(find.text('Header')) - origin, const Offset(20, 4));
    expect(t.getTopLeft(find.text('Body')) - origin, const Offset(20, 41));
  });
  testWidgets(
    'secondary overlap retains pointer input in the negative margin',
    (t) async {
      var count = 0;
      await t.pumpWidget(
        host(
          SteyLayerCard.layers(
            children: [
              const SizedBox(height: 53),
              SteyLayerCardSecondary(
                padding: EdgeInsets.zero,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => count++,
                  child: const SizedBox(height: 36, child: Text('Action')),
                ),
              ),
            ],
          ),
        ),
      );
      await t.tapAt(t.getTopLeft(card()) + const Offset(20, 50));
      await t.pump();
      expect(count, 1);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Surface colors share paint and allow native radius/padding overrides',
    (t) async {
      for (final color in SteySurfaceColor.values) {
        await t.pumpWidget(
          host(
            SteySurface(
              color: color,
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(12),
              child: const Text('Body'),
            ),
          ),
        );
        expect(t.getSize(card()), const Size(320, 53));
        expect(decoration(t).color, const SteyColors(Brightness.light).base);
        expect(decoration(t).borderRadius, BorderRadius.circular(12));
        expect(t.widget<SteySurface>(card()).clipBehavior, Clip.none);
      }
    },
  );
  testWidgets(
    'positioned Primary stays above a later overlapping footer for hits',
    (t) async {
      var count = 0;
      await t.pumpWidget(
        host(
          SteyLayerCard.layers(
            children: [
              const SteyLayerCardPrimary(child: SizedBox(height: 21)),
              SteyLayerCardSecondary(
                padding: EdgeInsets.zero,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => count++,
                  child: const SizedBox(
                    height: 36,
                    child: Text('Footer action'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      final origin = t.getTopLeft(card());
      await t.tapAt(origin + const Offset(20, 50));
      expect(count, 0);
      await t.tapAt(origin + const Offset(20, 55));
      expect(count, 1);
    },
  );
  testWidgets(
    'Surface layers retain sections and default to square root corners',
    (t) async {
      await t.pumpWidget(
        host(
          const SteySurface.layers(
            children: [
              SteyLayerCardSecondary(child: Text('Header')),
              SteyLayerCardPrimary(child: Text('Body')),
            ],
          ),
        ),
      );
      expect(t.getSize(card()).height, 90);
      expect(decoration(t).borderRadius, BorderRadius.zero);
    },
  );
  testWidgets('section semantics keep names and child input state', (t) async {
    Widget view(bool footer) => host(
      SteyLayerCard.layers(
        semanticLabel: 'Card',
        children: [
          const SteyLayerCardSecondary(
            semanticLabel: 'Header section',
            child: Text('Header'),
          ),
          const SteyLayerCardPrimary(
            semanticLabel: 'Primary section',
            child: TextField(decoration: InputDecoration(labelText: 'Name')),
          ),
          if (footer) const SteyLayerCardSecondary(child: Text('Footer')),
        ],
      ),
    );
    await t.pumpWidget(view(true));
    await t.enterText(find.byType(TextField), 'Saved draft');
    await t.pumpWidget(view(false));
    expect(find.text('Saved draft'), findsOneWidget);
    expect(find.bySemanticsLabel('Header section'), findsOneWidget);
    expect(find.bySemanticsLabel('Primary section'), findsOneWidget);
  });
  testWidgets('long sections wrap at narrow widths and enlarged text', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const SizedBox(
          width: 160,
          child: SingleChildScrollView(
            child: SteyLayerCard.layers(
              children: [
                SteyLayerCardSecondary(
                  child: Text('Next steps for every team member'),
                ),
                SteyLayerCardPrimary(
                  child: Text(
                    'Review the configuration before publishing the service',
                  ),
                ),
              ],
            ),
          ),
        ),
        scale: 2,
        width: 160,
      ),
    );
    expect(
      t.getSize(find.text('Next steps for every team member')).height,
      greaterThan(42),
    );
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'negative margins participate in intrinsic height without invalid constraints',
    (t) async {
      await t.pumpWidget(
        host(
          const IntrinsicHeight(
            child: SteyLayerCard.layers(
              children: [
                SteyLayerCardSecondary(child: Text('Header')),
                SteyLayerCardPrimary(child: Text('Body')),
              ],
            ),
          ),
        ),
      );
      expect(t.getSize(card()).height, 90);
      expect(t.takeException(), isNull);
    },
  );
}
