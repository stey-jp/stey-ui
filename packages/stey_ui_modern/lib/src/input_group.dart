part of 'input.dart';

enum SteyInputGroupFocusMode { container, individual, hybrid }

enum SteyInputGroupAlign { start, end }

class SteyInputGroup extends StatefulWidget {
  const SteyInputGroup({
    super.key,
    this.child,
    this.addon,
    this.suffix,
    this.children = const [],
    this.size = SteySize.base,
    this.disabled = false,
    this.label,
    this.description,
    this.error,
    this.required,
    this.labelTooltip,
  });
  final Widget? child, addon, suffix;
  final List<Widget> children;
  final SteySize size;
  final bool disabled;
  final String? label, description, error, labelTooltip;
  final bool? required;
  static SteyInputGroupFocusMode detectFocusMode(List<Widget> children) {
    final standalone = children.whereType<SteyInputGroupButton>().any(
      (b) => b.variant != null && b.variant != SteyButtonVariant.ghost,
    );
    final addon = children.any(
      (c) => c is SteyInputGroupAddon && c is! SteyInputGroupLabel,
    );
    return standalone
        ? addon
              ? SteyInputGroupFocusMode.hybrid
              : SteyInputGroupFocusMode.individual
        : SteyInputGroupFocusMode.container;
  }

  @override
  State<SteyInputGroup> createState() => _SteyInputGroupState();
}

class _SteyInputGroupState extends State<SteyInputGroup> {
  final editors = <_SteyInputState, FocusNode>{};
  final inputKeys = <Object, GlobalKey>{};
  int? active, hovered;
  void focusFirst() {
    if (widget.disabled) return;
    for (final node in editors.values) {
      if (node.canRequestFocus) {
        node.requestFocus();
        return;
      }
    }
  }

