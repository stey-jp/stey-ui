import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'input.dart';
import 'theme.dart';

enum SteyCheckboxVariant { standard, error }

enum SteyCheckboxAppearance { inline, card }

class SteyCheckbox extends StatefulWidget {
  const SteyCheckbox({
    super.key,
    this.value,
    this.defaultValue = false,
    this.onChanged,
    this.label,
    this.description,
    this.semanticLabel,
    this.labelTooltip,
    this.enabled,
    this.required,
    this.indeterminate = false,
    this.parent = false,
    this.tristate = false,
    this.controlFirst,
    this.variant = SteyCheckboxVariant.standard,
    this.appearance = SteyCheckboxAppearance.inline,
    this.focusNode,
    this.autofocus = false,
  }) : assert(label != null || semanticLabel != null);
  final bool? value, enabled, required, controlFirst;
  final bool defaultValue, indeterminate, parent, tristate, autofocus;
  final ValueChanged<bool?>? onChanged;
  final String? label, description, semanticLabel, labelTooltip;
  final SteyCheckboxVariant variant;
  final SteyCheckboxAppearance appearance;
  final FocusNode? focusNode;
  @override
  State<SteyCheckbox> createState() => _SteyCheckboxState();
}

class _SteyCheckboxState extends State<SteyCheckbox> {
  late bool internalValue = widget.defaultValue;
  final ownedFocus = FocusNode();
  FocusNode get node => widget.focusNode ?? ownedFocus;
  bool showFocus = false, hasFocus = false, hovered = false;
  _CheckboxGroupContext? group;
  bool get isParent => widget.parent && group?.state.widget.allValues != null;
  bool get controlled => isParent || widget.value != null || widget.tristate;
  bool get checked => isParent
      ? group!.selected.length == group!.state.widget.allValues!.length
      : controlled
      ? widget.value == true
      : internalValue;
  bool get mixed => isParent
      ? group!.selected.isNotEmpty && !checked
      : widget.indeterminate || (widget.tristate && widget.value == null);
  bool get enabled =>
      !(group?.disabled ?? false) &&
      (widget.enabled ?? (isParent || !controlled || widget.onChanged != null));
  @override
  void initState() {
    super.initState();
    node.addListener(focusChanged);
  }

