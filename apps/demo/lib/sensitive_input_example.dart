import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class SensitiveInputExample extends StatefulWidget {
  const SensitiveInputExample({super.key});
  @override
  State<SensitiveInputExample> createState() => _SensitiveInputExampleState();
}

class _SensitiveInputExampleState extends State<SensitiveInputExample> {
  SteySize size = SteySize.base;
  String value = 'demo_secret_123';
  bool error = false,
      disabled = false,
      readOnly = false,
      rtl = false,
      optional = false,
      controlled = true;
  int changes = 0, copies = 0, after = 0, generation = 0;
  String? copyError;
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
            semanticLabel: 'サイズを変更',
            onPressed: () =>
                setState(() => size = SteySize.values[(size.index + 1) % 4]),
            child: Text('サイズ：${size.name}'),
          ),
          SteyButton(
            onPressed: () => setState(() {
              value = 'demo_secret_123';
              generation++;
            }),
            child: const Text('サンプル値を再設定'),
          ),
          SteyButton(
            onPressed: () => setState(() {
              value = '';
              generation++;
            }),
            child: const Text('空欄にする'),
          ),
          for (final row in <(String, bool, ValueChanged<bool>)>[
            ('エラーを表示', error, (v) => setState(() => error = v)),
            ('入力を無効にする', disabled, (v) => setState(() => disabled = v)),
            ('読み取り専用', readOnly, (v) => setState(() => readOnly = v)),
            ('右から左へ', rtl, (v) => setState(() => rtl = v)),
            ('任意項目を表示', optional, (v) => setState(() => optional = v)),
            ('制御モード', controlled, (v) => setState(() => controlled = v)),
          ])
            SteySwitch(label: row.$1, value: row.$2, onChanged: row.$3),
        ],
      ),
      Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SteySensitiveInput(
          key: ValueKey((controlled, generation)),
          size: size,
          label: 'APIトークン',
          labelTooltip: '動作確認用のサンプル値です。',
          description: 'クリックまたはEnterで表示できます。',
          error: error ? 'この値は使用できません。' : null,
          required: !optional,
          placeholder: '機密情報を入力',
          enabled: !disabled,
          readOnly: readOnly,
          value: controlled ? value : null,
          defaultValue: value,
          onValueChange: (v) => setState(() {
            value = v;
            changes++;
          }),
          onCopy: () => setState(() {
            copies++;
            copyError = null;
          }),
          onCopyError: (_) => setState(() => copyError = 'コピーできませんでした。'),
        ),
      ),
      Text('文字数：${value.length}文字／変更：$changes回／コピー：$copies回'),
      if (copyError != null) Text(copyError!),
      SteyButton(
        onPressed: () => setState(() => after++),
        child: const Text('入力欄の次の操作'),
      ),
      Text('次の操作：$after回'),
      const SteyText(
        '表示中はEscapeで隠せます。上部のコピー操作では表示状態を変えずに値をコピーできます。',
        subtle: true,
      ),
    ],
  );
}

class SensitiveInputSample extends StatefulWidget {
  const SensitiveInputSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<SensitiveInputSample> createState() => _SensitiveInputSampleState();
}

class _SensitiveInputSampleState extends State<SensitiveInputSample> {
  late String value = widget.query['value'] ?? 'demo_secret_123';
  int calls = 0, copies = 0, after = 0;
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
              label: 'Sensitive input preview',
              child: SizedBox(
                width: double.tryParse(q['host'] ?? '') ?? 280,
                child: SteySensitiveInput(
                  size: SteySize.values.firstWhere(
                    (s) => s.name == q['size'],
                    orElse: () => SteySize.base,
                  ),
                  placeholder: 'Enter secret',
                  semanticLabel: 'Secret',
                  value: q['uncontrolled'] == 'true' ? null : value,
                  defaultValue: value,
                  enabled: q['disabled'] != 'true',
                  readOnly: q['readOnly'] == 'true',
                  label: q['label'] == 'true' ? 'API key' : null,
                  description: q['description'] == 'true'
                      ? 'Keep this value private'
                      : null,
                  error: q['error'] == 'true' ? 'Invalid key' : null,
                  required: q.containsKey('required')
                      ? q['required'] == 'true'
                      : null,
                  variant: q['variant'] == 'default'
                      ? SteyInputVariant.standard
                      : q['variant'] == 'error'
                      ? SteyInputVariant.error
                      : null,
                  onValueChange: (v) => setState(() {
                    calls++;
                    if (q['frozen'] != 'true') value = v;
                  }),
                  onCopy: () => setState(() => copies++),
                ),
              ),
            ),
            SteyButton(
              onPressed: () => setState(() => after++),
              child: const Text('After secret'),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                jsonEncode({
                  'value': value,
                  'calls': calls,
                  'copies': copies,
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
