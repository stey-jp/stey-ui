import 'package:flutter/material.dart';

import 'button.dart';
import 'display.dart';
import 'input.dart';
import 'theme.dart';
import 'messages.dart';

export 'command.dart';
export 'dropdown.dart';

class SteyDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? description,
    required Widget child,
    List<Widget> actions = const [],
    bool dismissible = true,
    double width = 480,
  }) {
    final c = SteyTheme.colorsOf(context);
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: .4),
      transitionDuration: const Duration(milliseconds: 150),
      transitionBuilder: (context, animation, secondary, child) =>
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: .97, end: 1).animate(animation),
              child: child,
            ),
          ),
      pageBuilder: (context, animation, secondary) => Center(
        child: Dialog(
          backgroundColor: c.base,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: SteyText(title, heading: 3)),
                      if (dismissible)
                        SteyButton(
                          onPressed: () => Navigator.pop(context),
                          semanticLabel: SteyMessages.of(context).closeDialog,
                          variant: SteyButtonVariant.ghost,
                          child: const Icon(Icons.close, size: 16),
                        ),
                    ],
                  ),
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SteyText(description, subtle: true),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: child,
                  ),
                  if (actions.isNotEmpty)
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: actions,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SteyLayerDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? description,
    required Widget child,
    List<Widget> actions = const [],
    double width = 600,
  }) => SteyDialog.show<T>(
    context,
    title: title,
    description: description,
    child: SteyLayerCard(child: child),
    actions: actions,
    width: width,
  );
}

class SteyPopover extends StatelessWidget {
  const SteyPopover({
    super.key,
    required this.trigger,
    required this.child,
    this.title,
    this.width = 280,
  });
  final Widget trigger, child;
  final String? title;
  final double width;
  @override
  Widget build(BuildContext context) => MenuAnchor(
    menuChildren: [
      SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SteyText(title!, bold: true),
                ),
              child,
            ],
          ),
        ),
      ),
    ],
    builder: (context, controller, _) => SteyButton(
      onPressed: () =>
          controller.isOpen ? controller.close() : controller.open(),
      child: trigger,
    ),
  );
}

class SteyTooltip extends StatelessWidget {
  const SteyTooltip({super.key, required this.message, required this.child});
  final String message;
  final Widget child;
  @override
  Widget build(BuildContext context) => Tooltip(message: message, child: child);
}

class SteyToast {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    SteyTone tone = SteyTone.neutral,
    Duration duration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final c = SteyTheme.colorsOf(context);
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.base,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: c.line),
        ),
        showCloseIcon: true,
        closeIconColor: c.subtle,
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
                textColor: c.link,
              )
            : null,
        content: Text(
          message,
          style: TextStyle(fontSize: 14, color: tone.foreground(c)),
        ),
      ),
    );
  }
}

class SteyDeleteResource extends StatefulWidget {
  const SteyDeleteResource({
    super.key,
    required this.resourceName,
    required this.onDelete,
  });
  final String resourceName;
  final VoidCallback onDelete;
  @override
  State<SteyDeleteResource> createState() => _SteyDeleteResourceState();
}

class _SteyDeleteResourceState extends State<SteyDeleteResource> {
  String confirmation = '';
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SteyText(SteyMessages.of(context).confirmDeletion(widget.resourceName)),
      const SizedBox(height: 8),
      SteyInput(
        label: SteyMessages.of(context).resourceName,
        onChanged: (v) => setState(() => confirmation = v),
      ),
      const SizedBox(height: 16),
      SteyButton(
        variant: SteyButtonVariant.destructive,
        onPressed: confirmation == widget.resourceName ? widget.onDelete : null,
        child: Text(SteyMessages.of(context).deleteResource),
      ),
    ],
  );
}