  void focusChanged() {
    if (mounted && hasFocus != node.hasPrimaryFocus) {
      setState(() => hasFocus = node.hasPrimaryFocus);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    group = context.dependOnInheritedWidgetOfExactType<_CheckboxGroupContext>();
    assert(
      !widget.parent || isParent,
      'A parent checkbox requires SteyCheckboxGroup.allValues.',
    );
  }

  @override
  void didUpdateWidget(SteyCheckbox old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? ownedFocus).removeListener(focusChanged);
      node.addListener(focusChanged);
      hasFocus = node.hasPrimaryFocus;
    }
  }

  @override
  void dispose() {
    node.removeListener(focusChanged);
    ownedFocus.dispose();
    super.dispose();
  }

  void toggle() {
    if (!enabled) return;
    node.requestFocus();
    if (isParent) {
      group!.state.toggleAll();
      return;
    }
    // Kumo clears indeterminate on activation; tristate is the legacy API.
    final bool? next = mixed
        ? !(widget.tristate && !widget.indeterminate)
        : widget.tristate && checked
        ? null
        : !checked;
    if (!controlled) setState(() => internalValue = next ?? false);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final card = widget.appearance == SteyCheckboxAppearance.card;
    final inheritedItem = context
        .dependOnInheritedWidgetOfExactType<_CheckboxItemContext>();
    final item = inheritedItem?.isItem == true ? inheritedItem : null;
    final joined = item?.divider != null;
    final first = widget.controlFirst ?? !card;
    final error = widget.variant == SteyCheckboxVariant.error;
    final selected = checked || mixed;
    final control = Opacity(
      opacity: enabled || card || item != null ? 1 : .5,
      child: Padding(
        padding: EdgeInsets.only(top: widget.label == null ? 0 : 2),
        child: SizedBox.square(
          dimension: 16,
          child: CustomPaint(
            painter: _CheckboxPainter(
              fill: selected ? c.contrast : c.base,
              ring: selected
                  ? c.contrast
                  : showFocus && enabled
                  ? c.brand
                  : hasFocus && enabled
                  ? c.focus
                  : hovered && enabled && (!card || !error)
                  ? c.hairline
                  : error
                  ? c.danger
                  : card
                  ? c.line
                  : c.hairline,
              indicator: c.inverse,
              ringWidth: enabled && (showFocus || (hasFocus && !card)) ? 2 : 1,
              checked: checked,
              mixed: mixed,
            ),
          ),
        ),
      ),
    );
    final text = widget.label == null
        ? null
        : Flexible(
            fit: card ? FlexFit.tight : FlexFit.loose,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SteyLabel(
                  widget.label!,
                  required: widget.required,
                  tooltip: widget.labelTooltip,
                  excludeTextSemantics: true,
                  weight: item != null && !card
                      ? FontWeight.w400
                      : FontWeight.w500,
                ),
                if (widget.description != null && (item == null || card))
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
    Widget content = Row(
      mainAxisSize: card ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (first) control,
        if (text != null) ...[
          if (first) SizedBox(width: card ? 12 : 8),
          text,
          if (!first) SizedBox(width: card ? 12 : 8),
        ],
        if (!first) control,
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
              ? item!.divider
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
    return FocusableActionDetector(
      enabled: enabled,
      focusNode: node,
      autofocus: widget.autofocus,
      includeFocusSemantics: false,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onShowFocusHighlight: (value) => setState(() => showFocus = value),
      onShowHoverHighlight: (value) => setState(() => hovered = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            toggle();
            return null;
          },
        ),
      },
      child: Semantics(
        container: true,
        label: widget.semanticLabel ?? widget.label,
        hint: widget.description,
        checked: mixed ? null : checked,
        mixed: mixed ? true : null,
        enabled: enabled,
        isRequired: widget.required,
        focusable: enabled,
        focused: hasFocus,
        onTap: enabled ? toggle : null,
        child: GestureDetector(
          onTap: enabled ? toggle : null,
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: enabled || (!card && item == null) ? 1 : .5,
            child: content,
          ),
        ),
      ),
    );
  }
}

class _CheckboxPainter extends CustomPainter {
  const _CheckboxPainter({
    required this.fill,
    required this.ring,
    required this.indicator,
    required this.ringWidth,
    required this.checked,
    required this.mixed,
  });
  final Color fill, ring, indicator;
  final double ringWidth;
  final bool checked, mixed;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(ringWidth / 2),
        Radius.circular(4 + ringWidth / 2),
      ),
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth,
    );
    final paint = Paint()
      ..color = indicator
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.125
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (mixed) {
      canvas.drawLine(const Offset(3.875, 8), const Offset(12.125, 8), paint);
    } else if (checked) {
      canvas.drawPath(
        Path()
          ..moveTo(3.875, 8.75)
          ..lineTo(6.5, 11.375)
          ..lineTo(12.5, 5.375),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckboxPainter old) =>
      fill != old.fill ||
      ring != old.ring ||
      indicator != old.indicator ||
      ringWidth != old.ringWidth ||
      checked != old.checked ||
      mixed != old.mixed;
}

class _CheckboxItemContext extends InheritedWidget {
  const _CheckboxItemContext({
    required super.child,
    this.divider,
    this.isItem = false,
  });
  final Border? divider;
  final bool isItem;
  @override
  bool updateShouldNotify(_CheckboxItemContext old) =>
      divider != old.divider || isItem != old.isItem;
}

class SteyCheckboxLegend extends StatelessWidget {
  const SteyCheckboxLegend(this.text, {super.key, this.visuallyHidden = false});
  final String text;
  final bool visuallyHidden;
  @override
  Widget build(BuildContext context) => visuallyHidden
      ? const SizedBox.shrink()
      : ExcludeSemantics(child: SteyLabel(text));
}

