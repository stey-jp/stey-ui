import 'package:flutter/material.dart';

import 'messages.dart';

import 'button.dart';
import 'display.dart';
import 'input.dart';
import 'navigation.dart';

class SteyPageHeader extends StatelessWidget {
  const SteyPageHeader({
    super.key,
    required this.breadcrumbs,
    required this.title,
    this.description,
    this.actions = const [],
    this.tabs,
  });
  final List<SteyBreadcrumb> breadcrumbs;
  final String title;
  final String? description;
  final List<Widget> actions;
  final Widget? tabs;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SteyBreadcrumbs(items: breadcrumbs),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SteyText(title, heading: 1),
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SteyText(description!, subtle: true),
              ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(spacing: 8, runSpacing: 8, children: actions),
              ),
          ],
        ),
      ),
      ?tabs,
    ],
  );
}

class SteyResourceList<T> extends StatefulWidget {
  const SteyResourceList({
    super.key,
    required this.items,
    required this.labelOf,
    required this.itemBuilder,
    this.onCreate,
    this.emptyTitle = 'No resources',
    this.pageSize = 10,
  });
  final List<T> items;
  final String Function(T) labelOf;
  final Widget Function(BuildContext, T) itemBuilder;
  final VoidCallback? onCreate;
  final String emptyTitle;
  final int pageSize;
  @override
  State<SteyResourceList<T>> createState() => _SteyResourceListState<T>();
}

class _SteyResourceListState<T> extends State<SteyResourceList<T>> {
  String query = '';
  int page = 1;
  @override
  Widget build(BuildContext context) {
    final items = widget.items
        .where(
          (v) => widget.labelOf(v).toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    final pages = (items.length / widget.pageSize).ceil().clamp(1, 1000000);
    final active = page.clamp(1, pages);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SteyInput(
                placeholder: SteyMessages.of(context).searchResources,
                onChanged: (v) => setState(() {
                  query = v;
                  page = 1;
                }),
              ),
            ),
            if (widget.onCreate != null) ...[
              const SizedBox(width: 8),
              SteyButton(
                onPressed: widget.onCreate,
                child: Text(SteyMessages.of(context).create),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          SteyEmpty(title: widget.emptyTitle)
        else
          ...items
              .skip((active - 1) * widget.pageSize)
              .take(widget.pageSize)
              .map((item) => widget.itemBuilder(context, item)),
        if (pages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SteyPagination(
              page: active,
              totalPages: pages,
              onChanged: (v) => setState(() => page = v),
            ),
          ),
      ],
    );
  }
}
