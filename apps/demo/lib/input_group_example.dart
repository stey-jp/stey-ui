import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class InputGroupExample extends StatefulWidget {
  const InputGroupExample({super.key});
  @override
  State<InputGroupExample> createState() => _InputGroupExampleState();
}

class _InputGroupExampleState extends State<InputGroupExample> {
  SteySize size = SteySize.base;
  int mode = 0, calls = 0, actions = 0, clears = 0, after = 0;
  String value = 'my-worker';
  bool suffix = true,
      textAddon = false,
      disabled = false,
      error = false,
      readOnly = false,
      rtl = false,
      optional = false;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SteyButton(
            semanticLabel: '枠の形式を変更',
            onPressed: () => setState(() => mode = (mode + 1) % 3),
            child: Text('枠：${['共有', '個別', '混合'][mode]}'),
          ),
          SteyButton(
            semanticLabel: 'サイズを変更',
            onPressed: () =>
                setState(() => size = SteySize.values[(size.index + 1) % 4]),
            child: Text('サイズ：${size.name}'),
          ),
          for (final row in <(String, bool, ValueChanged<bool>)>[
            ('接尾辞を表示', suffix, (v) => setState(() => suffix = v)),
            ('テキストの補助表示', textAddon, (v) => setState(() => textAddon = v)),
            ('入力を無効にする', disabled, (v) => setState(() => disabled = v)),
            ('エラーを表示', error, (v) => setState(() => error = v)),
            ('読み取り専用', readOnly, (v) => setState(() => readOnly = v)),
            ('右から左へ', rtl, (v) => setState(() => rtl = v)),
            ('任意項目を表示', optional, (v) => setState(() => optional = v)),
          ])
            SteySwitch(label: row.$1, value: row.$2, onChanged: row.$3),
        ],
      ),
      Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SteyInputGroup(
          size: size,
          disabled: disabled,
          label: 'ドメイン',
          description: '公開するWorkerの名前を入力してください。',
          error: error ? 'この名前は使用できません。' : null,
          required: !optional,
          children: [
            if (mode != 1)
              SteyInputGroupAddon(
                child: textAddon ? const Text('https://') : const _GroupPlus(),
              ),
            if (mode == 1)
              SteyInputGroupButton(
                variant: SteyButtonVariant.secondary,
                onPressed: () => setState(() => actions++),
                child: const Text('戻る'),
              ),
            SteyInputGroupInput(
              value: value,
              readOnly: readOnly,
              placeholder: 'Worker名',
              onValueChange: (v) => setState(() {
                value = v;
                calls++;
              }),
            ),
            if (suffix) const SteyInputGroupSuffix(child: Text('.workers.dev')),
            if (mode != 1)
              SteyInputGroupAddon(
                align: SteyInputGroupAlign.end,
                child: SteyInputGroupButton(
                  shape: SteyButtonShape.square,
                  tooltip: '入力を消去',
                  onPressed: () => setState(() {
                    value = '';
                    clears++;
                  }),
                  child: const Icon(Icons.close, size: 12),
                ),
              ),
            if (mode != 0)
              SteyInputGroupButton(
                variant: SteyButtonVariant.secondary,
                onPressed: () => setState(() => actions++),
                child: const Text('実行'),
              ),
          ],
        ),
      ),
      Text('入力値：${value.isEmpty ? '未入力' : value}'),
      Text('変更：$calls回／実行：$actions回／消去：$clears回'),
      SteyButton(
        onPressed: () => setState(() => after++),
        child: const Text('入力欄の次の操作'),
      ),
      Text('次の操作：$after回'),
      const SteyText(
        '共有枠は入力欄と補助表示をまとめ、個別枠は各操作を独立させます。混合枠では入力部分をまとめたまま実行ボタンを並べます。',
        subtle: true,
      ),
    ],
  );
}

class _GroupPlus extends StatelessWidget {
  const _GroupPlus({this.size});
  final double? size;
  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context), extent = size ?? theme.size ?? 18;
    return CustomPaint(
      size: Size.square(extent),
      painter: _PlusPainter(theme.color ?? SteyTheme.colorsOf(context).subtle),
    );
  }
}