class SteyCheckboxGroup extends StatefulWidget {
  const SteyCheckboxGroup({
    super.key,
    required this.children,
    this.legend,
    this.description,
    this.error,
    this.value,
    this.defaultValue = const [],
    this.onChanged,
    this.allValues,
    this.disabled = false,
    this.orientation = Axis.vertical,
    this.appearance = SteyCheckboxAppearance.inline,
    this.controlFirst,
  });
  final List<Widget> children;
  final String? legend, description, error;
  final List<String>? value;
  final List<String> defaultValue;
  final List<String>? allValues;
  final ValueChanged<List<String>>? onChanged;
  final bool disabled;
  final Axis orientation;
  final SteyCheckboxAppearance appearance;
  final bool? controlFirst;
  @override
  State<SteyCheckboxGroup> createState() => _SteyCheckboxGroupState();
}

class _SteyCheckboxGroupState extends State<SteyCheckboxGroup> {
  late List<String> internal = List.of(widget.defaultValue);
  late List<String> partial = List.of(widget.value ?? widget.defaultValue);
  final disabledValues = <String, bool>{};
  String parentStatus = 'mixed';
  List<String> get selected => widget.value ?? internal;
  void setSelection(List<String> next) {
    if (widget.value == null) setState(() => internal = next);
    widget.onChanged?.call(List.unmodifiable(next));
  }

  void toggleAll() {
    if (widget.disabled || widget.allValues == null) return;
    final all = widget.allValues!
        .where(
          (value) =>
              !(disabledValues[value] ?? false) || partial.contains(value),
        )
        .toList();
    final none = widget.allValues!
        .where(
          (value) =>
              (disabledValues[value] ?? false) && partial.contains(value),
        )
        .toList();
    if (partial.isEmpty || partial.length == all.length) {
      setSelection(selected.length == all.length ? none : all);
      return;
    }
    final next = parentStatus == 'mixed'
        ? all
        : parentStatus == 'on'
        ? none
        : List.of(partial);
    parentStatus = parentStatus == 'mixed'
        ? 'on'
        : parentStatus == 'on'
        ? 'off'
        : 'mixed';
    setSelection(next);
  }

  void change(String value, bool checked) {
    if (widget.disabled) return;
    final next = List.of(selected);
    if (checked && !next.contains(value)) next.add(value);
    if (!checked) next.remove(value);
    partial = List.of(next);
    parentStatus = 'mixed';
    setSelection(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final card = widget.appearance == SteyCheckboxAppearance.card;
    final horizontal = widget.orientation == Axis.horizontal;
    final legends = widget.children.whereType<SteyCheckboxLegend>().toList();
    final children = widget.children
        .where((child) => child is! SteyCheckboxLegend)
        .toList();
    final gap = card ? 8.0 : 16.0;
    final items = <Widget>[
      for (var i = 0; i < children.length; i++)
        _CheckboxItemContext(
          divider: card
              ? Border(
                  bottom:
                      (horizontal
                          ? i < (children.length - 1) ~/ 2 * 2
                          : i < children.length - 1)
                      ? BorderSide(color: c.line)
                      : BorderSide.none,
                  right: horizontal && i.isEven && i + 1 < children.length
                      ? BorderSide(color: c.line)
                      : BorderSide.none,
                )
              : null,
          child: children[i],
        ),
    ];
    Widget content;
    if (card && horizontal) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i += 2)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: items[i]),
                  Expanded(
                    child: i + 1 < items.length
                        ? items[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      );
    } else if (horizontal) {
      content = Wrap(spacing: 8, runSpacing: 8, children: items);
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0 && !card) const SizedBox(height: 8),
            items[i],
          ],
        ],
      );
    }
    if (card) {
      content = CustomPaint(
        foregroundPainter: _ChoiceGroupRing(c.line),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: content,
        ),
      );
    }
    return _CheckboxGroupContext(
      state: this,
      selected: List.unmodifiable(selected),
      disabled: widget.disabled,
      appearance: widget.appearance,
      controlFirst: widget.controlFirst,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label:
            widget.legend ??
            (legends.isEmpty
                ? null
                : legends.map((legend) => legend.text).join(' ')),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.legend != null) ...[
              ExcludeSemantics(child: SteyLabel(widget.legend!)),
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
    );
  }
}

