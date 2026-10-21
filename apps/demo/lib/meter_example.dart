import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:stey_ui_modern/stey_ui_modern.dart';

class MeterExample extends StatefulWidget {
  const MeterExample({super.key});
  @override
  State<MeterExample> createState() => _MeterExampleState();
}

class _MeterExampleState extends State<MeterExample> {
  double value = 65;
  final input = TextEditingController(text: '65');
  void setValue(double v) {
    input.text = v.toStringAsFixed(0);
    setState(() => value = v);
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  bool custom = false,
      hidden = false,
      offset = false,
      decimal = false,
      rtl = false,
      colored = false,
      long = false;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          for (final item in <(String, bool, ValueChanged<bool>)>[
            ('独自の表示値', custom, (v) => setState(() => custom = v)),
            ('数値を非表示', hidden, (v) => setState(() => hidden = v)),
            ('値域を20〜80に変更', offset, (v) => setState(() => offset = v)),
            ('小数の書式', decimal, (v) => setState(() => decimal = v)),
            ('色を変更', colored, (v) => setState(() => colored = v)),
            ('長いラベル', long, (v) => setState(() => long = v)),
            ('右から左へ', rtl, (v) => setState(() => rtl = v)),
          ])
            SteySwitch(label: item.$1, value: item.$2, onChanged: item.$3),
        ],
      ),
      Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SteyMeter(
          value: value,
          min: offset ? 20 : 0,
          max: offset ? 80 : 100,
          label: long ? 'プロジェクト全体のストレージ使用量と利用可能な上限' : 'ストレージ使用量',
          customValue: custom
              ? '${value.toStringAsFixed(0)} / ${offset ? 80 : 100} GB'
              : null,
          showValue: !hidden,
          locale: 'ja_JP',
          format: decimal
              ? (NumberFormat.decimalPattern('ja_JP')
                  ..minimumFractionDigits = 1
                  ..maximumFractionDigits = 2)
              : null,
          color: colored ? SteyTheme.colorsOf(context).success : null,
        ),
      ),
      SteyInput(
        controller: input,
        label: '使用量',
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        onChanged: (text) {
          final v = double.tryParse(text);
          if (v != null) setState(() => value = v);
        },
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final n in [25, 75, 125])
            SteyButton(
              onPressed: () => setValue(n.toDouble()),
              child: Text(n == 125 ? '上限を超える値' : '使用量を$nに変更'),
            ),
        ],
      ),
      Text('入力値：${value.toStringAsFixed(1)}・値域：${offset ? '20〜80' : '0〜100'}'),
      const SteyText(
        '範囲外の値は表示範囲内に補正します。独自の表示値は「数値を非表示」より優先し、読み上げ値は測定値から計算します。幅は300msで変化します。',
        subtle: true,
      ),
    ],
  );
}

class MeterSample extends StatefulWidget {
  const MeterSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<MeterSample> createState() => _MeterSampleState();
}

class _MeterSampleState extends State<MeterSample> {
  late double value = double.tryParse(widget.query['value'] ?? '') ?? 65;
  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final format = switch (q['format']) {
      'decimal' =>
        NumberFormat.decimalPattern(q['locale'] ?? 'en_US')
          ..minimumFractionDigits = 1
          ..maximumFractionDigits = 2,
      'currency' => NumberFormat.currency(
        locale: q['locale'] ?? 'en_US',
        name: 'USD',
        symbol: r'$',
      ),
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        if (q.containsKey('target'))
          SteyButton(
            onPressed: () =>
                setState(() => value = double.tryParse(q['target']!) ?? 75),
            child: const Text('Change value'),
          ),
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: 'Meter preview',
          child: SizedBox(
            width: double.tryParse(q['host'] ?? '') ?? 320,
            height: 120,
            child: Center(
              child: SteyMeter(
                value: value,
                min: double.tryParse(q['min'] ?? '') ?? 0,
                max: double.tryParse(q['max'] ?? '') ?? 100,
                label: q['long'] == 'true'
                    ? 'Total storage usage across the entire project'
                    : 'Storage used',
                showValue: q['hide'] != 'true',
                customValue: q['custom'],
                locale: q['locale'] ?? 'en_US',
                format: format,
                getAriaValueText: q['aria'] == 'true'
                    ? (formatted, raw) =>
                          '$formatted of storage used; input $raw'
                    : null,
                color: q['color'] == 'green'
                    ? SteyTheme.colorsOf(context).success
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
