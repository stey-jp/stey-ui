import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

void main() {
  Future<void> host(
    WidgetTester tester,
    VoidCallback Function(BuildContext) open, {
    double width = 1280,
    double height = 900,
    FocusNode? triggerFocus,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: SteyTheme.material(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => SteyButton(
              onPressed: open(context),
              focusNode: triggerFocus,
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    triggerFocus?.requestFocus();
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  final surface = find.byKey(const ValueKey('stey-layer-dialog-surface'));

  testWidgets('All desktop sizes and top alignment follow the reference', (
    tester,
  ) async {
    for (final size in SteyLayerDialogSize.values) {
      await host(
        tester,
        (context) =>
            () => SteyLayerDialog.show(
              context,
              title: 'Settings',
              child: const Text('Body'),
              size: size,
              verticalAlign: SteyLayerDialogVerticalAlign.top,
            ),
      );
      expect(tester.getSize(surface).width, size.width);
      expect(tester.getTopLeft(surface).dy, 64);
      expect(find.byType(SteyLayerDialogActions), findsNothing);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Mobile full-width sheet and desktop breakpoint at 640', (
    tester,
  ) async {
    for (final width in [320.0, 639.0, 640.0]) {
      await host(
        tester,
        (context) =>
            () => SteyLayerDialog.show(
              context,
              title: 'Settings',
              child: const Text('Body'),
              action: SteyLayerDialogAction(
                onPressed: () {},
                child: const Text('Save'),
              ),
            ),
        width: width,
      );
      final rect = tester.getRect(surface);
      expect(rect.width, width < 640 ? width : 576);
      if (width < 640) expect(rect.bottom, 900);
      final close = tester.widget<SteyButton>(
        find.widgetWithText(SteyButton, 'Close'),
      );
      expect(
        close.variant,
        width < 640 ? SteyButtonVariant.secondary : SteyButtonVariant.ghost,
      );
      expect(find.byIcon(Icons.close), findsNothing);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Normal barrier and Escape dismiss; alerts reject barrier only', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final alert in [false, true]) {
      await host(
        tester,
        (context) =>
            () => SteyLayerDialog.show(
              context,
              title: 'Settings',
              alert: alert,
              child: const Text('Consequence'),
              action: SteyLayerDialogAction(
                onPressed: () {},
                child: const Text('Confirm'),
              ),
            ),
      );
      expect(
        find.semantics.byPredicate(
          (n) =>
              n.getSemanticsData().role ==
              (alert ? SemanticsRole.alertDialog : SemanticsRole.dialog),
        ),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(surface, alert ? findsOneWidget : findsNothing);
      if (alert) {
        expect(find.text('Cancel'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(surface, findsNothing);
      }
    }
    semantics.dispose();
  });

  testWidgets('Pending state blocks user dismissal but not controller.close', (
    tester,
  ) async {
    final controller = SteyLayerDialogController<String>();
    String? result;
    await host(
      tester,
      (context) => () async {
        result = await SteyLayerDialog.show<String>(
          context,
          controller: controller,
          title: 'Settings',
          child: const Text('Body'),
          action: SteyLayerDialogAction(
            onPressed: () {},
            child: const Text('Save'),
          ),
        );
      },
    );
    controller.dismissDisabled = true;
    await tester.pump();
    expect(
      tester
          .widget<SteyButton>(find.widgetWithText(SteyButton, 'Close'))
          .onPressed,
      isNull,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(surface, findsOneWidget);
    controller.close('saved');
    await tester.pump();
    expect(surface, findsOneWidget); // Retained during the reverse transition.
    await tester.pumpAndSettle();
    expect(surface, findsNothing);
    expect(result, 'saved');
    expect(controller.isOpen, isFalse);
    controller.dispose();
  });

  testWidgets('Re-enabling dismissal updates the barrier and dismiss button', (
    tester,
  ) async {
    final controller = SteyLayerDialogController<void>(dismissDisabled: true);
    await host(
      tester,
      (context) =>
          () => SteyLayerDialog.show<void>(
            context,
            controller: controller,
            title: 'Settings',
            child: const Text('Body'),
            action: SteyLayerDialogAction(
              onPressed: () {},
              child: const Text('Save'),
            ),
          ),
    );
    controller.dismissDisabled = false;
    await tester.pump();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(surface, findsNothing);
    controller.dispose();
  });

  testWidgets('Split action menu stays inside the dialog and returns focus', (
    tester,
  ) async {
    var draft = 0;
    await host(
      tester,
      (context) =>
          () => SteyLayerDialog.show(
            context,
            title: 'Settings',
            child: const Text('Body'),
            action: SteyLayerDialogAction(
              onPressed: () {},
              menu: [SteyMenuItem('Save draft', onPressed: () => draft++)],
              child: const Text('Save'),
            ),
          ),
    );
    await tester.tap(find.bySemanticsLabel('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    expect(draft, 1);
    expect(surface, findsOneWidget);
    expect(find.text('Save draft'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(surface, findsNothing);
  });

  testWidgets(
    'Long bodies scroll independently with sticky actions and title',
    (tester) async {
      await host(
        tester,
        (context) =>
            () => SteyLayerDialog.show(
              context,
              title: 'Settings',
              description: 'Supporting description',
              child: Column(
                children: [
                  for (var i = 0; i < 50; i++)
                    SizedBox(height: 40, child: Text('Setting $i')),
                ],
              ),
              action: SteyLayerDialogAction(
                onPressed: () {},
                child: const Text('Save'),
              ),
            ),
      );
      final titleBefore = tester.getTopLeft(find.text('Settings'));
      final actionBefore = tester.getTopLeft(find.text('Save'));
      await tester.drag(
        find.byKey(const ValueKey('stey-layer-dialog-scroll')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Settings')), titleBefore);
      expect(tester.getTopLeft(find.text('Save')), actionBefore);
      final transition = tester.widget<SizeTransition>(
        find.byType(SizeTransition),
      );
      expect(transition.sizeFactor.value, 0);
      final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('stey-layer-dialog-scroll')),
      );
      scroll.controller!.jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SizeTransition>(find.byType(SizeTransition))
            .sizeFactor
            .value,
        1,
      );
    },
  );

  testWidgets(
    'Alias produces the same action; primary action never closes itself',
    (tester) async {
      var invoked = 0;
      // ignore: deprecated_member_use_from_same_package
      final SteyLayerDialogPrimary action = SteyLayerDialogPrimary(
        onPressed: () => invoked++,
        child: const Text('Save'),
      );
      await host(
        tester,
        (context) =>
            () => SteyLayerDialog.show(
              context,
              title: 'Settings',
              child: const Text('Body'),
              action: action,
            ),
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(invoked, 1);
      expect(surface, findsOneWidget);
    },
  );

  testWidgets('Mobile drag dismissal is disabled for pending work and alerts', (
    tester,
  ) async {
    for (final pending in [false, true]) {
      final controller = SteyLayerDialogController<void>(
        dismissDisabled: pending,
      );
      await host(
        tester,
        (context) =>
            () => SteyLayerDialog.show<void>(
              context,
              controller: controller,
              title: 'Settings',
              child: const Text('Body'),
            ),
        width: 390,
      );
      await tester.drag(
        find.byKey(const ValueKey('stey-layer-dialog-handle')),
        const Offset(0, 100),
      );
      await tester.pumpAndSettle();
      expect(surface, pending ? findsOneWidget : findsNothing);
      if (pending) {
        controller.close();
        await tester.pumpAndSettle();
      }
      controller.dispose();
    }
    await host(
      tester,
      (context) =>
          () => SteyLayerDialog.show(
            context,
            title: 'Alert',
            alert: true,
            child: const Text('Consequence'),
            action: SteyLayerDialogAction(
              onPressed: () {},
              child: const Text('Confirm'),
            ),
          ),
      width: 390,
    );
    expect(
      find.byKey(const ValueKey('stey-layer-dialog-handle')),
      findsNothing,
    );
  });

  testWidgets('Short scroll range does not oscillate the description', (
    tester,
  ) async {
    await host(
      tester,
      (context) =>
          () => SteyLayerDialog.show(
            context,
            title: 'Settings',
            description: 'Supporting description',
            child: const SizedBox(height: 610),
            action: SteyLayerDialogAction(
              onPressed: () {},
              child: const Text('Save'),
            ),
          ),
      height: 780,
    );
    await tester.drag(
      find.byKey(const ValueKey('stey-layer-dialog-scroll')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SizeTransition>(find.byType(SizeTransition))
          .sizeFactor
          .value,
      1,
    );
  });

  testWidgets('Animations preserve their full duration with reduced motion', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final controller = SteyLayerDialogController<void>();
    await host(
      tester,
      (context) =>
          () => SteyLayerDialog.show<void>(
            context,
            title: 'Settings',
            controller: controller,
            child: const Text('Body'),
          ),
      width: 390,
    );
    controller.close();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(surface, findsOneWidget);
    await tester.pumpAndSettle();
    expect(surface, findsNothing);
    controller.dispose();
  });

  testWidgets('Repeated programmatic close does not pop the underlying page', (
    tester,
  ) async {
    final controller = SteyLayerDialogController<void>();
    await host(
      tester,
      (context) =>
          () => SteyLayerDialog.show<void>(
            context,
            title: 'Settings',
            controller: controller,
            child: const Text('Body'),
          ),
    );
    controller.close();
    controller.close();
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(surface, findsNothing);
    controller.dispose();
  });

  testWidgets('Tab stays in the modal and dismissal restores trigger focus', (
    tester,
  ) async {
    final triggerFocus = FocusNode();
    await host(
      tester,
      (context) =>
          () => SteyLayerDialog.show(
            context,
            title: 'Settings',
            child: const SteyInput(label: 'Name'),
            action: SteyLayerDialogAction(
              onPressed: () {},
              child: const Text('Save'),
            ),
          ),
      triggerFocus: triggerFocus,
    );
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(triggerFocus.hasFocus, isFalse);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(surface, findsNothing);
    expect(triggerFocus.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    triggerFocus.dispose();
  });

  testWidgets('Mobile footer remains above the software keyboard', (
    tester,
  ) async {
    await host(
      tester,
      (context) =>
          () => SteyLayerDialog.show(
            context,
            title: 'Settings',
            child: const SteyInput(label: 'Name'),
            action: SteyLayerDialogAction(
              onPressed: () {},
              child: const Text('Save'),
            ),
          ),
      width: 390,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getRect(surface).bottom, 540);
    expect(tester.getRect(find.text('Save')).bottom, lessThan(540));
    expect(tester.takeException(), isNull);
  });
}
