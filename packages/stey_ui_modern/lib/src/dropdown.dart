import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'theme.dart';

/// A menu action, or a submenu when [children] is nonempty.
class SteyMenuItem {
  const SteyMenuItem(
    this.label, {
    this.onPressed,
    this.icon,
    this.leading,
    this.child,
    this.disabled = false,
    this.destructive = false,
    this.checked,
    this.inset = false,
    this.shortcut,
    this.href,
    this.closeOnActivate = true,
    this.children = const [],
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading, child;
  final bool disabled, destructive, inset, closeOnActivate;
  final bool? checked;
  final String? shortcut;

  /// Link semantics; the caller performs navigation in [onPressed].
  final Uri? href;
  final List<SteyMenuItem> children;
  bool get enabled => !disabled && (onPressed != null || children.isNotEmpty);
  bool? get selection => checked;
  SemanticsRole get role => SemanticsRole.menuItem;
  void activate() => onPressed?.call();
}

class SteyMenuGroup extends SteyMenuItem {
  const SteyMenuGroup(super.label, {required super.children, super.inset});
}

class SteyMenuSeparator extends SteyMenuItem {
  const SteyMenuSeparator() : super('');
}

class SteyMenuCheckboxItem extends SteyMenuItem {
  const SteyMenuCheckboxItem(
    super.label, {
    required bool value,
    this.onChanged,
    super.disabled,
    super.closeOnActivate,
    super.shortcut,
  }) : super(checked: value);
  final ValueChanged<bool>? onChanged;
  @override
  bool get enabled => !disabled && onChanged != null;
  @override
  SemanticsRole get role => SemanticsRole.menuItemCheckbox;
  @override
  void activate() => onChanged?.call(!checked!);
}

class SteyMenuRadioItem<T> extends SteyMenuItem {
  const SteyMenuRadioItem(
    super.label, {
    required this.value,
    required this.groupValue,
    this.onChanged,
    super.icon,
    super.leading,
    super.inset,
    super.disabled,
    super.closeOnActivate,
  });
  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;
  @override
  bool get enabled => !disabled && onChanged != null;
  @override
  bool get selection => value == groupValue;
  @override
  SemanticsRole get role => SemanticsRole.menuItemRadio;
  @override
  void activate() => onChanged?.call(value);
}

/// Native cascading menus; [controller] can also open and close the root.
class SteyDropdownMenu extends StatefulWidget {
  const SteyDropdownMenu({
    super.key,
    required this.items,
    required this.child,
    this.controller,
    this.onOpenChanged,
    this.disabled = false,
    this.label,
    this.width,
    this.sideOffset = 8,
    this.alignOffset = 0,
    this.submenuSideOffset = 2,
  }) : assert(width == null || width >= 144);
  final List<SteyMenuItem> items;
  final Widget child;
  final MenuController? controller;
  final ValueChanged<bool>? onOpenChanged;
  final bool disabled;
  final String? label;
  final double? width;
  final double sideOffset, alignOffset, submenuSideOffset;
  @override
  State<SteyDropdownMenu> createState() => _DropdownState();
}

class _DropdownState extends State<SteyDropdownMenu> {
  final internalController = MenuController();
  final triggerFocus = FocusNode();
  final panelKey = GlobalKey<_MenuPanelState>();
  bool open = false;
  MenuController get controller => widget.controller ?? internalController;

  void openFromKeyboard(bool last) {
    if (widget.disabled || widget.items.isEmpty) return;
    controller.open();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) panelKey.currentState?.focusBoundary(last);
    });
  }

  void changed(bool value) {
    if (open == value) return;
    setState(() => open = value);
    widget.onOpenChanged?.call(value);
  }

  @override
  void dispose() {
    triggerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !open,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) controller.close();
    },
    child: MenuAnchor(
      clipBehavior: Clip.none,
      controller: controller,
      childFocusNode: triggerFocus,
      useRootOverlay: true,
      consumeOutsideTap: true,
      alignmentOffset: Offset(widget.alignOffset, widget.sideOffset),
      style: _menuStyle(context, width: widget.width),
      onOpen: () => changed(true),
      onClose: () => changed(false),
      menuChildren: [
        _MenuPanel(
          key: panelKey,
          items: widget.items,
          rootController: controller,
          direction: Directionality.of(context),
          label: widget.label,
          submenuSideOffset: widget.submenuSideOffset,
          width: widget.width,
        ),
      ],
      builder: (context, controller, _) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): controller.close,
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              openFromKeyboard(false),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              openFromKeyboard(true),
        },
        child: Semantics(
          expanded: open,
          child: SteyButton(
            focusNode: triggerFocus,
            semanticLabel: widget.label,
            onPressed: widget.disabled || widget.items.isEmpty
                ? null
                : () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
            trailing: const Icon(Icons.expand_more, size: 16),
            child: widget.child,
          ),
        ),
      ),
    ),
  );
}

