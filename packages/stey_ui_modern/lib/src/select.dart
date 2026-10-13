import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'display.dart';
import 'input.dart';
import 'theme.dart';

sealed class SteySelectEntry<T> {
  const SteySelectEntry();
}

class SteySelectOption<T> extends SteySelectEntry<T> {
  const SteySelectOption({
    required this.value,
    required this.label,
    this.child,
    this.disabled = false,
  });
  final T value;
  final String label;
  final Widget? child;
  final bool disabled;
}

class SteySelectGroup<T> extends SteySelectEntry<T> {
  const SteySelectGroup({required this.label, required this.entries});
  final String label;
  final List<SteySelectEntry<T>> entries;
}

class SteySelectSeparator<T> extends SteySelectEntry<T> {
  const SteySelectSeparator();
}

/// Native Kumo select. Existing value/options/onChanged calls remain controlled.
/// Set controlled=false to use defaultValue/defaultValues and internal state.
class SteySelect<T> extends StatefulWidget {
  const SteySelect({
    super.key,
    this.value,
    this.options = const {},
    this.entries = const [],
    this.onChanged,
    this.defaultValue,
    this.controlled = true,
    this.multiple = false,
    this.values = const [],
    this.defaultValues = const [],
    this.onValuesChanged,
    this.label,
    this.semanticLabel,
    this.hideLabel = false,
    this.placeholder = 'Select an option',
    this.size = SteySize.base,
    this.error,
    this.description,
    this.required,
    this.labelTooltip,
    this.disabled = false,
    this.readOnly = false,
    this.loading = false,
    this.focusNode,
    this.autofocus = false,
    this.renderValue,
    this.renderValues,
    this.popupAbove = false,
    this.popupAlignment = AlignmentDirectional.centerStart,
    this.sideOffset = 4,
    this.alignOffset = 0,
    this.collisionPadding = 8,
    this.popupWidth,
    this.maxPopupHeight,
    this.onOpenChanged,
  });
  final T? value, defaultValue;
  final Map<T, String> options;
  final List<SteySelectEntry<T>> entries;
  final ValueChanged<T?>? onChanged;
  final List<T> values, defaultValues;
  final ValueChanged<List<T>>? onValuesChanged;
  final bool controlled, multiple, hideLabel, disabled, readOnly, loading;
  final bool autofocus, popupAbove;
  final String? label, semanticLabel, error, description, labelTooltip;
  final String placeholder;
  final bool? required;
  final SteySize size;
  final FocusNode? focusNode;
  final Widget Function(BuildContext, T)? renderValue;
  final Widget Function(BuildContext, List<T>)? renderValues;
  final AlignmentGeometry popupAlignment;
  final double sideOffset, alignOffset, collisionPadding;
  final double? popupWidth, maxPopupHeight;
  final ValueChanged<bool>? onOpenChanged;
  @override
  State<SteySelect<T>> createState() => _SteySelectState<T>();
}

class _SteySelectState<T> extends State<SteySelect<T>> {
  final portal = OverlayPortalController();
  final ownedFocus = FocusNode();
  final optionFocus = <T, FocusNode>{};
  final optionKeys = <T, GlobalKey>{};
  final popupFocus = FocusNode();
  late List<T> internal = widget.multiple
      ? List.of(widget.defaultValues)
      : [if (widget.defaultValue != null) widget.defaultValue as T];
  bool open = false, hovered = false, keyboardFocus = false;
  int active = -1;
  String typed = '';
  Timer? typingTimer;
  FocusNode get focus => widget.focusNode ?? ownedFocus;
  List<T> get selected => !widget.controlled
      ? internal
      : widget.multiple
      ? widget.values
      : [if (widget.value != null) widget.value as T];
  bool get enabled =>
      !widget.disabled &&
      !widget.loading &&
      (!widget.controlled ||
          widget.readOnly ||
          (widget.multiple
              ? widget.onValuesChanged != null
              : widget.onChanged != null));
  List<SteySelectEntry<T>> get entries => widget.entries.isNotEmpty
      ? widget.entries
      : [
          for (final entry in widget.options.entries)
            SteySelectOption<T>(value: entry.key, label: entry.value),
        ];
  Iterable<SteySelectOption<T>> flatten(List<SteySelectEntry<T>> source) sync* {
    for (final entry in source) {
      if (entry is SteySelectOption<T>) yield entry;
      if (entry is SteySelectGroup<T>) yield* flatten(entry.entries);
    }
  }

