part of 'input.dart';

/// Generated messages can be overridden independently, as in Kumo TagInput.
class SteyTagInputLabels {
  const SteyTagInputLabels({
    this.input,
    this.removeValue,
    this.invalidValue,
    this.maxValuesReached,
  });
  final String? input;
  final String Function(String)? removeValue, invalidValue;
  final String Function(int)? maxValuesReached;
}

/// A native, wrapping editor for accepted tags and an independent text draft.
class SteyTagInput extends StatefulWidget {
  const SteyTagInput({
    super.key,
    this.value,
    this.defaultValue = const [],
    this.onChanged,
    this.onValueChange,
    this.validateValue,
    this.maxValues,
    this.labels = const SteyTagInputLabels(),
    this.label,
    this.placeholder,
    this.description,
    this.error,
    this.labelTooltip,
    this.variant,
    this.enabled = true,
    this.readOnly = false,
    this.required,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.onDraftChange,
    this.onKeyEvent,
    this.onBlur,
    this.onPaste,
    this.validate,
    this.maxTags,
  });
  final List<String>? value;
  final List<String> defaultValue;
  final ValueChanged<List<String>>? onChanged, onValueChange;
  final bool Function(String value, List<String> acceptedValues)? validateValue;
  final int? maxValues;
  final SteyTagInputLabels labels;
  final String? label, placeholder, description, error, labelTooltip;
  final SteyInputVariant? variant;
  final bool enabled, readOnly, autofocus;
  final bool? required;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final ValueChanged<String>? onDraftChange;

  /// Returning handled cancels the default TagInput key behavior.
  final KeyEventResult Function(KeyEvent)? onKeyEvent;

  /// Returning false suppresses the default blur/paste behavior.
  final bool Function()? onBlur;
  final bool Function(String)? onPaste;

  /// Compatibility with the original Stey preview API.
  final String? Function(String)? validate;
  final int? maxTags;
  @override
  State<SteyTagInput> createState() => _SteyTagInputState();
}

class _SteyTagInputState extends State<SteyTagInput> {
  final controller = TextEditingController();
  late List<String> uncontrolled = List.of(widget.defaultValue);
  late FocusNode focus = widget.focusNode ?? FocusNode();
  final groupFocus = FocusNode(skipTraversal: true, canRequestFocus: false);
  String? message;
  bool editorActivated = false,
      pointerRemoving = false,
      keyboardTraversal = false;
  int pasteRevision = 0;
  List<String> get values => widget.value ?? uncontrolled;
  bool get writable => widget.enabled && !widget.readOnly;
  @override
  void initState() {
    super.initState();
    focus.addListener(focusChanged);
    groupFocus.addListener(groupChanged);
  }