MenuStyle _menuStyle(BuildContext context, {double? width}) {
  final c = SteyTheme.colorsOf(context);
  return MenuStyle(
    backgroundColor: WidgetStatePropertyAll(c.control),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: WidgetStatePropertyAll(c.shadowDrop),
    elevation: const WidgetStatePropertyAll(8),
    side: WidgetStatePropertyAll(BorderSide(color: c.line)),
    shape: const WidgetStatePropertyAll(
      _MenuRingBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    ),
    padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
    minimumSize: const WidgetStatePropertyAll(Size(144, 0)),
    fixedSize: width == null
        ? null
        : WidgetStatePropertyAll(Size(width, double.infinity)),
    alignment: AlignmentDirectional.bottomStart,
    visualDensity: VisualDensity.standard,
  );
}

class _MenuRingBorder extends RoundedRectangleBorder {
  const _MenuRingBorder({required super.borderRadius, super.side});
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  _MenuRingBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => _MenuRingBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
  );
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawRRect(
      borderRadius.resolve(textDirection).toRRect(rect).inflate(side.width / 2),
      side.toPaint(),
    );
  }
}

List<SteyMenuItem> _flatten(List<SteyMenuItem> items) => [
  for (final item in items) ...[
    item,
    if (item is SteyMenuGroup) ..._flatten(item.children),
  ],
];

({double width, double height}) _popupSize(
  BuildContext context,
  List<SteyMenuItem> items,
) {
  final entries = _flatten(items);
  final inset = entries.any((e) => e.leading != null || e.icon != null);
  var width = 144.0, height = 12.0;
  double measure(String label, {bool bold = false, bool shortcut = false}) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Inter',
          package: 'stey_ui_modern',
          fontSize: shortcut ? 12 : 14,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          height: 1.5,
          letterSpacing: shortcut ? 1.2 : 0,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final result = painter.width;
    painter.dispose();
    return result;
  }

  for (final item in entries) {
    if (item is SteyMenuSeparator) {
      height += 9;
      continue;
    }
    final icon = item.leading != null || item.icon != null;
    final left = inset || item.inset || item is SteyMenuCheckboxItem
        ? 32.0
        : 8.0;
    final trailing = item.shortcut != null
        ? measure(item.shortcut!, shortcut: true) + 8
        : item.children.isNotEmpty && item is! SteyMenuGroup ||
              item.selection == true
        ? 24.0
        : 0.0;
    width = math.max(
      width,
      measure(item.label, bold: item is SteyMenuGroup) +
          math.max(left, icon ? 32.0 : 8.0) +
          20 +
          trailing,
    );
    height += math.max(
      33,
      MediaQuery.textScalerOf(context).scale(14) * 1.5 + 12,
    );
  }
  return (width: width, height: height);
}

class _MenuPanel extends StatefulWidget {
  const _MenuPanel({
    super.key,
    required this.items,
    required this.rootController,
    required this.direction,
    required this.submenuSideOffset,
    this.width,
    this.label,
    this.onBack,
  });
  final List<SteyMenuItem> items;
  final MenuController rootController;
  final TextDirection direction;
  final double submenuSideOffset;
  final double? width;
  final String? label;
  final VoidCallback? onBack;
  @override
  State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  final nodes = <FocusNode>[];
  Timer? searchTimer;
  String search = '';
  VoidCallback? closeChild;
  void activateRow(VoidCallback? close) {
    if (closeChild != close) closeChild?.call();
    closeChild = close;
  }

