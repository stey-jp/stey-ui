import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_demo/empty_example.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
void main() {
  testWidgets(
    'Japanese empty controls update size/content and preserve action and copy counts',
    (t) async {
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await t.pumpWidget(host(const EmptyExample()));
      await t.tap(find.bySemanticsLabel('Copy command'));
      await t.pump();
      expect(copied, 'npm create cloudflare@latest');
      await t.ensureVisible(find.text('Workerを作成'));
      await t.tap(find.text('Workerを作成'));
      await t.pump();
      expect(find.text('コピー：1回・作成操作：1回'), findsOneWidget);
      await t.tap(find.text('説明を表示'));
      await t.pump();
      expect(t.widget<SteyEmpty>(find.byType(SteyEmpty)).description, isNull);
      final select = t.widget<SteySelect<SteyEmptySize>>(
        find.byType(SteySelect<SteyEmptySize>),
      );
      select.onChanged!(SteyEmptySize.sm);
      await t.pumpAndSettle();
      expect(
        t.widget<SteyEmpty>(find.byType(SteyEmpty)).size,
        SteyEmptySize.sm,
      );
      await t.tap(find.text('長い内容'));
      await t.pump();
      await t.tap(find.bySemanticsLabel('Copy command'));
      await t.pump();
      expect(copied, contains('--deploy false'));
      await t.tap(find.text('コマンドを表示'));
      await t.pump();
      expect(find.bySemanticsLabel('Copy command'), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('comparison fixture supports RTL and multiple content actions', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: EmptySample({
            'actions': 'true',
            'multiple': 'true',
            'emptySize': 'sm',
          }),
        ),
      ),
    );
    await t.tap(find.text('Create resource'));
    await t.pump();
    await t.tap(find.text('Read guide'));
    await t.pump();
    expect(
      find.bySemanticsLabel('Copy calls: 0; Action calls: 2'),
      findsOneWidget,
    );
    expect(t.widget<SteyEmpty>(find.byType(SteyEmpty)).size, SteyEmptySize.sm);
    expect(
      Directionality.of(t.element(find.byType(SteyEmpty))),
      TextDirection.rtl,
    );
    expect(t.takeException(), isNull);
  });
}
