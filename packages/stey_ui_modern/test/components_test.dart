import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: SteyTheme.material(brightness),
      home: SteyTheme(
        brightness: brightness,
        child: Scaffold(
          body: Center(child: SizedBox(width: 500, child: child)),
        ),
      ),
    );
void main() {
  testWidgets(
    'Sidebar labels are announced once in expanded and collapsed modes',
    (tester) async {
      final semantics = tester.ensureSemantics();
      for (final collapsed in [false, true]) {
        await tester.pumpWidget(
          host(
            SizedBox(
              height: 200,
              child: SteySidebar(
                items: const [
                  SteySidebarItem('workers', 'Workers', icon: Icons.cloud),
                ],
                selected: 'workers',
                collapsed: collapsed,
                onSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.bySemanticsLabel('Workers'), findsOneWidget);
        expect(find.bySemanticsLabel('Workers Workers'), findsNothing);
      }
      semantics.dispose();
    },
  );
  testWidgets('Button activates with keyboard and disabled/loading are inert', (
    tester,
  ) async {
    var clicks = 0;
    await tester.pumpWidget(
      host(
        SteyButton(
          autofocus: true,
          onPressed: () => clicks++,
          child: const Text('Save'),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(clicks, 1);
    await tester.pumpWidget(
      host(
        SteyButton(
          loading: true,
          onPressed: () => clicks++,
          child: const Text('Save'),
        ),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(clicks, 1);
    await tester.pumpWidget(host(const SteyButton(child: Text('Disabled'))));
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
  });
  testWidgets('Input edits, multiline and secret reveal preserve value', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'secret');
    await tester.pumpWidget(
      host(SteySensitiveInput(controller: controller, label: 'Token')),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    expect(controller.text, 'secret');
    await tester.enterText(find.byType(TextField), 'updated');
    expect(controller.text, 'updated');
    await tester.pumpWidget(host(const SteyTextarea(label: 'Description')));
    expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 4);
    controller.dispose();
  });
  testWidgets('Tabs arrow keys skip disabled entries and wrap', (tester) async {
    var value = 'a';
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SteyTabs(
            tabs: const [
              SteyTab('a', 'First'),
              SteyTab('b', 'Disabled', disabled: true),
              SteyTab('c', 'Last'),
            ],
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('First'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 'c');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 'a');
  });
  testWidgets('Autocomplete filters and commits with keyboard', (tester) async {
    String? selected;
    await tester.pumpWidget(
      host(
        SteyAutocomplete(
          options: const ['Workers', 'Pages', 'Storage'],
          onSelected: (v) => selected = v,
          label: 'Product',
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'wor');
    await tester.pump();
    expect(find.text('Workers'), findsOneWidget);
    expect(find.text('Pages'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(selected, 'Workers');
  });
  testWidgets('Tag input rejects duplicates and validates new tags', (
    tester,
  ) async {
    var tags = <String>['production'];
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SteyTagInput(
            value: tags,
            onChanged: (v) => setState(() => tags = v),
            validate: (v) => v.contains(' ') ? 'No spaces' : null,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'production');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tags, ['production']);
    await tester.enterText(find.byType(TextField), 'two words');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('No spaces'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'staging');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tags, ['production', 'staging']);
  });
  testWidgets('Dialog traps focus and Escape closes it', (tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => SteyButton(
            onPressed: () => SteyDialog.show(
              context,
              title: 'Edit worker',
              child: const SteyInput(label: 'Name'),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Edit worker'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Edit worker'), findsNothing);
  });
  testWidgets('Collapsible keeps its content alive and hides focus', (
    tester,
  ) async {
    var open = true;
    final controller = TextEditingController(text: 'retained');
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SteyCollapsible(
            open: open,
            onChanged: (v) => setState(() => open = v),
            title: const Text('Advanced'),
            child: SteyInput(controller: controller, label: 'Name'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    expect(controller.text, 'retained');
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextField, skipOffstage: false), findsOneWidget);
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    expect(controller.text, 'retained');
    controller.dispose();
  });
  testWidgets('Meter clamps finite values and exposes accessible values', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const SteyMeter(value: 150, max: 100, label: 'Usage')),
    );
    expect(find.bySemanticsLabel('Usage'), findsOneWidget);
    final data = tester
        .getSemantics(find.bySemanticsLabel('Usage'))
        .getSemanticsData();
    expect(data.value, '100.0');
    expect(data.minValue, '0.0');
    expect(data.maxValue, '100.0');
    handle.dispose();
  });
  testWidgets('Charts render dark empty and keyboard exploration', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const SteyTimeseriesChart(series: []), brightness: Brightness.dark),
    );
    expect(find.text('No data available'), findsOneWidget);
    await tester.pumpWidget(
      host(
        const SteyTimeseriesChart(
          series: [
            SteyChartSeries(
              name: 'Requests',
              points: [SteyChartPoint(0, 2), SteyChartPoint(1, 3)],
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
  test('GeoJSON preserves polygon holes and rejects unsupported geometry', () {
    final feature = SteyMapFeature.fromGeoJson({
      'features': [
        {
          'id': 'a',
          'properties': {'name': 'A', 'value': 4},
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [0, 0],
                [10, 0],
                [10, 10],
                [0, 0],
              ],
              [
                [1, 1],
                [2, 1],
                [1, 2],
                [1, 1],
              ],
            ],
          },
        },
      ],
    }).single;
    expect(feature.polygons.single.length, 2);
    expect(feature.value, 4);
  });
}
