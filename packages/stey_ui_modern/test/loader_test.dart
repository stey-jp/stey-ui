import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  testWidgets(
    'Loader keeps animating with reduced motion and repeats its composed timeline',
    (tester) async {
      final boundaryKey = GlobalKey();
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: const ColoredBox(
                  color: Colors.white,
                  child: SteyLoader(
                    size: 24,
                    color: Colors.black,
                    label: 'Loading resources',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Loading resources'), findsOneWidget);
      expect(tester.getSize(find.byType(SteyLoader)), const Size(24, 24));
      Future<List<int>> pixels() async => (await tester.runAsync(() async {
        final image =
            await (boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data!.buffer.asUint8List().toList();
      }))!;
      final initial = await pixels();
      await tester.pump(const Duration(milliseconds: 750));
      final advanced = await pixels();
      expect(advanced, isNot(orderedEquals(initial)));
      await tester.pump(const Duration(milliseconds: 5250));
      expect(await pixels(), orderedEquals(initial));
      semantics.dispose();
    },
  );
}
