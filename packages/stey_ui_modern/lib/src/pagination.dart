import 'dart:ui' show FontFeature, SemanticsRole;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'messages.dart';
import 'select.dart';

enum SteyPaginationMode { full, simple }

enum SteyPaginationSelector { input, dropdown }

class SteyPaginationLabels {
  const SteyPaginationLabels({
    this.navigation,
    this.firstPage,
    this.previousPage,
    this.nextPage,
    this.lastPage,
    this.pageNumber,
    this.pageSize,
  });
  final String? navigation,
      firstPage,
      previousPage,
      nextPage,
      lastPage,
      pageNumber,
      pageSize;
}

class SteyPaginationData {
  const SteyPaginationData({
    required this.page,
    required this.maxPage,
    required this.pageShowingRange,
    this.perPage,
    this.totalCount,
  });
  final int page, maxPage;
  final int? perPage, totalCount;
  final String pageShowingRange;
}

typedef SteyPaginationInfoBuilder = Widget Function(
  BuildContext context,
  SteyPaginationData data,
);

/// Controlled pagination. The original totalPages/onChanged constructor stays
/// available; perPage/totalCount and child provide Kumo's compound API.
class SteyPagination extends StatefulWidget {
  const SteyPagination({
    super.key,
    this.page = 1,
    this.totalPages,
    required this.onChanged,
    this.perPage,
    this.totalCount,
    this.hasNextPage,
    this.child,
    this.controls = SteyPaginationMode.full,
    this.pageSelector = SteyPaginationSelector.input,
    this.labels = const SteyPaginationLabels(),
    this.label = 'Page',
    this.infoBuilder,
  }) : assert(totalPages == null || totalPages >= 0),
       assert(perPage == null || perPage > 0),
       assert(totalCount == null || totalCount >= 0);
  final int page;
  final int? totalPages, perPage, totalCount;
  final bool? hasNextPage;
  final ValueChanged<int> onChanged;
  final Widget? child;
  final SteyPaginationMode controls;
  final SteyPaginationSelector pageSelector;
  final SteyPaginationLabels labels;
  final String label;
  final SteyPaginationInfoBuilder? infoBuilder;
  @override
  State<SteyPagination> createState() => _PaginationState();
}

class _PaginationState extends State<SteyPagination> {
  late final editing = TextEditingController(text: '${widget.page}');
  @override
  void didUpdateWidget(SteyPagination oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) editing.text = '${widget.page}';
  }

  @override
  void dispose() {
    editing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perPage = widget.perPage ?? (widget.totalPages == null ? null : 1),
        total = widget.totalCount ?? widget.totalPages;
    final maxPage = (((total ?? 1) / (perPage ?? 1)).ceil()).clamp(
      1,
      9007199254740991,
    );
    final lower = widget.page * (perPage ?? 1) - (perPage ?? 0) + 1,
        upper = (widget.page * (perPage ?? 0)).clamp(
          -9007199254740991,
          total ?? 0,
        );
    final ja = SteyMessages.of(context).japanese, labels = widget.labels;
    final data = SteyPaginationData(
      page: widget.page,
      maxPage: maxPage,
      perPage: perPage,
      totalCount: total,
      pageShowingRange: '$lower-$upper',
    );
    return _PaginationScope(
      state: this,
      data: data,
      hasNext: widget.hasNextPage,
      labels: SteyPaginationLabels(
        navigation: labels.navigation ?? (ja ? 'ページ切り替え' : 'Pagination'),
        firstPage: labels.firstPage ?? (ja ? '最初のページ' : 'First page'),
        previousPage: labels.previousPage ?? (ja ? '前のページ' : 'Previous page'),
        nextPage: labels.nextPage ?? (ja ? '次のページ' : 'Next page'),
        lastPage: labels.lastPage ?? (ja ? '最後のページ' : 'Last page'),
        pageNumber:
            labels.pageNumber ??
            (widget.label != 'Page'
                ? widget.label
                : ja
                ? 'ページ番号'
                : 'Page number'),
        pageSize: labels.pageSize ?? (ja ? '1ページの件数' : 'Page size'),
      ),
      child:
          widget.child ??
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: SteyPaginationInfo(builder: widget.infoBuilder),
                ),
              ),
              SteyPaginationControls(
                controls: widget.controls,
                pageSelector: widget.pageSelector,
              ),
            ],
          ),
    );
  }

  void setPage(int value) {
    widget.onChanged(value);
    editing.text = '$value';
  }

  void commit(SteyPaginationData data) {
    final raw = editing.text.trim();
    if (!RegExp(r'^[0-9]+$').hasMatch(raw)) {
      editing.text = '${widget.page}';
      return;
    }
    final n = BigInt.parse(raw);
    final target = n < BigInt.one
        ? 1
        : n > BigInt.from(data.maxPage)
        ? data.maxPage
        : n.toInt();
    setPage(target);
  }
}