  @override
  void didUpdateWidget(SteyTagInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      focus.removeListener(focusChanged);
      if (oldWidget.focusNode == null) focus.dispose();
      focus = widget.focusNode ?? FocusNode();
      focus.addListener(focusChanged);
    }
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.readOnly != widget.readOnly) {
      pasteRevision++;
    }
  }

  void groupChanged() {
    if (mounted) setState(() {});
  }

  void focusChanged() {
    if (focus.hasFocus) {
      keyboardTraversal = false;
      return;
    }
    // Web's semantic button click can move browser focus without delivering a
    // Flutter pointer-down. Treat that inner transfer like prevented mousedown.
    if (!focus.hasFocus && groupFocus.hasFocus && !keyboardTraversal) {
      pointerRemoving = true;
    }
    if (pointerRemoving) return;
    if (!focus.hasFocus &&
        (editorActivated || widget.focusNode != null || widget.autofocus)) {
      final allow = widget.onBlur?.call() != false;
      if (writable && allow) commit(controller.text);
    }
  }

  void finishPointerRemove() {
    if (!pointerRemoving) return;
    if (writable) focus.requestFocus();
    scheduleMicrotask(() => pointerRemoving = false);
  }

  void setValues(List<String> next) {
    if (!mounted) return;
    setState(() {
      if (widget.value == null) uncontrolled = List.of(next);
    });
    widget.onChanged?.call(List.of(next));
    widget.onValueChange?.call(List.of(next));
  }

  bool commit(String raw) {
    if (!writable) return false;
    final entries = raw
        .split(RegExp(r'[\n,]+'))
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    final next = List<String>.of(values);
    final max = widget.maxValues ?? widget.maxTags;
    final ja = SteyMessages.of(context).japanese;
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      if (next.contains(entry)) continue;
      String? failure;
      if (max != null && next.length >= max) {
        failure =
            widget.labels.maxValuesReached?.call(max) ??
            (ja ? 'タグは$max個までです。' : 'Limit of $max tags reached.');
      } else {
        failure = widget.validate?.call(entry);
        if (failure == null &&
            widget.validateValue?.call(entry, List.of(next)) == false) {
          failure =
              widget.labels.invalidValue?.call(entry) ??
              (ja ? '「$entry」は使用できません。' : '"$entry" is not valid.');
        }
      }
      if (failure != null) {
        final rest = entries.sublist(index).join(', ');
        controller.value = TextEditingValue(
          text: rest,
          selection: TextSelection.collapsed(offset: rest.length),
        );
        setState(() => message = failure);
        setValues(next);
        return false;
      }
      next.add(entry);
    }
    controller.clear();
    setState(() => message = null);
    setValues(next);
    return true;
  }

  KeyEventResult keyEvent(FocusNode node, KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      keyboardTraversal = event is! KeyUpEvent;
    }
    final custom = widget.onKeyEvent?.call(event);
    if (custom != null && custom != KeyEventResult.ignored) return custom;
    if (!writable || event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    editorActivated = true;
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    final platform = Theme.of(context).platform;
    final pasteModifier =
        platform == TargetPlatform.macOS || platform == TargetPlatform.iOS
        ? keyboard.isMetaPressed
        : keyboard.isControlPressed;
    // Web's default text shortcuts delegate paste to the browser, bypassing
    // overridable PasteTextIntent. Handle it here before single-line filtering.
    if (key == LogicalKeyboardKey.keyV && pasteModifier ||
        key == LogicalKeyboardKey.insert && keyboard.isShiftPressed) {
      paste();
      return KeyEventResult.handled;
    }
    if (!controller.value.composing.isCollapsed &&
        controller.value.composing.isValid) {
      return KeyEventResult.ignored;
    }
    if (controller.text.isEmpty && key == LogicalKeyboardKey.backspace) {
      setValues(values.isEmpty ? [] : values.sublist(0, values.length - 1));
      return KeyEventResult.handled;
    }
    if (controller.text.isEmpty ||
        ![
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.numpadEnter,
          LogicalKeyboardKey.comma,
          LogicalKeyboardKey.tab,
        ].contains(key)) {
      return KeyEventResult.ignored;
    }
    final accepted = commit(controller.text);
    // A failed Tab may move focus; blur then retries, matching upstream.
    return key != LogicalKeyboardKey.tab || accepted
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  Future<void> paste() async {
    if (!writable) return;
    editorActivated = true;
    final attempt = ++pasteRevision, before = controller.value;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted ||
        !writable ||
        attempt != pasteRevision ||
        controller.value != before ||
        data?.text == null) {
      return;
    }
    final text = data!.text!;
    if (widget.onPaste?.call(text) == false) return;
    final selection = before.selection.isValid
        ? before.selection
        : TextSelection.collapsed(offset: before.text.length);
    final next = before.text.replaceRange(selection.start, selection.end, text);
    if (text.contains(RegExp(r'[\n,]'))) {
      commit(next);
    } else {
      controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(
          offset: selection.start + text.length,
        ),
      );
      draftChanged(next);
    }
  }

  void draftChanged(String text) {
    editorActivated = true;
    setState(() => message = null);
    widget.onDraftChange?.call(text);
  }

  @override
  void dispose() {
    pasteRevision++;
    focus.removeListener(focusChanged);
    if (widget.focusNode == null) focus.dispose();
    groupFocus.removeListener(groupChanged);
    groupFocus.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context),
        ja = SteyMessages.of(context).japanese;
    final error = widget.error?.isNotEmpty == true ? widget.error : message;
    final invalid = error?.isNotEmpty == true;
    final errorStyle =
        widget.variant == SteyInputVariant.error ||
        widget.variant == null && invalid;
    final ringColor = errorStyle
        ? c.danger
        : groupFocus.hasFocus && widget.enabled
        ? c.focus.withValues(alpha: .5)
        : c.line;
    final style = TextStyle(
      fontFamily: 'Inter',
      package: 'stey_ui_modern',
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: widget.enabled ? c.text : c.inactive,
    );
    final hasField =
        widget.label?.isNotEmpty == true ||
        widget.description?.isNotEmpty == true ||
        invalid;
    return SteyField(
      label: hasField ? widget.label ?? '' : null,
      labelTooltip: widget.labelTooltip,
      description: widget.description,
      error: error,
      // Kumo TagInput forwards required to the editor, not Field's optional label.
      onLabelTap: widget.enabled
          ? () {
              editorActivated = true;
              focus.requestFocus();
            }
          : null,
      child: Focus(
        focusNode: groupFocus,
        includeSemantics: false,
        onKeyEvent: keyEvent,
        child: CustomPaint(
          foregroundPainter: _InputRing(
            ringColor,
            8,
            groupFocus.hasFocus && widget.enabled ? 1.5 : 1,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.control,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: TextFieldTapRegion(
                child: _TagWrap(
                  direction: Directionality.of(context),
                  children: [
                    for (final item in values)
                      Container(
                        key: ValueKey(item),
                        height: 24,
                        padding: const EdgeInsets.only(left: 8, right: 3),
                        decoration: BoxDecoration(
                          color: c.overlay,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        foregroundDecoration: BoxDecoration(
                          border: Border.all(color: c.hairline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                item,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style.copyWith(color: c.text),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Listener(
                              onPointerDown: (_) {
                                if (writable && focus.hasFocus) {
                                  pointerRemoving = true;
                                }
                              },
                              onPointerUp: (_) => finishPointerRemove(),
                              onPointerCancel: (_) => finishPointerRemove(),
                              child: SteyButton(
                                variant: SteyButtonVariant.ghost,
                                size: SteySize.xs,
                                shape: SteyButtonShape.square,
                                semanticLabel:
                                    widget.labels.removeValue?.call(item) ??
                                    (ja ? '$itemを削除' : 'Remove $item'),
                                onPressed: writable
                                    ? () {
                                        setValues(
                                          values
                                              .where((v) => v != item)
                                              .toList(),
                                        );
                                        finishPointerRemove();
                                      }
                                    : null,
                                child: CustomPaint(
                                  size: const Size(10, 10),
                                  painter: _TagClosePainter(
                                    writable ? c.text : c.inactive,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Semantics(
                      container: true,
                      label:
                          widget.semanticLabel ??
                          widget.label ??
                          widget.labels.input ??
                          (ja ? 'タグを追加' : 'Add tag'),
                      hint: error ?? widget.description,
                      isRequired: widget.required == true && values.isEmpty,
                      validationResult: invalid
                          ? SemanticsValidationResult.invalid
                          : SemanticsValidationResult.none,
                      child: Actions(
                        actions: {
                          PasteTextIntent: CallbackAction<PasteTextIntent>(
                            onInvoke: (_) {
                              paste();
                              return null;
                            },
                          ),
                        },
                        child: Shortcuts(
                          shortcuts: const {
                            SingleActivator(
                              LogicalKeyboardKey.arrowLeft,
                            ): ExtendSelectionByCharacterIntent(
                              forward: false,
                              collapseSelection: true,
                            ),
                            SingleActivator(
                              LogicalKeyboardKey.arrowRight,
                            ): ExtendSelectionByCharacterIntent(
                              forward: true,
                              collapseSelection: true,
                            ),
                            SingleActivator(
                              LogicalKeyboardKey.arrowLeft,
                              shift: true,
                            ): ExtendSelectionByCharacterIntent(
                              forward: false,
                              collapseSelection: false,
                            ),
                            SingleActivator(
                              LogicalKeyboardKey.arrowRight,
                              shift: true,
                            ): ExtendSelectionByCharacterIntent(
                              forward: true,
                              collapseSelection: false,
                            ),
                            SingleActivator(
                              LogicalKeyboardKey.home,
                            ): ExtendSelectionToLineBreakIntent(
                              forward: false,
                              collapseSelection: true,
                            ),
                            SingleActivator(
                              LogicalKeyboardKey.end,
                            ): ExtendSelectionToLineBreakIntent(
                              forward: true,
                              collapseSelection: true,
                            ),
                            SingleActivator(
                              LogicalKeyboardKey.home,
                              shift: true,
                            ): ExtendSelectionToLineBreakIntent(
                              forward: false,
                              collapseSelection: false,
                            ),
                            SingleActivator(
                              LogicalKeyboardKey.end,
                              shift: true,
                            ): ExtendSelectionToLineBreakIntent(
                              forward: true,
                              collapseSelection: false,
                            ),
                          },
                          child: TextField(
                            controller: controller,
                            focusNode: focus,
                            enabled: widget.enabled,
                            readOnly: widget.readOnly,
                            autofocus: widget.autofocus,
                            onTap: () => editorActivated = true,
                            selectAllOnFocus: false,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: style,
                            strutStyle: StrutStyle.fromTextStyle(
                              style,
                              forceStrutHeight: true,
                            ),
                            cursorColor: c.text,
                            textInputAction: TextInputAction.done,
                            onEditingComplete: () {},
                            onChanged: draftChanged,
                            onSubmitted: (_) {
                              if (writable &&
                                  controller.text.isNotEmpty &&
                                  controller.value.composing.isCollapsed) {
                                commit(controller.text);
                              }
                            },
                            contextMenuBuilder: (context, editable) =>
                                AdaptiveTextSelectionToolbar.buttonItems(
                                  anchors: editable.contextMenuAnchors,
                                  buttonItems: [
                                    for (final item
                                        in editable.contextMenuButtonItems)
                                      item.type == ContextMenuButtonType.paste
                                          ? ContextMenuButtonItem(
                                              type: item.type,
                                              onPressed: () {
                                                paste();
                                                editable.hideToolbar();
                                              },
                                            )
                                          : item,
                                  ],
                                ),
                            decoration: InputDecoration(
                              isDense: true,
                              visualDensity: VisualDensity.standard,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              filled: false,
                              hintFadeDuration: Duration.zero,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              hint: widget.placeholder == null
                                  ? null
                                  : ExcludeSemantics(
                                      child: Text(
                                        widget.placeholder!,
                                        style: style.copyWith(
                                          color: c.placeholder,
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
        ),
      ),
    );
  }
}

class _TagClosePainter extends CustomPainter {
  const _TagClosePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    // Phosphor Regular X: diagonal centers 56..200 on its 256-unit viewBox.
    final scale = size.width / 256;
    final p = Paint()
      ..color = color
      ..strokeWidth = 16 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(56 * scale, 56 * scale),
      Offset(200 * scale, 200 * scale),
      p,
    );
    canvas.drawLine(
      Offset(200 * scale, 56 * scale),
      Offset(56 * scale, 200 * scale),
      p,
    );
  }

  @override
  bool shouldRepaint(_TagClosePainter old) => color != old.color;
}

/// CSS flex-wrap with a final editor that grows into the remaining row (min128).
class _TagWrap extends MultiChildRenderObjectWidget {
  const _TagWrap({required super.children, required this.direction});
  final TextDirection direction;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTagWrap(direction);
  @override
  void updateRenderObject(BuildContext context, _RenderTagWrap renderObject) {
    if (renderObject.direction != direction) {
      renderObject.direction = direction;
      renderObject.markNeedsLayout();
    }
  }
}

class _TagParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTagWrap extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        > {
  _RenderTagWrap(this.direction);
  TextDirection direction;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ContainerBoxParentData<RenderBox>) {
      child.parentData = _TagParentData();
    }
  }

  Size layoutChildren(BoxConstraints constraints, {required bool dry}) {
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : 320.0;
    var x = 0.0, y = 0.0, height = 0.0;
    final row = <(RenderBox, double, Size)>[];
    void finishRow() {
      if (!dry) {
        for (final (child, dx, sz) in row) {
          (child.parentData! as ContainerBoxParentData<RenderBox>).offset =
              Offset(
                direction == TextDirection.ltr ? dx : width - dx - sz.width,
                y + (height - sz.height) / 2,
              );
        }
      }
      row.clear();
      y += height + 6;
      x = 0;
      height = 0;
    }

    RenderBox? child = firstChild;
    while (child != null) {
      final next = childAfter(child), editor = next == null;
      if (editor && x > 0 && width - x < 128) finishRow();
      final box = editor
          ? BoxConstraints.tightFor(width: math.max(128, width - x))
          : BoxConstraints(maxWidth: width);
      final sz = dry
          ? child.getDryLayout(box)
          : (child..layout(box, parentUsesSize: true)).size;
      if (!editor && x > 0 && x + sz.width > width + .001) finishRow();
      row.add((child, x, sz));
      x += sz.width + 8;
      height = math.max(height, sz.height);
      child = next;
    }
    finishRow();
    return constraints.constrain(Size(width, math.max(24, y - 6)));
  }

  @override
  void performLayout() => size = layoutChildren(constraints, dry: false);
  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      layoutChildren(constraints, dry: true);
  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
