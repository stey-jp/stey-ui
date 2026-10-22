import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:stey_ui_modern/stey_ui_modern.dart';

class SliderExample extends StatefulWidget {
  const SliderExample({super.key});
  @override
  State<SliderExample> createState() => _SliderExampleState();
}

class _SliderExampleState extends State<SliderExample> {
  List<double> values = [25, 75];
  double value = 40;
  int changes = 0, commits = 0, after = 0;
  bool range = false,
      small = false,
      disabled = false,
      rtl = false,
      decimal = false,
      separated = false,
      canceled = false,
      center = false;
  SteySliderCollision collision = SteySliderCollision.push;
  @override
  Widget build(BuildContext context) {
    final format = decimal
        ? (NumberFormat.decimalPattern('ja_JP')
            ..minimumFractionDigits = 1
            ..maximumFractionDigits = 2)
        : null;
    void detail(List<double> next, SteySliderChangeDetails d) {
      if (canceled) d.cancel();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            for (final row in <(String, bool, ValueChanged<bool>)>[
              ('範囲を選択', range, (v) => setState(() => range = v)),
              ('小さいサイズ', small, (v) => setState(() => small = v)),
              ('無効にする', disabled, (v) => setState(() => disabled = v)),
              ('右から左へ', rtl, (v) => setState(() => rtl = v)),
              ('小数を選択', decimal, (v) => setState(() => decimal = v)),
              ('つまみの間隔を確保', separated, (v) => setState(() => separated = v)),
              ('変更を取り消す', canceled, (v) => setState(() => canceled = v)),
              ('中央を端へ合わせる', center, (v) => setState(() => center = v)),
            ])
              SteySwitch(label: row.$1, value: row.$2, onChanged: row.$3),
          ],
        ),
        SteySelect<SteySliderCollision>(
          label: 'つまみが重なるとき',
          value: collision,
          options: const {
            SteySliderCollision.push: '隣のつまみを押す',
            SteySliderCollision.swap: 'つまみを入れ替える',
            SteySliderCollision.none: '隣のつまみで止める',
          },
          onChanged: (v) {
            if (v != null) setState(() => collision = v);
          },
        ),
        Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: range
              ? SteySlider.range(
                  values: values,
                  label: 'キャッシュ時間の範囲',
                  size: small ? SteySliderSize.sm : SteySliderSize.base,
                  disabled: disabled,
                  step: decimal ? .5 : 1,
                  format: format,
                  locale: 'ja_JP',
                  minStepsBetweenValues: separated ? 10 : 0,
                  getAriaLabel: (i) => i == 0 ? '開始の値' : '終了の値',
                  onValueChange: detail,
                  thumbCollisionBehavior: collision,
                  thumbAlignment: center
                      ? SteySliderThumbAlignment.center
                      : SteySliderThumbAlignment.edge,
                  onChanged: (v) => setState(() {
                    values = v;
                    changes++;
                  }),
                  onChangeCommitted: (_) => setState(() => commits++),
                )
              : SteySlider(
                  value: value,
                  label: 'キャッシュ時間',
                  size: small ? SteySliderSize.sm : SteySliderSize.base,
                  disabled: disabled,
                  step: decimal ? .5 : 1,
                  format: format,
                  locale: 'ja_JP',
                  onValueChange: detail,
                  thumbAlignment: center
                      ? SteySliderThumbAlignment.center
                      : SteySliderThumbAlignment.edge,
                  onChanged: (v) => setState(() {
                    value = v;
                    changes++;
                  }),
                  onChangeCommitted: (_) => setState(() => commits++),
                ),
        ),
        Text(
          '選択値：${range ? values.map((v) => v.toStringAsFixed(decimal ? 1 : 0)).join('〜') : value.toStringAsFixed(decimal ? 1 : 0)}分',
        ),
        Text('変更：$changes回・確定：$commits回'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SteyButton(
              onPressed: () => setState(() {
                value = 40;
                values = [25, 75];
                changes = 0;
                commits = 0;
              }),
              child: const Text('値をリセット'),
            ),
            SteyButton(
              onPressed: () => setState(() => after++),
              child: const Text('スライダーの次の操作'),
            ),
          ],
        ),
        Text('次の操作：$after回'),
        const SteyText(
          'ドラッグまたは矢印キーで調整できます。Shift＋矢印・Page Up／Downは大きく移動し、Home／Endは端へ移動します。値はつまみの下に常時表示します。',
          subtle: true,
        ),
      ],
    );
  }
}

