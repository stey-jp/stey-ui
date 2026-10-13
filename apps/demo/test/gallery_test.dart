import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stey_ui_demo/catalog.g.dart';
import 'package:stey_ui_demo/gallery.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final width in [320.0, 390.0, 1280.0]) {
      testWidgets('Every preview renders at $width in ${brightness.name}', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final id in componentIds) {
          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('ja'),
              supportedLocales: const [Locale('ja')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: SteyTheme.material(brightness),
              home: SteyTheme(
                brightness: brightness,
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ComponentExample(key: ValueKey(id), id: id),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull, reason: id);
        }
      });
    }
  }
  testWidgets('Gallery is usable on a narrow viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SteyGallery());
    await tester.pump();
    expect(find.text('Stey UI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
