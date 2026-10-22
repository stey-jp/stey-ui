import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind, SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'messages.dart';
import 'theme.dart';

class SteyTab {
  const SteyTab(
    this.value,
    this.label, {
    this.disabled = false,
    this.child,
    this.semanticLabel,
  });
  final String value, label;
  final bool disabled;
  final Widget? child;
  final String? semanticLabel;
}

enum SteyTabsVariant { segmented, underline }

class SteyTabsLabels {
  const SteyTabsLabels({this.scrollStart, this.scrollEnd});
  final String? scrollStart, scrollEnd;
}

class SteyTabs extends StatefulWidget {
  const SteyTabs({
    super.key,
    this.tabs = const [],
    this.value,
    this.selectedValue,
    this.onChanged,
    this.onValueChange,
    this.activateOnFocus = false,
    this.variant = SteyTabsVariant.segmented,
    this.size = SteySize.base,
    this.label = 'Tabs',
    this.labels = const SteyTabsLabels(),
  });
  final List<SteyTab> tabs;
  final String? value, selectedValue;
  final ValueChanged<String>? onChanged, onValueChange;
  final bool activateOnFocus;
  final SteyTabsVariant variant;
  final SteySize size;
  final String label;
  final SteyTabsLabels labels;
  @override
  State<SteyTabs> createState() => _TabsState();
}

