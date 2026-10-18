import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

const _motion = Duration(milliseconds: 100);
const _easeOut = Cubic(0, 0, .2, 1);

enum SteyCollapsibleChangeReason { triggerPress, none }

class SteyCollapsibleChangeDetails {
  SteyCollapsibleChangeDetails(this.reason);
  final SteyCollapsibleChangeReason reason;
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

typedef SteyCollapsibleChangeHandler = void Function(
  bool open,
  SteyCollapsibleChangeDetails details,
);

/// State owner for composable Trigger/Panel children. An explicit open value is
/// controlled; defaultOpen only initializes uncontrolled state.
class SteyCollapsibleRoot extends StatefulWidget {
  const SteyCollapsibleRoot({
    super.key,
    required this.child,
    this.open,
    this.defaultOpen = false,
    this.disabled = false,
    this.onOpenChange,
    this.panelIdentifier,
  });
  final Widget child;
  final bool? open;
  final bool defaultOpen, disabled;
  final SteyCollapsibleChangeHandler? onOpenChange;
  final String? panelIdentifier;
  @override
  State<SteyCollapsibleRoot> createState() => _RootState();
}

class _RootState extends State<SteyCollapsibleRoot> {
  static int nextIdentifier = 0;
  late bool internal = widget.defaultOpen;
  late final generatedIdentifier = 'stey-collapsible-panel-${nextIdentifier++}';
  final triggers = <FocusNode>{};
  bool panelReady = false;
  void publishPanel() {
    if (mounted && open && !panelReady) {
      setState(() => panelReady = true);
    }
  }

  bool get open => widget.open ?? internal;
  void toggle() {
    final next = !open;
    final details = SteyCollapsibleChangeDetails(
      SteyCollapsibleChangeReason.triggerPress,
    );
    widget.onOpenChange?.call(next, details);
    if (!mounted || details.isCancelled) return;
    if (widget.open == null) setState(() => internal = next);
  }

  void focusTrigger() {
    for (final node in triggers) {
      if (node.context != null && node.canRequestFocus) {
        node.requestFocus();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!open) panelReady = false;
    return _CollapsibleScope(
      owner: this,
      open: open,
      disabled: widget.disabled,
      panelReady: panelReady,
      identifier: widget.panelIdentifier ?? generatedIdentifier,
      child: widget.child,
    );
  }
}

class _CollapsibleScope extends InheritedWidget {
  const _CollapsibleScope({
    required this.owner,
    required this.open,
    required this.disabled,
    required this.panelReady,
    required this.identifier,
    required super.child,
  });
  final _RootState owner;
  final bool open, disabled, panelReady;
  final String identifier;
  static _CollapsibleScope of(BuildContext context) {
    final value = context
        .dependOnInheritedWidgetOfExactType<_CollapsibleScope>();
    assert(value != null, 'Collapsible parts require SteyCollapsibleRoot.');
    return value!;
  }

