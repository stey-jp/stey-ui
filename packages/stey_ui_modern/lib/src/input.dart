import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'theme.dart';

class SteyLabel extends StatelessWidget {
  const SteyLabel(this.text, {super.key, this.required = false});
  final String text;
  final bool required;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: text),
        if (required)
          TextSpan(
            text: ' *',
            style: TextStyle(color: SteyTheme.colorsOf(context).dangerText),
          ),
      ],
    ),
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: SteyTheme.colorsOf(context).text,
    ),
  );
}

class SteyField extends StatelessWidget {
  const SteyField({
    super.key,
    required this.child,
    this.label,
    this.description,
    this.error,
    this.required = false,
  });
  final Widget child;
  final String? label, description, error;
  final bool required;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SteyLabel(label!, required: required),
        ),
      child,
      if (description != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            description!,
            style: TextStyle(
              fontSize: 12,
              color: SteyTheme.colorsOf(context).subtle,
            ),
          ),
        ),
      if (error != null)
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error!,
              style: TextStyle(
                fontSize: 12,
                color: SteyTheme.colorsOf(context).dangerText,
              ),
            ),
          ),
        ),
    ],
  );
}

class SteyInput extends StatelessWidget {
  const SteyInput({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.description,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.obscureText = false,
    this.size = SteySize.base,
    this.maxLines = 1,
    this.keyboardType,
    this.focusNode,
    this.prefix,
    this.suffix,
    this.inputFormatters,
    this.autofocus = false,
    this.semanticLabel,
  });
  final TextEditingController? controller;
  final String? label, placeholder, description, error, semanticLabel;
  final ValueChanged<String>? onChanged, onSubmitted;
  final bool enabled, readOnly, required, obscureText, autofocus;
  final SteySize size;
  final int maxLines;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final Widget? prefix, suffix;
  final List<TextInputFormatter>? inputFormatters;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(size.radius),
          borderSide: BorderSide(color: color, width: width),
        );
    return SteyField(
      label: label,
      description: description,
      error: error,
      required: required,
      child: Semantics(
        label: semanticLabel ?? label ?? placeholder,
        textField: true,
        child: SizedBox(
          height: maxLines == 1 ? size.height : null,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            enabled: enabled,
            readOnly: readOnly,
            obscureText: obscureText,
            autofocus: autofocus,
            focusNode: focusNode,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontSize: size.fontSize,
              color: enabled ? c.text : c.subtle,
              height: 1.5,
            ),
            cursorColor: c.focus,
            decoration: InputDecoration(
              isDense: true,
              visualDensity: VisualDensity.standard,
              constraints: maxLines == 1
                  ? BoxConstraints.tightFor(height: size.height)
                  : null,
              filled: true,
              fillColor: c.control,
              hintText: placeholder,
              hintStyle: TextStyle(color: c.placeholder),
              contentPadding: EdgeInsets.symmetric(
                horizontal: size.padding,
                vertical: maxLines == 1 ? 0 : 12,
              ),
              border: border(c.line),
              enabledBorder: border(error == null ? c.line : c.dangerText),
              focusedBorder: border(
                error == null ? c.focus.withValues(alpha: .5) : c.dangerText,
                1.5,
              ),
              disabledBorder: border(c.line.withValues(alpha: .5)),
              prefixIcon: prefix,
              suffixIcon: suffix,
              prefixIconConstraints: BoxConstraints(
                minHeight: size.height,
                minWidth: size.height,
              ),
              suffixIconConstraints: BoxConstraints(
                minHeight: size.height,
                minWidth: size.height,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SteyTextarea extends SteyInput {
  const SteyTextarea({
    super.key,
    super.controller,
    super.label,
    super.placeholder,
    super.description,
    super.error,
    super.onChanged,
    super.enabled,
    super.required,
    super.maxLines = 4,
    super.focusNode,
  });
}

class SteySensitiveInput extends StatefulWidget {
  const SteySensitiveInput({
    super.key,
    this.controller,
    this.label = 'Secret',
    this.onChanged,
    this.enabled = true,
  });
  final TextEditingController? controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  @override
  State<SteySensitiveInput> createState() => _SteySensitiveInputState();
}

class _SteySensitiveInputState extends State<SteySensitiveInput> {
  bool visible = false;
  @override
  Widget build(BuildContext context) => SteyInput(
    controller: widget.controller,
    label: widget.label,
    enabled: widget.enabled,
    obscureText: !visible,
    onChanged: widget.onChanged,
    suffix: SteyButton(
      onPressed: widget.enabled
          ? () => setState(() => visible = !visible)
          : null,
      variant: SteyButtonVariant.ghost,
      shape: SteyButtonShape.square,
      semanticLabel: visible ? 'Hide ${widget.label}' : 'Show ${widget.label}',
      child: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 16,
      ),
    ),
  );
}

class SteyInputGroup extends StatelessWidget {
  const SteyInputGroup({
    super.key,
    required this.child,
    this.addon,
    this.suffix,
  });
  final Widget child;
  final Widget? addon, suffix;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (addon != null)
        Padding(padding: const EdgeInsets.only(right: 8), child: addon!),
      Expanded(child: child),
      if (suffix != null)
        Padding(padding: const EdgeInsets.only(left: 8), child: suffix!),
    ],
  );
}

class SteyTagInput extends StatefulWidget {
  const SteyTagInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Tags',
    this.placeholder = 'Add a tag',
    this.enabled = true,
    this.validate,
    this.maxTags,
  });
  final List<String> value;
  final ValueChanged<List<String>> onChanged;
  final String label, placeholder;
  final bool enabled;
  final String? Function(String)? validate;
  final int? maxTags;
  @override
  State<SteyTagInput> createState() => _SteyTagInputState();
}

class _SteyTagInputState extends State<SteyTagInput> {
  final controller = TextEditingController();
  String? error;
  void add(String raw) {
    if (!widget.enabled) return;
    final tag = raw.trim();
    if (tag.isEmpty) return;
    final validation = widget.validate?.call(tag);
    if (validation != null) {
      setState(() => error = validation);
      return;
    }
    if (widget.maxTags != null && widget.value.length >= widget.maxTags!) {
      setState(() => error = 'Maximum ${widget.maxTags} tags');
      return;
    }
    if (!widget.value.contains(tag)) widget.onChanged([...widget.value, tag]);
    controller.clear();
    setState(() => error = null);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SteyField(
    label: widget.label,
    error: error,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: widget.value
              .map(
                (tag) => SteyButton(
                  size: SteySize.sm,
                  onPressed: widget.enabled
                      ? () => widget.onChanged(
                          widget.value.where((v) => v != tag).toList(),
                        )
                      : null,
                  semanticLabel: 'Remove $tag',
                  trailing: const Icon(Icons.close, size: 12),
                  child: Text(tag),
                ),
              )
              .toList(),
        ),
        if (widget.value.isNotEmpty) const SizedBox(height: 6),
        SteyInput(
          controller: controller,
          semanticLabel: widget.label,
          placeholder: widget.placeholder,
          enabled: widget.enabled,
          onSubmitted: add,
          onChanged: (value) {
            if (value.endsWith(',')) add(value.substring(0, value.length - 1));
          },
        ),
      ],
    ),
  );
}