  BorderRadius corners(bool first, bool last) => BorderRadius.horizontal(
    left: first ? Radius.circular(radius) : Radius.zero,
    right: last ? Radius.circular(radius) : Radius.zero,
  );
  double get radius => widget.size == SteySize.xs ? 4 : widget.size.radius;
  List<Widget> ordered(List<Widget> children) => [
    ...children.where(
      (c) => c is SteyInputGroupAddon && c.align == SteyInputGroupAlign.start,
    ),
    ...children.where((c) => c is! SteyInputGroupAddon),
    ...children.where(
      (c) => c is SteyInputGroupAddon && c.align == SteyInputGroupAlign.end,
    ),
  ];
  _GroupConfig config(
    List<Widget> children, {
    bool individual = false,
    BorderRadius? radius,
  }) => _GroupConfig(
    owner: this,
    size: widget.size,
    disabled: widget.disabled,
    error: widget.error,
    label: widget.label,
    required: widget.required,
    individual: individual,
    radius: radius ?? BorderRadius.circular(this.radius),
    hasStart: children.any(
      (c) => c is SteyInputGroupAddon && c.align == SteyInputGroupAlign.start,
    ),
    hasEnd: children.any(
      (c) => c is SteyInputGroupAddon && c.align == SteyInputGroupAlign.end,
    ),
    hasSuffix: children.any((c) => c is SteyInputGroupSuffix),
  );
  Widget row(List<Widget> children, _GroupConfig data, {bool joined = false}) {
    final parts = joined ? children : ordered(children), out = <Widget>[];
    var inputIndex = 0;
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i],
          input = part is SteyInputGroupInput,
          suffix = part is SteyInputGroupSuffix;
      Widget child = part;
      if (input) {
        final identity = part.key ?? ValueKey('input-${inputIndex++}');
        child = KeyedSubtree(
          key: inputKeys.putIfAbsent(identity, () => GlobalKey()),
          child: child,
        );
      }
      final local = joined
          ? data.copyWith(radius: corners(i == 0, i == parts.length - 1))
          : data;
      Widget scoped = _GroupScope(data: local, child: child);
      if (joined) {
        scoped = Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onFocusChange: (v) {
            if (!mounted) return;
            setState(() {
              if (v) {
                active = i;
              } else if (active == i) {
                active = null;
              }
            });
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => hovered = i),
            onExit: (_) {
              if (hovered == i) setState(() => hovered = null);
            },
            child: scoped,
          ),
        );
      }
      out.add(
        _GroupCell(
          grow: input && !data.hasSuffix || suffix,
          basis: input && data.hasSuffix || suffix,
          shrink: input || suffix,
          priority: active == i
              ? 2
              : hovered == i
              ? 1
              : 0,
          child: scoped,
        ),
      );
    }
    return _GroupRow(
      height: data.inputHeight,
      overlap: joined ? 1 : 0,
      direction: Directionality.of(context),
      children: out,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.child == null || widget.children.isEmpty);
    if (widget.child != null) {
      return Row(
        children: [
          if (widget.addon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: widget.addon!,
            ),
          Expanded(child: widget.child!),
          if (widget.suffix != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: widget.suffix!,
            ),
        ],
      );
    }
    final mode = SteyInputGroup.detectFocusMode(widget.children),
        c = SteyTheme.colorsOf(context);
    final data = config(
      widget.children,
      individual: mode != SteyInputGroupFocusMode.container,
    );
    Widget body;
    if (mode == SteyInputGroupFocusMode.container) {
      body = _GroupSurface(data: data, child: row(widget.children, data));
    } else if (mode == SteyInputGroupFocusMode.individual) {
      body = row(widget.children, data, joined: true);
    } else {
      final container = widget.children
              .where((c) => c is! SteyInputGroupButton)
              .toList(),
          buttons = widget.children.whereType<SteyInputGroupButton>().toList();
      final zoneData = config(
        container,
        radius: corners(true, buttons.isEmpty),
      );
      final zone = _GroupSurface(
        data: zoneData,
        insideBorder: true,
        child: row(
          container,
          zoneData.copyWith(height: widget.size.height - 2),
        ),
      );
      final outer = <Widget>[
        _GroupCell(
          grow: true,
          shrink: true,
          priority: active == 0 ? 2 : 0,
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            onFocusChange: (v) => setState(() => active = v ? 0 : null),
            child: _GroupScope(data: zoneData, child: zone),
          ),
        ),
      ];
      for (var i = 0; i < buttons.length; i++) {
        final n = i + 1;
        outer.add(
          _GroupCell(
            priority: active == n
                ? 2
                : hovered == n
                ? 1
                : 0,
            child: _GroupScope(
              data: data.copyWith(
                radius: corners(false, i == buttons.length - 1),
              ),
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                includeSemantics: false,
                onFocusChange: (v) => setState(() => active = v ? n : null),
                child: MouseRegion(
                  onEnter: (_) => setState(() => hovered = n),
                  onExit: (_) => setState(() => hovered = null),
                  child: buttons[i],
                ),
              ),
            ),
          ),
        );
      }
      body = _GroupRow(
        height: widget.size.height,
        overlap: 1,
        direction: Directionality.of(context),
        children: outer,
      );
    }
    body = Opacity(
      opacity: widget.disabled ? .5 : 1,
      child: IgnorePointer(
        ignoring: widget.disabled,
        child: ExcludeFocus(
          excluding: widget.disabled,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.control,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: body,
          ),
        ),
      ),
    );
    if (widget.label?.isNotEmpty == true) {
      body = SteyField(
        label: widget.label,
        description: widget.description,
        error: widget.error,
        required: widget.required,
        labelTooltip: widget.labelTooltip,
        onLabelTap: widget.disabled ? null : focusFirst,
        child: body,
      );
    }
    return body;
  }
}