class _CheckboxGroupContext extends InheritedWidget {
  const _CheckboxGroupContext({
    required this.state,
    required this.selected,
    required this.disabled,
    required this.appearance,
    required this.controlFirst,
    required super.child,
  });
  final _SteyCheckboxGroupState state;
  final List<String> selected;
  final bool disabled;
  final SteyCheckboxAppearance appearance;
  final bool? controlFirst;
  @override
  bool updateShouldNotify(_CheckboxGroupContext old) =>
      selected != old.selected ||
      disabled != old.disabled ||
      appearance != old.appearance ||
      controlFirst != old.controlFirst;
}

class SteyCheckboxItem extends StatelessWidget {
  const SteyCheckboxItem({
    super.key,
    required this.label,
    this.value,
    this.checked,
    this.defaultValue = false,
    this.indeterminate = false,
    this.disabled = false,
    this.description,
    this.onChanged,
    this.appearance,
    this.variant = SteyCheckboxVariant.standard,
  });
  final String label;
  final String? value, description;
  final bool? checked;
  final bool defaultValue, indeterminate, disabled;
  final ValueChanged<bool?>? onChanged;
  final SteyCheckboxAppearance? appearance;
  final SteyCheckboxVariant variant;
  @override
  Widget build(BuildContext context) {
    final group = context
        .dependOnInheritedWidgetOfExactType<_CheckboxGroupContext>();
    final grouped = group != null && value != null;
    if (grouped) group.state.disabledValues[value!] = disabled;
    final item = context
        .dependOnInheritedWidgetOfExactType<_CheckboxItemContext>();
    final effectiveAppearance =
        appearance ?? group?.appearance ?? SteyCheckboxAppearance.inline;
    return _CheckboxItemContext(
      isItem: true,
      divider: effectiveAppearance == SteyCheckboxAppearance.card
          ? item?.divider
          : null,
      child: SteyCheckbox(
        label: label,
        description: description,
        indeterminate: indeterminate,
        variant: variant,
        appearance: effectiveAppearance,
        controlFirst: group?.controlFirst,
        value: checked ?? (grouped ? group.selected.contains(value) : null),
        defaultValue: defaultValue,
        enabled: !disabled && !(group?.disabled ?? false),
        onChanged: (next) {
          if (grouped) group.state.change(value!, next == true);
          onChanged?.call(next);
        },
      ),
    );
  }
}

class _ChoiceGroupRing extends CustomPainter {
  const _ChoiceGroupRing(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(.5),
      const Radius.circular(8.5),
    ),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  @override
  bool shouldRepaint(_ChoiceGroupRing old) => color != old.color;
}

enum SteySwitchVariant { standard, neutral }

enum SteySwitchSize {
  sm(16),
  base(18),
  lg(20);

  const SteySwitchSize(this.height);
  final double height;
}

class SteySwitch extends StatefulWidget {
  const SteySwitch({
    super.key,
    this.value,
    this.defaultValue = false,
    this.onChanged,
    this.label,
    this.semanticLabel,
    this.labelTooltip,
    this.required,
    this.enabled,
    this.controlFirst = true,
    this.transitioning = false,
    this.busyLabel = 'Updating',
    this.variant = SteySwitchVariant.standard,
    this.size = SteySwitchSize.base,
    this.focusNode,
    this.autofocus = false,
  }) : assert(label != null || semanticLabel != null);
  final bool? value, enabled, required;
  final bool defaultValue, controlFirst, transitioning, autofocus;
  final ValueChanged<bool>? onChanged;
  final String? label, semanticLabel, labelTooltip;
  final String busyLabel;
  final SteySwitchVariant variant;
  final SteySwitchSize size;
  final FocusNode? focusNode;
  @override
  State<SteySwitch> createState() => _SteySwitchState();
}