class SliderSample extends StatefulWidget {
  const SliderSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<SliderSample> createState() => _SliderSampleState();
}

class _SliderSampleState extends State<SliderSample> {
  late List<double> values =
      widget.query['values']?.split(',').map(double.parse).toList() ??
      [double.tryParse(widget.query['value'] ?? '') ?? 40];
  int calls = 0, commits = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query,
        range = q.containsKey('values'),
        uncontrolled = q['uncontrolled'] == 'true';
    final size = q['size'] == 'sm' ? SteySliderSize.sm : SteySliderSize.base;
    final alignment = SteySliderThumbAlignment.values.firstWhere(
      (v) => v.name == q['alignment'],
      orElse: () => SteySliderThumbAlignment.edge,
    );
    final collision = SteySliderCollision.values.firstWhere(
      (v) => v.name == q['collision'],
      orElse: () => SteySliderCollision.push,
    );
    final format = q['format'] == 'decimal'
        ? (NumberFormat.decimalPattern(q['locale'] ?? 'en_US')
            ..minimumFractionDigits = 1
            ..maximumFractionDigits = 2)
        : null;
    void change(List<double> v) {
      setState(() {
        calls++;
        if (q['frozen'] != 'true') values = v;
      });
    }

    void detail(List<double> v, SteySliderChangeDetails d) {
      if (q['cancel'] == 'true') d.cancel();
    }

    final slider = range
        ? SteySlider.range(
            values: uncontrolled ? null : values,
            defaultValues: values,
            onChanged: change,
            onChangeCommitted: (_) => setState(() => commits++),
            onValueChange: detail,
            min: double.tryParse(q['min'] ?? '') ?? 0,
            max: double.tryParse(q['max'] ?? '') ?? 100,
            step: double.tryParse(q['step'] ?? '') ?? 1,
            largeStep: double.tryParse(q['largeStep'] ?? '') ?? 10,
            size: size,
            label: q['noLabel'] == 'true' ? null : 'Volume',
            locale: q['locale'] ?? 'en_US',
            format: format,
            disabled: q['disabled'] == 'true',
            getAriaLabel: (i) => 'Handle ${i + 1}',
            minStepsBetweenValues: int.tryParse(q['gap'] ?? '') ?? 0,
            thumbAlignment: alignment,
            thumbCollisionBehavior: collision,
          )
        : SteySlider(
            value: uncontrolled ? null : values.first,
            defaultValue: values.first,
            onChanged: (v) => change([v]),
            onChangeCommitted: (_) => setState(() => commits++),
            onValueChange: detail,
            min: double.tryParse(q['min'] ?? '') ?? 0,
            max: double.tryParse(q['max'] ?? '') ?? 100,
            step: double.tryParse(q['step'] ?? '') ?? 1,
            largeStep: double.tryParse(q['largeStep'] ?? '') ?? 10,
            size: size,
            label: q['noLabel'] == 'true' ? null : 'Volume',
            locale: q['locale'] ?? 'en_US',
            format: format,
            disabled: q['disabled'] == 'true',
            getAriaLabel: (_) => 'Volume',
            thumbAlignment: alignment,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: 'Slider preview',
          child: SizedBox(
            width: double.tryParse(q['host'] ?? '') ?? 320,
            height: 160,
            child: Center(child: slider),
          ),
        ),
        SteyButton(
          onPressed: () => setState(() => calls++),
          child: const Text('After slider'),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            jsonEncode({
              'value': range ? values : values.first,
              'calls': calls,
              'commits': commits,
            }),
          ),
        ),
      ],
    );
  }
}
