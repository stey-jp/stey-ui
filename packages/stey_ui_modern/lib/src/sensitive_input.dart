part of 'input.dart';

/// Secret editor with a constant mask, explicit reveal and native clipboard copy.
class SteySensitiveInput extends SteyInput {
  const SteySensitiveInput({
    super.key,
    super.controller,
    super.value,
    super.defaultValue,
    super.label,
    super.labelTooltip,
    super.description,
    super.error,
    super.required,
    super.placeholder,
    super.semanticLabel,
    super.size,
    super.variant,
    super.enabled,
    super.readOnly,
    super.focusNode,
    super.onChanged,
    super.onValueChange,
    super.onSubmitted,
    super.keyboardType,
    super.textInputAction,
    super.inputFormatters,
    super.autofocus,
    super.autofillHints = const [],
    this.onCopy,
    this.onCopyError,
  });
  final VoidCallback? onCopy;
  final ValueChanged<Object>? onCopyError;
  @override
  State<SteyInput> createState() => _SensitiveInputState();
}

enum _SensitiveMode { masked, revealed, empty }

class _SensitiveInputState extends _SteyInputState {
  SteySensitiveInput get w => widget as SteySensitiveInput;
  late _SensitiveMode mode;
  final container = FocusNode(), eye = FocusNode(), copyNode = FocusNode();
  final portal = OverlayPortalController();
  TextEditingController? listened;
  Timer? resetCopy;
  int attempt = 0;
  bool hovered = false,
      maskHovered = false,
      copyHovered = false,
      within = false,
      copied = false;
  bool editorActivated = false;
  bool get hasValue => controller.text.isNotEmpty;
  bool get masked => mode == _SensitiveMode.masked && hasValue;