class _SteySwitchState extends State<SteySwitch>
    with SingleTickerProviderStateMixin {
  late bool internalValue = widget.defaultValue;
  final ownedFocus = FocusNode();
  FocusNode get node => widget.focusNode ?? ownedFocus;
  bool showFocus = false, hasFocus = false;
  bool get checked => widget.value ?? internalValue;
  bool get enabled =>
      widget.enabled ?? (widget.value == null || widget.onChanged != null);
  late final animation = AnimationController(
    vsync: this,
    value: checked ? 1 : 0,
    duration: const Duration(milliseconds: 150),
    animationBehavior: AnimationBehavior.preserve,
  );
  @override
  void initState() {
    super.initState();
    node.addListener(focusChanged);
  }

  void focusChanged() {
    if (mounted && hasFocus != node.hasPrimaryFocus) {
      setState(() => hasFocus = node.hasPrimaryFocus);
    }
  }

  void toggle() {
    if (!enabled) return;
    node.requestFocus();
    final next = !checked;
    if (widget.value == null) {
      setState(() => internalValue = next);
      animation.animateTo(next ? 1 : 0, curve: Curves.easeOut);
    }
    widget.onChanged?.call(next);
  }

  @override
  void didUpdateWidget(SteySwitch old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? ownedFocus).removeListener(focusChanged);
      node.addListener(focusChanged);
      hasFocus = node.hasPrimaryFocus;
    }
    animation.animateTo(checked ? 1 : 0, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    node.removeListener(focusChanged);
    ownedFocus.dispose();
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context),
        neutral = widget.variant == SteySwitchVariant.neutral;
    final trackOff = neutral
        ? c.dark
              ? c.base
              : Colors.transparent
        : c.switchTrackOff;
    final trackOn = neutral ? c.switchNeutralTrackOn : c.switchTrackOn;
    final ringOff = neutral ? c.hairline : c.switchRingOff;
    final ringOn = neutral ? c.switchNeutralRingOn : c.switchRingOn;
    final thumbOn = neutral ? c.switchNeutralThumbOn : c.switchThumbOn;
    final control = Opacity(
      opacity: enabled ? 1 : .5,
      child: SizedBox(
        width: widget.size.height * 2,
        height: widget.size.height,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => CustomPaint(
            painter: _SwitchPainter(
              position: animation.value,
              track: Color.lerp(trackOff, trackOn, animation.value)!,
              ring: showFocus && enabled
                  ? c.brand
                  : Color.lerp(ringOff, ringOn, animation.value)!,
              thumb: Color.lerp(c.base, thumbOn, animation.value)!,
              edge: c.shadowEdge,
              drop: c.shadowDrop,
              ringWidth: showFocus && enabled ? 2 : 1,
            ),
          ),
        ),
      ),
    );
    final label = widget.label == null
        ? null
        : Flexible(
            child: SteyLabel(
              widget.label!,
              required: widget.required,
              tooltip: widget.labelTooltip,
              excludeTextSemantics: true,
            ),
          );
    return FocusableActionDetector(
      enabled: enabled,
      focusNode: node,
      autofocus: widget.autofocus,
      includeFocusSemantics: false,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onShowFocusHighlight: (value) => setState(() => showFocus = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            toggle();
            return null;
          },
        ),
      },
      child: Semantics(
        container: true,
        label: widget.semanticLabel ?? widget.label,
        toggled: checked,
        enabled: enabled,
        isRequired: widget.required,
        focusable: enabled,
        focused: hasFocus,
        onTap: enabled ? toggle : null,
        hint: widget.transitioning ? widget.busyLabel : null,
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: enabled ? toggle : null,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.controlFirst) control,
              if (label != null) ...[
                if (widget.controlFirst) const SizedBox(width: 8),
                label,
                if (!widget.controlFirst) const SizedBox(width: 8),
              ],
              if (!widget.controlFirst) control,
            ],
          ),
        ),
      ),
    );
  }
}

class SteySwitchLegend extends StatelessWidget {
  const SteySwitchLegend(this.text, {super.key, this.visuallyHidden = false});
  final String text;
  final bool visuallyHidden;
  @override
  Widget build(BuildContext context) => visuallyHidden
      ? const SizedBox.shrink()
      : ExcludeSemantics(child: SteyLabel(text));
}

