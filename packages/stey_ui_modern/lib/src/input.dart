import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'label.dart';

export 'label.dart';
import 'theme.dart';
import 'messages.dart';

part 'input_group.dart';
part 'sensitive_input.dart';
part 'tag_input.dart';

class SteyField extends StatelessWidget {
  const SteyField({
    super.key,
    required this.child,
    this.label,
    this.description,
    this.error,
    this.required,
    this.hideLabel = false,
    this.labelTooltip,
    this.onLabelTap,
  });
  final Widget child;
  final String? label, description, error, labelTooltip;
  final bool? required;
  final bool hideLabel;
  final VoidCallback? onLabelTap;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null && !hideLabel)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SteyLabel(
            label!,
            required: required,
            tooltip: labelTooltip,
            onTap: onLabelTap,
          ),
        ),
      child,
      if (description != null && (error == null || error!.isEmpty))
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            description!,
            style: TextStyle(
              fontSize: 13,
              height: 1.375,
              color: SteyTheme.colorsOf(context).subtle,
            ),
          ),
        ),
      if (error != null && error!.isNotEmpty)
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: TextStyle(
                fontSize: 13,
                height: 1.375,
                color: SteyTheme.colorsOf(context).dangerText,
              ),
            ),
          ),
        ),
    ],
  );
}

enum SteyInputVariant { standard, error }

class SteyInput extends StatefulWidget {
  const SteyInput({
    super.key,
    this.controller,
    this.value,
    this.defaultValue = '',
    this.label,
    this.placeholder,
    this.description,
    this.error,
    this.labelTooltip,
    this.variant,
    this.onChanged,
    this.onValueChange,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.required,
    this.obscureText = false,
    this.size = SteySize.base,
    this.maxLines = 1,
    this.autoResize = false,
    this.minRows = 1,
    this.maxRows,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.focusNode,
    this.prefix,
    this.suffix,
    this.inputFormatters,
    this.autofocus = false,
    this.semanticLabel,
  }) : assert(controller == null || value == null),
       assert(maxLines > 0),
       assert(minRows > 0 && (maxRows == null || maxRows >= minRows)),
       assert(!obscureText || (maxLines == 1 && !autoResize));
  final TextEditingController? controller;
  final String? value;
  final String defaultValue;
  final String? label,
      placeholder,
      description,
      error,
      semanticLabel,
      labelTooltip;
  final SteyInputVariant? variant;
  final ValueChanged<String>? onChanged, onValueChange, onSubmitted;
  final bool enabled, readOnly, obscureText, autofocus, autoResize;
  final bool? required;
  final SteySize size;
  final int maxLines, minRows;
  final int? maxRows;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final Widget? prefix, suffix;
  final List<TextInputFormatter>? inputFormatters;
  @override
  State<SteyInput> createState() => _SteyInputState();
}

class _SteyInputState extends State<SteyInput> {
  TextEditingController? internal;
  FocusNode? internalFocus;
  _SteyInputGroupState? groupOwner;
  void groupValueChanged() {
    if (mounted) setState(() {});
  }

