import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class InputExample extends StatefulWidget {
  const InputExample({super.key});
  @override
  State<InputExample> createState() => _InputExampleState();
}

class _InputExampleState extends State<InputExample> {
  SteySize size = SteySize.base;
  String value = '', notes = '';
  int calls = 0, submitted = 0, after = 0;
  bool error = false,
      disabled = false,
      readOnly = false,
      controlled = false,
      password = false,
      autoResize = false,
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
            onPressed: () => setState(
              () => size =
                  SteySize.values[(size.index + 1) % SteySize.values.length],
            ),
            semanticLabel: 'サイズを変更',
            child: Text('サイズ：${size.name}'),
          ),
          for (final row in <(String, bool, ValueChanged<bool>)>[
            ('エラーを表示', error, (v) => setState(() => error = v)),
            ('入力を無効にする', disabled, (v) => setState(() => disabled = v)),
            ('読み取り専用', readOnly, (v) => setState(() => readOnly = v)),
            ('制御モード', controlled, (v) => setState(() => controlled = v)),
            ('文字を隠す', password, (v) => setState(() => password = v)),
            ('複数行を自動調整', autoResize, (v) => setState(() => autoResize = v)),
            ('右から左へ', rtl, (v) => setState(() => rtl = v)),
            ('任意項目を表示', optional, (v) => setState(() => optional = v)),
          ])
            SteySwitch(label: row.$1, value: row.$2, onChanged: row.$3),
        ],
      ),
      Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            SteyInput(
              key: ValueKey(controlled),
              label: 'プロジェクト名',
              placeholder: 'my-project',
              labelTooltip: '公開するプロジェクトの名前です。',
              description: '重複しない名前を指定してください。',
              error: error ? 'この名前は使用できません。' : null,
              required: !optional,
              size: size,
              enabled: !disabled,
              readOnly: readOnly,
              obscureText: password,
              value: controlled ? value : null,
              defaultValue: value,
              onValueChange: (v) => setState(() {
                value = v;
                calls++;
              }),
              onSubmitted: (_) => setState(() => submitted++),
            ),
            SteyInputArea(
              label: '説明',
              placeholder: '説明を複数行で入力',
              size: size,
              enabled: !disabled,
              readOnly: readOnly,
              autoResize: autoResize,
              minRows: 1,
              maxRows: 4,
              onValueChange: (v) => setState(() => notes = v),
            ),
          ],
        ),
      ),
      Text(
        '入力値：${value.isEmpty
            ? '未入力'
            : password
            ? '（非表示）'
            : value}',
      ),
      Text('変更：$calls回／確定：$submitted回'),
      Text('説明：${notes.length}文字'),
      SteyButton(
        onPressed: () => setState(() => after++),
        child: const Text('入力欄の次の操作'),
      ),
      Text('次の操作：$after回'),
      const SteyText(
        'ラベルをクリックすると入力欄に移動します。制御モードは親で値を保持します。複数行の自動調整は4行を上限とし、それ以降は欄の中をスクロールします。',
        subtle: true,
      ),
    ],
  );
}

class InputSample extends StatefulWidget {
  const InputSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<InputSample> createState() => _InputSampleState();
}

class _InputSampleState extends State<InputSample> {
  late String value = widget.query['value'] ?? '';
  int calls = 0, submitted = 0, after = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query,
        size = SteySize.values.firstWhere(
          (s) => s.name == q['size'],
          orElse: () => SteySize.base,
        ),
        area = q['area'] == 'true';
    final label = q['label'] == 'true' ? 'Project' : null,
        description = q['description'] == 'true'
            ? 'Choose a unique name'
            : null,
        error = q['error'] == 'true' ? 'Name is unavailable' : null;
    void changed(String v) => setState(() {
      calls++;
      if (q['frozen'] != 'true') value = v;
    });
    final style = q['variant'] == 'standard'
        ? SteyInputVariant.standard
        : q['variant'] == 'error'
        ? SteyInputVariant.error
        : null;
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
              label: 'Input preview',
              child: SizedBox(
                width: double.tryParse(q['host'] ?? '') ?? 280,
                child: area
                    ? SteyInputArea(
                        label: label,
                        semanticLabel: 'Name',
                        description: description,
                        error: error,
                        labelTooltip: q['tooltip'] == 'true'
                            ? 'Project help'
                            : null,
                        required: q['required'] == 'false'
                            ? false
                            : q['required'] == 'true'
                            ? true
                            : null,
                        placeholder: 'Project name',
                        size: size,
                        enabled: q['disabled'] != 'true',
                        readOnly: q['readOnly'] == 'true',
                        value: q['controlled'] == 'true' ? value : null,
                        defaultValue: value,
                        onValueChange: changed,
                        variant: style,
                        autoResize: q['auto'] == 'true',
                        minRows: int.tryParse(q['minRows'] ?? '') ?? 1,
                        maxRows: int.tryParse(q['maxRows'] ?? ''),
                        maxLines: int.tryParse(q['rows'] ?? '') ?? 2,
                      )
                    : SteyInput(
                        label: label,
                        semanticLabel: 'Name',
                        description: description,
                        error: error,
                        labelTooltip: q['tooltip'] == 'true'
                            ? 'Project help'
                            : null,
                        required: q['required'] == 'false'
                            ? false
                            : q['required'] == 'true'
                            ? true
                            : null,
                        placeholder: 'Project name',
                        size: size,
                        enabled: q['disabled'] != 'true',
                        readOnly: q['readOnly'] == 'true',
                        obscureText: q['password'] == 'true',
                        keyboardType: q['type'] == 'email'
                            ? TextInputType.emailAddress
                            : q['type'] == 'number'
                            ? TextInputType.number
                            : null,
                        value: q['controlled'] == 'true' ? value : null,
                        defaultValue: value,
                        onValueChange: changed,
                        onSubmitted: (_) => setState(() => submitted++),
                        variant: style,
                      ),
              ),
            ),
            SteyButton(
              onPressed: () => setState(() => after++),
              child: const Text('After input'),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                jsonEncode({
                  'value': value,
                  'calls': calls,
                  'submitted': submitted,
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
