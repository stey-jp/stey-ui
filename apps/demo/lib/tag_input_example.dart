import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class TagInputExample extends StatefulWidget {
  const TagInputExample({super.key});
  @override
  State<TagInputExample> createState() => _TagInputExampleState();
}

class _TagInputExampleState extends State<TagInputExample> {
  List<String> values = ['production', 'staging'];
  bool disabled = false,
      readOnly = false,
      validate = false,
      limited = false,
      error = false,
      rtl = false,
      controlled = true,
      required = false;
  int calls = 0, after = 0, generation = 0;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 24,
    children: [
      Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SteyButton(
            onPressed: () => setState(() {
              values = [];
              generation++;
            }),
            child: const Text('タグを空にする'),
          ),
          SteyButton(
            onPressed: () => setState(() {
              values = ['production', 'staging'];
              generation++;
            }),
            child: const Text('サンプル値を再設定'),
          ),
          for (final row in <(String, bool, ValueChanged<bool>)>[
            ('入力を無効にする', disabled, (v) => setState(() => disabled = v)),
            ('読み取り専用', readOnly, (v) => setState(() => readOnly = v)),
            ('メール形式を検証', validate, (v) => setState(() => validate = v)),
            ('上限3個', limited, (v) => setState(() => limited = v)),
            ('外部エラーを表示', error, (v) => setState(() => error = v)),
            ('右から左へ', rtl, (v) => setState(() => rtl = v)),
            ('制御モード', controlled, (v) => setState(() => controlled = v)),
            ('必須項目', required, (v) => setState(() => required = v)),
          ])
            SteySwitch(label: row.$1, value: row.$2, onChanged: row.$3),
        ],
      ),
      Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SteyTagInput(
          key: ValueKey((generation, controlled)),
          label: '環境タグ',
          labelTooltip: '動作確認用のタグです。',
          placeholder: 'タグを追加',
          description: 'Enter・カンマ・Tab、または入力欄の外へ移動すると確定します。',
          error: error ? 'タグを確認してください。' : null,
          value: controlled ? values : null,
          defaultValue: values,
          enabled: !disabled,
          readOnly: readOnly,
          required: required,
          maxValues: limited ? 3 : null,
          validateValue: validate ? (v, accepted) => v.contains('@') : null,
          onValueChange: (v) => setState(() {
            values = v;
            calls++;
          }),
        ),
      ),
      Text('確定済み：${values.join('、')}／通知：$calls回'),
      SteyButton(
        onPressed: () => setState(() => after++),
        child: const Text('入力欄の次の操作'),
      ),
      Text('次の操作：$after回'),
      const SteyText(
        'カンマ・改行を含む文字列を貼り付けると、選択範囲に挿入してまとめて確定します。重複は除外し、検証に失敗したタグ以降は入力欄に残します。空欄のBackspaceで末尾のタグを削除できます。',
        subtle: true,
      ),
    ],
  );
}

class TagInputSample extends StatefulWidget {
  const TagInputSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<TagInputSample> createState() => _TagInputSampleState();
}

class _TagInputSampleState extends State<TagInputSample> {
  late List<String> values = widget.query.containsKey('values')
      ? (widget.query['values']!.isEmpty
            ? []
            : widget.query['values']!.split('|'))
      : ['one', 'two'];
  int calls = 0, after = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query;
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
              label: 'Tag input preview',
              child: SizedBox(
                width: double.tryParse(q['host'] ?? '') ?? 360,
                child: SteyTagInput(
                  semanticLabel: 'Tags',
                  placeholder: 'Add tag',
                  label: q['label'] == 'true' ? 'Tags' : null,
                  description: q['description'] == 'true'
                      ? 'Separate tags with commas'
                      : null,
                  error: q['error'] == 'true' ? 'External error' : null,
                  variant: q['variant'] == 'default'
                      ? SteyInputVariant.standard
                      : null,
                  required: q['required'] == 'true',
                  value: q['uncontrolled'] == 'true' ? null : values,
                  defaultValue: values,
                  enabled: q['disabled'] != 'true',
                  readOnly: q['readOnly'] == 'true',
                  maxValues: int.tryParse(q['max'] ?? ''),
                  validateValue: q['validate'] == 'true'
                      ? (v, accepted) => v.contains('@')
                      : null,
                  onValueChange: (v) => setState(() {
                    calls++;
                    if (q['frozen'] != 'true') values = v;
                  }),
                ),
              ),
            ),
            SteyButton(
              onPressed: () => setState(() => after++),
              child: const Text('After tags'),
            ),
            Text(
              jsonEncode({'values': values, 'calls': calls, 'after': after}),
            ),
          ],
        ),
      ),
    );
  }
}
