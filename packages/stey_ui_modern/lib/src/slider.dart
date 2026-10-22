import 'dart:math' as math;
import 'dart:ui' show FontFeature, PointerDeviceKind;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:intl/intl.dart' show NumberFormat;

import 'messages.dart';
import 'theme.dart';

enum SteySliderSize { sm, base }

enum SteySliderThumbAlignment { edge, center, edgeClientOnly }

enum SteySliderCollision { push, swap, none }

enum SteySliderChangeReason { trackPress, drag, keyboard, accessibility }

class SteySliderChangeDetails {
  SteySliderChangeDetails(this.reason, this.activeThumbIndex);
  final SteySliderChangeReason reason;
  final int activeThumbIndex;
  bool get isCanceled => _canceled;
  bool _canceled = false;
  void cancel() => _canceled = true;
}

typedef SteySliderChange = void Function(
  List<double> values,
  SteySliderChangeDetails details,
);
typedef SteySliderValueText = String Function(
  String formatted,
  double value,
  int index,
);

/// Horizontal Kumo slider. [divisions] and scalar callbacks remain compatible.
class SteySlider extends StatefulWidget {
  const SteySlider({
    super.key,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.onChangeCommitted,
    this.onValueChange,
    this.onValueCommitted,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.step,
    this.largeStep = 10,
    this.minStepsBetweenValues = 0,
    this.size = SteySliderSize.base,
    this.label = 'Value',
    this.labelWidget,
    this.semanticLabel,
    this.disabled = false,
    this.format,
    this.locale,
    this.getAriaLabel,
    this.getAriaValueText,
    this.thumbAlignment = SteySliderThumbAlignment.edge,
    this.thumbCollisionBehavior = SteySliderCollision.push,
  }) : values = null,
       defaultValues = null,
       _range = false,
       _rangeChanged = null,
       _rangeCommitted = null,
       assert(
         min > double.negativeInfinity && max < double.infinity && min < max,
       ),
       assert(divisions == null || divisions > 0),
       assert(step == null || step > 0 && step < double.infinity),
       assert(largeStep > 0 && largeStep < double.infinity),
       assert(minStepsBetweenValues >= 0);

  const SteySlider.range({
    super.key,
    this.values,
    this.defaultValues = const [25, 75],
    ValueChanged<List<double>>? onChanged,
    ValueChanged<List<double>>? onChangeCommitted,
    this.onValueChange,
    this.onValueCommitted,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.step,
    this.largeStep = 10,
    this.minStepsBetweenValues = 0,
    this.size = SteySliderSize.base,
    this.label = 'Value',
    this.labelWidget,
    this.semanticLabel,
    this.disabled = false,
    this.format,
    this.locale,
    this.getAriaLabel,
    this.getAriaValueText,
    this.thumbAlignment = SteySliderThumbAlignment.edge,
    this.thumbCollisionBehavior = SteySliderCollision.push,
  }) : value = null,
       defaultValue = null,
       _range = true,
       onChanged = null,
       onChangeCommitted = null,
       _rangeChanged = onChanged,
       _rangeCommitted = onChangeCommitted,
       assert(
         min > double.negativeInfinity && max < double.infinity && min < max,
       ),
       assert(divisions == null || divisions > 0),
       assert(step == null || step > 0 && step < double.infinity),
       assert(largeStep > 0 && largeStep < double.infinity),
       assert(minStepsBetweenValues >= 0);

  final double? value, defaultValue, step;
  final List<double>? values, defaultValues;
  final ValueChanged<double>? onChanged, onChangeCommitted;
  final ValueChanged<List<double>>? _rangeChanged, _rangeCommitted;
  final SteySliderChange? onValueChange, onValueCommitted;
  final double min, max, largeStep;
  final int? divisions;
  final int minStepsBetweenValues;
  final SteySliderSize size;
  final String? label, semanticLabel, locale;
  final Widget? labelWidget;
  final bool disabled, _range;
  final NumberFormat? format;
  final String Function(int index)? getAriaLabel;
  final SteySliderValueText? getAriaValueText;
  final SteySliderThumbAlignment thumbAlignment;
  final SteySliderCollision thumbCollisionBehavior;
  bool get isRange => _range;
  double get effectiveStep =>
      step ?? (divisions == null ? 1 : (max - min) / divisions!);
  bool get controlled => _range ? values != null : value != null;
  @override
  State<SteySlider> createState() => _SliderState();
}

