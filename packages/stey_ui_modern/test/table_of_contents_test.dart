import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: SteyTheme.material(Brightness.light),
      home: Scaffold(
        body: Center(
          child: Directionality(
            textDirection: direction,
            child: SizedBox(width: 300, child: child),
          ),
        ),
      ),
    );

class Document {
  Document({double offset = 0, bool trackHash = true}) {
    tracker = SteyTableOfContentsController(
      scrollController: scroll,
      sections: keys,
      offset: offset,
      trackHash: trackHash,
      scrollOnHashChange: false,
    );
    addTearDown(() {
      tracker.dispose();
      scroll.dispose();
    });
  }
  final scroll = ScrollController();
  final keys = {
    for (final id in ['one', 'two', 'three']) id: GlobalKey(),
  };
  late final SteyTableOfContentsController tracker;
  Widget get widget => host(
    SizedBox(
      height: 200,
      child: SingleChildScrollView(
        controller: scroll,
        child: Column(
          children: [
            SizedBox(key: keys['one'], height: 20, child: const Text('One')),
            const SizedBox(height: 100),
            SizedBox(key: keys['two'], height: 20, child: const Text('Two')),
            const SizedBox(height: 360),
            SizedBox(
              key: keys['three'],
              height: 20,
              child: const Text('Three'),
            ),
            const SizedBox(height: 400),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('First visible heading wins within the supplied scroll root', (
    tester,
  ) async {
    final doc = Document();
    expect(doc.tracker.activeId, isNull);
    await tester.pumpWidget(doc.widget);
    expect(doc.tracker.activeId, 'one');
    doc.scroll.jumpTo(21);
    await tester.pump();
    expect(doc.tracker.activeId, 'two');
    doc.scroll.jumpTo(200);
    await tester.pump();
    expect(
      doc.tracker.activeId,
      'two',
      reason: 'A gap retains the last heading',
    );
    doc.scroll.jumpTo(500);
    await tester.pump();
    expect(doc.tracker.activeId, 'three');
  });

  testWidgets('Offset excludes headings above the activation line', (
    tester,
  ) async {
    final doc = Document(offset: 64);
    await tester.pumpWidget(doc.widget);
    expect(doc.tracker.activeId, 'two');
    await doc.tracker.scrollToSection('three', duration: Duration.zero);
    await tester.pump();
    expect(doc.scroll.offset, 436);
    expect(doc.tracker.activeId, 'three');
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets(
    'Selection remains pinned until scroll has been quiet for 150ms',
    (tester) async {
      final doc = Document();
      await tester.pumpWidget(doc.widget);
      doc.tracker.selectSection('three');
      doc.scroll.jumpTo(1);
      await tester.pump(const Duration(milliseconds: 100));
      doc.scroll.jumpTo(2);
      await tester.pump(const Duration(milliseconds: 100));
      expect(doc.tracker.activeId, 'three');
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        doc.tracker.activeId,
        'three',
        reason: 'Unpinning alone does not select',
      );
      doc.scroll.jumpTo(3);
      await tester.pump();
      expect(doc.tracker.activeId, 'one');
    },
  );

  testWidgets('Rapid selections supersede the previous settle deadline', (
    tester,
  ) async {
    final doc = Document();
    await tester.pumpWidget(doc.widget);
    doc.tracker.selectSection('two');
    await tester.pump(const Duration(milliseconds: 100));
    doc.tracker.selectSection('three');
    await tester.pump(const Duration(milliseconds: 75));
    doc.scroll.jumpTo(1);
    await tester.pump();
    expect(doc.tracker.activeId, 'three');
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets(
    'Missing keys are ignored and changes to section order are tracked',
    (tester) async {
      final doc = Document();
      doc.tracker.updateSections({'missing': GlobalKey()});
      await tester.pumpWidget(doc.widget);
      expect(doc.tracker.activeId, isNull);
      doc.tracker.updateSections({
        'two': doc.keys['two']!,
        'one': doc.keys['one']!,
      });
      await tester.pump();
      expect(doc.tracker.activeId, 'two');
      doc.tracker.updateSections({});
      await tester.pump();
      expect(doc.tracker.activeId, 'two');
    },
  );

  testWidgets(
    'Empty and malformed fragments do not break later valid changes',
    (tester) async {
      final doc = Document();
      for (final hash in [
        '',
        '#',
        '#%',
        '#%ZZ',
        '#%FF',
        '#%E0%A4%A',
        '#unknown',
      ]) {
        doc.tracker.syncFromFragment(hash);
        expect(doc.tracker.activeId, isNull, reason: hash);
      }
      doc.tracker.syncFromFragment('#two');
      expect(doc.tracker.activeId, 'two');
      doc.tracker.syncFromFragment('#%ZZ');
      expect(doc.tracker.activeId, 'two');
      doc.tracker.syncFromFragment('#one');
      expect(doc.tracker.activeId, 'one');
      await tester.pumpWidget(doc.widget);
      await tester.pump(const Duration(milliseconds: 200));
    },
  );

  testWidgets('Raw percent fragments and encoded Unicode decode exactly once', (
    tester,
  ) async {
    final doc = Document();
    doc.tracker.updateSections({
      '50%-off': GlobalKey(),
      'café': GlobalKey(),
      '%ZZ': GlobalKey(),
      'a+b': GlobalKey(),
    });
    for (final entry in {
      '#50%-off': '50%-off',
      '#caf%C3%A9': 'café',
      '#%25ZZ': '%ZZ',
      '#a+b': 'a+b',
    }.entries) {
      doc.tracker.syncFromFragment(entry.key);
      expect(doc.tracker.activeId, entry.value);
    }
    await tester.pumpWidget(doc.widget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets(
    'trackHash false ignores fragments but permits explicit selection',
    (tester) async {
      final doc = Document(trackHash: false);
      doc.tracker.syncFromFragment('#two');
      expect(doc.tracker.activeId, isNull);
      doc.tracker.selectSection('two');
      expect(doc.tracker.activeId, 'two');
      await tester.pumpWidget(doc.widget);
      await tester.pump(const Duration(milliseconds: 200));
    },
  );

  testWidgets('Disposal cancels pending timers and post-frame measurements', (
    tester,
  ) async {
    final scroll = ScrollController();
    final tracker = SteyTableOfContentsController(
      scrollController: scroll,
      sections: {},
    );
    tracker.selectSection('one');
    tracker.dispose();
    await tester.pumpWidget(host(const Text('Gone')));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    scroll.dispose();
  });

  testWidgets(
    'Convenience API retains callbacks, links and selected semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final selections = <String>[];
      await tester.pumpWidget(
        host(
          SteyTableOfContents(
            items: const {'one': 'First', 'two': 'Second'},
            activeId: 'one',
            onSelected: selections.add,
          ),
        ),
      );
      expect(
        tester
            .getSemantics(find.byType(SteyTableOfContents))
            .getSemanticsData()
            .role,
        SemanticsRole.navigation,
      );
      expect(find.semantics.byFlag(SemanticsFlag.isLink), findsNWidgets(2));
      expect(find.semantics.byFlag(SemanticsFlag.isSelected), findsOneWidget);
      await tester.tap(find.text('Second'));
      expect(selections, ['two']);
      semantics.dispose();
    },
  );

  testWidgets(
    'Nested child does not invoke the linked group callback; keyboard works',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var parent = 0, child = 0;
      await tester.pumpWidget(
        host(
          SteyTableOfContents(
            child: SteyTableOfContentsList(
              children: [
                SteyTableOfContentsGroup(
                  label: 'Parent',
                  href: '#parent',
                  onPressed: () => parent++,
                  children: [
                    SteyTableOfContentsItem(
                      label: 'Child',
                      href: '#child',
                      focusNode: focus,
                      onPressed: () => child++,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Child'));
      expect([parent, child], [0, 1]);
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect([parent, child], [0, 2]);
      await tester.tap(find.text('Parent'));
      expect([parent, child], [1, 2]);
    },
  );

  testWidgets(
    'Nonlinked group is inert and nesting respects RTL and text scaling',
    (tester) async {
      var calls = 0;
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          host(
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SteyTableOfContents(
                child: SteyTableOfContentsList(
                  children: [
                    SteyTableOfContentsGroup(
                      label: 'Group',
                      onPressed: () => calls++,
                      children: [
                        SteyTableOfContentsItem(
                          label:
                              'A very long nested heading which is truncated',
                          onPressed: () => calls++,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            direction: direction,
          ),
        );
        await tester.tap(find.text('Group'));
        expect(calls, 0);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
