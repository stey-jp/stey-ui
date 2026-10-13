import 'package:flutter/material.dart';

import 'input.dart';
import 'theme.dart';

enum SteyRadioVariant { standard, error }

enum SteyRadioAppearance { inline, card, segmented }

class SteyRadioLegend extends StatelessWidget {
  const SteyRadioLegend(this.text, {super.key, this.visuallyHidden = false});
  final String text;
  final bool visuallyHidden;
  @override
  Widget build(BuildContext context) => visuallyHidden
      ? const SizedBox.shrink()
      : ExcludeSemantics(child: SteyLabel(text));
}

class SteyRadioGroup<T> extends StatefulWidget {
  const SteyRadioGroup({
    super.key,
    this.value,
    this.defaultValue,
    this.options = const {},
    this.children = const [],
    this.onChanged,
    this.label,
    this.legend,
    this.error,
    this.description,
    this.card = false,
    this.appearance,
    this.orientation = Axis.vertical,
    this.controlFirst,
    this.disabled = false,
    this.disabledValues = const {},
  });
  final T? value, defaultValue;
  final Map<T, String> options;
  final List<Widget> children;
  final ValueChanged<T?>? onChanged;
  final String? label, legend, error, description;
  final bool card, disabled;
  final Set<T> disabledValues;
  final SteyRadioAppearance? appearance;
  final Axis orientation;
  final bool? controlFirst;
  @override
  State<SteyRadioGroup<T>> createState() => _SteyRadioGroupState<T>();
}

