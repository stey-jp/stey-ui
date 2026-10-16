import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'theme.dart';

/// A menu action, or a submenu when [children] is nonempty.
class SteyMenuItem {
  const SteyMenuItem(
    this.label, {
    this.onPressed,
    this.icon,
    this.leading,
    this.child,
    this.disabled = false,
    this.destructive = false,
    this.checked,
    this.inset = false,
    this.shortcut,
    this.href,
    this.closeOnActivate = true,
    this.children = const [],
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading, child;
  final bool disabled, destructive, inset, closeOnActivate;
  final bool? checked;
  final String? shortcut;

  /// Link semantics; the caller performs navigation in [onPressed].
  final Uri? href;
  final List<SteyMenuItem> children;
  bool get enabled => !disabled && (onPressed != null || children.isNotEmpty);
  bool? get selection => checked;
  SemanticsRole get role => SemanticsRole.menuItem;
  void activate() => onPressed?.call();
}

class SteyMenuGroup extends SteyMenuItem {
  const SteyMenuGroup(super.label, {required super.children, super.inset});
}

class SteyMenuSeparator extends SteyMenuItem {
  const SteyMenuSeparator() : super('');
}

class SteyMenuCheckboxItem extends SteyMenuItem {
  const SteyMenuCheckboxItem(
    super.label, {
    required bool value,
    this.onChanged,
    super.disabled,
    super.closeOnActivate,
    super.shortcut,
  }) : super(checked: value);
  final ValueChanged<bool>? onChanged;
  @override
  bool get enabled => !disabled && onChanged != null;
  @override
  SemanticsRole get role => SemanticsRole.menuItemCheckbox;
  @override
  void activate() => onChanged?.call(!checked!);
}

class SteyMenuRadioItem<T> extends SteyMenuItem {
  const SteyMenuRadioItem(
    super.label, {
    required this.value,
    required this.groupValue,
    this.onChanged,
    super.icon,
    super.leading,
    super.inset,
    super.disabled,
    super.closeOnActivate,
  });
  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;
  @override
  bool get enabled => !disabled && onChanged != null;
  @override
  bool get selection => value == groupValue;
  @override
  SemanticsRole get role => SemanticsRole.menuItemRadio;
  @override
  void activate() => onChanged?.call(value);
}

/// Native cascading menus; [controller] can also open and close the root.
class SteyDropdownMenu extends StatefulWidget {
  const SteyDropdownMenu({
    super.key,
    required this.items,
    required this.child,
    this.controller,
    this.onOpenChanged,
    this.disabled = false,
    this.label,
    this.width,
    this.sideOffset = 8,
    this.alignOffset = 0,
    this.submenuSideOffset = 2,
    this.collisionBoundary,
    this.collisionPadding = const EdgeInsets.all(5),
    this.sticky = false,
    this.triggerBuilder,
  }) : assert(width == null || width >= 144);
  final List<SteyMenuItem> items;
  final Widget child;
  final MenuController? controller;
  final ValueChanged<bool>? onOpenChanged;
  final bool disabled;
  final String? label;
  final double? width;
  final double sideOffset, alignOffset, submenuSideOffset;

  /// Collision rectangle in root-overlay logical pixels. Intersected with the
  /// viewport; null uses the viewport. Applies to every level of this menu.
  /// Rebuild with a new rectangle when the containing region moves or resizes.
  final Rect? collisionBoundary;

  /// Physical insets inside the collision boundary, including in RTL layouts.
  final EdgeInsets collisionPadding;

  /// Keep every popup inside its collision boundary when the anchor leaves
  /// that region. The default instead limits shifting to stay attached.
  final bool sticky;

  /// Custom native trigger. Use the supplied callback and focus node so menu
  /// dismissal restores focus and the existing keyboard shortcuts still apply.
  final Widget Function(BuildContext, VoidCallback?, FocusNode)? triggerBuilder;
  @override
  State<SteyDropdownMenu> createState() => _DropdownState();
}

class _DropdownState extends State<SteyDropdownMenu>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final internalController = MenuController();
  final triggerFocus = FocusNode();
  final menuFocus = FocusScopeNode();
  final panelKey = GlobalKey<_MenuPanelState>();
  final placement = _MenuPlacement();
  late final motion = AnimationController(
    vsync: this,
    duration: _menuDuration,
    animationBehavior: AnimationBehavior.preserve,
  );
  bool open = false;
  final input = _MenuInput();
  bool instantOpen = false, instantClose = true;
  int revision = 0;
  ScrollPosition? ancestorScroll;
  Size? viewSize;
  bool resizing = false, scrollNotification = false, explicitClose = false;
  MenuController get controller => widget.controller ?? internalController;

  void closeMenu(bool instant) {
    if (!open) return;
    instantClose = instant;
    explicitClose = true;
    try {
      controller.close();
    } finally {
      explicitClose = false;
    }
  }

  void ancestorScrolled() {
    if (!open) return;
    // RawMenuAnchor registers its listener after this parent. Its automatic
    // close request is synchronous with this notifier, not the whole scroll.
    scrollNotification = true;
    scheduleMicrotask(() => scrollNotification = false);
  }

  void requestHide(VoidCallback hideOverlay) {
    final metricNotification =
        resizing &&
        SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.postFrameCallbacks;
    if (!explicitClose && (metricNotification || scrollNotification)) {
      resizing = false;
      scrollNotification = false;
      return;
    }
    hide(hideOverlay);
  }

  void toggle() {
    if (open) {
      closeMenu(input.keyboard);
    } else {
      instantOpen = input.keyboard;
      controller.open();
    }
    input.keyboard = false;
  }

  void show(Offset? position, VoidCallback showOverlay) {
    revision++;
    instantClose = true;
    showOverlay();
    if (instantOpen) {
      motion.value = 1;
    } else {
      motion.animateTo(1, duration: _menuDuration, curve: _menuCurve);
    }
    instantOpen = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && open) panelKey.currentState?.focusPanel();
    });
  }

  void hide(VoidCallback hideOverlay) {
    if (!open) return;
    final request = ++revision;
    changed(false);
    if (revision != request) return;
    panelKey.currentState?.closeChild?.call(instantClose);
    if (menuFocus.hasFocus) triggerFocus.requestFocus();
    if (instantClose) {
      motion.value = 0;
      hideOverlay();
    } else {
      motion.animateBack(0, duration: _menuDuration, curve: _menuCurve).then((
        _,
      ) {
        if (mounted && revision == request) hideOverlay();
      });
    }
    instantClose = true;
  }

  void openFromKeyboard(bool last) {
    if (widget.disabled || widget.items.isEmpty) return;
    controller.open();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) panelKey.currentState?.focusBoundary(last);
    });
  }

  void changed(bool value) {
    if (open == value) return;
    input.active = value;
    setState(() => open = value);
    widget.onOpenChanged?.call(value);
  }

  KeyEventResult keyEvent(KeyEvent event) {
    input.keyEvent(event);
    if (open &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (input.dismissals.isEmpty) {
        closeMenu(true);
      } else {
        input.dismissals.last(true);
      }
      return KeyEventResult.handled;
    }
    final back = Directionality.of(context) == TextDirection.rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (open &&
        event is KeyDownEvent &&
        event.logicalKey == back &&
        input.dismissals.isNotEmpty) {
      input.dismissals.last(false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addEarlyKeyEventHandler(keyEvent);
  }

  @override
  void didChangeMetrics() {
    if (!open) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && open) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = Scrollable.maybeOf(context)?.position;
    if (scroll != ancestorScroll) {
      ancestorScroll?.isScrollingNotifier.removeListener(ancestorScrolled);
      ancestorScroll = scroll;
      scroll?.isScrollingNotifier.addListener(ancestorScrolled);
    }
    final size = MediaQuery.sizeOf(context);
    if (viewSize != null && viewSize != size && open) {
      resizing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // RawMenuAnchor also defers its resize close until post-frame. Clear
        // only after those callbacks have delivered their single request.
        scheduleMicrotask(() => resizing = false);
      });
    }
    viewSize = size;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeEarlyKeyEventHandler(keyEvent);
    ancestorScroll?.isScrollingNotifier.removeListener(ancestorScrolled);
    input.dispose();
    motion.dispose();
    menuFocus.dispose();
    triggerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !open,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) closeMenu(true);
    },
    child: RawMenuAnchor(
      controller: controller,
      childFocusNode: triggerFocus,
      useRootOverlay: true,
      consumeOutsideTaps: true,
      onOpenRequested: show,
      onCloseRequested: requestHide,
      onOpen: () => changed(true),
      overlayBuilder: (context, info) => _MenuTransition(
        motion: motion,
        origin: () => placement.origin,
        child: CustomSingleChildLayout(
          delegate: _MenuPositioner(
            info: info,
            media: _menuMedia(context),
            direction: Directionality.of(context),
            width: widget.width,
            offset: Offset(widget.alignOffset, widget.sideOffset),
            placement: placement,
            boundary: widget.collisionBoundary,
            padding: widget.collisionPadding,
            sticky: widget.sticky,
          ),
          child: Listener(
            onPointerDown: (_) => input.keyboard = false,
            child: TapRegion(
              groupId: info.tapRegionGroupId,
              onTapOutside: (_) => closeMenu(false),
              child: IntrinsicWidth(
                child: _MenuSurface(
                  child: FocusScope(
                    node: menuFocus,
                    child: _MenuPanel(
                      key: panelKey,
                      items: widget.items,
                      rootController: controller,
                      closeRoot: closeMenu,
                      input: input,
                      direction: Directionality.of(context),
                      label: widget.label,
                      submenuSideOffset: widget.submenuSideOffset,
                      boundary: widget.collisionBoundary,
                      padding: widget.collisionPadding,
                      sticky: widget.sticky,
                      width: widget.width,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      builder: (context, controller, _) => CallbackShortcuts(
        bindings: {
          if (open)
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                closeMenu(true),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              openFromKeyboard(false),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              openFromKeyboard(true),
        },
        child: Listener(
          onPointerDown: (_) => input.keyboard = false,
          child: Semantics(
            expanded: open,
            child:
                widget.triggerBuilder?.call(
                  context,
                  widget.disabled || widget.items.isEmpty ? null : toggle,
                  triggerFocus,
                ) ??
                SteyButton(
                  focusNode: triggerFocus,
                  semanticLabel: widget.label,
                  onPressed: widget.disabled || widget.items.isEmpty
                      ? null
                      : toggle,
                  trailing: const Icon(Icons.expand_more, size: 16),
                  child: widget.child,
                ),
          ),
        ),
      ),
    ),
  );
}

class _MenuInput {
  bool keyboard = false, active = false;
  final dismissals = <ValueChanged<bool>>[];
  final geometryObservers = <VoidCallback>{};
  int geometryEpoch = 0;

  void observeGeometry(VoidCallback observer) {
    geometryObservers.add(observer);
    if (geometryObservers.length != 1) return;
    final epoch = ++geometryEpoch;
    void afterLayout(Duration _) {
      if (epoch != geometryEpoch) return;
      for (final observer in geometryObservers.toList()) {
        observer();
      }
      if (epoch == geometryEpoch) {
        // Observe frames produced by layout/scroll/animation. Do not request
        // frames when nothing changes or keep a ticker running while idle.
        WidgetsBinding.instance.addPostFrameCallback(afterLayout);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void unobserveGeometry(VoidCallback observer) {
    geometryObservers.remove(observer);
    if (geometryObservers.isEmpty) geometryEpoch++;
  }

  void dispose() {
    geometryObservers.clear();
    geometryEpoch++;
  }

  KeyEventResult keyEvent(KeyEvent event) {
    keyboard =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space;
    return KeyEventResult.ignored;
  }
}

const _menuDuration = Duration(milliseconds: 150);
const _menuCurve = Curves.fastOutSlowIn;

MediaQueryData _menuMedia(BuildContext context) {
  final media = MediaQuery.of(context), view = View.of(context);
  EdgeInsets includeView(EdgeInsets local, EdgeInsets physical) =>
      EdgeInsets.fromLTRB(
        math.max(local.left, physical.left),
        math.max(local.top, physical.top),
        math.max(local.right, physical.right),
        math.max(local.bottom, physical.bottom),
      );
  // A Scaffold may already have removed the keyboard/notch insets from the
  // anchor's MediaQuery. Root overlays still span the complete Flutter view.
  return media.copyWith(
    padding: includeView(
      media.padding,
      EdgeInsets.fromViewPadding(view.padding, view.devicePixelRatio),
    ),
    viewInsets: includeView(
      media.viewInsets,
      EdgeInsets.fromViewPadding(view.viewInsets, view.devicePixelRatio),
    ),
  );
}

class _MenuPlacement {
  Offset origin = Offset.zero;
}

Rect _menuSafe(
  Size size,
  MediaQueryData media,
  Rect? boundary,
  EdgeInsets padding,
) {
  assert(padding.isNonNegative);
  final region = boundary ?? Offset.zero & size;
  final left = math.max(
    media.padding.left,
    math.max(0.0, region.left) + padding.left,
  );
  final top = math.max(
    media.padding.top,
    math.max(0.0, region.top) + padding.top,
  );
  final right = math.min(
    size.width - media.padding.right,
    math.min(size.width, region.right) - padding.right,
  );
  final bottom = math.min(
    size.height -
        math.max(
          media.padding.bottom,
          media.viewInsets.bottom + padding.bottom,
        ),
    math.min(size.height, region.bottom) - padding.bottom,
  );
  return Rect.fromLTRB(left, top, math.max(left, right), math.max(top, bottom));
}

// Floating UI's default limitShift keeps an offscreen popup attached to its
// reference rather than pinning a detached menu to the viewport edge.
double _attachedShift(double value, double start, double end, double extent) =>
    value.clamp(start - extent, end);

enum _MenuSide { right, left, bottom, top }

/// Default Base UI submenu order: preferred side/start, its end alignment,
/// opposite side/start/end, then bottom/start, top/start, bottom/end, top/end.
/// Only leave the horizontal axis when neither horizontal side has room.
({Rect rect, Offset origin}) _submenuPlacement({
  required Rect anchor,
  required Rect safe,
  required Size size,
  required TextDirection direction,
  required double sideOffset,
  required bool sticky,
}) {
  if (sticky) size = Size(size.width, math.min(size.height, safe.height));
  final rtl = direction == TextDirection.rtl;
  final preferred = rtl ? _MenuSide.left : _MenuSide.right;
  final opposite = rtl ? _MenuSide.right : _MenuSide.left;
  final candidates = [
    for (final side in [preferred, opposite])
      for (final end in [false, true]) (side: side, end: end),
    for (final end in [false, true])
      for (final side in [_MenuSide.bottom, _MenuSide.top])
        (side: side, end: end),
  ];
  Rect position(_MenuSide side, bool end, double height) {
    final vertical = side == _MenuSide.top || side == _MenuSide.bottom;
    return Rect.fromLTWH(
      vertical
          ? (end != rtl ? anchor.right - size.width : anchor.left)
          : side == _MenuSide.left
          ? anchor.left - size.width - sideOffset
          : anchor.right + sideOffset,
      vertical
          ? side == _MenuSide.top
                ? anchor.top - height - 8
                : anchor.bottom + 8
          : end
          ? anchor.bottom - height + 6
          : anchor.top - 6,
      size.width,
      height,
    );
  }

  final tried = <({int index, double main, double cross, double total})>[];
  var chosen = 0;
  for (var i = 0; i < candidates.length; i++) {
    if (i == 4 && tried.any((entry) => entry.main <= 0)) break;
    final candidate = candidates[i];
    final rect = position(candidate.side, candidate.end, size.height);
    final overflow = {
      _MenuSide.left: safe.left + 1 + (rtl ? 1 : 0) - rect.left,
      _MenuSide.right: rect.right - safe.right + 1 + (rtl ? 0 : 1),
      _MenuSide.top: safe.top + 1 - rect.top,
      _MenuSide.bottom: rect.bottom - safe.bottom + 1,
    };
    final vertical =
        candidate.side == _MenuSide.top || candidate.side == _MenuSide.bottom;
    var cross = vertical
        ? candidate.end == rtl
              ? _MenuSide.right
              : _MenuSide.left
        : candidate.end
        ? _MenuSide.top
        : _MenuSide.bottom;
    if (vertical ? anchor.width > size.width : anchor.height > size.height) {
      cross = switch (cross) {
        _MenuSide.right => _MenuSide.left,
        _MenuSide.left => _MenuSide.right,
        _MenuSide.top => _MenuSide.bottom,
        _MenuSide.bottom => _MenuSide.top,
      };
    }
    final main = overflow[candidate.side]!;
    final crossValue = overflow[cross]!;
    final values = vertical
        ? [main, overflow[_MenuSide.left]!, overflow[_MenuSide.right]!]
        : [main, overflow[_MenuSide.top]!, overflow[_MenuSide.bottom]!];
    tried.add((
      index: i,
      main: main,
      cross: crossValue,
      total: values.fold(0.0, (sum, value) => sum + math.max(0, value)),
    ));
    chosen = i;
    if (values.every((value) => value <= 0)) break;
    final fitting = tried.where((entry) => entry.main <= 0).toList();
    final ranked = fitting.isEmpty ? tried.toList() : fitting;
    ranked.sort((a, b) {
      final order = fitting.isEmpty
          ? a.total.compareTo(b.total)
          : a.cross.compareTo(b.cross);
      return order == 0 ? a.index.compareTo(b.index) : order;
    });
    chosen = ranked.first.index;
  }
  final candidate = candidates[chosen];
  final vertical =
      candidate.side == _MenuSide.top || candidate.side == _MenuSide.bottom;
  var rect = position(candidate.side, candidate.end, size.height);
  final availableHeight = vertical && !sticky
      ? candidate.side == _MenuSide.top
            ? rect.bottom - safe.top
            : safe.bottom - rect.top
      : safe.height;
  rect = position(
    candidate.side,
    candidate.end,
    math.min(size.height, math.max(0, math.min(safe.height, availableHeight))),
  );
  final unshifted = rect;
  rect = sticky
      ? Rect.fromLTWH(
          rect.left.clamp(
            safe.left,
            math.max(safe.left, safe.right - rect.width),
          ),
          rect.top.clamp(
            safe.top,
            math.max(safe.top, safe.bottom - rect.height),
          ),
          rect.width,
          rect.height,
        )
      : rect.shift(
          vertical
              ? Offset(
                  _attachedShift(
                        rect.left.clamp(
                          safe.left,
                          math.max(safe.left, safe.right - rect.width),
                        ),
                        anchor.left,
                        anchor.right,
                        rect.width,
                      ) -
                      rect.left,
                  0,
                )
              : Offset(
                  0,
                  _attachedShift(
                        rect.top.clamp(
                          safe.top,
                          math.max(safe.top, safe.bottom - rect.height),
                        ),
                        anchor.top,
                        anchor.bottom,
                        rect.height,
                      ) -
                      rect.top,
                ),
        );
  return (
    rect: rect,
    origin: vertical
        ? Offset(
            (rect.left - unshifted.left).abs() <= 1
                ? candidate.end != rtl
                      ? rect.right
                      : rect.left
                : anchor.center.dx.clamp(rect.left, rect.right),
            (rect.top - unshifted.top).abs() > 8
                ? anchor.center.dy
                : candidate.side == _MenuSide.top
                ? rect.bottom + 8
                : rect.top - 8,
          )
        : Offset(
            candidate.side == _MenuSide.left
                ? rect.right + sideOffset
                : rect.left - sideOffset,
            (rect.top - unshifted.top).abs() <= 1
                ? candidate.end
                      ? rect.bottom
                      : rect.top
                : anchor.center.dy.clamp(rect.top, rect.bottom),
          ),
  );
}

class _MenuPositioner extends SingleChildLayoutDelegate {
  _MenuPositioner({
    required this.info,
    required this.media,
    required this.direction,
    required this.width,
    required this.offset,
    required this.placement,
    required this.boundary,
    required this.padding,
    required this.sticky,
  });
  final RawMenuOverlayInfo info;
  final MediaQueryData media;
  final TextDirection direction;
  final double? width;
  final Offset offset;
  final _MenuPlacement placement;
  final Rect? boundary;
  final EdgeInsets padding;
  final bool sticky;
  Rect get safe => _menuSafe(info.overlaySize, media, boundary, padding);
  Rect get anchor => info.position == null
      ? info.anchorRect
      : Rect.fromLTWH(
          info.anchorRect.left + info.position!.dx,
          info.anchorRect.top + info.position!.dy,
          0,
          0,
        );
  double get belowSpace => safe.bottom - anchor.bottom - offset.dy;
  double get aboveSpace => anchor.top - offset.dy - safe.top;
  // Base UI biases flip detection by 1px, plus 1px on the preferred side.
  bool above(double height) =>
      height > belowSpace - 2 &&
      (height <= aboveSpace - 1 || aboveSpace > belowSpace);
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final available = math.max(0.0, safe.width);
    return BoxConstraints(
      minWidth: width ?? math.min(144, available),
      maxWidth: width ?? available,
      // Measure on the larger side, then choose using the actual laid-out
      // height. Rich children must not be reduced to estimated text rows.
      maxHeight: math.max(
        0,
        sticky
            ? safe.height
            : math.min(safe.height, math.max(aboveSpace, belowSpace)),
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final rect = anchor;
    final above = this.above(childSize.height);
    final top = above
        ? rect.top - offset.dy - childSize.height
        : rect.bottom + offset.dy;
    final left =
        rect.center.dx -
        childSize.width / 2 +
        (direction == TextDirection.ltr ? offset.dx : -offset.dx);
    final shiftedLeft = left
        .clamp(safe.left, math.max(safe.left, safe.right - childSize.width))
        .toDouble();
    final position = Offset(
      sticky
          ? shiftedLeft
          : _attachedShift(shiftedLeft, rect.left, rect.right, childSize.width),
      sticky
          ? top.clamp(
              safe.top,
              math.max(safe.top, safe.bottom - childSize.height),
            )
          : top,
    );
    placement.origin = Offset(
      rect.center.dx.clamp(position.dx, position.dx + childSize.width),
      (position.dy - top).abs() > offset.dy.abs()
          ? rect.center.dy
          : above
          ? position.dy + childSize.height + offset.dy
          : position.dy - offset.dy,
    );
    return position;
  }

  @override
  bool shouldRelayout(_MenuPositioner oldDelegate) => true;
}

/// Scale the whole positioned surface around the anchor, including its ring
/// and shadow. Keep the child mounted, but inert, during the exit transition.
class _MenuTransition extends StatelessWidget {
  const _MenuTransition({
    required this.motion,
    required this.origin,
    required this.child,
  });
  final AnimationController motion;
  final Offset Function() origin;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: motion,
    child: child,
    builder: (_, child) {
      final closing = motion.status == AnimationStatus.reverse;
      return ExcludeSemantics(
        excluding: closing,
        child: ExcludeFocus(
          excluding: closing,
          child: IgnorePointer(
            ignoring: closing,
            child: Opacity(
              opacity: motion.value,
              child: Transform.scale(
                alignment: Alignment.topLeft,
                origin: origin(),
                scale: .95 + .05 * motion.value,
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _MenuSurface extends StatelessWidget {
  const _MenuSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return Material(
      color: c.control,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: c.shadowDrop,
      shape: _MenuRingBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: c.line),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(6),
        child: child,
      ),
    );
  }
}

class _MenuRingBorder extends RoundedRectangleBorder {
  const _MenuRingBorder({required super.borderRadius, super.side});
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  _MenuRingBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => _MenuRingBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
  );
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawRRect(
      borderRadius.resolve(textDirection).toRRect(rect).inflate(side.width / 2),
      side.toPaint(),
    );
  }
}

List<SteyMenuItem> _flatten(List<SteyMenuItem> items) => [
  for (final item in items) ...[
    item,
    if (item is SteyMenuGroup) ..._flatten(item.children),
  ],
];

({double width, double height}) _popupSize(
  BuildContext context,
  List<SteyMenuItem> items,
) {
  final entries = _flatten(items);
  final inset = entries.any((e) => e.leading != null || e.icon != null);
  var width = 144.0, height = 12.0;
  double measure(String label, {bool bold = false, bool shortcut = false}) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Inter',
          package: 'stey_ui_modern',
          fontSize: shortcut ? 12 : 14,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          height: 1.5,
          letterSpacing: shortcut ? 1.2 : 0,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final result = painter.width;
    painter.dispose();
    return result;
  }

  for (final item in entries) {
    if (item is SteyMenuSeparator) {
      height += 9;
      continue;
    }
    final icon = item.leading != null || item.icon != null;
    final left = inset || item.inset || item is SteyMenuCheckboxItem
        ? 32.0
        : 8.0;
    final trailing = item.shortcut != null
        ? measure(item.shortcut!, shortcut: true) + 8
        : item.children.isNotEmpty && item is! SteyMenuGroup ||
              item.selection == true
        ? 24.0
        : 0.0;
    width = math.max(
      width,
      measure(item.label, bold: item is SteyMenuGroup) +
          math.max(left, icon ? 32.0 : 8.0) +
          20 +
          trailing,
    );
    height += math.max(
      33,
      MediaQuery.textScalerOf(context).scale(14) * 1.5 + 12,
    );
  }
  return (width: width, height: height);
}

class _MenuPanel extends StatefulWidget {
  const _MenuPanel({
    super.key,
    required this.items,
    required this.rootController,
    required this.closeRoot,
    required this.input,
    required this.direction,
    required this.submenuSideOffset,
    required this.boundary,
    required this.padding,
    required this.sticky,
    this.width,
    this.label,
    this.onBack,
    this.isActive,
  });
  final List<SteyMenuItem> items;
  final MenuController rootController;
  final ValueChanged<bool> closeRoot;
  final _MenuInput input;
  final TextDirection direction;
  final double submenuSideOffset;
  final Rect? boundary;
  final EdgeInsets padding;
  final bool sticky;
  final double? width;
  final String? label;
  final ValueChanged<bool>? onBack;
  final ValueGetter<bool>? isActive;
  @override
  State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  final nodes = <FocusNode>[];
  final panelFocus = FocusNode(skipTraversal: true);
  void focusPanel() => panelFocus.requestFocus();
  bool get interactive =>
      widget.input.active && (widget.isActive?.call() ?? true);
  Timer? searchTimer;
  String search = '';
  ValueChanged<bool>? closeChild;
  void activateRow(ValueChanged<bool>? close) {
    if (closeChild != close) closeChild?.call(false);
    closeChild = close;
  }

  late List<SteyMenuItem> entries;

  void sync() {
    entries = _flatten(widget.items);
    while (nodes.length < entries.length) {
      nodes.add(FocusNode());
    }
    while (nodes.length > entries.length) {
      nodes.removeLast().dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    sync();
  }

  @override
  void didUpdateWidget(_MenuPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  void dispose() {
    panelFocus.dispose();
    searchTimer?.cancel();
    for (final node in nodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool available(int i) =>
      entries[i] is! SteyMenuGroup &&
      entries[i] is! SteyMenuSeparator &&
      entries[i].enabled;
  void focusBoundary(bool last) {
    final indices = List.generate(entries.length, (i) => i).where(available);
    if (indices.isNotEmpty) {
      nodes[last ? indices.last : indices.first].requestFocus();
    }
  }

  void focusRelative(int delta) {
    final indices = List.generate(
      entries.length,
      (i) => i,
    ).where(available).toList();
    if (indices.isEmpty) return;
    final current = indices.indexWhere((i) => nodes[i].hasFocus);
    final next = current < 0
        ? (delta > 0 ? 0 : indices.length - 1)
        : (current + delta) % indices.length;
    nodes[indices[next]].requestFocus();
  }

  KeyEventResult keyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      widget.closeRoot(true);
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.home ||
        event.logicalKey == LogicalKeyboardKey.end) {
      focusBoundary(event.logicalKey == LogicalKeyboardKey.end);
      return KeyEventResult.handled;
    }
    final character = event.character;
    if (character == null ||
        character.trim().isEmpty ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    searchTimer?.cancel();
    final text = character.toLowerCase();
    search = search.length == 1 && search == text ? text : search + text;
    searchTimer = Timer(const Duration(milliseconds: 500), () => search = '');
    final current = nodes.indexWhere((n) => n.hasFocus);
    for (var step = 1; step <= entries.length; step++) {
      final i = (current + step) % entries.length;
      if (available(i) && entries[i].label.toLowerCase().startsWith(search)) {
        nodes[i].requestFocus();
        break;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final inset = entries.any((e) => e.leading != null || e.icon != null);
    var index = 0;
    Widget groupLabel(SteyMenuItem item) => Padding(
      padding: EdgeInsets.only(
        left: inset || item.inset ? 32 : 8,
        right: 8,
        top: 6,
        bottom: 6,
      ),
      child: Text(
        item.label,
        style: TextStyle(
          fontFamily: 'Inter',
          package: 'stey_ui_modern',
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: c.text,
        ),
      ),
    );
    Widget row(SteyMenuItem item) {
      final i = index++;
      if (item is SteyMenuSeparator) {
        return ExcludeSemantics(
          child: SizedBox(
            height: 9,
            child: CustomPaint(painter: _SeparatorPainter(c.hairline)),
          ),
        );
      }
      if (item is SteyMenuGroup) {
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: item.label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(child: groupLabel(item)),
              for (final child in item.children) row(child),
            ],
          ),
        );
      }
      return _MenuRow(
        key: ValueKey(nodes[i]),
        item: item,
        rootController: widget.rootController,
        closeRoot: widget.closeRoot,
        input: widget.input,
        isActive: () => interactive,
        onActive: activateRow,
        focusNode: nodes[i],
        inset: inset,
        submenuSideOffset: widget.submenuSideOffset,
        boundary: widget.boundary,
        padding: widget.padding,
        sticky: widget.sticky,
        width: widget.width,
      );
    }

    return Directionality(
      textDirection: widget.direction,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.menu,
        label: widget.label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 132),
          child: SizedBox(
            width: widget.width == null ? null : widget.width! - 12,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    (widget.onBack ?? widget.closeRoot)(true),
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    focusRelative(1),
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    focusRelative(-1),
                const SingleActivator(LogicalKeyboardKey.home): () =>
                    focusBoundary(false),
                const SingleActivator(LogicalKeyboardKey.end): () =>
                    focusBoundary(true),
                if (widget.onBack != null) ...{
                  SingleActivator(
                    widget.direction == TextDirection.ltr
                        ? LogicalKeyboardKey.arrowLeft
                        : LogicalKeyboardKey.arrowRight,
                  ): () =>
                      widget.onBack!(false),
                },
              },
              child: Focus(
                focusNode: panelFocus,
                autofocus: true,
                includeSemantics: false,
                skipTraversal: true,
                onKeyEvent: keyEvent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final item in widget.items) row(item)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeparatorPainter extends CustomPainter {
  const _SeparatorPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Rect.fromLTWH(-4, 4, size.width + 8, 1),
    Paint()..color = color,
  );
  @override
  bool shouldRepaint(_SeparatorPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({
    super.key,
    required this.item,
    required this.rootController,
    required this.closeRoot,
    required this.input,
    required this.isActive,
    required this.onActive,
    required this.focusNode,
    required this.inset,
    required this.submenuSideOffset,
    required this.boundary,
    required this.padding,
    required this.sticky,
    this.width,
  });
  final SteyMenuItem item;
  final MenuController rootController;
  final ValueChanged<bool> closeRoot;
  final _MenuInput input;
  final ValueGetter<bool> isActive;
  final ValueChanged<ValueChanged<bool>?> onActive;
  final FocusNode focusNode;
  final bool inset;
  final double submenuSideOffset;
  final Rect? boundary;
  final EdgeInsets padding;
  final bool sticky;
  final double? width;
  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow>
    with SingleTickerProviderStateMixin {
  bool hovered = false, popupOpen = false;
  late final motion = AnimationController(
    vsync: this,
    duration: _menuDuration,
    animationBehavior: AnimationBehavior.preserve,
  );
  int revision = 0;
  Timer? hoverTimer;
  OverlayEntry? popup;
  final anchorKey = GlobalKey();
  final submenuKey = GlobalKey<_MenuPanelState>();
  ({Rect anchor, Size overlay, MediaQueryData media})? popupSnapshot;

  ({Rect anchor, Size overlay, MediaQueryData media})? snapshot() {
    if (!mounted) return null;
    final anchor = anchorKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(
      context,
      rootOverlay: true,
    ).context.findRenderObject();
    if (anchor is! RenderBox ||
        overlay is! RenderBox ||
        !anchor.attached ||
        !overlay.attached ||
        !anchor.hasSize ||
        !overlay.hasSize) {
      return null;
    }
    return (
      anchor:
          anchor.localToGlobal(Offset.zero, ancestor: overlay) & anchor.size,
      overlay: overlay.size,
      media: _menuMedia(context),
    );
  }

  void trackGeometry() {
    if (!popupOpen || popup == null) return;
    final current = snapshot();
    if (current != null && current != popupSnapshot) popup?.markNeedsBuild();
  }

  @override
  void didUpdateWidget(_MenuRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (popup != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) popup?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    hoverTimer?.cancel();
    widget.input.dismissals.remove(dismiss);
    widget.input.unobserveGeometry(trackGeometry);
    motion.dispose();
    popup?.remove();
    popup?.dispose();
    super.dispose();
  }

  void closePopup(bool instant) {
    hoverTimer?.cancel();
    final entry = popup;
    if (entry == null || !popupOpen) return;
    widget.input.unobserveGeometry(trackGeometry);
    widget.input.dismissals.remove(dismiss);
    final request = ++revision;
    setState(() => popupOpen = false);
    submenuKey.currentState?.closeChild?.call(instant);
    void remove() {
      if (!mounted || request != revision || popup != entry) return;
      popup = null;
      entry.remove();
      entry.dispose();
    }

    if (instant) {
      motion.value = 0;
      remove();
    } else {
      motion
          .animateBack(0, duration: _menuDuration, curve: _menuCurve)
          .then((_) => remove());
    }
  }

  void onHover(bool value) {
    hovered = value;
    hoverTimer?.cancel();
    if (!value || !widget.item.enabled || !widget.isActive()) return;
    widget.onActive(widget.item.children.isEmpty ? null : closePopup);
    if (widget.item.children.isNotEmpty) {
      hoverTimer = Timer(
        const Duration(milliseconds: 100),
        () => showPopup(false),
      );
    }
  }

  void openSubmenu() => showPopup(true);

  void dismiss(bool instant) {
    closePopup(instant);
    widget.focusNode.requestFocus();
  }

  void showPopup(bool focusFirst, {bool instant = false}) {
    if (!widget.item.enabled || !widget.isActive()) return;
    hoverTimer?.cancel();
    revision++;
    if (!popupOpen) {
      widget.input.dismissals.add(dismiss);
      widget.input.observeGeometry(trackGeometry);
    }
    popupOpen = true;
    widget.onActive(closePopup);
    if (popup == null) {
      final overlay = Overlay.of(context, rootOverlay: true);
      // Independent entries preserve Web semantics for cascading menus. Read
      // geometry inside the builder so anchor/viewport changes keep state,
      // focus and the current transition rather than reopening the submenu.
      popup = OverlayEntry(
        builder: (_) {
          final current = snapshot();
          if (current == null) return const SizedBox.shrink();
          popupSnapshot = current;
          final rect = current.anchor;
          final direction = Directionality.of(context);
          final media = current.media;
          final safe = _menuSafe(
            current.overlay,
            media,
            widget.boundary,
            widget.padding,
          );
          final measured = _popupSize(context, widget.item.children);
          final width = widget.width ?? math.min(measured.width, safe.width);
          final geometry = _submenuPlacement(
            anchor: rect,
            safe: safe,
            size: Size(width, measured.height),
            direction: direction,
            sideOffset: widget.submenuSideOffset,
            sticky: widget.sticky,
          );
          final c = SteyTheme.colorsOf(context);
          // OverlayEntry keeps nested menu semantics independent of portal traversal
          // reparenting. No DOM or SDK patch is required.
          return _MenuTransition(
            motion: motion,
            origin: () => geometry.origin,
            child: Stack(
              children: [
                Positioned(
                  left: geometry.rect.left,
                  top: geometry.rect.top,
                  width: width,
                  child: InheritedTheme.captureAll(
                    context,
                    Directionality(
                      textDirection: direction,
                      child: Listener(
                        onPointerDown: (_) => widget.input.keyboard = false,
                        child: TapRegion(
                          groupId: widget.rootController,
                          child: Material(
                            color: c.control,
                            surfaceTintColor: Colors.transparent,
                            elevation: 8,
                            shadowColor: c.shadowDrop,
                            shape: _MenuRingBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: c.line),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: geometry.rect.height,
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(6),
                                child: FocusScope(
                                  child: _MenuPanel(
                                    key: submenuKey,
                                    items: widget.item.children,
                                    rootController: widget.rootController,
                                    closeRoot: widget.closeRoot,
                                    input: widget.input,
                                    isActive: () =>
                                        widget.isActive() && popupOpen,
                                    direction: direction,
                                    submenuSideOffset: widget.submenuSideOffset,
                                    boundary: widget.boundary,
                                    padding: widget.padding,
                                    sticky: widget.sticky,
                                    width: width,
                                    onBack: (instant) {
                                      closePopup(instant);
                                      widget.focusNode.requestFocus();
                                    },
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
          );
        },
      );
      overlay.insert(popup!);
      setState(() {});
    }
    if (instant) {
      motion.value = 1;
    } else {
      motion.animateTo(1, duration: _menuDuration, curve: _menuCurve);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !popupOpen) return;
      if (focusFirst) {
        submenuKey.currentState?.focusBoundary(false);
      } else {
        submenuKey.currentState?.focusPanel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final c = SteyTheme.colorsOf(context);
    final foreground = item.destructive ? c.danger : c.text;
    final icon = item.leading ?? (item.icon == null ? null : Icon(item.icon));
    final checkbox = item.role == SemanticsRole.menuItemCheckbox;
    final radio = item.role == SemanticsRole.menuItemRadio;
    final left = checkbox || item.inset || (widget.inset && icon == null)
        ? 32.0
        : 8.0;
    final style = ButtonStyle(
      animationDuration: Duration.zero,
      padding: WidgetStatePropertyAll(
        EdgeInsets.only(left: left, right: 8, top: 6, bottom: 6),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 33)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      alignment: AlignmentDirectional.centerStart,
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Inter',
          package: 'stey_ui_modern',
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
      ),
      foregroundColor: WidgetStatePropertyAll(foreground),
      iconColor: WidgetStatePropertyAll(foreground),
      iconSize: const WidgetStatePropertyAll(16),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            popupOpen ||
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)
            ? (item.destructive ? c.danger.withValues(alpha: .05) : c.tint)
            : Colors.transparent,
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.focused) && !hovered
              ? c.brand
              : Colors.transparent,
          width: 2,
        ),
      ),
    );
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        if (icon != null)
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: 16,
              child: IconTheme(
                data: IconThemeData(size: 16, color: foreground),
                child: icon,
              ),
            ),
          ),
        Flexible(
          child:
              item.child ??
              Text(item.label, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );
    final trailing = item.shortcut != null
        ? Text(
            item.shortcut!,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              color: foreground.withValues(alpha: .6),
            ),
          )
        : !checkbox && item.selection == true
        ? const ExcludeSemantics(child: Icon(Icons.check, size: 16))
        : null;
    final submenu = item.children.isNotEmpty;
    final direction = Directionality.of(context);
    final decoration = submenu
        ? const ExcludeSemantics(
            child: Icon(
              Icons.chevron_right,
              size: 16,
              textDirection: TextDirection.ltr,
            ),
          )
        : trailing;
    // Kumo uses physical `pl-8`, `left-2`, and `ml-auto`. In RTL the auto
    // margin occupies the space after the decoration, rather than before it.
    final autoMargin = submenu || item.shortcut != null || radio;
    final rowContent = Row(
      children: [
        if (decoration != null && autoMargin && direction == TextDirection.ltr)
          Expanded(child: content)
        else
          Flexible(child: content),
        if (decoration != null) ...[const SizedBox(width: 8), decoration],
      ],
    );
    final button = MenuItemButton(
      overflowAxis: Axis.vertical,
      key: anchorKey,
      focusNode: widget.focusNode,
      style: style,
      onHover: onHover,
      onFocusChange: (focused) {
        if (!focused) return;
        widget.onActive(submenu ? closePopup : null);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !widget.focusNode.hasPrimaryFocus) return;
          final object = anchorKey.currentContext?.findRenderObject();
          final scroll = Scrollable.maybeOf(context)?.position;
          if (object == null || !object.attached || scroll == null) return;
          // Reveal only this menu's focused row, as scrollIntoView(nearest)
          // does in Base UI. Do not scroll the anchor's application viewport.
          scroll.ensureVisible(
            object,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
          scroll.ensureVisible(
            object,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          );
        });
      },
      onPressed: !item.enabled
          ? null
          : () {
              if (!widget.isActive()) return;
              if (submenu) {
                showPopup(
                  widget.input.keyboard,
                  instant: widget.input.keyboard,
                );
              } else {
                if (item.closeOnActivate) {
                  widget.closeRoot(widget.input.keyboard);
                }
                item.activate();
              }
            },
      closeOnActivate: false,
      semanticsLabel: item.shortcut == null
          ? item.label
          : '${item.label} ${item.shortcut}',
      child: rowContent,
    );
    return MergeSemantics(
      child: Semantics(
        role: item.role,
        expanded: submenu ? popupOpen : null,
        checked: checkbox || radio ? item.selection : null,
        inMutuallyExclusiveGroup: radio,
        link: item.href == null ? null : true,
        linkUrl: item.href,
        child: Opacity(
          opacity: item.enabled ? 1 : .5,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              if (submenu)
                CallbackShortcuts(
                  bindings: {
                    SingleActivator(
                      Directionality.of(context) == TextDirection.ltr
                          ? LogicalKeyboardKey.arrowRight
                          : LogicalKeyboardKey.arrowLeft,
                    ): openSubmenu,
                  },
                  child: button,
                )
              else
                button,
              if (checkbox && item.selection == true)
                Positioned(
                  left: 8,
                  width: 14,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: Center(
                        child: Icon(Icons.check, size: 12, color: foreground),
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
