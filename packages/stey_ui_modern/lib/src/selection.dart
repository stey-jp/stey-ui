import 'package:flutter/material.dart';

import 'input.dart';
import 'theme.dart';

export 'checkable.dart';

export 'radio.dart';
export 'select.dart';

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
