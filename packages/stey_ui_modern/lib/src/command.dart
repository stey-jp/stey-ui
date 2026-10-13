import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'display.dart';
import 'input.dart';
import 'theme.dart';

/// Inclusive UTF-16 match indices, as used by the upstream search results.
typedef SteyHighlightRange = (int start, int end);

class SteyHighlightedText extends StatelessWidget {
  const SteyHighlightedText(this.text, {super.key, this.highlights = const []});
  final String text;
  final List<SteyHighlightRange> highlights;
  @override
  Widget build(BuildContext context) {
    final ranges =
        highlights
            .where((r) => r.$1 <= r.$2 && r.$2 >= 0 && r.$1 < text.length)
            .map(
              (r) => (
                r.$1.clamp(0, text.length),
                (r.$2 + 1).clamp(0, text.length),
              ),
            )
            .toList()
          ..sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(int, int)>[];
    for (final range in ranges) {
      if (merged.isNotEmpty && range.$1 <= merged.last.$2) {
        final last = merged.removeLast();
        merged.add((last.$1, range.$2 > last.$2 ? range.$2 : last.$2));
      } else {
        merged.add(range);
      }
    }
    final c = SteyTheme.colorsOf(context);
    final spans = <TextSpan>[];
    var offset = 0;
    for (final range in merged) {
      if (offset < range.$1) {
        spans.add(TextSpan(text: text.substring(offset, range.$1)));
      }
      spans.add(
        TextSpan(
          text: text.substring(range.$1, range.$2),
          style: TextStyle(backgroundColor: c.warningTint, color: c.text),
        ),
      );
      offset = range.$2;
    }
    if (offset < text.length) spans.add(TextSpan(text: text.substring(offset)));
    return Text.rich(TextSpan(children: spans));
  }
}

class SteyCommand {
  const SteyCommand(
    this.label,
    this.onPressed, {
    this.group = 'Commands',
    this.keywords = const [],
    this.description,
    this.breadcrumbs = const [],
    this.highlights = const [],
    this.breadcrumbHighlights = const [],
    this.icon,
    this.disabled = false,
    this.nonInteractive = false,
    this.external = false,
    this.showArrow = true,
    this.onSelect,
  });
  final String label, group;
  final VoidCallback onPressed;
  final List<String> keywords, breadcrumbs;
  final String? description;
  final List<SteyHighlightRange> highlights;
  final List<List<SteyHighlightRange>> breadcrumbHighlights;
  final Widget? icon;
  final bool disabled, nonInteractive, external, showArrow;
  final ValueChanged<bool>? onSelect;
  bool get selectable => !disabled && !nonInteractive;
}

class SteyCommandPalette extends StatefulWidget {
  const SteyCommandPalette({
    super.key,
    required this.commands,
    this.controller,
    this.onQueryChanged,
    this.onHighlighted,
    this.filter,
    this.loading = false,
    this.emptyText = 'No results found',
    this.placeholder = 'Search commands',
    this.footer,
    this.closeOnSelect = false,
  });
  final List<SteyCommand> commands;
  final TextEditingController? controller;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<SteyCommand?>? onHighlighted;
  final bool Function(SteyCommand, String)? filter;
  final bool loading, closeOnSelect;
  final String emptyText, placeholder;
  final Widget? footer;