class _TabsState extends State<SteyTabs> with SingleTickerProviderStateMixin {
  final nodes = <String, FocusNode>{}, keys = <String, GlobalKey>{};
  final contentKey = GlobalKey();
  final scroll = ScrollController();
  final hovered = <String>{};
  final rects = <String, Rect>{};
  late String? internal =
      widget.selectedValue ?? widget.tabs.firstOrNull?.value;
  String? roving, pending, spacePressed;
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
    animationBehavior: AnimationBehavior.preserve,
  );
  RectTween? indicator;
  double viewport = 0, extent = 0;
  bool keyboardFocus = false, suppressClick = false;
  int? pointer;
  double pressX = 0, pressScroll = 0;
  bool get segmented => widget.variant == SteyTabsVariant.segmented;
  bool get small => widget.size == SteySize.sm;
  bool get rtl => Directionality.of(context) == TextDirection.rtl;
  double get height => segmented ? (small ? 26 : 36) : (small ? 26 : 30);
  double get tabHeight => segmented ? height - 4 : (small ? 20 : 24);
  String? get selected => widget.value ?? internal;
  Rect? get currentIndicator =>
      indicator?.transform(Curves.fastOutSlowIn.transform(animation.value));

  @override
  void initState() {
    super.initState();
    sync();
    scroll.addListener(scrolled);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.value == null &&
          widget.tabs.isNotEmpty &&
          !widget.tabs.any((t) => t.value == internal)) {
        final fallback = widget.tabs.where((t) => !t.disabled).firstOrNull;
        if (fallback != null) {
          choose(fallback.value);
        }
      }
    });
  }

  void sync() {
    final values = widget.tabs.map((t) => t.value).toSet();
    assert(values.length == widget.tabs.length, 'Tab values must be unique');
    for (final value in nodes.keys.toList()) {
      if (!values.contains(value)) {
        nodes.remove(value)!.dispose();
        keys.remove(value);
        rects.remove(value);
      }
    }
    for (final tab in widget.tabs) {
      if (!nodes.containsKey(tab.value)) {
        final node = FocusNode(debugLabel: 'SteyTab ${tab.value}');
        node.addListener(() => focusChanged(tab.value));
        nodes[tab.value] = node;
        keys[tab.value] = GlobalKey();
      }
    }
    if (roving == null ||
        !widget.tabs.any((t) => t.value == roving && !t.disabled)) {
      roving =
          widget.tabs
              .where((t) => !t.disabled && t.value == selected)
              .firstOrNull
              ?.value ??
          widget.tabs.where((t) => !t.disabled).firstOrNull?.value;
    }
  }

  @override
  void didUpdateWidget(SteyTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null) {
      if (widget.tabs.isEmpty) {
        internal = null;
      } else if (oldWidget.tabs.isEmpty) {
        internal = widget.selectedValue ?? widget.tabs.first.value;
      } else if (!widget.tabs.any((t) => t.value == internal)) {
        internal = widget.tabs.where((t) => !t.disabled).firstOrNull?.value;
        final next = internal;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && next != null && internal == next) {
            widget.onChanged?.call(next);
            widget.onValueChange?.call(next);
          }
        });
      }
    }
    sync();
    if (oldWidget.value != widget.value &&
        !nodes.values.any((n) => n.hasFocus)) {
      roving =
          widget.tabs
              .where((t) => !t.disabled && t.value == selected)
              .firstOrNull
              ?.value ??
          roving;
    }
  }

  @override
  void dispose() {
    scroll.removeListener(scrolled);
    scroll.dispose();
    animation.dispose();
    for (final node in nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void scrolled() {
    if (mounted) {
      setState(() {});
    }
  }

  void focusChanged(String value) {
    if (!mounted || !nodes.containsKey(value)) {
      return;
    }
    final focused = nodes[value]!.hasFocus;
    setState(() {
      if (focused) {
        roving = value;
        if (HardwareKeyboard.instance.logicalKeysPressed.isNotEmpty) {
          keyboardFocus = true;
        }
      }
    });
    if (focused) {
      if (widget.activateOnFocus) {
        choose(value);
      }
      reveal(value);
    }
  }

  void choose(String value) {
    if (value == selected ||
        value == pending ||
        widget.tabs.firstWhere((t) => t.value == value).disabled) {
      return;
    }
    setState(() {
      pending = value;
      if (widget.value == null) {
        internal = value;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && pending == value) {
        pending = null;
      }
    });
    widget.onChanged?.call(value);
    widget.onValueChange?.call(value);
  }

  void reveal(String value) {
    if (!scroll.hasClients || !rects.containsKey(value)) {
      return;
    }
    final rect = rects[value]!,
        total = scroll.position.maxScrollExtent + viewport;
    final start = rtl ? total - rect.right : rect.left;
    final end = start + rect.width, offset = scroll.offset;
    double? target;
    if (start < offset + 48) {
      target = start - 48;
    } else if (end > offset + viewport - 48) {
      target = end - viewport + 48;
    }
    if (target != null) {
      final next = target.clamp(0.0, scroll.position.maxScrollExtent);
      if ((next - offset).abs() > .1) {
        scroll.animateTo(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  KeyEventResult key(String value, KeyEvent event) {
    final k = event.logicalKey;
    if (event is KeyUpEvent) {
      if (k == LogicalKeyboardKey.space && spacePressed == value) {
        spacePressed = null;
        choose(value);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    setState(() => keyboardFocus = true);
    final available = widget.tabs.where((t) => !t.disabled).toList();
    if (available.isEmpty) {
      return KeyEventResult.ignored;
    }
    final index = available.indexWhere((t) => t.value == value);
    int? target;
    if (k == LogicalKeyboardKey.arrowRight) {
      target = (index + (rtl ? -1 : 1)) % available.length;
    }
    if (k == LogicalKeyboardKey.arrowLeft) {
      target = (index + (rtl ? 1 : -1)) % available.length;
    }
    if (k == LogicalKeyboardKey.home) {
      target = 0;
    }
    if (k == LogicalKeyboardKey.end) {
      target = available.length - 1;
    }
    if (target != null) {
      nodes[available[target].value]!.requestFocus();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter) {
      choose(value);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space) {
      spacePressed = value;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void measured() {
    if (!mounted) {
      return;
    }
    final content = contentKey.currentContext?.findRenderObject();
    if (content is! RenderBox || !content.hasSize) {
      return;
    }
    final next = <String, Rect>{};
    for (final tab in widget.tabs) {
      final box = keys[tab.value]?.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        next[tab.value] =
            box.localToGlobal(Offset.zero, ancestor: content) & box.size;
      }
    }
    rects
      ..clear()
      ..addAll(next);
    final active = next[selected];
    final target = active == null
        ? null
        : segmented
        ? active
        : Rect.fromLTWH(active.left, height - 3, active.width, 2);
    final max = scroll.hasClients ? scroll.position.maxScrollExtent : 0.0;
    if (target != indicator?.end || max != extent) {
      setState(() {
        extent = max;
        if (target == null) {
          indicator = null;
        } else if (indicator == null) {
          indicator = RectTween(begin: target, end: target);
          animation.value = 1;
        } else if (target != indicator!.end) {
          indicator = RectTween(begin: currentIndicator, end: target);
          animation.forward(from: 0);
        }
      });
    }
  }

  void begin(PointerDownEvent e) {
    if (e.kind != PointerDeviceKind.mouse ||
        e.buttons != 1 ||
        extent <= 1 ||
        !scroll.hasClients) {
      return;
    }
    pointer = e.pointer;
    pressX = e.position.dx;
    pressScroll = scroll.offset;
    suppressClick = false;
  }

  void move(PointerMoveEvent e) {
    if (pointer != e.pointer || !scroll.hasClients) {
      return;
    }
    final travel = e.position.dx - pressX;
    if (!suppressClick && travel.abs() <= 3) {
      return;
    }
    suppressClick = true;
    scroll.jumpTo(
      (pressScroll + (rtl ? travel : -travel)).clamp(
        0.0,
        scroll.position.maxScrollExtent,
      ),
    );
  }

  void end(PointerEvent e) {
    if (e.pointer != pointer) {
      return;
    }
    pointer = null;
    Timer.run(() {
      if (mounted) {
        suppressClick = false;
      }
    });
  }

  void scrollButton(bool left) {
    if (!scroll.hasClients) {
      return;
    }
    var width = 0.0;
    for (final tab in widget.tabs) {
      final next = rects[tab.value]?.width.roundToDouble() ?? 0;
      if (width + next > viewport) {
        break;
      }
      width += next;
    }
    final all = widget.tabs.fold(
      0.0,
      (n, t) => n + (rects[t.value]?.width.roundToDouble() ?? 0),
    );
    final distance = all <= viewport
        ? math.max(80.0, (viewport * .8).floorToDouble())
        : width == 0
        ? viewport
        : width;
    final direction = (left ? -1 : 1) * (rtl ? -1 : 1);
    scroll.animateTo(
      (scroll.offset + direction * distance).clamp(
        0.0,
        scroll.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return const SizedBox.shrink();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => measured());
    final c = SteyTheme.colorsOf(context), radius = small ? 6.0 : 8.0;
    final ja = SteyMessages.of(context).japanese;
    final label = widget.label == 'Tabs' && ja ? 'タブ' : widget.label;
    final style = TextStyle(
      fontFamily: 'Inter',
      package: 'stey_ui_modern',
      fontSize: small ? 12 : 14,
      height: small ? 16 / 12 : 1.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        viewport = constraints.maxWidth;
        assert(viewport.isFinite, 'Tabs needs a bounded width');
        final offset = scroll.hasClients ? scroll.offset : 0.0;
        final leftVisible = rtl ? extent - offset > 1 : offset > 1;
        final rightVisible = rtl ? offset > 1 : extent - offset > 1;
        return SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: segmented ? c.recessed : null,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: segmented
                  ? [
                      BoxShadow(
                        color: c.hairline.withValues(alpha: .7),
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(segmented ? radius : 0),
                  child: Listener(
                    onPointerDown: begin,
                    onPointerMove: move,
                    onPointerUp: end,
                    onPointerCancel: end,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(scrollbars: false, overscroll: false),
                      child: SingleChildScrollView(
                        controller: scroll,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Semantics(
                          role: SemanticsRole.tabBar,
                          container: true,
                          explicitChildNodes: true,
                          label: label,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: viewport),
                            child: _TabsMeasure(
                              onLayout: measured,
                              child: Stack(
                                key: contentKey,
                                clipBehavior: Clip.none,
                                children: [
                                  if (indicator != null)
                                    AnimatedBuilder(
                                      animation: animation,
                                      builder: (context, _) {
                                        final rect = currentIndicator!;
                                        return Positioned.fromRect(
                                          rect: rect,
                                          child: IgnorePointer(
                                            child: DecoratedBox(
                                              key: const ValueKey(
                                                'stey-tabs-indicator',
                                              ),
                                              decoration: BoxDecoration(
                                                color: segmented
                                                    ? c.base
                                                    : c.brand,
                                                borderRadius: segmented
                                                    ? BorderRadius.circular(
                                                        small ? 4 : 6,
                                                      )
                                                    : null,
                                                boxShadow: segmented
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: .1,
                                                              ),
                                                          offset: const Offset(
                                                            0,
                                                            1,
                                                          ),
                                                          blurRadius: 3,
                                                        ),
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: .1,
                                                              ),
                                                          offset: const Offset(
                                                            0,
                                                            1,
                                                          ),
                                                          blurRadius: 2,
                                                          spreadRadius: -1,
                                                        ),
                                                        BoxShadow(
                                                          color: c.line,
                                                          spreadRadius: 1,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: segmented ? 2 : 0,
                                      right: segmented ? 2 : 0,
                                      bottom: segmented ? 0 : 6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: segmented ? 0 : 16,
                                      children: [
                                        for (final tab in widget.tabs)
                                          SizedBox(
                                            height: segmented
                                                ? height
                                                : tabHeight,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: segmented ? 2 : 0,
                                              ),
                                              child: _tab(tab, style, c),
                                            ),
                                          ),
                                      ],
                                    ),
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
                if (!segmented)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 1,
                    child: IgnorePointer(child: ColoredBox(color: c.hairline)),
                  ),
                if (segmented)
                  for (final left in [true, false])
                    Positioned(
                      left: left ? 0 : null,
                      right: left ? null : 0,
                      top: 0,
                      bottom: 0,
                      width: small ? 32 : 40,
                      child: _TabsScrollControl(
                        left: left,
                        small: small,
                        visible: left ? leftVisible : rightVisible,
                        label: left
                            ? widget.labels.scrollStart ??
                                  (ja ? 'タブを左へスクロール' : 'Scroll tabs left')
                            : widget.labels.scrollEnd ??
                                  (ja ? 'タブを右へスクロール' : 'Scroll tabs right'),
                        onPressed: () => scrollButton(left),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tab(SteyTab tab, TextStyle style, SteyColors c) {
    final node = nodes[tab.value]!, active = selected == tab.value;
    final focusVisible = node.hasFocus && keyboardFocus;
    final tabRadius = segmented ? (small ? 2.0 : 6.0) : 4.0;
    void press() {
      if (tab.disabled || suppressClick) {
        return;
      }
      node.requestFocus();
      choose(tab.value);
      reveal(tab.value);
    }

    return SizedBox(
      key: keys[tab.value],
      height: tabHeight,
      child: Focus(
        focusNode: node,
        canRequestFocus: !tab.disabled,
        skipTraversal: tab.value != roving,
        includeSemantics: false,
        onKeyEvent: (_, e) => key(tab.value, e),
        child: Semantics(
          role: SemanticsRole.tab,
          container: true,
          excludeSemantics: true,
          selected: active,
          enabled: !tab.disabled,
          focused: !tab.disabled && tab.value == roving ? node.hasFocus : null,
          label: tab.semanticLabel ?? tab.label,
          onTap: tab.disabled ? null : press,
          onFocus: tab.disabled ? null : () => node.requestFocus(),
          onDidGainAccessibilityFocus: tab.disabled
              ? null
              : () {
                  setState(() => keyboardFocus = true);
                  node.requestFocus();
                },
          child: MouseRegion(
            cursor: tab.disabled
                ? SystemMouseCursors.forbidden
                : extent > 1
                ? pointer != null && suppressClick
                      ? SystemMouseCursors.grabbing
                      : SystemMouseCursors.grab
                : SystemMouseCursors.click,
            onEnter: (_) {
              setState(() => hovered.add(tab.value));
            },
            onExit: (_) {
              setState(() => hovered.remove(tab.value));
            },
            child: Listener(
              onPointerDown: (e) {
                if (!tab.disabled && e.buttons == 1) {
                  setState(() => keyboardFocus = false);
                  node.requestFocus();
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: tab.disabled ? null : press,
                child: CustomPaint(
                  foregroundPainter: focusVisible
                      ? _TabFocus(c.brand, tabRadius, segmented)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: !segmented && hovered.contains(tab.value)
                          ? c.tint
                          : null,
                      borderRadius: BorderRadius.circular(tabRadius),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: segmented
                          ? small
                                ? 8
                                : 10
                          : small
                          ? 6
                          : 8,
                    ),
                    alignment: Alignment.center,
                    child: IgnorePointer(
                      child: ExcludeFocus(
                        child: DefaultTextStyle(
                          style: style.copyWith(
                            color: active || hovered.contains(tab.value)
                                ? c.text
                                : c.subtle,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          child: tab.child ?? Text(tab.label),
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

class _TabsMeasure extends SingleChildRenderObjectWidget {
  const _TabsMeasure({required this.onLayout, required super.child});
  final VoidCallback onLayout;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _TabsMeasureBox(onLayout);
  @override
  void updateRenderObject(BuildContext context, _TabsMeasureBox object) {
    object.onLayout = onLayout;
  }
}

class _TabsMeasureBox extends RenderProxyBox {
  _TabsMeasureBox(this.onLayout);
  VoidCallback onLayout;
  @override
  void performLayout() {
    super.performLayout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) {
        onLayout();
      }
    });
  }
}

class _TabFocus extends CustomPainter {
  const _TabFocus(this.color, this.radius, this.inset);
  final Color color;
  final double radius;
  final bool inset;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).inflate(inset ? -1 : 1),
        Radius.circular(radius),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_TabFocus old) =>
      color != old.color || radius != old.radius || inset != old.inset;
}

class _TabsScrollControl extends StatefulWidget {
  const _TabsScrollControl({
    required this.left,
    required this.small,
    required this.visible,
    required this.label,
    required this.onPressed,
  });
  final bool left, small, visible;
  final String label;
  final VoidCallback onPressed;
  @override
  State<_TabsScrollControl> createState() => _TabsScrollControlState();
}

class _TabsScrollControlState extends State<_TabsScrollControl>
    with SingleTickerProviderStateMixin {
  final node = FocusNode();
  late final fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    value: widget.visible ? 1 : 0,
    animationBehavior: AnimationBehavior.preserve,
  );
  late final opacity = CurvedAnimation(
    parent: fade,
    curve: Curves.fastOutSlowIn,
  );
  bool hovered = false, focused = false;
  void press() {
    node.requestFocus();
    widget.onPressed();
  }

  @override
  void didUpdateWidget(_TabsScrollControl old) {
    super.didUpdateWidget(old);
    if (old.visible != widget.visible) {
      widget.visible ? fade.forward() : fade.reverse();
    }
  }

  @override
  void dispose() {
    node.dispose();
    opacity.dispose();
    fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context),
        radius = widget.small ? 6.0 : 8.0,
        side = widget.small ? 20.0 : 24.0;
    return ExcludeSemantics(
      excluding: !widget.visible,
      child: ExcludeFocus(
        excluding: !widget.visible,
        child: IgnorePointer(
          ignoring: !widget.visible,
          child: FadeTransition(
            opacity: opacity,
            child: FocusableActionDetector(
              focusNode: node,
              includeFocusSemantics: false,
              onFocusChange: (_) => setState(() {}),
              onShowFocusHighlight: (v) => setState(() => focused = v),
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    press();
                    return null;
                  },
                ),
              },
              child: Semantics(
                button: true,
                label: widget.label,
                focused: widget.visible ? node.hasFocus : null,
                onFocus: node.requestFocus,
                onTap: press,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => hovered = true),
                  onExit: (_) => setState(() => hovered = false),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap: press,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        gradient: LinearGradient(
                          begin: widget.left
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          end: widget.left
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          colors: [
                            c.recessed,
                            c.recessed.withValues(alpha: .95),
                            c.recessed.withValues(alpha: 0),
                          ],
                          stops: const [0, .5, 1],
                        ),
                      ),
                      child: Align(
                        alignment: widget.left
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Padding(
                          padding: widget.left
                              ? const EdgeInsets.only(left: 4)
                              : const EdgeInsets.only(right: 4),
                          child: CustomPaint(
                            foregroundPainter: focused
                                ? _TabFocus(
                                    c.brand,
                                    widget.small ? 2 : 6,
                                    false,
                                  )
                                : null,
                            child: SizedBox(
                              width: side,
                              height: side,
                              child: Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CustomPaint(
                                    painter: _TabArrow(
                                      widget.left,
                                      hovered ? c.text : c.subtle,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabArrow extends CustomPainter {
  const _TabArrow(this.left, this.color);
  final bool left;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 16, size.height / 16);
    final x = left ? 9.25 : 6.75, point = left ? 5.75 : 10.25;
    canvas.drawPath(
      Path()
        ..moveTo(x, 4.25)
        ..lineTo(point, 8)
        ..lineTo(x, 11.75),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TabArrow old) => left != old.left || color != old.color;
}