  @override
  bool updateShouldNotify(_CollapsibleScope oldWidget) =>
      owner != oldWidget.owner ||
      open != oldWidget.open ||
      disabled != oldWidget.disabled ||
      panelReady != oldWidget.panelReady ||
      identifier != oldWidget.identifier;
}

class SteyCollapsibleTriggerData {
  const SteyCollapsibleTriggerData({
    required this.open,
    required this.disabled,
    required this.focusNode,
    required this.onPressed,
  });
  final bool open, disabled;
  final FocusNode focusNode;
  final VoidCallback? onPressed;
}

/// Unstyled button. A builder can supply a native SteyButton; wire its focusNode
/// and onPressed from the provided data to keep one keyboard target.
class SteyCollapsibleTrigger extends StatefulWidget {
  const SteyCollapsibleTrigger({
    super.key,
    this.child = const SizedBox.shrink(),
    this.builder,
    this.disabled,
    this.focusNode,
    this.autofocus = false,
  }) : _styled = false;
  const SteyCollapsibleTrigger._default({
    required this.child,
    this.disabled,
    this.focusNode,
    this.autofocus = false,
  }) : _styled = true,
       builder = null;
  final Widget child;
  final Widget Function(BuildContext, SteyCollapsibleTriggerData)? builder;
  final bool? disabled;
  final FocusNode? focusNode;
  final bool autofocus, _styled;
  @override
  State<SteyCollapsibleTrigger> createState() => _TriggerState();
}

class _TriggerState extends State<SteyCollapsibleTrigger>
    with SingleTickerProviderStateMixin {
  final ownFocus = FocusNode();
  FocusNode get node => widget.focusNode ?? ownFocus;
  late final caret = AnimationController(
    vsync: this,
    duration: _motion,
    animationBehavior: AnimationBehavior.preserve,
  );
  _CollapsibleScope? scope;
  bool initialized = false,
      lastOpen = false,
      highlight = false,
      spacePressed = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = _CollapsibleScope.of(context);
    if (scope?.owner != next.owner) {
      scope?.owner.triggers.remove(node);
      next.owner.triggers.add(node);
    }
    scope = next;
    if (!initialized) {
      caret.value = next.open ? 1 : 0;
      initialized = true;
    } else if (lastOpen != next.open) {
      next.open
          ? caret.animateTo(1, duration: _motion, curve: _easeOut)
          : caret.animateBack(0, duration: _motion, curve: _easeOut);
    }
    lastOpen = next.open;
  }

  @override
  void didUpdateWidget(SteyCollapsibleTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      scope?.owner.triggers.remove(oldWidget.focusNode ?? ownFocus);
      scope?.owner.triggers.add(node);
    }
  }