  TextEditingController get controller => widget.controller ?? internal!;
  FocusNode get focus => widget.focusNode ?? internalFocus!;
  bool get multiline => widget.maxLines != 1 || widget.autoResize;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      internal = TextEditingController(
        text: widget.value ?? widget.defaultValue,
      );
    }
    if (widget.focusNode == null) internalFocus = FocusNode();
    focus.addListener(focusChanged);
    if (widget is SteyInputGroupInput) {
      controller.addListener(groupValueChanged);
    }
  }

  @override
  void didUpdateWidget(SteyInput old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      final previous = old.controller?.value ?? internal!.value;
      if (widget is SteyInputGroupInput) {
        (old.controller ?? internal!).removeListener(groupValueChanged);
      }
      internal?.dispose();
      internal = widget.controller == null
          ? TextEditingController.fromValue(previous)
          : null;
      if (widget is SteyInputGroupInput) {
        controller.addListener(groupValueChanged);
      }
    }
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? internalFocus!).removeListener(focusChanged);
      internalFocus?.dispose();
      internalFocus = widget.focusNode == null ? FocusNode() : null;
      focus.addListener(focusChanged);
    }
    restoreValue();
  }

  void focusChanged() {
    if (mounted) setState(() {});
  }

  void restoreValue() {
    final value = widget.value;
    if (value == null || controller.text == value) return;
    final selection = controller.selection;
    controller.value = TextEditingValue(
      text: value,
      selection: selection.isValid
          ? TextSelection(
              baseOffset: selection.baseOffset.clamp(0, value.length),
              extentOffset: selection.extentOffset.clamp(0, value.length),
            )
          : TextSelection.collapsed(offset: value.length),
    );
  }

  void change(String value) {
    widget.onChanged?.call(value);
    widget.onValueChange?.call(value);
    if (widget.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) restoreValue();
      });
    }
  }

  @override
  void dispose() {
    groupOwner?.editors.remove(this);
    if (widget is SteyInputGroupInput) {
      controller.removeListener(groupValueChanged);
    }
    focus.removeListener(focusChanged);
    internal?.dispose();
    internalFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget is SteyInputGroupInput
        ? _GroupScope.maybeOf(context)
        : null;
    if (group != null) return _buildGroupEditor(this, context, group);

    final c = SteyTheme.colorsOf(context),
        hasError = widget.error?.isNotEmpty ?? false,
        errorStyle =
            widget.variant == SteyInputVariant.error ||
            (widget.variant == null && hasError),
        focused = focus.hasFocus && widget.enabled,
        ringColor = errorStyle
            ? c.danger
            : focused
            ? c.focus.withValues(alpha: .5)
            : c.line,
        fontSize = widget.size.fontSize,
        lineHeight = fontSize == 12 ? 16 / 12 : 1.5;
    final style = TextStyle(
      fontFamily: 'Inter',
      package: 'stey_ui_modern',
      fontSize: fontSize,
      height: lineHeight,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: widget.enabled ? c.text : c.inactive,
    );
    return SteyField(
      label: widget.label?.isNotEmpty == true
          ? widget.label
          : hasError || widget.description?.isNotEmpty == true
          ? ''
          : null,
      description: widget.description,
      error: widget.error,
      required: widget.required,
      labelTooltip: widget.labelTooltip,
      onLabelTap: widget.enabled ? focus.requestFocus : null,
      child: Semantics(
        label: widget.semanticLabel ?? widget.label ?? widget.placeholder,
        hint: hasError ? widget.error : widget.description,
        isRequired: widget.required,
        validationResult: hasError
            ? SemanticsValidationResult.invalid
            : SemanticsValidationResult.none,
        child: CustomPaint(
          foregroundPainter: _InputRing(
            ringColor,
            widget.size.radius,
            focused ? 1.5 : 1,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.control,
              borderRadius: BorderRadius.circular(widget.size.radius),
            ),
            child: SizedBox(
              height: multiline ? null : widget.size.height,
              child: TextField(
                controller: controller,
                focusNode: focus,
                onChanged: change,
                onSubmitted: widget.onSubmitted,
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                obscureText: widget.obscureText,
                autofocus: widget.autofocus,
                minLines: multiline
                    ? widget.autoResize
                          ? widget.minRows
                          : widget.maxLines
                    : 1,
                maxLines: widget.autoResize ? widget.maxRows : widget.maxLines,
                textAlignVertical: multiline
                    ? TextAlignVertical.top
                    : TextAlignVertical.center,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                autofillHints: widget.autofillHints,
                inputFormatters: widget.inputFormatters,
                style: style,
                strutStyle: StrutStyle.fromTextStyle(
                  style,
                  forceStrutHeight: true,
                ),
                cursorColor: c.text,
                decoration: InputDecoration(
                  isDense: true,
                  visualDensity: VisualDensity.standard,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  hintFadeDuration: Duration.zero,
                  hint: widget.placeholder == null
                      ? null
                      : ExcludeSemantics(
                          child: Text(
                            widget.placeholder!,
                            style: style.copyWith(color: c.placeholder),
                          ),
                        ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: widget.size.padding,
                    vertical: multiline
                        ? 8
                        : (widget.size.height - fontSize * lineHeight) / 2,
                  ),
                  prefixIcon: widget.prefix,
                  suffixIcon: widget.suffix,
                  prefixIconConstraints: BoxConstraints(
                    minHeight: widget.size.height,
                    minWidth: widget.size.height,
                  ),
                  suffixIconConstraints: BoxConstraints(
                    minHeight: widget.size.height,
                    minWidth: widget.size.height,
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

class _InputRing extends CustomPainter {
  const _InputRing(this.color, this.radius, this.width);
  final Color color;
  final double radius, width;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(width / 2),
      Radius.circular(radius + width / 2),
    ),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width,
  );
  @override
  bool shouldRepaint(_InputRing old) =>
      color != old.color || radius != old.radius || width != old.width;
}

class SteyTextarea extends SteyInput {
  const SteyTextarea({
    super.key,
    super.controller,
    super.value,
    super.defaultValue,
    super.label,
    super.placeholder,
    super.description,
    super.error,
    super.labelTooltip,
    super.variant,
    super.onChanged,
    super.onValueChange,
    super.enabled,
    super.readOnly,
    super.required,
    super.size,
    super.maxLines = 4,
    super.autoResize,
    super.minRows,
    super.maxRows,
    super.keyboardType = TextInputType.multiline,
    super.textInputAction,
    super.autofillHints,
    super.focusNode,
    super.inputFormatters,
    super.autofocus,
    super.semanticLabel,
  });
}

/// The upstream InputArea name, with its browser-default two-row height.
class SteyInputArea extends SteyTextarea {
  const SteyInputArea({
    super.key,
    super.controller,
    super.value,
    super.defaultValue,
    super.label,
    super.placeholder,
    super.description,
    super.error,
    super.labelTooltip,
    super.variant,
    super.onChanged,
    super.onValueChange,
    super.enabled,
    super.readOnly,
    super.required,
    super.size,
    super.maxLines = 2,
    super.autoResize,
    super.minRows,
    super.maxRows,
    super.keyboardType,
    super.textInputAction,
    super.autofillHints,
    super.focusNode,
    super.inputFormatters,
    super.autofocus,
    super.semanticLabel,
  });
}
