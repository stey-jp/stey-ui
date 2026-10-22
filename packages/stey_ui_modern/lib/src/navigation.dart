import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'display.dart';
import 'theme.dart';
import 'messages.dart';

export 'table_of_contents.dart';
export 'collapsible.dart';
export 'breadcrumbs.dart';
export 'pagination.dart';
export 'tabs.dart';

class SteyToolbar extends StatelessWidget {
  const SteyToolbar({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: SteyTheme.colorsOf(context).base,
      border: Border(
        bottom: BorderSide(color: SteyTheme.colorsOf(context).line),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    ),
  );
}

class SteySidebarItem {
  const SteySidebarItem(
    this.id,
    this.label, {
    this.icon,
    this.badge,
    this.children = const [],
  });
  final String id, label;
  final IconData? icon;
  final String? badge;
  final List<SteySidebarItem> children;
}

enum SteySidebarSide { left, right }

/// A submenu list whose decorative guide is neither announced nor interactive.
class SteySidebarMenuSub extends StatelessWidget {
  const SteySidebarMenuSub({
    super.key,
    required this.children,
    this.semanticLabel,
  });
  final List<Widget> children;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    role: SemanticsRole.list,
    label: semanticLabel,
    child: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 1,
            children: [
              for (final child in children)
                child is SteySidebarMenuSubItem
                    ? child
                    : SteySidebarMenuSubItem(child: child),
            ],
          ),
        ),
        Positioned(
          left: 19,
          top: 1,
          bottom: 1,
          width: 1,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: ColoredBox(color: SteyTheme.colorsOf(context).line),
            ),
          ),
        ),
      ],
    ),
  );
}

class SteySidebarMenuSubItem extends StatelessWidget {
  const SteySidebarMenuSubItem({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    role: SemanticsRole.listItem,
    child: child,
  );
}

class SteySidebarMenuSubButton extends StatelessWidget {
  const SteySidebarMenuSubButton({
    super.key,
    required this.child,
    this.onPressed,
    this.selected = false,
    this.focusNode,
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final bool selected;
  final FocusNode? focusNode;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        label: semanticLabel,
        child: TextButton(
          focusNode: focusNode,
          onPressed: onPressed,
          style: ButtonStyle(
            animationDuration: Duration.zero,
            minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12),
            ),
            alignment: Alignment.centerLeft,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.standard,
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) =>
                  selected ||
                      states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused)
                  ? c.tint
                  : Colors.transparent,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.focused) ? c.strong : c.text,
            ),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(
                fontFamily: 'Inter',
                package: 'stey_ui_modern',
                fontSize: 13,
                height: 1 / .85,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
          child: ExcludeSemantics(
            excluding: semanticLabel != null,
            child: child,
          ),
        ),
      ),
    );
  }
}

class SteySidebar extends StatefulWidget {
  const SteySidebar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.header,
    this.footer,
    double? width,
    this.collapsed = false,
    this.resizable = false,
    this.minWidth = 200,
    this.maxWidth = 480,
    this.onWidthChanged,
    this.onCollapsedChanged,
    this.side = SteySidebarSide.left,
  }) : width = width ?? (resizable ? 256 : 260),
       assert(minWidth > 57 && maxWidth >= minWidth);
  final List<SteySidebarItem> items;
  final String selected;
  final ValueChanged<String> onSelected;
  final Widget? header, footer;
  final double width, minWidth, maxWidth;
  final bool collapsed, resizable;
  final ValueChanged<double>? onWidthChanged;
  final ValueChanged<bool>? onCollapsedChanged;
  final SteySidebarSide side;
  @override
  State<SteySidebar> createState() => _SteySidebarState();
}

class _SteySidebarState extends State<SteySidebar> {
  final Set<String> expanded = {};
  late double width;
  late bool collapsed;
  double dragStartWidth = 0, dragDelta = 0;

  @override
  void initState() {
    super.initState();
    width = widget.width.clamp(widget.minWidth, widget.maxWidth);
    collapsed = widget.collapsed;
  }