  @override
  void dispose() {
    scope?.owner.triggers.remove(node);
    caret.dispose();
    ownFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _CollapsibleScope.of(context);
    final disabled = widget.disabled ?? s.disabled;
    final c = SteyTheme.colorsOf(context);
    void activate() {
      if (!disabled) {
        node.requestFocus();
        s.owner.toggle();
      }
    }

    final data = SteyCollapsibleTriggerData(
      open: s.open,
      disabled: disabled,
      focusNode: node,
      onPressed: disabled ? null : activate,
    );
    Widget content = widget.child;
    if (widget._styled) {
      content = DefaultTextStyle.merge(
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w500,
          color: c.text,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Flexible(child: widget.child),
            ExcludeSemantics(
              child: SizedBox(
                width: 16,
                child: Center(
                  child: AnimatedBuilder(
                    animation: caret,
                    builder: (context, _) => Transform.rotate(
                      angle: math.pi * caret.value,
                      child: CustomPaint(
                        size: const Size.square(12),
                        painter: _Caret(c.text),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (widget.builder != null) {
      content = widget.builder!(context, data);
    } else {
      content = FocusableActionDetector(
        focusNode: node,
        enabled: !disabled,
        autofocus: widget.autofocus,
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => highlight = value),
        child: Semantics(
          onTap: disabled ? null : activate,
          child: GestureDetector(
            excludeFromSemantics: true,
            behavior: HitTestBehavior.opaque,
            onTap: disabled ? null : activate,
            child: CustomPaint(
              foregroundPainter: highlight ? _TriggerFocus(c.brand) : null,
              child: content,
            ),
          ),
        ),
      );
    }
    return MergeSemantics(
      child: Semantics(
        button: true,
        // Publish expanded with controlsNodes once the Panel is registered.
        // Flutter 3.47 does not mark a semantics node dirty for a change to
        // controlsNodes alone; the meaningful expanded flag updates both.
        expanded: s.open && s.panelReady,
        enabled: !disabled,
        controlsNodes: s.open && s.panelReady ? {s.identifier} : null,
        child: Focus(
          canRequestFocus: false,
          includeSemantics: false,
          onFocusChange: (value) {
            if (!value) spacePressed = false;
          },
          onKeyEvent: (_, event) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.space) {
              if (event is KeyDownEvent) spacePressed = !disabled;
              if (event is KeyUpEvent) {
                final armed = spacePressed;
                spacePressed = false;
                if (armed) activate();
              }
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.enter) {
              if (event is KeyDownEvent || event is KeyRepeatEvent) activate();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: content,
        ),
      ),
    );
  }
}

class SteyCollapsibleDefaultTrigger extends StatelessWidget {
  const SteyCollapsibleDefaultTrigger({
    super.key,
    required this.child,
    this.disabled,
    this.focusNode,
    this.autofocus = false,
  });
  final Widget child;
  final bool? disabled;
  final FocusNode? focusNode;
  final bool autofocus;
  @override
  Widget build(BuildContext context) => SteyCollapsibleTrigger._default(
    disabled: disabled,
    focusNode: focusNode,
    autofocus: autofocus,
    child: child,
  );
}

/// Bare Panel has no animation. DefaultPanel supplies Kumo's 100ms height/fade.
class SteyCollapsiblePanel extends StatefulWidget {
  const SteyCollapsiblePanel({
    super.key,
    required this.child,
    this.keepMounted = false,
  }) : _animate = false;
  const SteyCollapsiblePanel._default({
    required this.child,
    this.keepMounted = false,
  }) : _animate = true;
  final Widget child;
  final bool keepMounted, _animate;
  @override
  State<SteyCollapsiblePanel> createState() => _PanelState();
}

class _PanelState extends State<SteyCollapsiblePanel>
    with SingleTickerProviderStateMixin {
  final panelFocus = FocusNode(skipTraversal: true, canRequestFocus: false);
  late final animation = AnimationController(
    vsync: this,
    duration: _motion,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(finished);
  bool initialized = false, open = false, contentMounted = false;
  void finished(AnimationStatus status) {
    if (status == AnimationStatus.dismissed &&
        !open &&
        contentMounted &&
        !widget.keepMounted) {
      setState(() => contentMounted = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    update(_CollapsibleScope.of(context));
  }

  @override
  void didUpdateWidget(SteyCollapsiblePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    update(_CollapsibleScope.of(context));
  }

  void update(_CollapsibleScope s) {
    final changed = initialized && open != s.open;
    open = s.open;
    if (open || widget.keepMounted) contentMounted = true;
    if (open && !s.panelReady) {
      // Publish the relation after the Panel's first semantics update. The Web
      // engine resolves controlsNodes only when that field changes, so a lazy
      // Panel that is still absent from the engine must not be targeted yet.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) s.owner.publishPanel();
      });
    }
    if (!initialized) {
      animation.value = open ? 1 : 0;
      initialized = true;
      return;
    }
    if (changed && !open && panelFocus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !open) s.owner.focusTrigger();
      });
    }
    if (changed || !widget._animate) {
      final duration = widget._animate ? _motion : Duration.zero;
      open
          ? animation.animateTo(1, duration: duration, curve: _easeOut)
          : animation.animateBack(0, duration: duration, curve: _easeOut);
    }
    if (!open && animation.isDismissed && !widget.keepMounted) {
      contentMounted = false;
    }
  }

  @override
  void dispose() {
    panelFocus.dispose();
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _CollapsibleScope.of(context);
    if (!contentMounted) return const SizedBox.shrink();
    return ExcludeSemantics(
      excluding: !open,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        identifier: s.identifier,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Offstage(
            offstage: !open && animation.isDismissed,
            child: ExcludeFocus(
              excluding: !open,
              child: ExcludeSemantics(
                excluding: !open,
                child: IgnorePointer(
                  ignoring: !open,
                  child: Opacity(
                    opacity: animation.value,
                    // Register the Panel ID in the same semantics update as the
                    // Trigger's controlsNodes, including the opening zero frame.
                    alwaysIncludeSemantics: true,
                    child: _Reveal(
                      factor: animation.value,
                      closing: !open,
                      child: child!,
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: Focus(
            focusNode: panelFocus,
            includeSemantics: false,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class SteyCollapsibleDefaultPanel extends StatelessWidget {
  const SteyCollapsibleDefaultPanel({
    super.key,
    this.child,
    this.children = const [],
    this.keepMounted = false,
  }) : assert(child == null || children.length == 0);
  final Widget? child;
  final List<Widget> children;
  final bool keepMounted;
  @override
  Widget build(BuildContext context) => SteyCollapsiblePanel._default(
    keepMounted: keepMounted,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: SteyTheme.colorsOf(context).fill, width: 2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 4, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [?child, ...children],
          ),
        ),
      ),
    ),
  );
}

/// Compatibility convenience; keeps the original controlled API and content state.
class SteyCollapsible extends StatelessWidget {
  const SteyCollapsible({
    super.key,
    required this.open,
    required this.onChanged,
    required this.title,
    required this.child,
    this.disabled = false,
    this.keepMounted = true,
  });
  final bool open, disabled, keepMounted;
  final ValueChanged<bool> onChanged;
  final Widget title, child;
  @override
  Widget build(BuildContext context) => SteyCollapsibleRoot(
    open: open,
    disabled: disabled,
    onOpenChange: (value, _) => onChanged(value),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SteyCollapsibleDefaultTrigger(child: title),
        ),
        SteyCollapsibleDefaultPanel(keepMounted: keepMounted, child: child),
      ],
    ),
  );
}

class _Caret extends CustomPainter {
  const _Caret(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 256, size.height / 256);
    canvas.drawPath(
      Path()
        ..moveTo(48, 96)
        ..lineTo(128, 176)
        ..lineTo(208, 96),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Caret oldDelegate) => color != oldDelegate.color;
}

class _TriggerFocus extends CustomPainter {
  const _TriggerFocus(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    (Offset.zero & size).inflate(1),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  @override
  bool shouldRepaint(_TriggerFocus oldDelegate) => color != oldDelegate.color;
}

class _Reveal extends SingleChildRenderObjectWidget {
  const _Reveal({
    required this.factor,
    required this.closing,
    required super.child,
  });
  final double factor;
  final bool closing;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReveal(factor, closing);
  @override
  void updateRenderObject(BuildContext context, _RenderReveal renderObject) =>
      renderObject.update(factor, closing);
}

/// The child always receives its expanded width/height constraints. Closing uses
/// the last measured natural height, even when child contents change mid-close.
class _RenderReveal extends RenderProxyBox {
  _RenderReveal(this.factor, this.closing);
  double factor, naturalHeight = 0;
  double? closingHeight;
  bool closing;
  void update(double nextFactor, bool nextClosing) {
    if (!closing && nextClosing) closingHeight = naturalHeight;
    if (!nextClosing) closingHeight = null;
    if (factor != nextFactor || closing != nextClosing) {
      factor = nextFactor;
      closing = nextClosing;
      markNeedsLayout();
    }
  }

  BoxConstraints expanded(BoxConstraints value) =>
      value.copyWith(minHeight: 0, maxHeight: double.infinity);
  @override
  void performLayout() {
    child?.layout(expanded(constraints), parentUsesSize: true);
    naturalHeight = child?.size.height ?? 0;
    size = constraints.constrain(
      Size(child?.size.width ?? 0, (closingHeight ?? naturalHeight) * factor),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final natural = child?.getDryLayout(expanded(constraints)) ?? Size.zero;
    return constraints.constrain(
      Size(natural.width, (closingHeight ?? natural.height) * factor),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || factor == 0) return;
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) => context.paintChild(child!, offset),
    );
  }

  @override
  Rect? describeSemanticsClip(RenderObject? child) => Offset.zero & size;
}