  List<SteySelectOption<T>> get items => flatten(entries).toList();
  @override
  void initState() {
    super.initState();
    focus.addListener(focusChanged);
    HardwareKeyboard.instance.addHandler(trackKeyboard);
  }

  bool trackKeyboard(KeyEvent event) {
    if (event is! KeyUpEvent && !keyboardFocus) {
      keyboardFocus = true;
      if (mounted && (focus.hasFocus || open)) setState(() {});
    }
    return false;
  }

  void focusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(SteySelect<T> old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? ownedFocus).removeListener(focusChanged);
      focus.addListener(focusChanged);
    }
    if (!enabled && open) close(restore: false);
    final valid = items.map((item) => item.value).toSet();
    for (final key in optionFocus.keys.toList()) {
      if (!valid.contains(key)) {
        optionFocus.remove(key)!.dispose();
        optionKeys.remove(key);
      }
    }
    if (active >= items.length) active = -1;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(trackKeyboard);
    typingTimer?.cancel();
    focus.removeListener(focusChanged);
    ownedFocus.dispose();
    popupFocus.dispose();
    for (final node in optionFocus.values) {
      node.dispose();
    }
    super.dispose();
  }

  void show({bool last = false}) {
    if (!enabled || open) return;
    typed = '';
    typingTimer?.cancel();
    final options = items;
    final selectedIndex = options.indexWhere(
      (item) => selected.contains(item.value) && !item.disabled,
    );
    active = selectedIndex >= 0
        ? selectedIndex
        : last
        ? options.lastIndexWhere((item) => !item.disabled)
        : options.indexWhere((item) => !item.disabled);
    setState(() => open = true);
    portal.show();
    widget.onOpenChanged?.call(true);
    focusActive();
  }

  void close({bool restore = true}) {
    if (!open) return;
    typed = '';
    typingTimer?.cancel();
    portal.hide();
    setState(() => open = false);
    widget.onOpenChanged?.call(false);
    if (restore && enabled) focus.requestFocus();
  }

  void focusActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !open) return;
      final options = items;
      if (active < 0 || active >= options.length) {
        popupFocus.requestFocus();
        return;
      }
      final value = options[active].value;
      optionFocus[value]?.requestFocus();
      final itemContext = optionKeys[value]?.currentContext;
      if (itemContext != null) {
        Scrollable.ensureVisible(
          itemContext,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  void move(int direction, {bool boundary = false}) {
    final options = items;
    var next = boundary
        ? (direction > 0 ? 0 : options.length - 1)
        : active + direction;
    while (next >= 0 && next < options.length && options[next].disabled) {
      next += direction;
    }
    if (next < 0 || next >= options.length) return;
    setState(() => active = next);
    focusActive();
  }

  void choose(T value) {
    if (!enabled || widget.readOnly) return;
    if (items.any((item) => item.value == value && item.disabled)) return;
    final wasSelected = selected.contains(value);
    final next = widget.multiple ? List.of(selected) : <T>[];
    if (widget.multiple && next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    if (!widget.controlled) setState(() => internal = next);
    if (widget.multiple) {
      widget.onValuesChanged?.call(List.unmodifiable(next));
    } else {
      if (!wasSelected) {
        widget.onChanged?.call(value);
      }
      close();
    }
  }

  KeyEventResult key(FocusNode node, KeyEvent event) {
    if (!enabled || event is KeyUpEvent) return KeyEventResult.ignored;
    final logical = event.logicalKey;
    if (logical == LogicalKeyboardKey.escape && open) {
      close();
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.tab && open) {
      close();
      if (HardwareKeyboard.instance.isShiftPressed) {
        focus.previousFocus();
      } else {
        focus.nextFocus();
      }
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.arrowDown ||
        logical == LogicalKeyboardKey.arrowUp) {
      final direction = logical == LogicalKeyboardKey.arrowDown ? 1 : -1;
      if (open) {
        move(direction);
      } else {
        show(last: direction < 0);
      }
      return KeyEventResult.handled;
    }
    if (open &&
        (logical == LogicalKeyboardKey.home ||
            logical == LogicalKeyboardKey.end)) {
      move(logical == LogicalKeyboardKey.home ? 1 : -1, boundary: true);
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.enter ||
        (logical == LogicalKeyboardKey.space && typed.isEmpty)) {
      if (!open) {
        show();
      } else if (active >= 0 && active < items.length) {
        choose(items[active].value);
      }
      return KeyEventResult.handled;
    }
    final character = event.character;
    if (character != null &&
        character.runes.length == 1 &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed &&
        !HardwareKeyboard.instance.isAltPressed &&
        (open || (!widget.multiple && !widget.readOnly))) {
      typed += character.toLowerCase();
      typingTimer?.cancel();
      typingTimer = Timer(const Duration(milliseconds: 750), () => typed = '');
      final repeated = typed.split('').every((letter) => letter == typed[0]);
      final search = repeated ? typed[0] : typed;
      final options = items;
      final start = open
          ? active
          : options.indexWhere((item) => selected.contains(item.value));
      for (var step = 1; step <= options.length; step++) {
        final index = (start + step) % options.length;
        if (!options[index].disabled &&
            options[index].label.toLowerCase().startsWith(search)) {
          if (open) {
            setState(() => active = index);
            focusActive();
          } else {
            choose(options[index].value);
          }
          break;
        }
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.options.isEmpty || widget.entries.isEmpty);
    final options = items;
    assert(options.map((item) => item.value).toSet().length == options.length);
    final c = SteyTheme.colorsOf(context);
    final labels = [
      for (final value in selected)
        for (final option in options)
          if (option.value == value) option.label,
    ];
    final hasValue = selected.isNotEmpty;
    final keyboard = focus.hasFocus && keyboardFocus;
    final radius = widget.size == SteySize.xs ? 4.0 : widget.size.radius;
    final error = widget.error?.isNotEmpty ?? false;
    final foreground = hasValue
        ? enabled
              ? c.text
              : c.text.withValues(alpha: .7)
        : c.placeholder;
    final rendered = hasValue
        ? widget.multiple
              ? widget.renderValues?.call(context, selected)
              : widget.renderValue?.call(context, selected.first)
        : null;
    final trigger = Focus(
      focusNode: focus,
      autofocus: widget.autofocus,
      canRequestFocus: enabled,
      onKeyEvent: key,
      child: Semantics(
        button: true,
        label: widget.semanticLabel ?? widget.label ?? widget.placeholder,
        value: widget.loading ? 'Loading' : labels.join(', '),
        hint: error ? widget.error : widget.description,
        enabled: enabled,
        expanded: open,
        isRequired: widget.required,
        onTap: enabled ? () => open ? close() : show() : null,
        onExpand: enabled && !open ? show : null,
        onCollapse: enabled && open ? close : null,
        child: ExcludeSemantics(
          child: MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            onEnter: (_) => setState(() {
              hovered = true;
              keyboardFocus = false;
            }),
            onExit: (_) => setState(() => hovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: enabled
                  ? (_) => setState(() => keyboardFocus = false)
                  : null,
              onTap: enabled
                  ? () {
                      focus.requestFocus();
                      open ? close() : show();
                    }
                  : null,
              child: Opacity(
                opacity: widget.disabled || (!enabled && !widget.loading)
                    ? .5
                    : 1,
                child: CustomPaint(
                  foregroundPainter: _SelectRing(
                    error
                        ? c.danger.withValues(alpha: focus.hasFocus ? .5 : 1)
                        : keyboard
                        ? c.brand
                        : focus.hasFocus
                        ? c.focus.withValues(alpha: .5)
                        : c.line,
                    width: error && focus.hasFocus
                        ? 1.5
                        : keyboard
                        ? 2
                        : 1,
                    radius: radius,
                    inset: keyboard && !error,
                  ),
                  child: Container(
                    height: widget.size.height,
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.size.padding,
                    ),
                    decoration: BoxDecoration(
                      color: hovered && enabled
                          ? c.tint
                          : enabled
                          ? c.control
                          : c.control.withValues(alpha: .5),
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DefaultTextStyle.merge(
                            style: TextStyle(
                              fontSize: widget.size.fontSize,
                              fontWeight: FontWeight.w400,
                              color: foreground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: widget.loading
                                ? const Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: SteySkeletonLine(width: 128),
                                  )
                                : rendered ??
                                      Text(
                                        hasValue
                                            ? labels.join(', ')
                                            : widget.placeholder,
                                      ),
                          ),
                        ),
                        SizedBox(
                          width: widget.size == SteySize.lg
                              ? 8
                              : widget.size == SteySize.base
                              ? 6
                              : 4,
                        ),
                        CustomPaint(
                          size: Size.square(switch (widget.size) {
                            SteySize.xs => 12,
                            SteySize.sm => 14,
                            SteySize.base => 16,
                            SteySize.lg => 18,
                          }),
                          painter: _SelectIcon(c.subtle),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return PopScope(
      canPop: !open,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && open) close();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null && !widget.hideLabel) ...[
            SteyLabel(
              widget.label!,
              required: widget.required,
              tooltip: widget.labelTooltip,
              excludeTextSemantics: true,
            ),
            const SizedBox(height: 8),
          ],
          OverlayPortal.overlayChildLayoutBuilder(
            controller: portal,
            overlayChildBuilder: (context, info) => popup(context, info),
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              child: trigger,
            ),
          ),
          if (error || widget.description != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: error,
              child: Text(
                (error ? widget.error : widget.description)!,
                style: TextStyle(
                  fontSize: 13,
                  height: error ? 1 / .85 : 1.375,
                  color: error ? c.dangerText : c.subtle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget popup(BuildContext context, OverlayChildLayoutInfo info) {
    final c = SteyTheme.colorsOf(context);
    final options = items;
    List<Widget> children(List<SteySelectEntry<T>> source) => [
      for (final entry in source)
        if (entry is SteySelectSeparator<T>)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            height: 1,
            color: c.hairline,
          )
        else if (entry is SteySelectGroup<T>)
          Semantics(
            container: true,
            explicitChildNodes: true,
            label: entry.label,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Text(
                      entry.label,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1 / .85,
                        fontWeight: FontWeight.w600,
                        color: c.subtle,
                      ),
                    ),
                  ),
                ),
                ...children(entry.entries),
              ],
            ),
          )
        else if (entry is SteySelectOption<T>)
          option(
            context,
            entry,
            options.indexWhere((item) => item.value == entry.value),
          ),
    ];
    final anchor = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    // SafeArea removes inherited padding. Use original view metrics in this
    // overlay's coordinates, including keyboard insets.
    final metrics = MediaQueryData.fromView(View.of(context));
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final origin = overlayBox.localToGlobal(Offset.zero);
    final safeBounds =
        Rect.fromLTRB(
              math.max(metrics.viewPadding.left, metrics.viewInsets.left),
              math.max(metrics.viewPadding.top, metrics.viewInsets.top),
              metrics.size.width -
                  math.max(metrics.viewPadding.right, metrics.viewInsets.right),
              metrics.size.height -
                  math.max(
                    metrics.viewPadding.bottom,
                    metrics.viewInsets.bottom,
                  ),
            )
            .shift(-origin)
            .intersect(Offset.zero & info.overlaySize)
            .deflate(widget.collisionPadding);
    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: close,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        ),
        CustomSingleChildLayout(
          delegate: _SelectPopupLayout(
            anchor: anchor,
            above: widget.popupAbove,
            alignment: widget.popupAlignment
                .resolve(Directionality.of(context))
                .x,
            gap: widget.sideOffset,
            offset: widget.alignOffset,
            available: safeBounds,
            width: widget.popupWidth,
            maxHeight: widget.maxPopupHeight,
          ),
          child: Focus(
            focusNode: popupFocus,
            skipTraversal: true,
            descendantsAreTraversable: false,
            onKeyEvent: key,
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              role: SemanticsRole.list,
              label: widget.semanticLabel ?? widget.label ?? widget.placeholder,
              child: CustomPaint(
                foregroundPainter: _SelectRing(c.line, radius: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.base,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .1),
                        blurRadius: 15,
                        spreadRadius: -3,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .1),
                        blurRadius: 6,
                        spreadRadius: -4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      children: children(entries),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget option(BuildContext context, SteySelectOption<T> item, int index) {
    final c = SteyTheme.colorsOf(context);
    final node = optionFocus.putIfAbsent(item.value, () => FocusNode());
    final itemKey = optionKeys.putIfAbsent(item.value, GlobalKey.new);
    final highlighted = active == index;
    final checked = selected.contains(item.value);
    final keyboard = keyboardFocus;
    return Focus(
      focusNode: node,
      canRequestFocus: !item.disabled,
      skipTraversal: true,
      onFocusChange: (focused) {
        if (focused && active != index) setState(() => active = index);
      },
      child: Semantics(
        button: true,
        label: item.label,
        selected: checked,
        enabled: !item.disabled,
        onTap: item.disabled ? null : () => choose(item.value),
        child: ExcludeSemantics(
          child: MouseRegion(
            cursor: item.disabled
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.click,
            onEnter: item.disabled
                ? null
                : (_) {
                    setState(() {
                      active = index;
                      keyboardFocus = false;
                    });
                    node.requestFocus();
                  },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: item.disabled ? null : () => choose(item.value),
              child: Opacity(
                opacity: item.disabled ? .5 : 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: CustomPaint(
                    foregroundPainter: highlighted && keyboard
                        ? _SelectRing(c.brand, width: 2, radius: 4, inset: true)
                        : null,
                    child: Container(
                      key: itemKey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: highlighted ? c.tint : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: DefaultTextStyle.merge(
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                                color: c.text,
                              ),
                              child: item.child ?? Text(item.label),
                            ),
                          ),
                          if (checked) ...[
                            const SizedBox(width: 8),
                            CustomPaint(
                              size: const Size.square(14),
                              painter: _SelectIcon(c.text, check: true),
                            ),
                          ],
                        ],
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
}

class _SelectPopupLayout extends SingleChildLayoutDelegate {
  _SelectPopupLayout({
    required this.anchor,
    required this.above,
    required this.alignment,
    required this.gap,
    required this.offset,
    required this.available,
    this.width,
    this.maxHeight,
  });
  final Rect anchor;
  final Rect available;
  final bool above;
  final double alignment, gap, offset;
  final double? width, maxHeight;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final availableWidth = math.max(0.0, available.width);
    final popupWidth = (width ?? anchor.width).clamp(0.0, availableWidth);
    final room = math.max(
      anchor.top - gap - available.top,
      available.bottom - anchor.bottom - gap,
    );
    return BoxConstraints(
      minWidth: popupWidth,
      maxWidth: popupWidth,
      maxHeight: math.max(0, math.min(room, maxHeight ?? double.infinity)),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final below = available.bottom - anchor.bottom - gap;
    final top = anchor.top - gap - available.top;
    final flip = above
        ? childSize.height > top && below > top
        : childSize.height > below && top > below;
    final atTop = above != flip;
    final x =
        anchor.left +
        (anchor.width - childSize.width) * (alignment + 1) / 2 +
        offset;
    return Offset(
      x.clamp(
        available.left,
        math.max(available.left, available.right - childSize.width),
      ),
      (atTop ? anchor.top - gap - childSize.height : anchor.bottom + gap).clamp(
        available.top,
        math.max(available.top, available.bottom - childSize.height),
      ),
    );
  }

  @override
  bool shouldRelayout(_SelectPopupLayout old) =>
      anchor != old.anchor ||
      above != old.above ||
      alignment != old.alignment ||
      gap != old.gap ||
      offset != old.offset ||
      available != old.available ||
      width != old.width ||
      maxHeight != old.maxHeight;
}

class _SelectRing extends CustomPainter {
  const _SelectRing(
    this.color, {
    this.width = 1,
    required this.radius,
    this.inset = false,
  });
  final Color color;
  final double width, radius;
  final bool inset;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(inset ? -width / 2 : width / 2),
      Radius.circular(radius),
    ),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width,
  );
  @override
  bool shouldRepaint(_SelectRing old) =>
      color != old.color ||
      width != old.width ||
      radius != old.radius ||
      inset != old.inset;
}

class _SelectIcon extends CustomPainter {
  const _SelectIcon(this.color, {this.check = false});
  final Color color;
  final bool check;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (check) {
      path.moveTo(40, 144);
      path.lineTo(96, 200);
      path.lineTo(224, 72);
    } else {
      path.moveTo(80, 80);
      path.lineTo(128, 32);
      path.lineTo(176, 80);
      path.moveTo(80, 176);
      path.lineTo(128, 224);
      path.lineTo(176, 176);
    }
    canvas.save();
    canvas.scale(size.width / 256, size.height / 256);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SelectIcon old) =>
      color != old.color || check != old.check;
}