class _GroupConfig {
  const _GroupConfig({
    required this.owner,
    required this.size,
    required this.disabled,
    this.error,
    this.label,
    this.required,
    this.individual = false,
    this.insideAddon = false,
    this.hasStart = false,
    this.hasEnd = false,
    this.hasSuffix = false,
    this.radius = BorderRadius.zero,
    this.height,
  });
  final _SteyInputGroupState owner;
  final SteySize size;
  final bool disabled, individual, insideAddon, hasStart, hasEnd, hasSuffix;
  final String? error, label;
  final bool? required;
  final BorderRadius radius;
  final double? height;
  double get inputHeight => height ?? size.height;
  _GroupConfig copyWith({
    bool? insideAddon,
    BorderRadius? radius,
    double? height,
  }) => _GroupConfig(
    owner: owner,
    size: size,
    disabled: disabled,
    error: error,
    label: label,
    required: required,
    individual: individual,
    insideAddon: insideAddon ?? this.insideAddon,
    hasStart: hasStart,
    hasEnd: hasEnd,
    hasSuffix: hasSuffix,
    radius: radius ?? this.radius,
    height: height ?? this.height,
  );
}

class _GroupScope extends InheritedWidget {
  const _GroupScope({required this.data, required super.child});
  final _GroupConfig data;
  static _GroupConfig? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GroupScope>()?.data;
  @override
  bool updateShouldNotify(_GroupScope old) => data != old.data;
}

class SteyInputGroupInput extends SteyInput {
  const SteyInputGroupInput({
    super.key,
    super.controller,
    super.value,
    super.defaultValue,
    super.placeholder,
    super.onChanged,
    super.onValueChange,
    super.onSubmitted,
    super.enabled,
    super.readOnly,
    super.obscureText,
    super.keyboardType,
    super.textInputAction,
    super.autofillHints,
    super.focusNode,
    super.inputFormatters,
    super.autofocus,
    super.semanticLabel,
  });
}

