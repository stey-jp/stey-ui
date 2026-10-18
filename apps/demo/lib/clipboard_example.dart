import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class ClipboardExample extends StatefulWidget {
  const ClipboardExample({super.key});
  @override
  State<ClipboardExample> createState() => _ClipboardExampleState();
}

class _ClipboardExampleState extends State<ClipboardExample> {
  SteyClipboardSize size = SteyClipboardSize.lg;
  SteyClipboardSide side = SteyClipboardSide.top;
  bool tooltip = true, long = false, explicit = true;
  int copies = 0;
  String status = 'コピーはまだ実行していません。';
  @override
  Widget build(BuildContext context) {
    final text = long
        ? 'account_12345 / ${'namespace-' * 12}'
        : 'account_12345';
    final value = explicit ? 'account_complete_12345' : text;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        SteySelect(
          label: '入力欄のサイズ',
          value: size,
          options: const {
            SteyClipboardSize.sm: '小',
            SteyClipboardSize.base: '標準',
            SteyClipboardSize.lg: '大',
          },
          onChanged: (v) {
            if (v != null) setState(() => size = v);
          },
        ),
        SteySelect(
          label: '通知の方向',
          value: side,
          options: const {
            SteyClipboardSide.top: '上',
            SteyClipboardSide.bottom: '下',
            SteyClipboardSide.left: '左',
            SteyClipboardSide.right: '右',
          },
          onChanged: (v) {
            if (v != null) setState(() => side = v);
          },
        ),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            SteySwitch(
              value: tooltip,
              label: 'ツールチップと通知',
              onChanged: (v) => setState(() => tooltip = v),
            ),
            SteySwitch(
              value: long,
              label: '長い文字列',
              onChanged: (v) => setState(() => long = v),
            ),
            SteySwitch(
              value: explicit,
              label: '別の値をコピー',
              onChanged: (v) => setState(() => explicit = v),
            ),
          ],
        ),
        SteyClipboardText(
          text,
          textToCopy: explicit ? value : null,
          size: size,
          copyActionLabel: 'テキストをコピー',
          tooltip: tooltip
              ? SteyClipboardTooltip(
                  text: 'コピー',
                  copiedText: 'コピーしました',
                  side: side,
                )
              : null,
          onCopied: () => setState(() {
            copies++;
            status = 'コピーしました。';
          }),
          onCopyError: (_) => setState(() => status = 'コピーに失敗しました。'),
        ),
        SteyText('コピーする値：$value', subtle: true),
        const SteyText(
          '本文を押してもコピーされません。右側のボタンを押すか、Tabで移動してEnter・Spaceでコピーできます。',
          subtle: true,
        ),
        const SteyText('通知は最後の成功から1.5秒後に消えます。連続して押して動作を確認できます。', subtle: true),
        Semantics(liveRegion: true, child: Text('$status コピー回数：$copies')),
      ],
    );
  }
}

Widget clipboardSample(Map<String, String> q) => Builder(
  builder: (context) => Localizations.override(
    context: context,
    locale: const Locale('en'),
    child: Directionality(
      textDirection: Directionality.of(context),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Clipboard preview',
        child: SizedBox(
          width: double.tryParse(q['host'] ?? '') ?? 280,
          child: SteyClipboardText(
            q['text'] ?? 'namespace-id',
            textToCopy: q['value'],
            size: SteyClipboardSize.values.firstWhere(
              (s) => s.name == q['fieldSize'],
              orElse: () => SteyClipboardSize.lg,
            ),
            copyActionLabel: 'Copy to clipboard',
            tooltip: q['tooltip'] == 'true'
                ? SteyClipboardTooltip(
                    text: 'Copy',
                    copiedText: 'Copied',
                    side: SteyClipboardSide.values.firstWhere(
                      (s) => s.name == q['side'],
                      orElse: () => SteyClipboardSide.top,
                    ),
                  )
                : null,
          ),
        ),
      ),
    ),
  ),
);
