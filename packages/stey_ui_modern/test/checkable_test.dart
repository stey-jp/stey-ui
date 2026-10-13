import 'dart:ui' show Tristate;

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
    'Parent checkbox cycles partial, all, none and restores partial while keeping disabled selections',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final changes = <List<String>>[];
      await tester.pumpWidget(
        host(
          SteyCheckboxGroup(
            defaultValue: const ['a', 'locked'],
            allValues: const ['a', 'b', 'locked', 'unavailable'],
            onChanged: changes.add,
            children: const [
              SteyCheckbox(parent: true, label: 'Select all'),
              SteyCheckboxItem(value: 'a', label: 'First'),
              SteyCheckboxItem(value: 'b', label: 'Second'),
              SteyCheckboxItem(
                value: 'locked',
                label: 'Locked selected',
                disabled: true,
              ),
              SteyCheckboxItem(
                value: 'unavailable',
                label: 'Unavailable',
                disabled: true,
              ),
            ],
          ),
        ),
      );
      expect(
        find.semantics.byFlag(SemanticsFlag.isCheckStateMixed),
        findsOneWidget,
      );
      for (var step = 0; step < 3; step++) {
        await tester.tap(find.text('Select all'));
        await tester.pump();
      }
      expect(changes, [
        ['a', 'b', 'locked'],
        ['locked'],
        ['a', 'locked'],
      ]);
      await tester.tap(find.text('Second'));
      await tester.pump();
      await tester.tap(find.text('Select all'));
      await tester.pump();
      expect(changes.last, ['locked']);
      semantics.dispose();
    },
  );
  testWidgets(
    'Label information opens by touch or keyboard without toggling its checkbox',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var changes = 0;
      await tester.pumpWidget(
        host(
          SteyCheckbox(
            label: 'Analytics',
            labelTooltip: 'Collected anonymously',
            onChanged: (_) => changes++,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('More information'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Collected anonymously'), findsOneWidget);
      expect(changes, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(changes, 0);
      expect(find.semantics.byLabel('Analytics'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        host(
          SteyCheckbox(
            label: 'Analytics',
            labelTooltip: 'Keyboard description',
            onChanged: (_) => changes++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Keyboard description'), findsOneWidget);
      expect(changes, 0);
      semantics.dispose();
    },
  );
  testWidgets(
    'Checkbox pointer focus, Space and Enter update one named control',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final changes = <bool?>[];
      await tester.pumpWidget(
        host(
          SteyCheckbox(
            label: 'Analytics',
            focusNode: focus,
            onChanged: changes.add,
          ),
        ),
      );
      expect(
        find.semantics.byFlag(SemanticsFlag.hasCheckedState),
        findsOneWidget,
      );
      expect(find.semantics.byLabel('Analytics'), findsOneWidget);
      await tester.tap(find.text('Analytics'));
      await tester.pump();
      expect(focus.hasPrimaryFocus, isTrue);
      expect(find.semantics.byFlag(SemanticsFlag.isChecked), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(changes, [true, false, true]);
      semantics.dispose();
    },
  );

  testWidgets(
    'Mixed checkbox reports mixed and clears to checked; legacy tristate cycles',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var checked = false, mixed = true;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, update) => SteyCheckbox(
              label: 'Select all',
              value: checked,
              indeterminate: mixed,
              onChanged: (next) => update(() {
                checked = next!;
                mixed = false;
              }),
            ),
          ),
        ),
      );
      expect(
        find.semantics.byFlag(SemanticsFlag.isCheckStateMixed),
        findsOneWidget,
      );
      await tester.tap(find.text('Select all'));
      await tester.pump();
      expect(checked, isTrue);
      expect(
        find.semantics.byFlag(SemanticsFlag.isCheckStateMixed),
        findsNothing,
      );
      bool? legacy = false;
      final changes = <bool?>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, update) => SteyCheckbox(
              label: 'Legacy',
              tristate: true,
              value: legacy,
              onChanged: (next) => update(() {
                legacy = next;
                changes.add(next);
              }),
            ),
          ),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Legacy'));
        await tester.pump();
      }
      expect(changes, [true, null, false]);
      semantics.dispose();
    },
  );

  testWidgets(
    'Disabled controls ignore pointer, keyboard and expose disabled state',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var calls = 0;
      await tester.pumpWidget(
        host(
          Column(
            children: [
              SteyCheckbox(
                value: true,
                enabled: false,
                label: 'Disabled checkbox',
                onChanged: (_) => calls++,
              ),
              SteySwitch(
                value: true,
                enabled: false,
                label: 'Disabled switch',
                onChanged: (_) => calls++,
              ),
            ],
          ),
        ),
      );
      for (final label in ['Disabled checkbox', 'Disabled switch']) {
        await tester.tap(find.text(label));
        await tester.pump();
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(label))
              .getSemanticsData()
              .flagsCollection
              .isEnabled,
          Tristate.isFalse,
        );
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(calls, 0);
      semantics.dispose();
    },
  );

  testWidgets(
    'Controlled checkbox changes only after its owner supplies the next value',
    (tester) async {
      final semantics = tester.ensureSemantics();
      bool? requested;
      await tester.pumpWidget(
        host(
          SteyCheckbox(
            label: 'Controlled',
            value: false,
            onChanged: (value) => requested = value,
          ),
        ),
      );
      await tester.tap(find.text('Controlled'));
      await tester.pump();
      expect(requested, isTrue);
      expect(find.semantics.byFlag(SemanticsFlag.isChecked), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'Checkbox group preserves selection, announces legend once and shows error with helper',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final changes = <List<String>>[];
      await tester.pumpWidget(
        host(
          SteyCheckboxGroup(
            defaultValue: const ['email'],
            onChanged: changes.add,
            error: 'Choose channels',
            description: 'Used for alerts',
            children: const [
              SteyCheckboxLegend('Channels', visuallyHidden: true),
              SteyCheckboxItem(value: 'email', label: 'Email'),
              SteyCheckboxItem(value: 'sms', label: 'SMS'),
            ],
          ),
        ),
      );
      expect(find.semantics.byLabel('Channels'), findsOneWidget);
      expect(find.text('Choose channels'), findsOneWidget);
      expect(find.text('Used for alerts'), findsOneWidget);
      await tester.tap(find.text('SMS'));
      await tester.pump();
      await tester.tap(find.text('Email'));
      await tester.pump();
      expect(changes, [
        ['email', 'sms'],
        ['sms'],
      ]);
      expect(find.semantics.byFlag(SemanticsFlag.isChecked), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'Card groups support odd horizontal rows, RTL, text scale and disable all children',
    (tester) async {
      var calls = 0;
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          host(
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: SteyCheckboxGroup(
                appearance: SteyCheckboxAppearance.card,
                orientation: Axis.horizontal,
                disabled: true,
                onChanged: (_) => calls++,
                children: const [
                  SteyCheckboxItem(
                    value: 'a',
                    label: 'First long option',
                    description: 'A helpful description',
                  ),
                  SteyCheckboxItem(value: 'b', label: 'Second long option'),
                  SteyCheckboxItem(value: 'c', label: 'Third option'),
                ],
              ),
            ),
            direction: direction,
          ),
        );
        await tester.tap(find.text('Third option'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      expect(calls, 0);
    },
  );

  testWidgets(
    'Switch toggles with pointer and keyboard while busy, animates despite reduced motion',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final changes = <bool>[];
      await tester.pumpWidget(
        host(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SteySwitch(
              label: 'Notifications',
              transitioning: true,
              onChanged: changes.add,
              focusNode: focus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.semantics.byLabel('Notifications'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Notifications'))
            .getSemanticsData()
            .hint,
        'Updating',
      );
      await tester.tap(find.text('Notifications'));
      await tester.pump();
      expect(focus.hasPrimaryFocus, isTrue);
      expect(find.semantics.byFlag(SemanticsFlag.isToggled), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 75));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 75));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(changes, [true, false]);
      semantics.dispose();
    },
  );

  testWidgets(
    'Switch group disables items and keeps validation and helper visible',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        host(
          SteySwitchGroup(
            legend: 'Preferences',
            disabled: true,
            error: 'Choose one',
            description: 'Your preferences',
            children: [
              SteySwitchItem(label: 'Email', onChanged: (_) => calls++),
              const SteySwitchItem(
                label: 'SMS',
                size: SteySwitchSize.sm,
                variant: SteySwitchVariant.neutral,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Email'));
      await tester.pump();
      expect(calls, 0);
      expect(find.text('Choose one'), findsOneWidget);
      expect(find.text('Your preferences'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