class _PaginationScope extends InheritedWidget {
  const _PaginationScope({
    required this.state,
    required this.data,
    required this.labels,
    required this.hasNext,
    required super.child,
  });
  final _PaginationState state;
  final SteyPaginationData data;
  final SteyPaginationLabels labels;
  final bool? hasNext;
  static _PaginationScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_PaginationScope>();
    assert(scope != null, 'Pagination parts must be inside SteyPagination');
    return scope!;
  }

  @override
  bool updateShouldNotify(_PaginationScope oldWidget) => true;
}

class SteyPaginationInfo extends StatelessWidget {
  const SteyPaginationInfo({super.key, this.builder});
  final SteyPaginationInfoBuilder? builder;
  @override
  Widget build(BuildContext context) {
    final s = _PaginationScope.of(context),
        d = s.data,
        c = SteyTheme.colorsOf(context);
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: 13,
        height: 1 / .85,
        color: c.subtle,
        fontWeight: FontWeight.w400,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      child:
          builder?.call(context, d) ??
          (d.totalCount != null && d.totalCount! > 0
              ? Text(
                  SteyMessages.of(context).japanese
                      ? '${d.totalCount}件中 ${d.pageShowingRange}件を表示'
                      : 'Showing ${d.pageShowingRange} of ${d.totalCount}',
                )
              : const SizedBox.shrink()),
    );
  }
}

class SteyPaginationPageSize extends StatelessWidget {
  const SteyPaginationPageSize({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = const [25, 50, 100, 250],
    this.label,
    this.showLabel = true,
  });
  final int value;
  final ValueChanged<int> onChanged;
  final List<int> options;
  final Widget? label;
  final bool showLabel;
  @override
  Widget build(BuildContext context) {
    final s = _PaginationScope.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        if (showLabel)
          DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 13,
              height: 1 / .85,
              color: SteyTheme.colorsOf(context).subtle,
              fontWeight: FontWeight.w400,
            ),
            child:
                label ??
                Text(SteyMessages.of(context).japanese ? '1ページ：' : 'Per page:'),
          ),
        IntrinsicWidth(
          child: SteySelect<int>(
            value: value,
            semanticLabel: s.labels.pageSize,
            options: {for (final n in options) n: '$n'},
            onChanged: (n) {
              if (n != null) onChanged(n);
            },
          ),
        ),
      ],
    );
  }
}

class SteyPaginationSeparator extends StatelessWidget {
  const SteyPaginationSeparator({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 1,
        height: 24,
        child: ColoredBox(color: SteyTheme.colorsOf(context).hairline),
      ),
    ),
  );
}

class SteyPaginationControls extends StatelessWidget {
  const SteyPaginationControls({
    super.key,
    this.controls = SteyPaginationMode.full,
    this.pageSelector = SteyPaginationSelector.input,
  });
  final SteyPaginationMode controls;
  final SteyPaginationSelector pageSelector;
  @override
  Widget build(BuildContext context) {
    final s = _PaginationScope.of(context), d = s.data;
    final full =
        controls == SteyPaginationMode.full &&
        !(d.totalCount == null && s.hasNext != null);
    final nextDisabled = d.totalCount != null
        ? d.page >= d.maxPage
        : s.hasNext != true;
    final parts = <Widget>[
      if (full)
        _PageButton(
          label: s.labels.firstPage!,
          kind: 0,
          onPressed: d.page <= 1 ? null : () => s.state.setPage(1),
        ),
      _PageButton(
        label: s.labels.previousPage!,
        kind: 1,
        onPressed: d.page <= 1
            ? null
            : () => s.state.setPage(d.page - 1 < 1 ? 1 : d.page - 1),
      ),
      if (full)
        pageSelector == SteyPaginationSelector.dropdown
            ? IntrinsicWidth(
                child: SteySelect<int>(
                  semanticLabel: s.labels.pageNumber,
                  value: d.page,
                  options: {for (var p = 1; p <= d.maxPage; p++) p: '$p'},
                  onChanged: (p) {
                    if (p != null) s.state.setPage(p);
                  },
                ),
              )
            : _PageInput(
                controller: s.state.editing,
                label: s.labels.pageNumber!,
                commit: () => s.state.commit(d),
              ),
      _PageButton(
        label: s.labels.nextPage!,
        kind: 2,
        onPressed: nextDisabled
            ? null
            : () => s.state.setPage(
                d.totalCount == null
                    ? d.page + 1
                    : (d.page + 1).clamp(1, d.maxPage),
              ),
      ),
      if (full)
        _PageButton(
          label: s.labels.lastPage!,
          kind: 3,
          onPressed: d.page >= d.maxPage
              ? null
              : () => s.state.setPage(d.maxPage),
        ),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.navigation,
      label: s.labels.navigation,
      child: _PageGroup(children: parts),
    );
  }
}