class _SteyRadioGroupState<T> extends State<SteyRadioGroup<T>> {
  late T? internal = widget.defaultValue;
  T? get value => widget.value ?? internal;
  void change(T? next) {
    if (widget.disabled || next == value) return;
    if (widget.value == null) setState(() => internal = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.options.isEmpty || widget.children.isEmpty,
      'Use options or children.',
    );
    final c = SteyTheme.colorsOf(context);
    final appearance =
        widget.appearance ??
        (widget.card ? SteyRadioAppearance.card : SteyRadioAppearance.inline);
    final card = appearance == SteyRadioAppearance.card;
    final segmented = appearance == SteyRadioAppearance.segmented;
    final horizontal = widget.orientation == Axis.horizontal;
    final source = widget.options.isEmpty
        ? widget.children
        : [
            for (final entry in widget.options.entries)
              SteyRadioItem<T>(value: entry.key, label: entry.value),
          ];
    final legends = source.whereType<SteyRadioLegend>().toList();
    final items = source.where((item) => item is! SteyRadioLegend).toList();
    final gap = appearance == SteyRadioAppearance.inline ? 16.0 : 8.0;
    final rows = <Widget>[
      for (var i = 0; i < items.length; i++)
        _RadioCell(
          first: i == 0,
          last: i == items.length - 1,
          divider: card
              ? Border(
                  bottom:
                      (horizontal
                          ? i < (items.length - 1) ~/ 2 * 2
                          : i < items.length - 1)
                      ? BorderSide(color: c.line)
                      : BorderSide.none,
                  right: horizontal && i.isEven && i + 1 < items.length
                      ? BorderSide(color: c.line)
                      : BorderSide.none,
                )
              : null,
          child: items[i],
        ),
    ];
    Widget content;
    if (segmented) {
      content = Row(mainAxisSize: MainAxisSize.min, children: rows);
    } else if (card && horizontal) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i += 2)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: rows[i]),
                  Expanded(
                    child: i + 1 < rows.length
                        ? rows[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      );
    } else if (horizontal) {
      content = Wrap(spacing: 8, runSpacing: 8, children: rows);
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0 && !card) const SizedBox(height: 8),
            rows[i],
          ],
        ],
      );
    }
    if (card || segmented) {
      content = CustomPaint(
        foregroundPainter: _RadioGroupRing(c.line),
        child: card
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColoredBox(color: c.base, child: content),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: c.control,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadowDrop,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: content,
              ),
      );
    }
    final enabled =
        !widget.disabled && (widget.value == null || widget.onChanged != null);
    return _SteyRadioContext<T>(
      appearance: appearance,
      enabled: enabled,
      disabledValues: widget.disabledValues,
      controlFirst: widget.controlFirst,
      child: RadioGroup<T>(
        groupValue: value,
        onChanged: change,
        child: Semantics(
          explicitChildNodes: true,
          label:
              widget.legend ??
              widget.label ??
              (legends.isEmpty
                  ? null
                  : legends.map((legend) => legend.text).join(' ')),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.legend != null || widget.label != null) ...[
                ExcludeSemantics(
                  child: SteyLabel((widget.legend ?? widget.label)!),
                ),
                SizedBox(height: gap),
              ],
              for (final legend in legends) ...[
                legend,
                if (!legend.visuallyHidden) SizedBox(height: gap),
              ],
              content,
              if (widget.error != null) ...[
                SizedBox(height: gap),
                Text(
                  widget.error!,
                  style: TextStyle(fontSize: 13, color: c.dangerText),
                ),
              ],
              if (widget.description != null) ...[
                SizedBox(height: gap),
                Text(
                  widget.description!,
                  style: TextStyle(fontSize: 13, color: c.subtle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SteyRadioContext<T> extends InheritedWidget {
  const _SteyRadioContext({
    required this.appearance,
    required this.enabled,
    required this.disabledValues,
    required this.controlFirst,
    required super.child,
  });
  final SteyRadioAppearance appearance;
  final bool enabled;
  final Set<T> disabledValues;
  final bool? controlFirst;
  @override
  bool updateShouldNotify(_SteyRadioContext<T> old) =>
      appearance != old.appearance ||
      enabled != old.enabled ||
      disabledValues != old.disabledValues ||
      controlFirst != old.controlFirst;
}

class _RadioCell extends InheritedWidget {
  const _RadioCell({
    required this.first,
    required this.last,
    required super.child,
    this.divider,
  });
  final bool first, last;
  final Border? divider;
  @override
  bool updateShouldNotify(_RadioCell old) =>
      first != old.first || last != old.last || divider != old.divider;
}

class SteyRadioItem<T> extends StatefulWidget {
  const SteyRadioItem({
    super.key,
    required this.value,
    required this.label,
    this.labelWidget,
    this.description,
    this.disabled = false,
    this.variant = SteyRadioVariant.standard,
    this.appearance,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         appearance != SteyRadioAppearance.segmented,
         'Segmented appearance is group-only.',
       );
  final T value;
  final String label;
  final Widget? labelWidget;
  final String? description;
  final bool disabled, autofocus;
  final SteyRadioVariant variant;
  final SteyRadioAppearance? appearance;
  final FocusNode? focusNode;
  @override
  State<SteyRadioItem<T>> createState() => _SteyRadioItemState<T>();
}

class _SteyRadioItemState<T> extends State<SteyRadioItem<T>> {
  final ownedFocus = FocusNode();
  FocusNode get focus => widget.focusNode ?? ownedFocus;
  @override
  void initState() {
    super.initState();
    focus.addListener(focusChanged);
  }

  void focusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(SteyRadioItem<T> old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? ownedFocus).removeListener(focusChanged);
      focus.addListener(focusChanged);
    }
  }

  @override
  void dispose() {
    focus.removeListener(focusChanged);
    ownedFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final group = context
        .dependOnInheritedWidgetOfExactType<_SteyRadioContext<T>>();
    final cell = context.dependOnInheritedWidgetOfExactType<_RadioCell>();
    final registry = RadioGroup.maybeOf<T>(context);
    final appearance = group?.appearance == SteyRadioAppearance.segmented
        ? SteyRadioAppearance.segmented
        : widget.appearance ?? group?.appearance ?? SteyRadioAppearance.inline;
    final card = appearance == SteyRadioAppearance.card;
    final segmented = appearance == SteyRadioAppearance.segmented;
    final joined =
        card &&
        group?.appearance == SteyRadioAppearance.card &&
        cell?.divider != null;
    final enabled =
        !widget.disabled &&
        (group?.enabled ?? registry != null) &&
        !(group?.disabledValues.contains(widget.value) ?? false);
    final first = group?.controlFirst ?? !card;
    final selected = registry?.groupValue == widget.value;
    final error = widget.variant == SteyRadioVariant.error;
    return Semantics(
      label: widget.label,
      hint: card ? widget.description : null,
      child: Listener(
        onPointerDown: enabled ? (_) => focus.requestFocus() : null,
        child: RawRadio<T>(
          value: widget.value,
          groupRegistry: registry,
          enabled: enabled,
          mouseCursor: WidgetStatePropertyAll(
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
          ),
          toggleable: false,
          focusNode: focus,
          autofocus: widget.autofocus,
          builder: (context, state) {
            final keyboard = state.states.contains(WidgetState.focused);
            final hovered = state.states.contains(WidgetState.hovered);
            final ring = keyboard && enabled
                ? c.brand
                : focus.hasPrimaryFocus && enabled
                ? c.focus
                : error
                ? c.danger
                : hovered && enabled
                ? c.hairline
                : c.line;
            final control = Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox.square(
                dimension: 16,
                child: CustomPaint(
                  painter: _RadioPainter(
                    fill: selected ? c.contrast : c.base,
                    ring: ring,
                    dot: c.base,
                    selected: selected,
                    ringWidth:
                        enabled &&
                            (keyboard || (focus.hasPrimaryFocus && !card))
                        ? 2
                        : 1,
                  ),
                ),
              ),
            );
            final label = ExcludeSemantics(
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: segmented ? 13 : 14,
                  fontWeight: card || segmented
                      ? FontWeight.w500
                      : FontWeight.w400,
                  color: segmented && selected ? c.inverse : c.text,
                ),
                child:
                    widget.labelWidget ??
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: segmented ? 13 : 14,
                        fontWeight: card || segmented
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: segmented && selected ? c.inverse : c.text,
                      ),
                    ),
              ),
            );
            Widget content;
            if (segmented) {
              final radius = BorderRadius.horizontal(
                left: Radius.circular(cell?.first == true ? 8 : 0),
                right: Radius.circular(cell?.last == true ? 8 : 0),
              );
              content = CustomPaint(
                foregroundPainter: keyboard && enabled
                    ? _RadioGroupRing(c.brand, width: 2, outset: 4, radius: 8)
                    : null,
                child: Container(
                  height: 34,
                  padding: EdgeInsets.only(
                    left: cell?.first == true ? 11 : 12,
                    right: cell?.last == true ? 11 : 12,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: selected
                        ? c.contrast
                        : hovered && enabled
                        ? c.contrast.withValues(alpha: .07)
                        : Colors.transparent,
                    border: cell?.last == true
                        ? null
                        : Border(
                            right: BorderSide(
                              color: c.line.withValues(alpha: c.line.a * .6),
                            ),
                          ),
                  ),
                  child: label,
                ),
              );
            } else {
              final text = Flexible(
                fit: card ? FlexFit.tight : FlexFit.loose,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    if (card && widget.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: ExcludeSemantics(
                          child: Text(
                            widget.description!,
                            style: TextStyle(fontSize: 13, color: c.subtle),
                          ),
                        ),
                      ),
                  ],
                ),
              );
              content = Row(
                mainAxisSize: card ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (first) ...[control, SizedBox(width: card ? 12 : 8)],
                  text,
                  if (!first) ...[SizedBox(width: card ? 12 : 8), control],
                ],
              );
              if (card) {
                content = Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: joined ? null : BorderRadius.circular(8),
                    color: error
                        ? c.base
                        : selected
                        ? c.tint
                        : hovered && enabled
                        ? c.elevated
                        : c.base,
                    border: joined
                        ? cell!.divider
                        : Border.all(
                            color: error
                                ? c.danger
                                : selected
                                ? c.interact
                                : c.hairline,
                          ),
                  ),
                  child: content,
                );
              }
            }
            return Opacity(opacity: enabled ? 1 : .5, child: content);
          },
        ),
      ),
    );
  }
}

class _RadioPainter extends CustomPainter {
  const _RadioPainter({
    required this.fill,
    required this.ring,
    required this.dot,
    required this.selected,
    required this.ringWidth,
  });
  final Color fill, ring, dot;
  final bool selected;
  final double ringWidth;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, 8, Paint()..color = fill);
    canvas.drawCircle(
      center,
      8 + ringWidth / 2,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth,
    );
    if (selected) canvas.drawCircle(center, 4, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_RadioPainter old) =>
      fill != old.fill ||
      ring != old.ring ||
      dot != old.dot ||
      selected != old.selected ||
      ringWidth != old.ringWidth;
}

class _RadioGroupRing extends CustomPainter {
  const _RadioGroupRing(
    this.color, {
    this.width = 1,
    this.outset = 0,
    this.radius = 8,
  });
  final Color color;
  final double width, outset, radius;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(outset + width / 2),
      Radius.circular(radius + width / 2),
    ),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width,
  );
  @override
  bool shouldRepaint(_RadioGroupRing old) =>
      color != old.color ||
      width != old.width ||
      outset != old.outset ||
      radius != old.radius;
}