class _SliderState extends State<SteySlider> {
  late List<double> internal = widget.isRange
      ? List.of(widget.defaultValues ?? [widget.min])
      : [widget.defaultValue ?? widget.min];
  final nodes = <FocusNode>[];
  int active = -1, lastUsed = -1;
  int? pointer;
  double pressOffset = 0;
  Offset? pressPosition;
  bool keyboardFocus = false, canceledTouch = false;
  List<double>? interaction, pendingCommit;
  SteySliderChangeReason lastReason = SteySliderChangeReason.trackPress;
  bool get enabled =>
      !widget.disabled &&
      (!widget.controlled ||
          widget.onChanged != null ||
          widget._rangeChanged != null ||
          widget.onValueChange != null);
  List<double> get current {
    final raw = widget.controlled
        ? (widget.isRange ? widget.values! : [widget.value!])
        : internal;
    assert(raw.isNotEmpty, 'A slider needs at least one value');
    return [
      for (final v in raw)
        (v.isNaN ? widget.min : v).clamp(widget.min, widget.max),
    ]..sort();
  }

  double get gap => widget.minStepsBetweenValues * widget.effectiveStep;
  bool get edge => widget.thumbAlignment != SteySliderThumbAlignment.center;
  bool get rtl => Directionality.of(context) == TextDirection.rtl;