class _PlusPainter extends CustomPainter {
  const _PlusPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = size.width * 1.5 / 16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width / 2, size.height * .1875),
      Offset(size.width / 2, size.height * .8125),
      p,
    );
    canvas.drawLine(
      Offset(size.width * .1875, size.height / 2),
      Offset(size.width * .8125, size.height / 2),
      p,
    );
  }

  @override
  bool shouldRepaint(_PlusPainter old) => old.color != color;
}

class InputGroupSample extends StatefulWidget {
  const InputGroupSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<InputGroupSample> createState() => _InputGroupSampleState();
}

class _InputGroupSampleState extends State<InputGroupSample> {
  late String value = widget.query['value'] ?? 'my-worker';
  int calls = 0, actions = 0, clears = 0, after = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query, layout = q['layout'] ?? 'addons';
    final edit = SteyInputGroupInput(
      key: const ValueKey('input'),
      value: value,
      placeholder: 'Worker name',
      semanticLabel: 'Domain',
      readOnly: q['readOnly'] == 'true',
      onValueChange: (v) => setState(() {
        calls++;
        if (q['frozen'] != 'true') value = v;
      }),
    );
    final start = SteyInputGroupAddon(
      child: q['textAddon'] == 'true'
          ? const Text('https://')
          : const _GroupPlus(),
    );
    const end = SteyInputGroupAddon(
      align: SteyInputGroupAlign.end,
      child: Text('GB'),
    );
    const suffix = SteyInputGroupSuffix(child: Text('.workers.dev'));
    final clear = SteyInputGroupAddon(
      align: SteyInputGroupAlign.end,
      child: SteyInputGroupButton(
        shape: SteyButtonShape.square,
        tooltip: 'Clear',
        onPressed: () => setState(() {
          value = '';
          clears++;
        }),
        child: const _GroupPlus(size: 12),
      ),
    );
    final action = SteyInputGroupButton(
      variant: SteyButtonVariant.values.firstWhere(
        (v) => v.name == q['variant'],
        orElse: () => SteyButtonVariant.secondary,
      ),
      onPressed: () => setState(() => actions++),
      child: const Text('Go'),
    );
    final children = switch (layout) {
      'plain' => [edit],
      'suffix' => [edit, suffix],
      'action' => [edit, clear],
      'ghost' => [
        edit,
        SteyInputGroupButton(
          onPressed: () => setState(() => actions++),
          child: const Text('Go'),
        ),
      ],
      'individual' => [
        SteyInputGroupButton(
          variant: SteyButtonVariant.secondary,
          onPressed: () => setState(() => actions++),
          child: const Text('Prev'),
        ),
        edit,
        action,
      ],
      'hybrid' => [start, edit, clear, action],
      'hybrid-suffix' => [start, edit, suffix, action],
      'leading-hybrid' => [action, start, edit],
      _ => [start, edit, end],
    };
    return Localizations.override(
      context: context,
      locale: const Locale('en'),
      child: Directionality(
        textDirection: q['direction'] == 'rtl'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Semantics(
              container: true,
              explicitChildNodes: true,
              label: 'Input group preview',
              child: SizedBox(
                width: double.tryParse(q['host'] ?? '') ?? 320,
                child: SteyInputGroup(
                  size: SteySize.values.firstWhere(
                    (s) => s.name == q['size'],
                    orElse: () => SteySize.base,
                  ),
                  disabled: q['disabled'] == 'true',
                  label: q['label'] == 'true' ? 'Project' : null,
                  description: q['description'] == 'true'
                      ? 'Choose a unique name'
                      : null,
                  error: q['error'] == 'true' ? 'Name is unavailable' : null,
                  required: q.containsKey('required')
                      ? q['required'] == 'true'
                      : null,
                  children: children,
                ),
              ),
            ),
            SteyButton(
              onPressed: () => setState(() => after++),
              child: const Text('After group'),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                jsonEncode({
                  'value': value,
                  'calls': calls,
                  'actions': actions,
                  'clears': clears,
                  'after': after,
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