class SteySwitchGroup extends StatelessWidget {
  const SteySwitchGroup({
    super.key,
    required this.children,
    this.legend,
    this.description,
    this.error,
    this.disabled = false,
    this.controlFirst = true,
  });
  final List<Widget> children;
  final String? legend, description, error;
  final bool disabled, controlFirst;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final legends = children.whereType<SteySwitchLegend>().toList();
    final items = children
        .where((child) => child is! SteySwitchLegend)
        .toList();
    return _SwitchGroupContext(
      disabled: disabled,
      controlFirst: controlFirst,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label:
            legend ??
            (legends.isEmpty
                ? null
                : legends.map((legend) => legend.text).join(' ')),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (legend != null) ...[
              ExcludeSemantics(child: SteyLabel(legend!)),
              const SizedBox(height: 16),
            ],
            for (final legend in legends) ...[
              legend,
              if (!legend.visuallyHidden) const SizedBox(height: 16),
            ],
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              items[i],
            ],
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error!, style: TextStyle(fontSize: 13, color: c.dangerText)),
            ],
            if (description != null) ...[
              const SizedBox(height: 16),
              Text(
                description!,
                style: TextStyle(fontSize: 13, color: c.subtle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwitchGroupContext extends InheritedWidget {
  const _SwitchGroupContext({
    required this.disabled,
    required this.controlFirst,
    required super.child,
  });
  final bool disabled, controlFirst;
  @override
  bool updateShouldNotify(_SwitchGroupContext old) =>
      disabled != old.disabled || controlFirst != old.controlFirst;
}

class SteySwitchItem extends StatelessWidget {
  const SteySwitchItem({
    super.key,
    required this.label,
    this.value,
    this.defaultValue = false,
    this.disabled = false,
    this.transitioning = false,
    this.onChanged,
    this.variant = SteySwitchVariant.standard,
    this.size = SteySwitchSize.base,
  });
  final String label;
  final bool? value;
  final bool defaultValue, disabled, transitioning;
  final ValueChanged<bool>? onChanged;
  final SteySwitchVariant variant;
  final SteySwitchSize size;
  @override
  Widget build(BuildContext context) {
    final group = context
        .dependOnInheritedWidgetOfExactType<_SwitchGroupContext>();
    return Opacity(
      opacity: disabled ? .5 : 1,
      child: SteySwitch(
        label: label,
        value: value,
        defaultValue: defaultValue,
        onChanged: onChanged,
        enabled: !disabled && !(group?.disabled ?? false),
        controlFirst: group?.controlFirst ?? true,
        transitioning: transitioning,
        variant: variant,
        size: size,
      ),
    );
  }
}

// CSS corner-shape: squircle is superellipse(2), whose exponent is 2^2.
Path _squircle(Rect rect) {
  final r = math.min(10.0, math.min(rect.width, rect.height) / 2),
      path = Path();
  final centers = [
    Offset(rect.right - r, rect.top + r),
    Offset(rect.right - r, rect.bottom - r),
    Offset(rect.left + r, rect.bottom - r),
    Offset(rect.left + r, rect.top + r),
  ];
  for (var corner = 0; corner < 4; corner++) {
    for (var sample = 0; sample <= 24; sample++) {
      final angle = (-.5 + corner * .5 + sample / 48) * math.pi;
      final x = math.cos(angle), y = math.sin(angle);
      final point =
          centers[corner] +
          Offset(
            r * x.sign * math.sqrt(x.abs()),
            r * y.sign * math.sqrt(y.abs()),
          );
      if (corner == 0 && sample == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
  }
  return path..close();
}

class _SwitchPainter extends CustomPainter {
  const _SwitchPainter({
    required this.position,
    required this.track,
    required this.ring,
    required this.thumb,
    required this.edge,
    required this.drop,
    required this.ringWidth,
  });
  final double position, ringWidth;
  final Color track, ring, thumb, edge, drop;
  @override
  void paint(Canvas canvas, Size size) {
    final trackPath = _squircle(Offset.zero & size);
    canvas.drawPath(trackPath, Paint()..color = track);
    canvas.drawPath(
      _squircle((Offset.zero & size).inflate(ringWidth / 2)),
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth,
    );
    final thumbPath = _squircle(
      Rect.fromLTWH(position * size.height, 0, size.height, size.height),
    );
    canvas.drawPath(
      thumbPath.shift(const Offset(0, 1)),
      Paint()
        ..color = drop
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
    canvas.drawPath(
      thumbPath,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .5),
    );
    canvas.drawPath(thumbPath, Paint()..color = thumb);
  }

  @override
  bool shouldRepaint(_SwitchPainter old) =>
      position != old.position ||
      track != old.track ||
      ring != old.ring ||
      thumb != old.thumb ||
      edge != old.edge ||
      drop != old.drop ||
      ringWidth != old.ringWidth;
}