  @override
  void didUpdateWidget(SteySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!enabled ||
        oldWidget.isRange != widget.isRange ||
        (interaction != null && interaction!.length != current.length)) {
      pointer = null;
      interaction = null;
      pendingCommit = null;
      active = -1;
      if (!enabled) {
        for (final node in nodes) {
          node.unfocus();
        }
      }
    }
  }

  @override
  void dispose() {
    for (final n in nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void syncNodes(int count) {
    while (nodes.length < count) {
      nodes.add(FocusNode()..addListener(focusChanged));
    }
    while (nodes.length > count) {
      nodes.removeLast().dispose();
    }
    if (lastUsed >= count) lastUsed = -1;
    if (active >= count) active = -1;
  }

  void focusChanged() {
    if (mounted) {
      setState(() {
        if (pointer == null &&
            HardwareKeyboard.instance.logicalKeysPressed.isNotEmpty &&
            nodes.any((n) => n.hasFocus)) {
          keyboardFocus = true;
        }
      });
    }
  }

  double rounded(double n) {
    final s = widget.effectiveStep;
    // JS Math.round rounds a negative half toward positive infinity.
    final snapped = ((n - widget.min) / s + .5).floor() * s + widget.min;
    return double.parse(snapped.toStringAsFixed(12))
        .clamp(widget.min, widget.max);
  }

  double tidy(double n) => double.parse(n.toStringAsFixed(12));
  List<double> push(
    List<double> values,
    int index,
    double next, [
    List<double>? initial,
  ]) {
    final out = List.of(values), last = values.length - 1;
    out[index] = next.clamp(
      widget.min + index * gap,
      widget.max - (last - index) * gap,
    );
    for (var i = index + 1; i <= last; i++) {
      final low = out[i - 1] + gap, high = widget.max - (last - i) * gap;
      var candidate = math.max(out[i], low);
      if ((initial ?? values)[i] < candidate) {
        candidate = math.max((initial ?? values)[i], low);
      }
      out[i] = candidate.clamp(low, high);
    }
    for (var i = index - 1; i >= 0; i--) {
      final low = widget.min + i * gap, high = out[i + 1] - gap;
      var candidate = math.min(out[i], high);
      if ((initial ?? values)[i] > candidate) {
        candidate = math.min((initial ?? values)[i], high);
      }
      out[i] = candidate.clamp(low, high);
    }
    return out.map(tidy).toList();
  }

  (List<double>, int) collide(List<double> values, int index, double next) {
    if (values.length == 1) return ([next], 0);
    if (widget.thumbCollisionBehavior == SteySliderCollision.push) {
      return (push(values, index, next), index);
    }
    final low = index == 0 ? widget.min : values[index - 1] + gap;
    final high = index == values.length - 1
        ? widget.max
        : values[index + 1] - gap;
    final clamped = tidy(next.clamp(low, high)),
        out = List.of(values)..[index] = clamped;
    if (widget.thumbCollisionBehavior == SteySliderCollision.none) {
      return (out, index);
    }
    final forward =
        next > values[index] &&
        index < values.length - 1 &&
        next >= values[index + 1] - 1e-7;
    final backward =
        next < values[index] && index > 0 && next <= values[index - 1] + 1e-7;
    if (!forward && !backward) return (out, index);
    final target = index + (forward ? 1 : -1);
    final initial = List.of(interaction ?? values)..[index] = clamped;
    final result = push(
      out,
      target,
      forward ? math.max(next, out[target]) : math.min(next, out[target]),
      initial,
    );
    final neighbor = forward ? target - 1 : target + 1;
    final lower = math.max(
      neighbor == 0 ? widget.min : result[neighbor - 1] + gap,
      widget.min + neighbor * gap,
    );
    final upper = math.min(
      neighbor == result.length - 1 ? widget.max : result[neighbor + 1] - gap,
      widget.max - (result.length - 1 - neighbor) * gap,
    );
    result[neighbor] = tidy(clamped.clamp(lower, upper));
    return (result, target);
  }

  bool apply(
    List<double> next,
    int index,
    SteySliderChangeReason reason, {
    bool commit = false,
  }) {
    if (!enabled || listEquals(next, interaction ?? current)) return false;
    if (next.asMap().entries.any(
      (e) => e.key > 0 && next[e.key] - next[e.key - 1] < gap - 1e-10,
    )) {
      return false;
    }
    final details = SteySliderChangeDetails(reason, index);
    widget.onValueChange?.call(List.unmodifiable(next), details);
    if (details.isCanceled) return false;
    if (widget.isRange) {
      widget._rangeChanged?.call(List.of(next));
    } else {
      widget.onChanged?.call(next.first);
    }
    if (!mounted) return true;
    setState(() {
      if (!widget.controlled) internal = List.of(next);
      lastUsed = index;
    });
    if (commit) {
      committed(next, reason, index);
    } else {
      interaction = List.of(next);
      pendingCommit = List.of(next);
      lastReason = reason;
    }
    return true;
  }

  void committed(
    List<double> values,
    SteySliderChangeReason reason,
    int index,
  ) {
    if (widget.isRange) {
      widget._rangeCommitted?.call(List.of(values));
    } else {
      widget.onChangeCommitted?.call(values.first);
    }
    widget.onValueCommitted?.call(
      List.unmodifiable(values),
      SteySliderChangeDetails(reason, index),
    );
  }

  void keyboardChange(int index, double next, SteySliderChangeReason reason) {
    final values = current, out = List.of(values);
    out[index] = tidy(
      next.clamp(
        index == 0 ? widget.min : values[index - 1],
        index == values.length - 1 ? widget.max : values[index + 1],
      ),
    );
    apply(out, index, reason, commit: true);
  }

  KeyEventResult key(int index, KeyEvent event) {
    if (!enabled || event is KeyUpEvent) return KeyEventResult.ignored;
    final k = event.logicalKey, values = current, value = values[index];
    final increment = HardwareKeyboard.instance.isShiftPressed
        ? widget.largeStep
        : widget.effectiveStep;
    double? next;
    if (k == LogicalKeyboardKey.arrowUp ||
        k == LogicalKeyboardKey.arrowRight && !rtl ||
        k == LogicalKeyboardKey.arrowLeft && rtl) {
      next = rounded(value) + increment;
    }
    if (k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.arrowLeft && !rtl ||
        k == LogicalKeyboardKey.arrowRight && rtl) {
      next = rounded(value) - increment;
    }
    if (k == LogicalKeyboardKey.pageUp) {
      next = rounded(value) + widget.largeStep;
    }
    if (k == LogicalKeyboardKey.pageDown) {
      next = rounded(value) - widget.largeStep;
    }
    if (k == LogicalKeyboardKey.home) {
      next = index == 0 ? widget.min : values[index - 1] + gap;
    }
    if (k == LogicalKeyboardKey.end) {
      next = index == values.length - 1 ? widget.max : values[index + 1] - gap;
    }
    if (next == null) return KeyEventResult.ignored;
    setState(() {
      keyboardFocus = true;
      lastUsed = index;
    });
    keyboardChange(index, next, SteySliderChangeReason.keyboard);
    return KeyEventResult.handled;
  }

  double center(double value, double width) {
    final fraction = (value - widget.min) / (widget.max - widget.min);
    final position = (edge ? 8 : 0) + (width - 6 - (edge ? 16 : 0)) * fraction;
    return 3 + (rtl ? width - 6 - position : position);
  }

  void beginPress(PointerDownEvent event, double width) {
    if (!enabled || pointer != null || event.buttons & 1 == 0) return;
    final values = current, x = event.localPosition.dx;
    var index = -1, distance = double.infinity;
    final order = [for (var i = 0; i < values.length; i++) i];
    if (lastUsed >= 0) {
      order.remove(lastUsed);
      order.add(lastUsed);
    }
    for (final i in order) {
      if ((x - center(values[i], width)).abs() <= 8) index = i;
    }
    final onThumb = index >= 0;
    if (!onThumb) {
      for (var i = 0; i < values.length; i++) {
        final d = (x - center(values[i], width)).abs();
        if (d <= distance) {
          distance = d;
          index = i;
        }
      }
    }
    if (values[index] == widget.max) {
      while (index > 0 && values[index - 1] == widget.max) {
        index--;
      }
    }
    setState(() {
      active = index;
      lastUsed = index;
      pointer = event.pointer;
      keyboardFocus = false;
      canceledTouch = false;
    });
    pressPosition = event.localPosition;
    pressOffset = onThumb ? x - center(values[index], width) : 0;
    interaction = List.of(values);
    pendingCommit = null;
    lastReason = SteySliderChangeReason.trackPress;
    nodes[index].requestFocus();
    fromPointer(x, width, SteySliderChangeReason.trackPress);
  }

  void fromPointer(double x, double width, SteySliderChangeReason reason) {
    final logical = rtl ? width - 3 - (x - pressOffset) : x - pressOffset - 3;
    final fraction =
        ((logical - (edge ? 8 : 0)) / (width - 6 - (edge ? 16 : 0))).clamp(
          0.0,
          1.0,
        );
    final next = rounded(widget.min + (widget.max - widget.min) * fraction);
    final (out, index) = collide(interaction ?? current, active, next);
    if (apply(out, index, reason)) {
      active = index;
      nodes[index].requestFocus();
    }
  }

  void move(PointerMoveEvent e, double width) {
    if (e.pointer != pointer || canceledTouch || active < 0) return;
    if (e.kind == PointerDeviceKind.touch && pressPosition != null) {
      final travel = e.localPosition - pressPosition!;
      if (travel.dy.abs() > 12 && travel.dy.abs() > travel.dx.abs()) {
        canceledTouch = true;
        return;
      }
    }
    if (e.buttons == 0) {
      end(e);
      return;
    }
    fromPointer(e.localPosition.dx, width, SteySliderChangeReason.drag);
  }

  void end(PointerEvent e) {
    if (e.pointer != pointer) return;
    final result = pendingCommit, index = active;
    setState(() {
      pointer = null;
      interaction = null;
      pendingCommit = null;
      active = -1;
    });
    if (result != null && result.length == current.length) {
      committed(result, lastReason, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = current;
    syncNodes(values.length);
    assert(
      gap * (values.length - 1) <= widget.max - widget.min,
      'Minimum gaps exceed the range',
    );
    final c = SteyTheme.colorsOf(context),
        sm = widget.size == SteySliderSize.sm;
    final height = sm ? 24.0 : 32.0,
        radius = sm ? 6.0 : 8.0,
        innerRadius = sm ? 4.0 : 6.0;
    final textStyle = TextStyle(
      fontSize: sm ? 12 : 13,
      height: sm ? 1 / .75 : 1 / .85,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
      color: c.subtle,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final formatter =
        widget.format ??
        NumberFormat.decimalPattern(
          widget.locale ?? Localizations.localeOf(context).toString(),
        );
    final label = widget.label == 'Value' && SteyMessages.of(context).japanese
        ? '値'
        : widget.label;
    String thumbLabel(int i) =>
        widget.getAriaLabel?.call(i) ??
        widget.semanticLabel ??
        label ??
        (SteyMessages.of(context).japanese ? '値' : 'Value');
    String valueText(double value, int i) {
      final text = formatter.format(value);
      return widget.getAriaValueText?.call(text, value, i) ??
          (values.length == 2
              ? '$text ${SteyMessages.of(context).japanese ? (i == 0 ? '範囲の開始' : '範囲の終了') : (i == 0 ? 'start range' : 'end range')}'
              : text);
    }

    return Opacity(
      opacity: enabled ? 1 : .5,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: widget.semanticLabel ?? label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              if (widget.labelWidget != null ||
                  label != null && label.isNotEmpty)
                ExcludeSemantics(
                  child: GestureDetector(
                    onTap: enabled && values.length == 1
                        ? () {
                            setState(() => keyboardFocus = true);
                            nodes.first.requestFocus();
                          }
                        : null,
                    child: DefaultTextStyle.merge(
                      style: textStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.text,
                      ),
                      child: widget.labelWidget ?? Text(label!),
                    ),
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final centers = [
                    for (final value in values) center(value, width),
                  ];
                  final textHeight = TextPainter(
                    text: TextSpan(text: '0', style: textStyle),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout();
                  final footerHeight = textHeight.height;
                  textHeight.dispose();
                  final start = values.length > 1
                      ? centers.reduce(math.min) - (rtl ? 16 : 8)
                      : (rtl ? centers.first - 8 : 3.0);
                  final finish = values.length > 1
                      ? centers.reduce(math.max) + (rtl ? 0 : 8)
                      : (rtl ? width - 3 : centers.first + 8);
                  final order = [for (var i = 0; i < values.length; i++) i];
                  if (lastUsed >= 0) {
                    order.remove(lastUsed);
                    order.add(lastUsed);
                  }
                  if (active >= 0) {
                    order.remove(active);
                    order.add(active);
                  }
                  return SizedBox(
                    height: height + 8 + footerHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          height: height,
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (e) => beginPress(e, width),
                            onPointerMove: (e) => move(e, width),
                            onPointerUp: end,
                            onPointerCancel: end,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.recessed,
                                borderRadius: BorderRadius.circular(radius),
                                boxShadow: [
                                  BoxShadow(color: c.line, spreadRadius: 1),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: start,
                                    top: 3,
                                    width: math.max(0, finish - start),
                                    height: height - 6,
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: c.overlay,
                                          borderRadius: BorderRadius.circular(
                                            innerRadius,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: .1,
                                              ),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                            BoxShadow(
                                              color: c.line,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  for (final i in order)
                                    Positioned(
                                      key: ValueKey(i),
                                      left: centers[i] - 8,
                                      top: 3,
                                      width: 16,
                                      height: height - 6,
                                      child: FocusTraversalOrder(
                                        order: NumericFocusOrder(i.toDouble()),
                                        child: Focus(
                                          focusNode: nodes[i],
                                          canRequestFocus: enabled,
                                          includeSemantics: false,
                                          onKeyEvent: (_, e) => key(i, e),
                                          child: Semantics(
                                            sortKey: OrdinalSortKey(
                                              i.toDouble(),
                                            ),
                                            container: true,
                                            excludeSemantics: true,
                                            slider: true,
                                            enabled: enabled,
                                            focusable: enabled,
                                            focused: nodes[i].hasFocus,
                                            label: thumbLabel(i),
                                            value: valueText(values[i], i),
                                            minValue: '${widget.min}',
                                            maxValue: '${widget.max}',
                                            increasedValue:
                                                values[i] >= widget.max
                                                ? ''
                                                : valueText(
                                                    (values[i] +
                                                            widget
                                                                .effectiveStep)
                                                        .clamp(
                                                          widget.min,
                                                          widget.max,
                                                        ),
                                                    i,
                                                  ),
                                            decreasedValue:
                                                values[i] <= widget.min
                                                ? ''
                                                : valueText(
                                                    (values[i] -
                                                            widget
                                                                .effectiveStep)
                                                        .clamp(
                                                          widget.min,
                                                          widget.max,
                                                        ),
                                                    i,
                                                  ),
                                            onFocus: enabled
                                                ? () => nodes[i].requestFocus()
                                                : null,
                                            onDidGainAccessibilityFocus: enabled
                                                ? () {
                                                    setState(
                                                      () =>
                                                          keyboardFocus = true,
                                                    );
                                                    nodes[i].requestFocus();
                                                  }
                                                : null,
                                            onIncrease:
                                                enabled &&
                                                    values[i] < widget.max
                                                ? () => keyboardChange(
                                                    i,
                                                    rounded(values[i]) +
                                                        widget.effectiveStep,
                                                    SteySliderChangeReason
                                                        .accessibility,
                                                  )
                                                : null,
                                            onDecrease:
                                                enabled &&
                                                    values[i] > widget.min
                                                ? () => keyboardChange(
                                                    i,
                                                    rounded(values[i]) -
                                                        widget.effectiveStep,
                                                    SteySliderChangeReason
                                                        .accessibility,
                                                  )
                                                : null,
                                            child: MouseRegion(
                                              cursor: !enabled
                                                  ? SystemMouseCursors.forbidden
                                                  : pointer != null &&
                                                        active == i
                                                  ? SystemMouseCursors.grabbing
                                                  : SystemMouseCursors.grab,
                                              child: CustomPaint(
                                                foregroundPainter:
                                                    nodes[i].hasFocus &&
                                                        keyboardFocus
                                                    ? _SliderFocusRing(
                                                        c.focus,
                                                        innerRadius,
                                                      )
                                                    : null,
                                                child: Center(
                                                  child: Container(
                                                    width: 2,
                                                    height: (height - 6) / 2,
                                                    decoration: BoxDecoration(
                                                      color: c.contrast
                                                          .withValues(
                                                            alpha: .25,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            9999,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: height + 8,
                          left: 0,
                          right: 0,
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatter.format(widget.min),
                                  style: textStyle,
                                ),
                                Text(
                                  formatter.format(widget.max),
                                  style: textStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                        for (final i in order)
                          Positioned(
                            left: centers[i],
                            top: height + 8,
                            child: IgnorePointer(
                              child: ExcludeSemantics(
                                child: FractionalTranslation(
                                  translation: const Offset(-.5, 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: enabled ? c.contrast : c.fill,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      formatter.format(values[i]),
                                      style: textStyle.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: enabled ? c.inverse : c.text,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderFocusRing extends CustomPainter {
  const _SliderFocusRing(this.color, this.radius);
  final Color color;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(1),
      Radius.circular(radius + 1),
    ),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  @override
  bool shouldRepaint(_SliderFocusRing old) =>
      color != old.color || radius != old.radius;
}
