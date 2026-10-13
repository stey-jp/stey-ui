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

class SteySidebar extends StatefulWidget {
  const SteySidebar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.header,
    this.footer,
    this.width = 256,
    this.collapsed = false,
  });
  final List<SteySidebarItem> items;
  final String selected;
  final ValueChanged<String> onSelected;
  final Widget? header, footer;
  final double width;
  final bool collapsed;
  @override
  State<SteySidebar> createState() => _SteySidebarState();
}

class _SteySidebarState extends State<SteySidebar> {
  final Set<String> expanded = {};
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
              child: SteyButton(
                variant: SteyButtonVariant.ghost,
                semanticLabel: entry.label,
                alignment: Alignment.centerLeft,
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
                icon: entry.icon == null ? null : Icon(entry.icon, size: 16),
                trailing: entry.children.isNotEmpty
                    ? Icon(
                        expanded.contains(entry.id)
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 14,
                      )
                    : entry.badge == null || widget.collapsed
                    ? null
                    : SteyBadge(child: Text(entry.badge!)),
                child: widget.collapsed
                    ? const SizedBox.shrink()
                    : Text(entry.label),
              ),
            ),
          ),
          if (!widget.collapsed && expanded.contains(entry.id))
            ...entry.children.map((e) => item(e, depth: depth + 1)),
        ],
      ),
    );
    return SizedBox(
      width: widget.collapsed ? 52 : widget.width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.base,
          border: Border(right: BorderSide(color: c.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.header != null)
              Padding(padding: const EdgeInsets.all(16), child: widget.header),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: widget.items.map(item).toList(),
              ),
            ),
            if (widget.footer != null)
              Padding(padding: const EdgeInsets.all(12), child: widget.footer),
          ],
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