  late List<SteyMenuItem> entries;

  void sync() {
    entries = _flatten(widget.items);
    while (nodes.length < entries.length) {
      nodes.add(FocusNode());
    }
    while (nodes.length > entries.length) {
      nodes.removeLast().dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    sync();
  }

  @override
  void didUpdateWidget(_MenuPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  void dispose() {
    searchTimer?.cancel();
    for (final node in nodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool available(int i) =>
      entries[i] is! SteyMenuGroup &&
      entries[i] is! SteyMenuSeparator &&
      entries[i].enabled;
  void focusBoundary(bool last) {
    final indices = List.generate(entries.length, (i) => i).where(available);
    if (indices.isNotEmpty) {
      nodes[last ? indices.last : indices.first].requestFocus();
    }
  }

  void focusRelative(int delta) {
    final indices = List.generate(
      entries.length,
      (i) => i,
    ).where(available).toList();
    if (indices.isEmpty) return;
    final current = indices.indexWhere((i) => nodes[i].hasFocus);
    final next = current < 0
        ? (delta > 0 ? 0 : indices.length - 1)
        : (current + delta) % indices.length;
    nodes[indices[next]].requestFocus();
  }

  KeyEventResult keyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      widget.rootController.close();
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.home ||
        event.logicalKey == LogicalKeyboardKey.end) {
      focusBoundary(event.logicalKey == LogicalKeyboardKey.end);
      return KeyEventResult.handled;
    }
    final character = event.character;
    if (character == null ||
        character.trim().isEmpty ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    searchTimer?.cancel();
    final text = character.toLowerCase();
    search = search.length == 1 && search == text ? text : search + text;
    searchTimer = Timer(const Duration(milliseconds: 500), () => search = '');
    final current = nodes.indexWhere((n) => n.hasFocus);
    for (var step = 1; step <= entries.length; step++) {
      final i = (current + step) % entries.length;
      if (available(i) && entries[i].label.toLowerCase().startsWith(search)) {
        nodes[i].requestFocus();
        break;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final inset = entries.any((e) => e.leading != null || e.icon != null);
    var index = 0;
    Widget groupLabel(SteyMenuItem item) => Padding(
      padding: EdgeInsetsDirectional.only(
        start: inset || item.inset ? 32 : 8,
        end: 8,
        top: 6,
        bottom: 6,
      ),
      child: Text(
        item.label,
        style: TextStyle(
          fontFamily: 'Inter',
          package: 'stey_ui_modern',
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: c.text,
        ),
      ),
    );
    Widget row(SteyMenuItem item) {
      final i = index++;
      if (item is SteyMenuSeparator) {
        return ExcludeSemantics(
          child: SizedBox(
            height: 9,
            child: CustomPaint(painter: _SeparatorPainter(c.hairline)),
          ),
        );
      }
      if (item is SteyMenuGroup) {
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: item.label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(child: groupLabel(item)),
              for (final child in item.children) row(child),
            ],
          ),
        );
      }
      return _MenuRow(
        key: ValueKey(nodes[i]),
        item: item,
        rootController: widget.rootController,
        onActive: activateRow,
        focusNode: nodes[i],
        inset: inset,
        submenuSideOffset: widget.submenuSideOffset,
        width: widget.width,
      );
    }

    return Directionality(
      textDirection: widget.direction,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.menu,
        label: widget.label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 132),
          child: SizedBox(
            width: widget.width == null ? null : widget.width! - 12,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape):
                    widget.onBack ?? widget.rootController.close,
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    focusRelative(1),
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    focusRelative(-1),
                const SingleActivator(LogicalKeyboardKey.home): () =>
                    focusBoundary(false),
                const SingleActivator(LogicalKeyboardKey.end): () =>
                    focusBoundary(true),
                if (widget.onBack != null) ...{
                  SingleActivator(
                    widget.direction == TextDirection.ltr
                        ? LogicalKeyboardKey.arrowLeft
                        : LogicalKeyboardKey.arrowRight,
                  ): widget.onBack!,
                },
              },
              child: Focus(
                autofocus: true,
                includeSemantics: false,
                skipTraversal: true,
                onKeyEvent: keyEvent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final item in widget.items) row(item)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeparatorPainter extends CustomPainter {
  const _SeparatorPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Rect.fromLTWH(-4, 4, size.width + 8, 1),
    Paint()..color = color,
  );
  @override
  bool shouldRepaint(_SeparatorPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({
    super.key,
    required this.item,
    required this.rootController,
    required this.onActive,
    required this.focusNode,
    required this.inset,
    required this.submenuSideOffset,
    this.width,
  });
  final SteyMenuItem item;
  final MenuController rootController;
  final ValueChanged<VoidCallback?> onActive;
  final FocusNode focusNode;
  final bool inset;
  final double submenuSideOffset;
  final double? width;
  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool hovered = false;
  Timer? hoverTimer;
  OverlayEntry? popup;
  final anchorKey = GlobalKey();
  final submenuKey = GlobalKey<_MenuPanelState>();

  @override
  void didUpdateWidget(_MenuRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (popup != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) popup?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    hoverTimer?.cancel();
    popup?.remove();
    popup?.dispose();
    super.dispose();
  }

  void closePopup() {
    hoverTimer?.cancel();
    final entry = popup;
    if (entry == null) return;
    popup = null;
    entry.remove();
    entry.dispose();
    if (mounted) setState(() {});
  }

  void onHover(bool value) {
    hovered = value;
    hoverTimer?.cancel();
    if (!value || !widget.item.enabled) return;
    widget.onActive(widget.item.children.isEmpty ? null : closePopup);
    if (widget.item.children.isNotEmpty) {
      hoverTimer = Timer(
        const Duration(milliseconds: 100),
        () => showPopup(false),
      );
    }
  }

  void openSubmenu() => showPopup(true);

  void showPopup(bool focusFirst) {
    if (!widget.item.enabled) return;
    widget.onActive(closePopup);
    if (popup == null) {
      final overlay = Overlay.of(context, rootOverlay: true);
      final anchor = anchorKey.currentContext!.findRenderObject()! as RenderBox;
      final overlayBox = overlay.context.findRenderObject()! as RenderBox;
      final rect =
          anchor.localToGlobal(Offset.zero, ancestor: overlayBox) & anchor.size;
      final direction = Directionality.of(context);
      final media = MediaQuery.of(context);
      final safeLeft = math.max(8.0, media.padding.left);
      final safeRight =
          overlayBox.size.width - math.max(8.0, media.padding.right);
      final safeTop = math.max(8.0, media.padding.top);
      final safeBottom =
          overlayBox.size.height -
          math.max(
            8.0,
            math.max(media.padding.bottom, media.viewInsets.bottom),
          );
      final measured = _popupSize(context, widget.item.children);
      final width = math.min(
        widget.width ?? measured.width,
        safeRight - safeLeft,
      );
      final height = measured.height;
      var left = direction == TextDirection.ltr
          ? rect.right + widget.submenuSideOffset
          : rect.left - width - widget.submenuSideOffset;
      if (left + width > safeRight || left < safeLeft) {
        left = direction == TextDirection.ltr
            ? rect.left - width - widget.submenuSideOffset
            : rect.right + widget.submenuSideOffset;
      }
      left = left.clamp(safeLeft, math.max(safeLeft, safeRight - width));
      final top = (rect.top - 6)
          .clamp(safeTop, math.max(safeTop, safeBottom - height))
          .toDouble();
      final c = SteyTheme.colorsOf(context);
      // OverlayEntry keeps nested menu semantics independent of portal traversal
      // reparenting. No DOM or SDK patch is required.
      popup = OverlayEntry(
        builder: (_) => Positioned(
          left: left,
          top: top,
          width: width,
          child: InheritedTheme.captureAll(
            context,
            Directionality(
              textDirection: direction,
              child: TapRegion(
                groupId: widget.rootController,
                child: Material(
                  color: c.control,
                  surfaceTintColor: Colors.transparent,
                  elevation: 8,
                  shadowColor: c.shadowDrop,
                  shape: _MenuRingBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: c.line),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: math.max(0, safeBottom - top),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(6),
                      child: FocusScope(
                        child: _MenuPanel(
                          key: submenuKey,
                          items: widget.item.children,
                          rootController: widget.rootController,
                          direction: direction,
                          submenuSideOffset: widget.submenuSideOffset,
                          width: width,
                          onBack: () {
                            closePopup();
                            widget.focusNode.requestFocus();
                          },
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
      overlay.insert(popup!);
      setState(() {});
    }
    if (focusFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) submenuKey.currentState?.focusBoundary(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final c = SteyTheme.colorsOf(context);
    final foreground = item.destructive ? c.danger : c.text;
    final icon = item.leading ?? (item.icon == null ? null : Icon(item.icon));
    final checkbox = item.role == SemanticsRole.menuItemCheckbox;
    final radio = item.role == SemanticsRole.menuItemRadio;
    final left = checkbox || item.inset || (widget.inset && icon == null)
        ? 32.0
        : 8.0;
    final style = ButtonStyle(
      animationDuration: Duration.zero,
      padding: WidgetStatePropertyAll(
        EdgeInsetsDirectional.only(start: left, end: 8, top: 6, bottom: 6),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 33)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      alignment: AlignmentDirectional.centerStart,
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Inter',
          package: 'stey_ui_modern',
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
      ),
      foregroundColor: WidgetStatePropertyAll(foreground),
      iconColor: WidgetStatePropertyAll(foreground),
      iconSize: const WidgetStatePropertyAll(16),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            popup != null ||
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)
            ? (item.destructive ? c.danger.withValues(alpha: .05) : c.tint)
            : Colors.transparent,
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.focused) && !hovered
              ? c.brand
              : Colors.transparent,
          width: 2,
        ),
      ),
    );
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        if (icon != null)
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: 16,
              child: IconTheme(
                data: IconThemeData(size: 16, color: foreground),
                child: icon,
              ),
            ),
          ),
        Flexible(
          child:
              item.child ??
              Text(item.label, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );
    final trailing = item.shortcut != null
        ? Text(
            item.shortcut!,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              color: foreground.withValues(alpha: .6),
            ),
          )
        : !checkbox && item.selection == true
        ? const ExcludeSemantics(child: Icon(Icons.check, size: 16))
        : null;
    final submenu = item.children.isNotEmpty;
    final button = MenuItemButton(
      overflowAxis: Axis.vertical,
      key: anchorKey,
      focusNode: widget.focusNode,
      style: style,
      onHover: onHover,
      onFocusChange: (focused) {
        if (focused) widget.onActive(submenu ? closePopup : null);
      },
      onPressed: !item.enabled
          ? null
          : () {
              if (submenu) {
                showPopup(false);
              } else {
                if (item.closeOnActivate) widget.rootController.close();
                item.activate();
              }
            },
      closeOnActivate: false,
      semanticsLabel: item.shortcut == null
          ? item.label
          : '${item.label} ${item.shortcut}',
      trailingIcon: submenu
          ? ExcludeSemantics(
              child: Icon(
                Directionality.of(context) == TextDirection.ltr
                    ? Icons.chevron_right
                    : Icons.chevron_left,
                size: 16,
              ),
            )
          : trailing,
      child: content,
    );
    return MergeSemantics(
      child: Semantics(
        role: item.role,
        expanded: submenu ? popup != null : null,
        checked: checkbox || radio ? item.selection : null,
        inMutuallyExclusiveGroup: radio,
        link: item.href == null ? null : true,
        linkUrl: item.href,
        child: Opacity(
          opacity: item.enabled ? 1 : .5,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              if (submenu)
                CallbackShortcuts(
                  bindings: {
                    SingleActivator(
                      Directionality.of(context) == TextDirection.ltr
                          ? LogicalKeyboardKey.arrowRight
                          : LogicalKeyboardKey.arrowLeft,
                    ): openSubmenu,
                  },
                  child: button,
                )
              else
                button,
              if (checkbox && item.selection == true)
                PositionedDirectional(
                  start: 8,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: Icon(Icons.check, size: 12, color: foreground),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