Widget _buildGroupEditor(
  _SteyInputState state,
  BuildContext context,
  _GroupConfig g,
) {
  final w = state.widget,
      c = SteyTheme.colorsOf(context),
      enabled = !g.disabled && w.enabled,
      error = g.error?.isNotEmpty == true,
      size = g.size;
  if (state.groupOwner != g.owner) {
    state.groupOwner?.editors.remove(state);
    state.groupOwner = g.owner;
  }
  g.owner.editors[state] = state.focus;
  final seam = switch (size) {
    SteySize.xs => 4.0,
    SteySize.sm => 6.0,
    SteySize.base => 8.0,
    SteySize.lg => 10.0,
  };
  final border = g.individual ? 1.0 : 0.0,
      left = (g.hasStart ? seam : size.padding) + border,
      right =
          (g.hasSuffix
              ? 0.0
              : g.hasEnd
              ? seam
              : size.padding) +
          border;
  final line = size.fontSize == 12 ? 16.0 : 21.0;
  final style = TextStyle(
    fontFamily: 'Inter',
    package: 'stey_ui_modern',
    fontSize: size.fontSize,
    height: line / size.fontSize,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: enabled ? c.text : c.inactive,
  );
  Widget input = Semantics(
    label: w.semanticLabel ?? g.label ?? w.placeholder,
    hint: error ? g.error : null,
    isRequired: g.required,
    validationResult: error
        ? SemanticsValidationResult.invalid
        : SemanticsValidationResult.none,
    child: TextField(
      controller: state.controller,
      focusNode: state.focus,
      enabled: enabled,
      readOnly: w.readOnly,
      obscureText: w.obscureText,
      autofocus: w.autofocus,
      onChanged: state.change,
      onSubmitted: w.onSubmitted,
      keyboardType: w.keyboardType,
      textInputAction: w.textInputAction,
      autofillHints: w.autofillHints,
      inputFormatters: w.inputFormatters,
      style: style,
      strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
      cursorColor: c.text,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        isDense: true,
        visualDensity: VisualDensity.standard,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: false,
        hintFadeDuration: Duration.zero,
        hint: w.placeholder == null
            ? null
            : ExcludeSemantics(
                child: Text(
                  w.placeholder!,
                  style: style.copyWith(color: c.placeholder),
                ),
              ),
        contentPadding: EdgeInsets.fromLTRB(
          left,
          (g.inputHeight - line) / 2,
          right,
          (g.inputHeight - line) / 2,
        ),
      ),
    ),
  );
  if (g.individual) {
    input = CustomPaint(
      foregroundPainter: _GroupBorder(
        state.focus.hasFocus ? c.focus.withValues(alpha: .5) : c.line,
        g.radius,
      ),
      child: input,
    );
  }
  double? width;
  if (g.hasSuffix) {
    final p = TextPainter(
      text: TextSpan(
        text: state.controller.text.isEmpty
            ? w.placeholder ?? ''
            : state.controller.text,
        style: style,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    width = p.width + left + right + 1;
    p.dispose();
  }
  return SizedBox(width: width, height: g.inputHeight, child: input);
}

class SteyInputGroupAddon extends StatelessWidget {
  const SteyInputGroupAddon({
    super.key,
    this.child,
    this.children = const [],
    this.align = SteyInputGroupAlign.start,
  });
  final Widget? child;
  final List<Widget> children;
  final SteyInputGroupAlign align;
  @override
  Widget build(BuildContext context) {
    assert(child == null || children.isEmpty);
    final g = _GroupScope.maybeOf(context),
        size = g?.size ?? SteySize.base,
        c = SteyTheme.colorsOf(context),
        parts = child == null ? children : [child!],
        button = parts.any((c) => c is SteyInputGroupButton);
    final outer = button
        ? size == SteySize.lg
              ? (align == SteyInputGroupAlign.start ? 6.0 : 2.0)
              : 4.0
        : switch (size) {
            SteySize.xs || SteySize.sm => 6.0,
            SteySize.base => 8.0,
            SteySize.lg => 10.0,
          };
    Widget body = Padding(
      padding: align == SteyInputGroupAlign.start
          ? EdgeInsets.only(left: outer)
          : EdgeInsets.only(right: outer),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontFamily: 'Inter',
          package: 'stey_ui_modern',
          fontSize: size.fontSize,
          height: size.fontSize == 12 ? 16 / 12 : 1.5,
          color: c.subtle,
        ),
        child: IconTheme(
          data: IconThemeData(
            color: c.subtle,
            size: switch (size) {
              SteySize.xs => 10,
              SteySize.sm => 13,
              SteySize.base => 18,
              SteySize.lg => 20,
            },
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: parts,
          ),
        ),
      ),
    );
    if (g != null) {
      body = _GroupScope(data: g.copyWith(insideAddon: true), child: body);
    }
    return body;
  }
}

class SteyInputGroupSuffix extends StatelessWidget {
  const SteyInputGroupSuffix({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final g = _GroupScope.maybeOf(context), size = g?.size ?? SteySize.base;
    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.only(right: g?.hasEnd == true ? 0 : size.padding),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontFamily: 'Inter',
            package: 'stey_ui_modern',
            fontSize: size.fontSize,
            height: size.fontSize == 12 ? 16 / 12 : 1.5,
            color: SteyTheme.colorsOf(context).subtle,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            heightFactor: 1,
            child: child,
          ),
        ),
      ),
    );
  }
}

@Deprecated('Use SteyInputGroupAddon.')
class SteyInputGroupLabel extends SteyInputGroupAddon {
  const SteyInputGroupLabel({
    super.key,
    super.child,
    super.children,
    super.align,
  });
}

@Deprecated('Use SteyInputGroupSuffix.')
class SteyInputGroupDescription extends SteyInputGroupSuffix {
  const SteyInputGroupDescription({super.key, required super.child});
}

