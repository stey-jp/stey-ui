import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'display.dart';
import 'theme.dart';

class SteyTab {
  const SteyTab(this.value, this.label, {this.disabled = false});
  final String value, label;
  final bool disabled;
}

enum SteyTabsVariant { segmented, underline }

class SteyTabs extends StatefulWidget {
  const SteyTabs({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
    this.variant = SteyTabsVariant.segmented,
    this.size = SteySize.base,
    this.label = 'Tabs',
  });
  final List<SteyTab> tabs;
  final String value, label;
  final ValueChanged<String> onChanged;
  final SteyTabsVariant variant;
  final SteySize size;
  @override
  State<SteyTabs> createState() => _SteyTabsState();
}

class _SteyTabsState extends State<SteyTabs> {
  final Map<String, FocusNode> nodes = {};
  @override
  void dispose() {
    for (final node in nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final segmented = widget.variant == SteyTabsVariant.segmented;
    return Semantics(
      label: widget.label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: segmented ? c.fill : null,
          borderRadius: BorderRadius.circular(8),
          border: segmented ? null : Border(bottom: BorderSide(color: c.line)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: EdgeInsets.all(segmented ? 2 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: widget.tabs.map((tab) {
                final active = widget.value == tab.value;
                final node = nodes.putIfAbsent(tab.value, FocusNode.new);
                return Focus(
                  onKeyEvent: (_, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;
                    final available = widget.tabs
                        .where((tab) => !tab.disabled)
                        .toList();
                    final index = available.indexWhere(
                      (v) => v.value == tab.value,
                    );
                    final key = event.logicalKey;
                    int? target;
                    if (key == LogicalKeyboardKey.arrowRight) {
                      target = (index + 1) % available.length;
                    }
                    if (key == LogicalKeyboardKey.arrowLeft) {
                      target =
                          (index - 1 + available.length) % available.length;
                    }
                    if (key == LogicalKeyboardKey.home) target = 0;
                    if (key == LogicalKeyboardKey.end) {
                      target = available.length - 1;
                    }
                    if (target == null || available.isEmpty) {
                      return KeyEventResult.ignored;
                    }
                    widget.onChanged(available[target].value);
                    nodes[available[target].value]?.requestFocus();
                    return KeyEventResult.handled;
                  },
                  child: Semantics(
                    selected: active,
                    child: Container(
                      decoration: BoxDecoration(
                        color: segmented && active ? c.base : null,
                        borderRadius: segmented
                            ? BorderRadius.circular(6)
                            : null,
                        border: segmented
                            ? (active ? Border.all(color: c.line) : null)
                            : Border(
                                bottom: BorderSide(
                                  color: active ? c.text : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                      ),
                      child: SteyButton(
                        onPressed: tab.disabled
                            ? null
                            : () {
                                node.requestFocus();
                                widget.onChanged(tab.value);
                              },
                        focusNode: node,
                        variant: SteyButtonVariant.ghost,
                        size: widget.size,
                        child: Text(
                          tab.label,
                          style: TextStyle(color: active ? c.text : c.subtle),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

@Deprecated('Use SteyTabs with segmented variant.')
class SteyMenuBar extends SteyTabs {
  const SteyMenuBar({
    super.key,
    required super.tabs,
    required super.value,
    required super.onChanged,
  });
}

class SteyPagination extends StatelessWidget {
  const SteyPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onChanged,
    this.label = 'Page',
  });
  final int page, totalPages;
  final ValueChanged<int> onChanged;
  final String label;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SteyButton(
        onPressed: page > 1 ? () => onChanged(page - 1) : null,
        semanticLabel: 'Previous page',
        child: const Icon(Icons.chevron_left, size: 16),
      ),
      ...List.generate(totalPages, (index) => index + 1)
          .where((p) => p == 1 || p == totalPages || (p - page).abs() <= 1)
          .map(
            (p) => Semantics(
              selected: p == page,
              child: SteyButton(
                onPressed: () => onChanged(p),
                variant: p == page
                    ? SteyButtonVariant.primary
                    : SteyButtonVariant.ghost,
                semanticLabel: '$label $p',
                child: Text('$p'),
              ),
            ),
          ),
      SteyButton(
        onPressed: page < totalPages ? () => onChanged(page + 1) : null,
        semanticLabel: 'Next page',
        child: const Icon(Icons.chevron_right, size: 16),
      ),
    ],
  );
}

class SteyBreadcrumb {
  const SteyBreadcrumb(this.label, {this.onPressed});
  final String label;
  final VoidCallback? onPressed;
}

class SteyBreadcrumbs extends StatelessWidget {
  const SteyBreadcrumbs({super.key, required this.items});
  final List<SteyBreadcrumb> items;
  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0)
          Icon(
            Icons.chevron_right,
            size: 14,
            color: SteyTheme.colorsOf(context).subtle,
          ),
        items[i].onPressed == null
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: SteyText(items[i].label),
              )
            : SteyLink(
                onPressed: items[i].onPressed,
                child: Text(items[i].label),
              ),
      ],
    ],
  );
}

class SteyCollapsible extends StatelessWidget {
  const SteyCollapsible({
    super.key,
    required this.open,
    required this.onChanged,
    required this.title,
    required this.child,
  });
  final bool open;
  final ValueChanged<bool> onChanged;
  final Widget title, child;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        expanded: open,
        child: SteyButton(
          onPressed: () => onChanged(!open),
          variant: SteyButtonVariant.ghost,
          trailing: Icon(
            open ? Icons.expand_less : Icons.expand_more,
            size: 16,
          ),
          child: title,
        ),
      ),
      ClipRect(
        child: AnimatedAlign(
          alignment: Alignment.topLeft,
          heightFactor: open ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: ExcludeFocus(
            excluding: !open,
            child: ExcludeSemantics(
              excluding: !open,
              child: IgnorePointer(ignoring: !open, child: child),
            ),
          ),
        ),
      ),
    ],
  );
}

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
      padding: EdgeInsets.only(left: depth * 12, bottom: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
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
          if (!isCollapsed && expanded.contains(entry.id))
            ...entry.children.map((e) => item(e, depth: depth + 1)),
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
          if (widget.resizable)
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
    label: 'Resize sidebar',
    value: '${widget.value.round()} pixels',
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

class SteyTableOfContents extends StatelessWidget {
  const SteyTableOfContents({
    super.key,
    required this.items,
    required this.activeId,
    required this.onSelected,
    this.title = 'On this page',
  });
  final Map<String, String> items;
  final String? activeId;
  final ValueChanged<String> onSelected;
  final String title;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SteyText(title, bold: true),
      const SizedBox(height: 8),
      ...items.entries.map(
        (e) => Semantics(
          selected: e.key == activeId,
          child: SteyButton(
            variant: SteyButtonVariant.ghost,
            onPressed: () => onSelected(e.key),
            child: Text(e.value),
          ),
        ),
      ),
    ],
  );
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