  static Future<void> show(
    BuildContext context, {
    required List<SteyCommand> commands,
    Widget? footer,
  }) {
    final brightness = SteyTheme.colorsOf(context).brightness;
    final c = SteyTheme.colorsOf(context);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: c.overlay.withValues(alpha: .8),
      transitionDuration: const Duration(milliseconds: 150),
      transitionBuilder: (context, animation, secondary, child) =>
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: .9, end: 1.0).animate(animation),
              child: child,
            ),
          ),
      pageBuilder: (context, _, _) => SteyTheme(
        brightness: brightness,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.sizeOf(context).height * .1,
                left: 16,
                right: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 672,
                  maxHeight: MediaQuery.sizeOf(context).height * .6,
                ),
                child: Material(
                  color: c.elevated,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: Shortcuts(
                    shortcuts: const {
                      SingleActivator(LogicalKeyboardKey.escape):
                          DismissIntent(),
                    },
                    child: Actions(
                      actions: {
                        DismissIntent: CallbackAction<DismissIntent>(
                          onInvoke: (_) {
                            Navigator.pop(context);
                            return null;
                          },
                        ),
                      },
                      child: SteyCommandPalette(
                        commands: commands,
                        footer: footer,
                        closeOnSelect: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<SteyCommandPalette> createState() => _SteyCommandPaletteState();
}

class _SteyCommandPaletteState extends State<SteyCommandPalette> {
  late TextEditingController controller;
  final Map<SteyCommand, GlobalKey> keys = {};
  SteyCommand? highlighted;
  List<SteyCommand> get filtered => widget.commands
      .where(
        (command) =>
            widget.filter?.call(command, controller.text) ??
            '${command.label} ${command.breadcrumbs.join(' ')} ${command.keywords.join(' ')}'
                .toLowerCase()
                .contains(controller.text.toLowerCase()),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? TextEditingController();
    controller.addListener(changed);
    resetHighlight();
  }

  @override
  void didUpdateWidget(SteyCommandPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      controller.removeListener(changed);
      if (oldWidget.controller == null) controller.dispose();
      controller = widget.controller ?? TextEditingController();
      controller.addListener(changed);
    }
    keys.removeWhere((command, _) => !widget.commands.contains(command));
    if (!filtered.contains(highlighted) || highlighted?.selectable != true) {
      resetHighlight();
    }
  }

  void resetHighlight() {
    highlighted = null;
    for (final command in filtered) {
      if (command.selectable) {
        highlighted = command;
        break;
      }
    }
  }

  void changed() {
    setState(resetHighlight);
    widget.onQueryChanged?.call(controller.text);
    widget.onHighlighted?.call(highlighted);
  }

  void highlight(SteyCommand command) {
    if (!command.selectable || command == highlighted) return;
    setState(() => highlighted = command);
    widget.onHighlighted?.call(command);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = keys[command]?.currentContext;
      if (mounted && target != null) {
        Scrollable.ensureVisible(
          target,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  void selectCommand(SteyCommand command) {
    if (!command.selectable || widget.loading) return;
    final newTab =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (widget.closeOnSelect) Navigator.pop(context);
    if (command.onSelect != null) {
      command.onSelect!(newTab);
    } else {
      command.onPressed();
    }
  }

  KeyEventResult onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (widget.loading) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter && highlighted != null) {
      selectCommand(highlighted!);
      return KeyEventResult.handled;
    }
    final direction = event.logicalKey == LogicalKeyboardKey.arrowDown
        ? 1
        : event.logicalKey == LogicalKeyboardKey.arrowUp
        ? -1
        : 0;
    if (direction == 0) return KeyEventResult.ignored;
    final selectable = filtered.where((command) => command.selectable).toList();
    if (selectable.isNotEmpty) {
      final index = selectable.indexOf(highlighted ?? selectable.first);
      highlight(selectable[(index + direction) % selectable.length]);
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    controller.removeListener(changed);
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final results = filtered;
    return Focus(
      onKeyEvent: onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SteyInput(
              controller: controller,
              placeholder: widget.placeholder,
              semanticLabel: widget.placeholder,
              autofocus: true,
              prefix: const Icon(Icons.search, size: 16),
            ),
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360, minHeight: 80),
              child: widget.loading
                  ? const Center(child: SteyLoader(size: 24))
                  : results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          widget.emptyText,
                          style: TextStyle(color: c.subtle),
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      children: [
                        for (
                          var index = 0;
                          index < results.length;
                          index++
                        ) ...[
                          if (index == 0 ||
                              results[index].group != results[index - 1].group)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                              child: Text(
                                results[index].group,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: c.subtle,
                                ),
                              ),
                            ),
                          result(results[index], c),
                        ],
                      ],
                    ),
            ),
          ),
          if (widget.footer != null)
            Container(
              color: c.elevated,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: DefaultTextStyle.merge(
                style: TextStyle(fontSize: 12, color: c.subtle),
                child: widget.footer!,
              ),
            ),
        ],
      ),
    );
  }

  Widget result(SteyCommand command, SteyColors c) => MouseRegion(
    onEnter: (_) => highlight(command),
    child: Semantics(
      selected: highlighted == command,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: SteyButton(
          key: keys.putIfAbsent(command, GlobalKey.new),
          variant: SteyButtonVariant.ghost,
          alignment: Alignment.centerLeft,
          backgroundColor: highlighted == command && command.selectable
              ? c.overlay
              : null,
          onPressed: command.selectable ? () => selectCommand(command) : null,
          icon: command.icon,
          trailing: command.external
              ? const Icon(Icons.open_in_new, size: 16)
              : highlighted == command && command.showArrow
              ? const Icon(Icons.arrow_forward, size: 16)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (var i = 0; i < command.breadcrumbs.length; i++) ...[
                      SteyHighlightedText(
                        command.breadcrumbs[i],
                        highlights: i < command.breadcrumbHighlights.length
                            ? command.breadcrumbHighlights[i]
                            : const [],
                      ),
                      Icon(Icons.chevron_right, size: 12, color: c.subtle),
                    ],
                    SteyHighlightedText(
                      command.label,
                      highlights: command.highlights,
                    ),
                  ],
                ),
                if (command.description != null)
                  Text(
                    command.description!,
                    style: TextStyle(fontSize: 12, color: c.subtle),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