class SteyInputGroupButton extends StatefulWidget {
  const SteyInputGroupButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant,
    this.size,
    this.shape = SteyButtonShape.base,
    this.disabled,
    this.loading = false,
    this.tooltip,
    this.semanticLabel,
    this.icon,
    this.focusNode,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final SteyButtonVariant? variant;
  final SteySize? size;
  final SteyButtonShape shape;
  final bool? disabled;
  final bool loading;
  final String? tooltip, semanticLabel;
  final Widget? icon;
  final FocusNode? focusNode;
  @override
  State<SteyInputGroupButton> createState() => _GroupButtonState();
}

class _GroupButtonState extends State<SteyInputGroupButton> {
  FocusNode? internal;
  FocusNode get focus => widget.focusNode ?? internal!;
  bool keyboard = false;
  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) internal = FocusNode();
    focus.addListener(changed);
  }

  void changed() {
    if (focus.hasFocus &&
        HardwareKeyboard.instance.logicalKeysPressed.isNotEmpty) {
      keyboard = true;
    }
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(SteyInputGroupButton old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? internal!).removeListener(changed);
      internal?.dispose();
      internal = widget.focusNode == null ? FocusNode() : null;
      focus.addListener(changed);
    }
  }

  @override
  void dispose() {
    focus.removeListener(changed);
    internal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = _GroupScope.maybeOf(context),
        base = g?.size ?? SteySize.base,
        individual = g?.individual ?? false,
        c = SteyTheme.colorsOf(context),
        disabled = g?.disabled == true || widget.disabled == true;
    final size =
        widget.size ??
        (individual
            ? base
            : switch (base) {
                SteySize.xs || SteySize.sm => SteySize.xs,
                SteySize.base => SteySize.sm,
                SteySize.lg => SteySize.base,
              });
    final radius = individual ? g!.radius : BorderRadius.circular(size.radius),
        side = individual
            ? BorderSide(
                color: focus.hasFocus && keyboard
                    ? c.focus.withValues(alpha: .5)
                    : c.line,
              )
            : BorderSide(
                color: focus.hasFocus && keyboard
                    ? c.focus.withValues(alpha: .5)
                    : Colors.transparent,
                width: 1.5,
              );
    final height = g?.size.height ?? size.height,
        square = size == SteySize.xs ? 14.0 : size.height;
    Widget body = Listener(
      onPointerDown: (_) => setState(() => keyboard = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent) setState(() => keyboard = true);
          return KeyEventResult.ignored;
        },
        child: SteyButton(
          onPressed: disabled || widget.onPressed == null
              ? null
              : () {
                  focus.requestFocus();
                  widget.onPressed!();
                },
          loading: widget.loading,
          size: size,
          variant: widget.variant ?? SteyButtonVariant.ghost,
          shape: widget.shape,
          icon: widget.icon == null
              ? null
              : IconTheme(
                  data: IconThemeData(
                    size: switch (base) {
                      SteySize.xs => 10,
                      SteySize.sm => 13,
                      SteySize.base => 18,
                      SteySize.lg => 20,
                    },
                  ),
                  child: widget.icon!,
                ),
          semanticLabel: widget.semanticLabel ?? widget.tooltip,
          focusNode: focus,
          style: ButtonStyle(
            elevation: const WidgetStatePropertyAll(0),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            shape: WidgetStatePropertyAll(
              individual
                  ? RoundedRectangleBorder(borderRadius: radius)
                  : _GroupButtonShape(borderRadius: radius),
            ),
            side: WidgetStatePropertyAll(side),
            padding: individual && widget.shape == SteyButtonShape.base
                ? WidgetStatePropertyAll(
                    EdgeInsets.only(
                      left:
                          size.padding +
                          1 -
                          (widget.icon != null || widget.loading ? 2 : 0),
                      right: size.padding + 1,
                      bottom: size.fontSize == 12 ? 1 : 2,
                    ),
                  )
                : null,
            minimumSize: individual
                ? WidgetStatePropertyAll(Size(0, height))
                : null,
            maximumSize: individual
                ? WidgetStatePropertyAll(Size(double.infinity, height))
                : null,
            fixedSize: individual
                ? WidgetStatePropertyAll(
                    Size(
                      widget.shape == SteyButtonShape.base
                          ? double.infinity
                          : square,
                      height,
                    ),
                  )
                : null,
            foregroundColor: disabled && individual
                ? WidgetStatePropertyAll(c.inactive)
                : null,
            backgroundColor: disabled && individual
                ? WidgetStatePropertyAll(c.overlay)
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
    if (widget.tooltip != null) {
      body = Tooltip(
        message: widget.tooltip!,
        excludeFromSemantics: true,
        preferBelow: true,
        child: body,
      );
    }
    return body;
  }
}

class _GroupButtonShape extends RoundedRectangleBorder {
  const _GroupButtonShape({required super.borderRadius, super.side});
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  _GroupButtonShape copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => _GroupButtonShape(
    borderRadius: borderRadius ?? this.borderRadius,
    side: side ?? this.side,
  );
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) =>
      canvas.drawRRect(
        borderRadius
            .resolve(textDirection)
            .toRRect(rect)
            .inflate(side.width / 2),
        side.toPaint(),
      );
}