// The input-group individual mode uses 1px shared seams and 36px controls.
class _PageGroup extends StatelessWidget {
  const _PageGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < children.length; i++)
        _PageCell(
          first: i == 0,
          last: i == children.length - 1,
          child: children[i],
        ),
    ],
  );
}

class _PageCell extends InheritedWidget {
  const _PageCell({
    required this.first,
    required this.last,
    required super.child,
  });
  final bool first, last;
  static _PageCell of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PageCell>()!;
  @override
  bool updateShouldNotify(_PageCell oldWidget) =>
      first != oldWidget.first || last != oldWidget.last;
}

class _PageButton extends StatefulWidget {
  const _PageButton({
    required this.label,
    required this.kind,
    required this.onPressed,
  });
  final String label;
  final int kind;
  final VoidCallback? onPressed;
  @override
  State<_PageButton> createState() => _PageButtonState();
}

class _PageButtonState extends State<_PageButton> {
  bool hover = false, focus = false;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context),
        cell = _PageCell.of(context),
        enabled = widget.onPressed != null;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(cell.first ? 8 : 0),
      bottomLeft: Radius.circular(cell.first ? 8 : 0),
      topRight: Radius.circular(cell.last ? 8 : 0),
      bottomRight: Radius.circular(cell.last ? 8 : 0),
    );
    return SizedBox(
      width: cell.first ? 42 : 41,
      height: 36,
      child: OverflowBox(
        minWidth: 42,
        maxWidth: 42,
        alignment: Alignment.centerRight,
        child: TextButton(
          style: ButtonStyle(
            animationDuration: Duration.zero,
            minimumSize: const WidgetStatePropertyAll(Size.zero),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            backgroundColor: WidgetStatePropertyAll(
              !enabled
                  ? c.overlay
                  : hover
                  ? c.tint
                  : c.base,
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(
                  color: focus ? c.focus.withValues(alpha: .5) : c.line,
                ),
              ),
            ),
          ),
          onHover: (v) => setState(() => hover = v),
          onFocusChange: (v) => setState(() => focus = v),
          onPressed: widget.onPressed,
          child: Semantics(
            label: widget.label,
            excludeSemantics: true,
            child: CustomPaint(
              size: const Size.square(16),
              painter: _PageCaret(
                widget.kind,
                enabled
                    ? c.text
                    : c.dark
                    ? const Color(0xff525252)
                    : const Color(0xffd4d4d4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageInput extends StatefulWidget {
  const _PageInput({
    required this.controller,
    required this.label,
    required this.commit,
  });
  final TextEditingController controller;
  final String label;
  final VoidCallback commit;
  @override
  State<_PageInput> createState() => _PageInputState();
}

class _PageInputState extends State<_PageInput> {
  final focus = FocusNode();
  @override
  void initState() {
    super.initState();
    focus.addListener(onFocus);
  }

  void onFocus() {
    if (!focus.hasFocus) widget.commit();
    setState(() {});
  }

  @override
  void dispose() {
    focus.removeListener(onFocus);
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return SizedBox(
      width: 49,
      height: 36,
      child: OverflowBox(
        minWidth: 50,
        maxWidth: 50,
        alignment: Alignment.centerRight,
        child: Semantics(
          label: widget.label,
          child: TextField(
            controller: widget.controller,
            focusNode: focus,
            // A done action restarts the Web input connection even when
            // onEditingComplete retains focus. Keep consecutive edits active.
            textInputAction: TextInputAction.none,
            autofillHints: const [],
            enableSuggestions: false,
            autocorrect: false,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              color: c.text,
            ),
            onSubmitted: (_) => widget.commit(),
            onEditingComplete: () {},
            decoration: InputDecoration(
              labelText: null,
              hintText: null,
              isDense: false,
              visualDensity: VisualDensity.standard,
              constraints: const BoxConstraints.tightFor(height: 36),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: c.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: c.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: c.focus.withValues(alpha: .5)),
              ),
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class _PageCaret extends CustomPainter {
  const _PageCaret(this.kind, this.color);
  final int kind;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 256, size.height / 256);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void caret(double x, bool left) {
      canvas.drawPath(
        Path()
          ..moveTo(x + (left ? 32 : -32), 48)
          ..lineTo(x + (left ? -48 : 48), 128)
          ..lineTo(x + (left ? 32 : -32), 208),
        paint,
      );
    }

    if (kind == 0) {
      caret(88, true);
      caret(168, true);
    } else if (kind == 3) {
      caret(88, false);
      caret(168, false);
    } else {
      caret(128, kind == 1);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PageCaret oldDelegate) =>
      kind != oldDelegate.kind || color != oldDelegate.color;
}
