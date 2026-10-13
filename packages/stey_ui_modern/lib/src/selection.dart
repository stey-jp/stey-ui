import 'package:flutter/material.dart';

import 'input.dart';
import 'theme.dart';

class SteyCheckbox extends StatelessWidget {
  const SteyCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.description,
    this.tristate = false,
  });
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final String label;
  final String? description;
  final bool tristate;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return Semantics(
      label: label,
      checked: value == true,
      enabled: onChanged != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              tristate: tristate,
              activeColor: c.brand,
              checkColor: Colors.white,
              side: BorderSide(color: c.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: GestureDetector(
              onTap: onChanged == null
                  ? null
                  : () => onChanged!(value == true ? false : true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 14, color: c.text, height: 1.5),
                  ),
                  if (description != null)
                    Text(
                      description!,
                      style: TextStyle(fontSize: 12, color: c.subtle),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SteySwitch extends StatelessWidget {
  const SteySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return Semantics(
      label: label,
      toggled: value,
      enabled: onChanged != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 24,
            child: FittedBox(
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: c.brand,
                activeThumbColor: Colors.white,
                inactiveTrackColor: c.fill,
                inactiveThumbColor: c.base,
                trackOutlineColor: WidgetStatePropertyAll(c.line),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class SteyRadioGroup<T> extends StatelessWidget {
  const SteyRadioGroup({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.label,
    this.card = false,
  });
  final T? value;
  final Map<T, String> options;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final bool card;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return SteyField(
      label: label,
      child: RadioGroup<T>(
        groupValue: value,
        onChanged: (v) => onChanged?.call(v),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries
              .map(
                (e) => Container(
                  margin: EdgeInsets.only(bottom: card ? 8 : 4),
                  padding: EdgeInsets.all(card ? 12 : 0),
                  decoration: card
                      ? BoxDecoration(
                          color: c.base,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: value == e.key ? c.brand : c.line,
                          ),
                        )
                      : null,
                  child: Row(
                    children: [
                      Radio<T>(
                        value: e.key,
                        activeColor: c.brand,
                        enabled: onChanged != null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class SteySelect<T> extends StatelessWidget {
  const SteySelect({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.label,
    this.placeholder = 'Select an option',
    this.size = SteySize.base,
    this.error,
  });
  final T? value;
  final Map<T, String> options;
  final ValueChanged<T?>? onChanged;
  final String? label, error;
  final String placeholder;
  final SteySize size;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return SteyField(
      label: label,
      error: error,
      child: Semantics(
        label: label ?? placeholder,
        child: Container(
          height: size.height,
          padding: EdgeInsets.symmetric(horizontal: size.padding),
          decoration: BoxDecoration(
            color: c.control,
            borderRadius: BorderRadius.circular(size.radius),
            border: Border.all(color: error == null ? c.line : c.dangerText),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              onChanged: onChanged,
              isExpanded: true,
              isDense: true,
              hint: Text(
                placeholder,
                style: TextStyle(fontSize: size.fontSize, color: c.subtle),
              ),
              dropdownColor: c.base,
              borderRadius: BorderRadius.circular(8),
              style: TextStyle(
                fontFamily: 'Inter',
                package: 'stey_ui_modern',
                fontSize: size.fontSize,
                color: c.text,
              ),
              icon: const Icon(Icons.unfold_more, size: 16),
              items: options.entries
                  .map(
                    (e) =>
                        DropdownMenuItem<T>(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class SteyAutocomplete extends StatelessWidget {
  const SteyAutocomplete({
    super.key,
    required this.options,
    required this.onSelected,
    this.label,
    this.placeholder = 'Search',
    this.initialValue = '',
    this.enabled = true,
  });
  final Iterable<String> options;
  final ValueChanged<String> onSelected;
  final String? label;
  final String placeholder, initialValue;
  final bool enabled;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final c = SteyTheme.colorsOf(context);
      return RawAutocomplete<String>(
        initialValue: TextEditingValue(text: initialValue),
        optionsBuilder: (value) => enabled
            ? options.where(
                (o) => o.toLowerCase().contains(value.text.toLowerCase()),
              )
            : const [],
        onSelected: onSelected,
        fieldViewBuilder: (context, controller, focusNode, submit) => SteyInput(
          controller: controller,
          focusNode: focusNode,
          label: label,
          placeholder: placeholder,
          enabled: enabled,
          onSubmitted: (_) => submit(),
        ),
        optionsViewBuilder: (context, select, matches) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: c.base,
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: constraints.maxWidth,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(4),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final option = matches.elementAt(index);
                    final active =
                        AutocompleteHighlightedOption.of(context) == index;
                    return InkWell(
                      onTap: () => select(option),
                      child: Container(
                        color: active ? c.tint : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Text(
                          option,
                          style: TextStyle(fontSize: 14, color: c.text),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class SteyCombobox extends SteyAutocomplete {
  const SteyCombobox({
    super.key,
    required super.options,
    required super.onSelected,
    super.label,
    super.placeholder,
    super.initialValue,
    super.enabled,
  });
}

class SteySlider extends StatelessWidget {
  const SteySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.label = 'Value',
  });
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        activeTrackColor: SteyTheme.colorsOf(context).brand,
        inactiveTrackColor: SteyTheme.colorsOf(context).fill,
        thumbColor: SteyTheme.colorsOf(context).base,
      ),
      child: Slider(
        value: value.clamp(min, max),
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        label: value.toStringAsFixed(0),
      ),
    ),
  );
}