class _GroupSurface extends StatefulWidget {
  const _GroupSurface({
    required this.data,
    required this.child,
    this.insideBorder = false,
  });
  final _GroupConfig data;
  final Widget child;
  final bool insideBorder;
  @override
  State<_GroupSurface> createState() => _GroupSurfaceState();
}

class _GroupSurfaceState extends State<_GroupSurface> {
  bool focused = false;
  @override
  Widget build(BuildContext context) {
    final d = widget.data,
        c = SteyTheme.colorsOf(context),
        color = widget.insideBorder
            ? focused
                  ? c.focus.withValues(alpha: .5)
                  : c.line
            : d.error?.isNotEmpty == true
            ? c.danger
            : focused
            ? c.focus.withValues(alpha: .5)
            : c.line;
    Widget body = ClipRRect(
      borderRadius: d.radius,
      child: widget.insideBorder
          ? Padding(padding: const EdgeInsets.all(1), child: widget.child)
          : widget.child,
    );
    body = CustomPaint(
      foregroundPainter: widget.insideBorder
          ? _GroupBorder(color, d.radius)
          : _GroupRing(color, d.radius, focused ? 1.5 : 1),
      child: body,
    );
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (v) => setState(() => focused = v),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: d.owner.focusFirst,
        child: body,
      ),
    );
  }
}

class _GroupRing extends CustomPainter {
  const _GroupRing(this.color, this.radius, this.width);
  final Color color;
  final BorderRadius radius;
  final double width;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    radius.toRRect(Offset.zero & size).inflate(width / 2),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width,
  );
  @override
  bool shouldRepaint(_GroupRing old) =>
      color != old.color || radius != old.radius || width != old.width;
}

class _GroupBorder extends CustomPainter {
  const _GroupBorder(this.color, this.radius);
  final Color color;
  final BorderRadius radius;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    radius.toRRect(Offset.zero & size).deflate(.5),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  @override
  bool shouldRepaint(_GroupBorder old) =>
      color != old.color || radius != old.radius;
}

class _GroupParentData extends ContainerBoxParentData<RenderBox> {
  bool grow = false, basis = false, shrink = false;
  int priority = 0;
}

