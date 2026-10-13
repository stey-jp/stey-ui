import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: SteyTheme.material(Brightness.light),
      home: SteyTheme(
        brightness: Brightness.light,
        child: Scaffold(
          body: Center(
            child: Directionality(
              textDirection: direction,
              child: SizedBox(width: 320, child: child),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    'Radio option label selects one control, focuses it and skips disabled on arrows',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final changes = <int?>[];
      await tester.pumpWidget(
        host(
          SteyRadioGroup<int>(
            legend: 'Plan',
            defaultValue: 1,
            onChanged: changes.add,
            children: const [
              SteyRadioItem(value: 1, label: 'Free'),
              SteyRadioItem(value: 2, label: 'Unavailable', disabled: true),
              SteyRadioItem(value: 3, label: 'Pro'),
            ],
          ),
        ),
      );
      expect(find.semantics.byLabel('Plan'), findsOneWidget);
      expect(find.semantics.byLabel('Free'), findsOneWidget);
      await tester.tap(find.text('Free'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(changes, [3]);
      expect(find.semantics.byFlag(SemanticsFlag.isChecked), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(changes, [3, 1]);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(changes, [3, 1]);
      semantics.dispose();
    },
  );

  testWidgets(
    'Controlled radios request values but wait for their owner; disabled labels are inert',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final changes = <String?>[];
      await tester.pumpWidget(
        host(
          SteyRadioGroup<String>(
            value: 'a',
            onChanged: changes.add,
            options: const {'a': 'First', 'b': 'Second', 'c': 'Disabled'},
            disabledValues: const {'c'},
          ),
        ),
      );
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      expect(changes, ['b']);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('First'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();
      expect(changes, ['b']);
      semantics.dispose();
    },
  );

  testWidgets(
    'Radio group shows errors and helper and hides inline item descriptions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const SteyRadioGroup<String>(
            error: 'Required',
            description: 'Select one',
            children: [
              SteyRadioLegend('Hidden legend', visuallyHidden: true),
              SteyRadioItem(
                value: 'a',
                label: 'First',
                description: 'Only in cards',
              ),
            ],
          ),
        ),
      );
      expect(find.semantics.byLabel('Hidden legend'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Select one'), findsOneWidget);
      expect(find.text('Only in cards'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'Card groups retain odd rows, rich labels, RTL and enlarged text without overflow',
    (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          host(
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: const SteyRadioGroup<int>(
                appearance: SteyRadioAppearance.card,
                orientation: Axis.horizontal,
                defaultValue: 1,
                children: [
                  SteyRadioItem(
                    value: 1,
                    label: 'Free plan',
                    description: 'Personal projects',
                  ),
                  SteyRadioItem(
                    value: 2,
                    label: 'Pro plan',
                    labelWidget: Wrap(
                      children: [
                        Text('Pro'),
                        SteyBadge(child: Text('New')),
                      ],
                    ),
                  ),
                  SteyRadioItem(
                    value: 3,
                    label: 'Enterprise plan',
                    description: 'For teams',
                  ),
                ],
              ),
            ),
            direction: direction,
          ),
        );
        await tester.tap(find.text('Enterprise plan'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Segmented group shares radio semantics and keeps keyboard selection',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final changes = <String?>[];
      await tester.pumpWidget(
        host(
          SteyRadioGroup<String>(
            appearance: SteyRadioAppearance.segmented,
            onChanged: changes.add,
            children: const [
              SteyRadioLegend('Billing'),
              SteyRadioItem(value: 'm', label: 'Monthly'),
              SteyRadioItem(value: 'y', label: 'Yearly'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(changes, ['m', 'y']);
      expect(
        find.semantics.byFlag(SemanticsFlag.isInMutuallyExclusiveGroup),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