  @override
  void didUpdateWidget(SteySidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width ||
        oldWidget.minWidth != widget.minWidth ||
        oldWidget.maxWidth != widget.maxWidth) {
      width = widget.width.clamp(widget.minWidth, widget.maxWidth);
    }
    if (oldWidget.collapsed != widget.collapsed) collapsed = widget.collapsed;
  }

  bool get isCollapsed =>
      widget.onCollapsedChanged == null ? collapsed : widget.collapsed;

  void changeCollapsed(bool value) {
    if (value == isCollapsed) return;
    if (widget.onCollapsedChanged == null) setState(() => collapsed = value);
    widget.onCollapsedChanged?.call(value);
  }

  void changeWidth(double value) {
    final next = value.clamp(widget.minWidth, widget.maxWidth);
    if (next == width) return;
    setState(() => width = next);
    widget.onWidthChanged?.call(next);
  }

  KeyEventResult resizeKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final grow = widget.side == SteySidebarSide.left
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final shrink = widget.side == SteySidebarSide.left
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final key = event.logicalKey;
    if (key == grow) {
      if (isCollapsed) {
        changeWidth(widget.minWidth);
        changeCollapsed(false);
      } else {
        changeWidth(width + 10);
      }
    } else if (key == shrink) {
      if (width - 10 < widget.minWidth) {
        changeCollapsed(true);
      } else {
        changeWidth(width - 10);
      }
    } else if (key == LogicalKeyboardKey.home) {
      changeCollapsed(true);
    } else if (key == LogicalKeyboardKey.end) {
      changeWidth(widget.maxWidth);
      changeCollapsed(false);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    Widget item(SteySidebarItem entry, {int depth = 0}) => Padding(
      padding: EdgeInsets.only(bottom: depth == 0 ? 2 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Semantics(
              expanded: entry.children.isEmpty
                  ? null
                  : expanded.contains(entry.id) && !isCollapsed,
              child: depth > 0 && !isCollapsed
                  ? SteySidebarMenuSubButton(
                      selected: widget.selected == entry.id,
                      onPressed: () {
                        if (entry.children.isNotEmpty) {
                          setState(
                            () => expanded.contains(entry.id)
                                ? expanded.remove(entry.id)
                                : expanded.add(entry.id),
                          );
                        } else {
                          widget.onSelected(entry.id);
                        }
                      },
                      child: Row(
                        spacing: 8,
                        children: [
                          if (entry.icon != null) Icon(entry.icon, size: 16),
                          Expanded(
                            child: Text(
                              entry.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entry.children.isNotEmpty)
                            Icon(
                              expanded.contains(entry.id)
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 14,
                            )
                          else if (entry.badge != null)
                            SteyBadge(child: Text(entry.badge!)),
                        ],
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.selected == entry.id ? c.tint : null,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Tooltip(
                        message: entry.label,
                        excludeFromSemantics: true,
                        child: SteyButton(
                          variant: SteyButtonVariant.ghost,
                          shape: isCollapsed
                              ? SteyButtonShape.square
                              : SteyButtonShape.base,
                          semanticLabel: isCollapsed ? entry.label : null,
                          alignment: isCollapsed
                              ? Alignment.center
                              : Alignment.centerLeft,
                          onPressed: () {
                            if (entry.children.isNotEmpty) {
                              setState(
                                () => expanded.contains(entry.id)
                                    ? expanded.remove(entry.id)
                                    : expanded.add(entry.id),
                              );
                            } else {
                              widget.onSelected(entry.id);
                            }
                          },
                          icon: isCollapsed || entry.icon == null
                              ? null
                              : Icon(entry.icon, size: 16),
                          trailing: isCollapsed
                              ? null
                              : entry.children.isNotEmpty
                              ? Icon(
                                  expanded.contains(entry.id)
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 14,
                                )
                              : entry.badge == null || isCollapsed
                              ? null
                              : SteyBadge(child: Text(entry.badge!)),
                          child: isCollapsed
                              ? ExcludeSemantics(
                                  child: entry.icon != null
                                      ? Icon(entry.icon, size: 16)
                                      : Text(
                                          entry.label.isEmpty
                                              ? ''
                                              : entry.label.substring(0, 1),
                                        ),
                                )
                              : Text(entry.label),
                        ),
                      ),
                    ),
            ),
          ),
          if (!isCollapsed && expanded.contains(entry.id))
            SteySidebarMenuSub(
              semanticLabel: entry.label,
              children: [
                for (final child in entry.children)
                  item(child, depth: depth + 1),
              ],
            ),
        ],
      ),
    );
    return SizedBox(
      width: isCollapsed
          ? 57
          : widget.resizable
          ? width
          : widget.width,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.base,
                border: widget.side == SteySidebarSide.left
                    ? Border(right: BorderSide(color: c.line))
                    : Border(left: BorderSide(color: c.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.header != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: widget.header,
                    ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: widget.items.map(item).toList(),
                    ),
                  ),
                  if (widget.footer != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: widget.footer,
                    ),
                ],
              ),
            ),
          ),
          if (widget.resizable && MediaQuery.sizeOf(context).width >= 640)
            Positioned(
              top: 0,
              bottom: 0,
              right: widget.side == SteySidebarSide.left ? 0 : null,
              left: widget.side == SteySidebarSide.right ? 0 : null,
              width: 12,
              child: _SidebarResizeHandle(
                value: isCollapsed ? 57 : width,
                side: widget.side,
                onKey: resizeKey,
                onDragStart: (_) {
                  dragStartWidth = isCollapsed ? 57 : width;
                  dragDelta = 0;
                },
                onDragUpdate: (details) {
                  dragDelta +=
                      details.delta.dx *
                      (widget.side == SteySidebarSide.left ? 1 : -1);
                  final next = dragStartWidth + dragDelta;
                  if (next < widget.minWidth) {
                    changeCollapsed(true);
                  } else {
                    changeWidth(next);
                    changeCollapsed(false);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarResizeHandle extends StatefulWidget {
  const _SidebarResizeHandle({
    required this.value,
    required this.side,
    required this.onKey,
    required this.onDragStart,
    required this.onDragUpdate,
  });
  final double value;
  final SteySidebarSide side;
  final KeyEventResult Function(KeyEvent) onKey;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  @override
  State<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<_SidebarResizeHandle> {
  bool hovered = false, focused = false;
  final focusNode = FocusNode();
  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: SteyMessages.of(context).resizeSidebar,
    value: SteyMessages.of(context).pixels(widget.value.round()),
    button: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Focus(
        focusNode: focusNode,
        onFocusChange: (value) => setState(() => focused = value),
        onKeyEvent: (_, event) => widget.onKey(event),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: focusNode.requestFocus,
          onHorizontalDragStart: (details) {
            focusNode.requestFocus();
            widget.onDragStart(details);
          },
          onHorizontalDragUpdate: widget.onDragUpdate,
          child: Align(
            alignment: widget.side == SteySidebarSide.left
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: SizedBox(
              width: 2,
              child: ColoredBox(
                color: hovered || focused
                    ? SteyTheme.colorsOf(context).hairline
                    : Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class SteySidebarSlidingView extends StatelessWidget {
  const SteySidebarSlidingView({
    super.key,
    required this.value,
    required this.child,
  });
  final String value;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

/// Mounted panels retain their state. Inactive panels cannot receive focus,
/// pointer input, or accessibility navigation, including during a transition.
class SteySidebarSlidingViews extends StatefulWidget {
  const SteySidebarSlidingViews({
    super.key,
    required this.activeKey,
    required this.views,
    this.duration = const Duration(milliseconds: 250),
  });
  final String activeKey;
  final List<SteySidebarSlidingView> views;
  final Duration duration;
  @override
  State<SteySidebarSlidingViews> createState() =>
      _SteySidebarSlidingViewsState();
}

class _SteySidebarSlidingViewsState extends State<SteySidebarSlidingViews>
    with SingleTickerProviderStateMixin {
  late final AnimationController position;
  int get activeIndex =>
      widget.views.indexWhere((view) => view.value == widget.activeKey);
  @override
  void initState() {
    super.initState();
    position = AnimationController.unbounded(
      vsync: this,
      value: activeIndex.toDouble(),
      duration: widget.duration,
      animationBehavior: AnimationBehavior.preserve,
    );
  }

  @override
  void didUpdateWidget(SteySidebarSlidingViews oldWidget) {
    super.didUpdateWidget(oldWidget);
    position.duration = widget.duration;
    if (oldWidget.views.indexWhere(
              (view) => view.value == oldWidget.activeKey,
            ) !=
            activeIndex ||
        oldWidget.activeKey != widget.activeKey) {
      position.animateTo(
        activeIndex.toDouble(),
        curve: const Cubic(.77, 0, .175, 1),
      );
    }
  }

  @override
  void dispose() {
    position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(activeIndex >= 0, 'activeKey must identify a sidebar view.');
    assert(
      widget.views.map((view) => view.value).toSet().length ==
          widget.views.length,
      'Sidebar view keys must be unique.',
    );
    return LayoutBuilder(
      builder: (context, constraints) => ClipRect(
        child: AnimatedBuilder(
          animation: position,
          builder: (context, _) => Stack(
            children: [
              for (var index = 0; index < widget.views.length; index++)
                Positioned.fill(
                  key: ValueKey(widget.views[index].value),
                  child: Transform.translate(
                    offset: Offset(
                      (index - position.value) * constraints.maxWidth,
                      0,
                    ),
                    child: ExcludeFocus(
                      excluding: index != activeIndex,
                      child: ExcludeSemantics(
                        excluding: index != activeIndex,
                        child: IgnorePointer(
                          ignoring: index != activeIndex,
                          child: widget.views[index],
                        ),
                      ),
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

class SteyTable extends StatelessWidget {
  const SteyTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.selectedRows = const {},
    this.onSelect,
  });
  final List<String> columns;
  final List<List<Widget>> rows;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int, bool)? onSort;
  final Set<int> selectedRows;
  final void Function(int, bool)? onSelect;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      headingRowColor: WidgetStatePropertyAll(SteyTheme.colorsOf(context).tint),
      dataTextStyle: const TextStyle(fontSize: 14),
      headingTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SteyTheme.colorsOf(context).text,
      ),
      horizontalMargin: 12,
      columnSpacing: 24,
      dataRowMinHeight: 40,
      dataRowMaxHeight: 64,
      headingRowHeight: 36,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      columns: List.generate(
        columns.length,
        (i) => DataColumn(
          label: Text(columns[i]),
          onSort: onSort == null
              ? null
              : (i, ascending) => onSort!(i, ascending),
        ),
      ),
      rows: List.generate(
        rows.length,
        (i) => DataRow(
          selected: selectedRows.contains(i),
          onSelectChanged: onSelect == null
              ? null
              : (value) => onSelect!(i, value ?? false),
          cells: rows[i].map(DataCell.new).toList(),
        ),
      ),
    ),
  );
}