class _GroupCell extends ParentDataWidget<_GroupParentData> {
  const _GroupCell({
    required super.child,
    this.grow = false,
    this.basis = false,
    this.shrink = false,
    this.priority = 0,
  });
  final bool grow, basis, shrink;
  final int priority;
  @override
  void applyParentData(RenderObject object) {
    final d = object.parentData! as _GroupParentData;
    if (d.grow != grow ||
        d.basis != basis ||
        d.shrink != shrink ||
        d.priority != priority) {
      d
        ..grow = grow
        ..basis = basis
        ..shrink = shrink
        ..priority = priority;
      object.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _GroupRow;
}

class _GroupRow extends MultiChildRenderObjectWidget {
  const _GroupRow({
    required this.height,
    required this.overlap,
    required this.direction,
    required super.children,
  });
  final double height, overlap;
  final TextDirection direction;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGroupRow(height, overlap, direction);
  @override
  void updateRenderObject(BuildContext context, _RenderGroupRow r) {
    r
      ..height = height
      ..overlap = overlap
      ..direction = direction
      ..markNeedsLayout();
  }
}

class _RenderGroupRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GroupParentData> {
  _RenderGroupRow(this.height, this.overlap, this.direction);
  double height, overlap;
  TextDirection direction;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GroupParentData) {
      child.parentData = _GroupParentData();
    }
  }

  List<RenderBox> get boxes {
    final out = <RenderBox>[];
    var c = firstChild;
    while (c != null) {
      out.add(c);
      c = (c.parentData! as _GroupParentData).nextSibling;
    }
    return out;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(Size(constraints.maxWidth, height));
  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth, 'InputGroup needs bounded width');
    size = constraints.constrain(Size(constraints.maxWidth, height));
    final children = boxes,
        widths = <double>[],
        grow = <int>[],
        shrink = <int>[];
    var total = 0.0;
    for (var i = 0; i < children.length; i++) {
      final c = children[i], d = c.parentData! as _GroupParentData;
      if (d.grow) grow.add(i);
      if (d.shrink) shrink.add(i);
      if (d.grow && !d.basis) {
        widths.add(0);
      } else {
        c.layout(
          BoxConstraints(
            maxWidth: d.shrink ? size.width : double.infinity,
            maxHeight: height,
          ),
          parentUsesSize: true,
        );
        widths.add(c.size.width);
        total += c.size.width;
      }
    }
    final available = size.width + overlap * math.max(0, children.length - 1),
        free = available - total;
    if (free >= 0 && grow.isNotEmpty) {
      for (final i in grow) {
        widths[i] += free / grow.length;
      }
    } else if (free < 0) {
      final base = shrink.fold(0.0, (sum, i) => sum + widths[i]);
      if (base > 0) {
        for (final i in shrink) {
          widths[i] = math.max(0, widths[i] + free * widths[i] / base);
        }
      }
    }
    var x = direction == TextDirection.ltr ? 0.0 : size.width;
    for (var i = 0; i < children.length; i++) {
      final c = children[i], d = c.parentData! as _GroupParentData;
      c.layout(
        BoxConstraints.tightFor(width: widths[i]).copyWith(maxHeight: height),
        parentUsesSize: true,
      );
      if (direction == TextDirection.rtl) x -= c.size.width;
      d.offset = Offset(x, (size.height - c.size.height) / 2);
      x += direction == TextDirection.ltr ? c.size.width - overlap : overlap;
    }
  }

  List<RenderBox> get painted {
    final source = boxes, out = source.toList();
    out.sort((a, b) {
      final priority = (a.parentData! as _GroupParentData).priority.compareTo(
        (b.parentData! as _GroupParentData).priority,
      );
      return priority == 0
          ? source.indexOf(a).compareTo(source.indexOf(b))
          : priority;
    });
    return out;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final c in painted) {
      context.paintChild(
        c,
        offset + (c.parentData! as _GroupParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final c in painted.reversed) {
      final d = c.parentData! as _GroupParentData;
      if (result.addWithPaintOffset(
        offset: d.offset,
        position: position,
        hitTest: (r, p) => c.hitTest(r, position: p),
      )) {
        return true;
      }
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final d = child.parentData! as _GroupParentData;
    transform.translateByDouble(d.offset.dx, d.offset.dy, 0, 1);
  }
}