  @override
  void initState() {
    super.initState();
    mode = hasValue ? _SensitiveMode.masked : _SensitiveMode.empty;
    listenToValue();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) portal.show();
    });
  }

  void listenToValue() {
    listened = controller;
    listened!.addListener(valueChanged);
  }

  void valueChanged() {
    if (!mounted) return;
    setState(() {
      if (!hasValue && mode == _SensitiveMode.masked) {
        mode = _SensitiveMode.empty;
      }
    });
  }

  @override
  void didUpdateWidget(SteyInput old) {
    if (old.controller != widget.controller) {
      listened!.removeListener(valueChanged);
    }
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) listenToValue();
    if (!hasValue && mode == _SensitiveMode.masked) mode = _SensitiveMode.empty;
  }

  @override
  void focusChanged() {
    super.focusChanged();
    if (!focus.hasFocus && editorActivated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            editorActivated &&
            hasValue &&
            !focus.hasFocus &&
            !container.hasPrimaryFocus &&
            !eye.hasFocus &&
            !copyNode.hasFocus) {
          setState(() {
            editorActivated = false;
            mode = _SensitiveMode.masked;
          });
        }
      });
    }
  }

  @override
  void change(String value) {
    editorActivated = true;
    if (mode == _SensitiveMode.empty && value.isNotEmpty) {
      setState(() => mode = _SensitiveMode.revealed);
    }
    super.change(value);
  }

  void reveal() {
    if (!w.enabled || !masked) return;
    if (w.readOnly) editorActivated = false;
    container.requestFocus();
    setState(() => mode = _SensitiveMode.revealed);
    if (!w.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          editorActivated = true;
          focus.requestFocus();
        }
      });
    }
  }

  void hide({bool returnFocus = false}) {
    editorActivated = false;
    setState(() => mode = _SensitiveMode.masked);
    if (returnFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) container.requestFocus();
      });
    }
  }

  Future<void> copyValue() async {
    if (!w.enabled || !hasValue) return;
    final current = ++attempt, text = controller.text;
    resetCopy?.cancel();
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted || current != attempt) return;
      setState(() => copied = true);
      resetCopy = Timer(const Duration(seconds: 2), () {
        if (mounted && current == attempt) setState(() => copied = false);
      });
      w.onCopy?.call();
    } catch (error) {
      if (!mounted || current != attempt) return;
      setState(() => copied = false);
      w.onCopyError?.call(error);
    }
  }

  @override
  void dispose() {
    attempt++;
    resetCopy?.cancel();
    listened?.removeListener(valueChanged);
    container.dispose();
    eye.dispose();
    copyNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context),
        size = w.size,
        ja = SteyMessages.of(context).japanese,
        name = w.semanticLabel ?? w.label ?? (ja ? '機密情報' : 'Sensitive value'),
        maskedName = w.label ?? (ja ? '機密情報' : 'Sensitive value'),
        showEye =
            w.enabled &&
            (mode == _SensitiveMode.revealed ||
                mode == _SensitiveMode.empty && hasValue),
        iconSize = size.fontSize == 12 ? 12.0 : 16.0,
        reserve = [20.0, 24.0, 32.0, 40.0][size.index],
        radius = size == SteySize.xs ? 4.0 : size.radius,
        line = size.fontSize == 12 ? 16.0 : 21.0,
        errorStyle =
            w.variant == SteyInputVariant.error ||
            w.variant == null && w.error?.isNotEmpty == true,
        ringColor = errorStyle
            ? c.danger
            : within
            ? c.focus.withValues(alpha: .5)
            : c.line,
        style = TextStyle(
          fontFamily: 'Inter',
          package: 'stey_ui_modern',
          fontSize: size.fontSize,
          height: line / size.fontSize,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: w.enabled ? c.text : c.subtle,
        );
    focus.skipTraversal = masked;
    eye.skipTraversal = !showEye;
    Widget editor = ExcludeSemantics(
      excluding: masked,
      child: Semantics(
        label: name,
        isRequired: w.required,
        validationResult: w.error?.isNotEmpty == true
            ? SemanticsValidationResult.invalid
            : SemanticsValidationResult.none,
        child: IgnorePointer(
          ignoring: masked,
          child: TextField(
            controller: controller,
            focusNode: focus,
            onTap: () => editorActivated = true,
            enabled: w.enabled,
            readOnly: w.readOnly || masked,
            obscureText: mode != _SensitiveMode.revealed,
            onChanged: change,
            onSubmitted: w.onSubmitted,
            autofocus: w.autofocus,
            keyboardType: w.keyboardType,
            textInputAction: w.textInputAction,
            inputFormatters: w.inputFormatters,
            autofillHints: w.autofillHints,
            style: style.copyWith(
              color: masked ? Colors.transparent : style.color,
            ),
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
                size.padding,
                (size.height - line) / 2,
                size.padding + reserve,
                (size.height - line) / 2,
              ),
            ),
          ),
        ),
      ),
    );
    final maskText = masked && w.enabled && (maskHovered || within)
        ? (ja ? 'クリックして表示' : 'Click to reveal')
        : '••••••••';
    Widget body = CustomPaint(
      foregroundPainter: _InputRing(ringColor, radius, within ? 1.5 : 1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.control,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: SizedBox(
          height: size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: editor),
              if (masked)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  right: reserve,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => maskHovered = true),
                    onExit: (_) => setState(() => maskHovered = false),
                    child: ExcludeSemantics(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: size.padding),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ClipRect(
                            child: Text(
                              maskText,
                              maxLines: 1,
                              softWrap: false,
                              style: style.copyWith(
                                color: w.enabled && (maskHovered || within)
                                    ? c.subtle
                                    : c.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: size.padding,
                top: (size.height - iconSize) / 2,
                child: Opacity(
                  opacity: showEye ? 1 : 0,
                  alwaysIncludeSemantics: true,
                  child: IgnorePointer(
                    ignoring: !showEye,
                    child: _SensitiveAction(
                      focusNode: eye,
                      label: mode == _SensitiveMode.revealed
                          ? (ja ? '値を隠す' : 'Hide value')
                          : (ja ? '値を表示' : 'Reveal value'),
                      enabled: w.enabled,
                      onPressed: () {
                        if (mode == _SensitiveMode.revealed) {
                          hide();
                        } else if (mode == _SensitiveMode.empty && hasValue) {
                          setState(() => mode = _SensitiveMode.revealed);
                        }
                      },
                      child: CustomPaint(
                        size: Size.square(iconSize),
                        painter: _SensitiveEye(
                          c.subtle,
                          mode == _SensitiveMode.revealed,
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
    );
    body = MouseRegion(
      cursor: !w.enabled
          ? SystemMouseCursors.forbidden
          : masked
          ? SystemMouseCursors.click
          : SystemMouseCursors.text,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() {
        hovered = false;
        maskHovered = false;
      }),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        button: masked,
        enabled: masked ? w.enabled : null,
        focusable: masked && w.enabled,
        focused: masked ? container.hasFocus : null,
        onFocus: masked && w.enabled ? container.requestFocus : null,
        label: masked
            ? (ja ? '$maskedName、非表示。' : '$maskedName, masked.')
            : null,
        hint: masked
            ? (ja ? 'クリックまたはEnterで表示します。' : 'Click or press Enter to reveal.')
            : null,
        onTap: masked && w.enabled ? reveal : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: masked && w.enabled ? reveal : null,
          child: body,
        ),
      ),
    );
    body = Focus(
      focusNode: container,
      canRequestFocus: w.enabled,
      skipTraversal: !masked,
      includeSemantics: false,
      onFocusChange: (v) => setState(() => within = v),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent || eye.hasFocus || copyNode.hasFocus) {
          return KeyEventResult.ignored;
        }
        if (masked &&
            w.enabled &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          reveal();
          return KeyEventResult.handled;
        }
        if (mode == _SensitiveMode.revealed &&
            focus.hasFocus &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          hide(returnFocus: true);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: OverlayPortal.overlayChildLayoutBuilder(
        controller: portal,
        overlayChildBuilder: (context, info) {
          if (!w.enabled || !hasValue) return const SizedBox.shrink();
          final anchor = MatrixUtils.transformRect(
                info.childPaintTransform,
                Offset.zero & info.childSize,
              ),
              text = copied
                  ? (ja ? 'コピーしました' : 'Copied')
                  : (ja ? 'コピー' : 'Copy'),
              textStyle = style.copyWith(
                fontSize: 12,
                height: 16 / 12,
                color: Colors.white,
              ),
              p = TextPainter(
                text: TextSpan(text: text, style: textStyle),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(),
              width = p.width + 16,
              height = p.height + 4;
          p.dispose();
          return Positioned(
            left: anchor.right - 8 - width,
            top: anchor.top - 1 - height,
            child: MouseRegion(
              onEnter: (_) => setState(() => copyHovered = true),
              onExit: (_) => setState(() => copyHovered = false),
              child: AnimatedOpacity(
                opacity: hovered || within || copyHovered ? 1 : 0,
                alwaysIncludeSemantics: true,
                duration: const Duration(milliseconds: 150),
                curve: const Cubic(.4, 0, .2, 1),
                child: _SensitiveAction(
                  focusNode: copyNode,
                  label: copied
                      ? (ja ? 'コピーしました' : 'Copied')
                      : (ja ? 'コピー' : 'Copy'),
                  enabled: true,
                  onPressed: () {
                    copyValue();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.brand,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                    child: Text(text, style: textStyle),
                  ),
                ),
              ),
            ),
          );
        },
        child: body,
      ),
    );
    body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        body,
        Semantics(
          liveRegion: true,
          child: SizedBox.shrink(
            child: Text(
              [
                if (masked) ja ? '値は非表示です' : 'Value hidden',
                if (copied) ja ? 'クリップボードにコピーしました' : 'Copied to clipboard',
              ].join(' '),
            ),
          ),
        ),
      ],
    );
    return w.label?.isNotEmpty == true
        ? SteyField(
            label: w.label,
            description: w.description,
            error: w.error,
            required: w.required,
            labelTooltip: w.labelTooltip,
            onLabelTap: w.enabled ? focus.requestFocus : null,
            child: body,
          )
        : body;
  }
}

class _SensitiveAction extends StatefulWidget {
  const _SensitiveAction({
    required this.focusNode,
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.child,
  });
  final FocusNode focusNode;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final Widget child;
  @override
  State<_SensitiveAction> createState() => _SensitiveActionState();
}

class _SensitiveActionState extends State<_SensitiveAction> {
  bool focusVisible = false, hover = false, space = false;
  void trigger() {
    if (widget.enabled) {
      widget.focusNode.requestFocus();
      widget.onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    Widget child = widget.child;
    if (child is CustomPaint && child.painter is _SensitiveEye) {
      final painter = child.painter! as _SensitiveEye;
      child = CustomPaint(
        size: child.size,
        painter: _SensitiveEye(
          hover || widget.focusNode.hasFocus ? c.text : c.subtle,
          painter.slash,
        ),
      );
    } else if (hover) {
      child = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          1.2,
          0,
          0,
          0,
          0,
          0,
          1.2,
          0,
          0,
          0,
          0,
          0,
          1.2,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: child,
      );
    }
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: (_, e) {
        if (e.logicalKey == LogicalKeyboardKey.space) {
          if (e is KeyDownEvent) space = true;
          if (e is KeyUpEvent && space) {
            space = false;
            trigger();
          }
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.enter) {
          if (e is KeyDownEvent || e is KeyRepeatEvent) trigger();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        onShowFocusHighlight: (v) => setState(() => focusVisible = v),
        onFocusChange: (v) {
          if (!v) space = false;
          setState(() {});
        },
        child: Semantics(
          button: true,
          label: widget.label,
          enabled: widget.enabled,
          excludeSemantics: true,
          onTap: widget.enabled ? trigger : null,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => hover = true),
            onExit: (_) => setState(() => hover = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: widget.enabled ? trigger : null,
              child: CustomPaint(
                foregroundPainter: focusVisible
                    ? _InputRing(c.brand, 4, 2)
                    : null,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SensitiveEye extends CustomPainter {
  const _SensitiveEye(this.color, this.slash);
  final Color color;
  final bool slash;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 256, size.height / 256);
    canvas.drawPath(slash ? _slash : _eye, Paint()..color = color);
    canvas.restore();
  }

  static final _eye = Path()
    ..moveTo(247.31, 124.76)
    ..cubicTo(246.96, 123.97, 238.49, 105.18, 219.66, 86.35)
    ..cubicTo(194.57, 61.26, 162.88, 48, 128, 48)
    ..cubicTo(93.12, 48, 61.43, 61.26, 36.34, 86.35)
    ..cubicTo(17.51, 105.18, 9, 124, 8.69, 124.76)
    ..arcToPoint(
      Offset(8.69, 131.26),
      radius: Radius.elliptical(8, 8),
      rotation: 0,
      largeArc: false,
      clockwise: false,
    )
    ..cubicTo(9.04, 132.05, 17.51, 150.83, 36.34, 169.66)
    ..cubicTo(61.43, 194.74, 93.12, 208, 128, 208)
    ..cubicTo(162.88, 208, 194.57, 194.74, 219.66, 169.66)
    ..cubicTo(238.49, 150.83, 246.96, 132.05, 247.31, 131.26)
    ..arcToPoint(
      Offset(247.31, 124.76),
      radius: Radius.elliptical(8, 8),
      rotation: 0,
      largeArc: false,
      clockwise: false,
    )
    ..close()
    ..moveTo(128, 192)
    ..cubicTo(97.22, 192, 70.33, 180.81, 48.07, 158.75)
    ..arcToPoint(
      Offset(25, 128),
      radius: Radius.elliptical(133.47, 133.47),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..arcToPoint(
      Offset(48.07, 97.25),
      radius: Radius.elliptical(133.33, 133.33),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..cubicTo(70.33, 75.19, 97.22, 64, 128, 64)
    ..cubicTo(158.78, 64, 185.67, 75.19, 207.93, 97.25)
    ..arcToPoint(
      Offset(231.05, 128),
      radius: Radius.elliptical(133.46, 133.46),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..cubicTo(223.84, 141.46, 192.43, 192, 128, 192)
    ..close()
    ..moveTo(128, 80)
    ..arcToPoint(
      Offset(176, 128),
      radius: Radius.elliptical(48, 48),
      rotation: 0,
      largeArc: true,
      clockwise: false,
    )
    ..arcToPoint(
      Offset(128, 80),
      radius: Radius.elliptical(48.05, 48.05),
      rotation: 0,
      largeArc: false,
      clockwise: false,
    )
    ..close()
    ..moveTo(128, 160)
    ..arcToPoint(
      Offset(160, 128),
      radius: Radius.elliptical(32, 32),
      rotation: 0,
      largeArc: true,
      clockwise: true,
    )
    ..arcToPoint(
      Offset(128, 160),
      radius: Radius.elliptical(32, 32),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..close();
  static final _slash = Path()
    ..moveTo(53.92, 34.62)
    ..arcToPoint(
      Offset(42.08, 45.38),
      radius: Radius.elliptical(8, 8),
      rotation: 0,
      largeArc: true,
      clockwise: false,
    )
    ..lineTo(61.32, 66.55)
    ..cubicTo(25, 88.84, 9.38, 123.2, 8.69, 124.76)
    ..arcToPoint(
      Offset(8.69, 131.26),
      radius: Radius.elliptical(8, 8),
      rotation: 0,
      largeArc: false,
      clockwise: false,
    )
    ..cubicTo(9.04, 132.05, 17.51, 150.83, 36.34, 169.66)
    ..cubicTo(61.43, 194.74, 93.12, 208, 128, 208)
    ..arcToPoint(
      Offset(180.07, 197.17),
      radius: Radius.elliptical(127.11, 127.11),
      rotation: 0,
      largeArc: false,
      clockwise: false,
    )
    ..lineTo(202.07, 221.38)
    ..arcToPoint(
      Offset(213.91, 210.62),
      radius: Radius.elliptical(8, 8),
      rotation: 0,
      largeArc: true,
      clockwise: false,
    )
    ..close()
    ..moveTo(101.25, 110.46)
    ..lineTo(142.92, 156.31)
    ..arcToPoint(
      Offset(101.25, 110.46),
      radius: Radius.elliptical(32, 32),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..close()
    ..moveTo(128, 192)
    ..cubicTo(97.22, 192, 70.33, 180.81, 48.07, 158.75)
    ..arcToPoint(
      Offset(25, 128),
      radius: Radius.elliptical(133.16, 133.16),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..cubicTo(29.69, 119.21, 44.66, 94.61, 72.35, 78.62)
    ..lineTo(90.35, 98.37)
    ..arcToPoint(
      Offset(154.01, 168.37),
      radius: Radius.elliptical(48, 48),
      rotation: 0,
      largeArc: false,
      clockwise: false,
    )
    ..lineTo(168.74, 184.57)
    ..arcToPoint(
      Offset(128, 192),
      radius: Radius.elliptical(112, 112),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..close()
    ..moveTo(134, 96.57)
    ..arcToPoint(
      Offset(137, 80.85),
      radius: Radius.elliptical(8, 8),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..arcToPoint(
      Offset(175.77, 123.49),
      radius: Radius.elliptical(48.16, 48.16),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..arcToPoint(
      Offset(168.55, 132.2),
      radius: Radius.elliptical(8, 8),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..arcToPoint(
      Offset(167.8, 132.2),
      radius: Radius.elliptical(6.39, 6.39),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..arcToPoint(
      Offset(159.8, 124.94),
      radius: Radius.elliptical(8, 8),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..arcToPoint(
      Offset(134, 96.57),
      radius: Radius.elliptical(32.09, 32.09),
      rotation: 0,
      largeArc: false,
      clockwise: false,
    )
    ..close()
    ..moveTo(247.28, 131.26)
    ..cubicTo(246.86, 132.2, 236.73, 154.63, 213.92, 175.06)
    ..arcToPoint(
      Offset(203.25, 163.14),
      radius: Radius.elliptical(8, 8),
      rotation: 0,
      largeArc: true,
      clockwise: true,
    )
    ..arcToPoint(
      Offset(231.05, 128),
      radius: Radius.elliptical(132.77, 132.77),
      rotation: 0,
      largeArc: false,
      clockwise: false,
    )
    ..arcToPoint(
      Offset(207.93, 97.23),
      radius: Radius.elliptical(133.15, 133.15),
      rotation: 0,
      largeArc: false,
      clockwise: false,
    )
    ..cubicTo(185.67, 75.19, 158.78, 64, 128, 64)
    ..arcToPoint(
      Offset(108.64, 65.57),
      radius: Radius.elliptical(118.37, 118.37),
      rotation: 0,
      largeArc: false,
      clockwise: false,
    )
    ..arcToPoint(
      Offset(106, 49.79),
      radius: Radius.elliptical(8, 8),
      rotation: 0,
      largeArc: true,
      clockwise: true,
    )
    ..arcToPoint(
      Offset(128, 48),
      radius: Radius.elliptical(134, 134),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..cubicTo(162.88, 48, 194.57, 61.26, 219.66, 86.35)
    ..cubicTo(238.49, 105.18, 246.96, 123.97, 247.31, 124.76)
    ..arcToPoint(
      Offset(247.31, 131.26),
      radius: Radius.elliptical(8, 8),
      rotation: 0,
      largeArc: false,
      clockwise: true,
    )
    ..close();
  @override
  bool shouldRepaint(_SensitiveEye old) =>
      color != old.color || slash != old.slash;
}
