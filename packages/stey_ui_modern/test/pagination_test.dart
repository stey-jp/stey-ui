import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child) => MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: Scaffold(body: Center(child: child)),
);
Finder button(String name) =>
    find.widgetWithText(TextButton, name).evaluate().isNotEmpty
    ? find.widgetWithText(TextButton, name)
    : find.ancestor(
        of: find.bySemanticsLabel(name),
        matching: find.byType(TextButton),
      );
TextField field(WidgetTester t) => t.widget<TextField>(find.byType(TextField));
void main() {
  testWidgets(
    'known totals, navigation landmark and first/last/previous/next boundary states',
    (t) async {
      final calls = <int>[];
      Widget sample(int page, int total) => host(
        SteyPagination(
          page: page,
          perPage: 10,
          totalCount: total,
          onChanged: calls.add,
        ),
      );
      for (final page in [1, 3, 10, 14]) {
        await t.pumpWidget(sample(page, 100));
        expect(
          t
              .getSemantics(find.bySemanticsLabel('Pagination'))
              .getSemanticsData()
              .role,
          SemanticsRole.navigation,
        );
        expect(
          t.widget<TextButton>(button('First page')).onPressed == null,
          page <= 1,
        );
        expect(
          t.widget<TextButton>(button('Previous page')).onPressed == null,
          page <= 1,
        );
        expect(
          t.widget<TextButton>(button('Next page')).onPressed == null,
          page >= 10,
        );
        expect(
          t.widget<TextButton>(button('Last page')).onPressed == null,
          page >= 10,
        );
      }
      await t.pumpWidget(sample(3, 100));
      expect(t.getSize(button('Previous page')), const Size(42, 36));
      expect(t.getSize(find.byType(TextField)), const Size(50, 36));
      for (final name in [
        'First page',
        'Previous page',
        'Next page',
        'Last page',
      ]) {
        await t.tap(button(name));
        await t.pump();
      }
      expect(calls, [1, 2, 4, 10]);
    },
  );
  testWidgets(
    'empty result set keeps maxPage1, disables all controls and never requests0',
    (t) async {
      final calls = <int>[];
      await t.pumpWidget(
        host(SteyPagination(perPage: 10, totalCount: 0, onChanged: calls.add)),
      );
      expect(find.textContaining('Showing'), findsNothing);
      expect(
        t
            .widgetList<TextButton>(find.byType(TextButton))
            .every((b) => b.onPressed == null),
        true,
      );
      await t.enterText(find.byType(TextField), '0');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(calls, [1]);
      expect(field(t).controller!.text, '1');
    },
  );
  testWidgets(
    'invalid text rejected on Enter and blur, decimal signs exponent and unicode digits',
    (t) async {
      final calls = <int>[];
      await t.pumpWidget(
        host(
          SteyPagination(
            page: 3,
            perPage: 10,
            totalCount: 200,
            onChanged: calls.add,
          ),
        ),
      );
      for (final raw in [
        'abc',
        '2.5',
        '0x10',
        '1e1',
        '-2',
        '+3',
        '',
        ' ',
        '３',
        '٣',
      ]) {
        await t.enterText(find.byType(TextField), raw);
        await t.testTextInput.receiveAction(TextInputAction.done);
        await t.pump();
        expect(field(t).controller!.text, '3', reason: raw);
        expect(calls, isEmpty);
      }
      await t.enterText(find.byType(TextField), 'abc');
      FocusManager.instance.primaryFocus!.unfocus();
      await t.pump();
      expect(field(t).controller!.text, '3');
      expect(calls, isEmpty);
    },
  );
  testWidgets(
    'digits trim whitespace, clamp, preserve safe huge values and commit on blur',
    (t) async {
      final calls = <int>[];
      await t.pumpWidget(
        host(
          SteyPagination(
            page: 3,
            perPage: 10,
            totalCount: 100,
            onChanged: calls.add,
          ),
        ),
      );
      for (final raw in [' 4 ', '999', '0007', '0', '9' * 80]) {
        await t.enterText(find.byType(TextField), raw);
        await t.testTextInput.receiveAction(TextInputAction.done);
        await t.pump();
      }
      expect(calls, [4, 10, 7, 1, 10]);
      await t.enterText(find.byType(TextField), '5');
      FocusManager.instance.primaryFocus!.unfocus();
      await t.pump();
      expect(calls.last, 5);
    },
  );
  testWidgets(
    'external page change replaces draft, unchanged parent page retains draft',
    (t) async {
      Widget sample(int p) => host(
        SteyPagination(
          page: p,
          perPage: 10,
          totalCount: 100,
          onChanged: (_) {},
        ),
      );
      await t.pumpWidget(sample(3));
      await t.enterText(find.byType(TextField), '8');
      await t.pumpWidget(sample(3));
      expect(field(t).controller!.text, '8');
      await t.pumpWidget(sample(2));
      expect(field(t).controller!.text, '2');
    },
  );
  testWidgets(
    'unknown total forces sequential controls while known total wins over hasNextPage',
    (t) async {
      final calls = <int>[];
      await t.pumpWidget(
        host(SteyPagination(page: 3, hasNextPage: true, onChanged: calls.add)),
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextButton), findsNWidgets(2));
      await t.tap(button('Next page'));
      await t.pump();
      expect(calls.last, 4);
      await t.pumpWidget(
        host(SteyPagination(page: 3, hasNextPage: false, onChanged: calls.add)),
      );
      expect(t.widget<TextButton>(button('Next page')).onPressed, isNull);
      await t.pumpWidget(
        host(
          SteyPagination(
            page: 3,
            perPage: 10,
            totalCount: 100,
            hasNextPage: false,
            onChanged: calls.add,
          ),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(t.widget<TextButton>(button('Next page')).onPressed, isNotNull);
    },
  );
  testWidgets(
    'simple mode ignores dropdown and missing total/hasNext keeps full controls with next disabled',
    (t) async {
      await t.pumpWidget(
        host(
          SteyPagination(
            onChanged: (_) {},
            controls: SteyPaginationMode.simple,
            pageSelector: SteyPaginationSelector.dropdown,
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(SteySelect<int>), findsNothing);
      expect(find.byType(TextButton), findsNWidgets(2));
      await t.pumpWidget(host(SteyPagination(onChanged: (_) {})));
      expect(find.byType(TextField), findsOneWidget);
      expect(t.widget<TextButton>(button('Next page')).onPressed, isNull);
    },
  );
  testWidgets(
    'compound info exposes exact ranges including missing perPage and custom renderer',
    (t) async {
      SteyPaginationData? data;
      await t.pumpWidget(
        host(
          SteyPagination(
            page: 2,
            perPage: 10,
            totalCount: 15,
            onChanged: (_) {},
            child: SteyPaginationInfo(
              builder: (_, d) {
                data = d;
                return Text(d.pageShowingRange);
              },
            ),
          ),
        ),
      );
      expect(find.text('11-15'), findsOneWidget);
      expect(data!.maxPage, 2);
      await t.pumpWidget(
        host(
          SteyPagination(
            page: 2,
            totalCount: 5,
            onChanged: (_) {},
            child: SteyPaginationInfo(
              builder: (_, d) => Text(d.pageShowingRange),
            ),
          ),
        ),
      );
      expect(find.text('3-0'), findsOneWidget);
    },
  );
  testWidgets(
    'page dropdown enumerates pages and selecting changes the controlled page',
    (t) async {
      final calls = <int>[];
      await t.pumpWidget(
        host(
          SteyPagination(
            page: 3,
            perPage: 10,
            totalCount: 100,
            onChanged: calls.add,
            pageSelector: SteyPaginationSelector.dropdown,
          ),
        ),
      );
      final select = t.widget<SteySelect<int>>(find.byType(SteySelect<int>));
      expect(select.options.keys.toList(), List.generate(10, (i) => i + 1));
      select.onChanged!(5);
      await t.pump();
      expect(calls, [5]);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'page size callback does not reset page automatically and separator is decorative24px',
    (t) async {
      int? size;
      await t.pumpWidget(
        host(
          SteyPagination(
            page: 3,
            perPage: 10,
            totalCount: 100,
            onChanged: (_) {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SteyPaginationSeparator(),
                SteyPaginationPageSize(value: 25, onChanged: (n) => size = n),
              ],
            ),
          ),
        ),
      );
      final select = t.widget<SteySelect<int>>(find.byType(SteySelect<int>));
      expect(select.options.keys, [25, 50, 100, 250]);
      select.onChanged!(50);
      expect(size, 50);
      expect(
        t.getSize(find.byType(SteyPaginationSeparator)),
        const Size(17, 24),
      );
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'custom labels, numeric legacy totalPages and physical arrows under RTL',
    (t) async {
      await t.pumpWidget(
        host(
          Directionality(
            textDirection: TextDirection.rtl,
            child: SteyPagination(
              page: 2,
              totalPages: 20,
              label: '番号',
              labels: const SteyPaginationLabels(
                navigation: '移動',
                nextPage: '続き',
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('移動'), findsOneWidget);
      expect(find.bySemanticsLabel('番号'), findsOneWidget);
      expect(button('続き'), findsOneWidget);
      expect(field(t).controller!.text, '2');
    },
  );
  testWidgets(
    'Tab reaches editable field and submit action applies the value',
    (t) async {
      final calls = <int>[];
      await t.pumpWidget(
        host(
          SteyPagination(
            page: 3,
            perPage: 10,
            totalCount: 100,
            onChanged: calls.add,
          ),
        ),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(field(t).focusNode!.hasFocus, true);
      expect(field(t).textInputAction, TextInputAction.none);
      await t.enterText(find.byType(TextField), '7');
      await t.testTextInput.receiveAction(TextInputAction.none);
      await t.pump();
      expect(calls.last, 7);
    },
  );
}
