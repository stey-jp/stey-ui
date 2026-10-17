import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class InlineCopyExample extends StatefulWidget {
  const InlineCopyExample({super.key});
  @override
  State<InlineCopyExample> createState() => _InlineCopyExampleState();
}

class _InlineCopyExampleState extends State<InlineCopyExample> {
  SteyInlineCopyVariant variant = SteyInlineCopyVariant.monoSecondary;
  SteyInlineCopySize size = SteyInlineCopySize.base;
  bool long = false,
      disabled = false,
      group = false,
      rich = false,
      cancel = false;
  int copies = 0;
  String status = 'コピーはまだ実行していません。';
  @override
  Widget build(BuildContext context) {
    const value = 'account_complete_12345';
    final text = long
        ? 'account_12345 / ${'namespace-' * 12}'
        : 'account_12345';
    void copied() => setState(() {
      copies++;
      status = '完全なIDをコピーしました。';
    });
    bool beforeCopy() {
      if (cancel) setState(() => status = 'コピー前に処理を中止しました。');
      return !cancel;
    }

    final copy = rich
        ? SteyInlineCopyText.rich(
            Text.rich(
              TextSpan(
                children: [
                  const WidgetSpan(child: Icon(Icons.tag, size: 14)),
                  TextSpan(text: ' $text'),
                ],
              ),
            ),
            value: value,
            variant: variant,
            size: size,
            disabled: disabled,
            copyActionLabel: '完全なIDをコピー',
            copiedLabel: 'コピーしました',
            onCopied: copied,
            onBeforeCopy: beforeCopy,
            onCopyError: (_) => setState(() => status = 'コピーに失敗しました。'),
          )
        : SteyInlineCopyText(
            text,
            value: value,
            variant: variant,
            size: size,
            disabled: disabled,
            copyActionLabel: '完全なIDをコピー',
            copiedLabel: 'コピーしました',
            onCopied: copied,
            onBeforeCopy: beforeCopy,
            onCopyError: (_) => setState(() => status = 'コピーに失敗しました。'),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        SteySelect(
          value: variant,
          label: '文字の種類',
          options: const {
            SteyInlineCopyVariant.body: '本文',
            SteyInlineCopyVariant.secondary: '補助',
            SteyInlineCopyVariant.success: '成功',
            SteyInlineCopyVariant.error: 'エラー',
            SteyInlineCopyVariant.mono: '等幅',
            SteyInlineCopyVariant.monoSecondary: '等幅・補助',
          },
          onChanged: (v) {
            if (v != null) setState(() => variant = v);
          },
        ),
        SteySelect(
          value: size,
          label: '文字サイズ',
          options: const {
            SteyInlineCopySize.xs: '最小',
            SteyInlineCopySize.sm: '小',
            SteyInlineCopySize.base: '標準',
            SteyInlineCopySize.lg: '大',
          },
          onChanged: (v) {
            if (v != null) setState(() => size = v);
          },
        ),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            SteySwitch(
              value: long,
              label: '長い文字列',
              onChanged: (v) => setState(() => long = v),
            ),
            SteySwitch(
              value: disabled,
              label: '無効',
              onChanged: (v) => setState(() => disabled = v),
            ),
            SteySwitch(
              value: group,
              label: '行グループ',
              onChanged: (v) => setState(() => group = v),
            ),
            SteySwitch(
              value: rich,
              label: '装飾付きの表示',
              onChanged: (v) => setState(() => rich = v),
            ),
            SteySwitch(
              value: cancel,
              label: 'コピー前に中止',
              onChanged: (v) => setState(() => cancel = v),
            ),
          ],
        ),
        if (group)
          SteyInlineCopyGroup(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: SteyTheme.colorsOf(context).tint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  copy,
                  SteyButton(
                    onPressed: () => setState(() => status = '行内の操作を実行しました。'),
                    child: const Text('行内の操作'),
                  ),
                ],
              ),
            ),
          )
        else
          copy,
        const SteyText(
          '表示を省略しても、コピーする値は account_complete_12345 です。',
          subtle: true,
        ),
        const SteyText(
          'マウスを重ねるか、Tabで移動するとアイコンが現れます。EnterまたはSpaceでもコピーできます。',
          subtle: true,
        ),
        Semantics(liveRegion: true, child: Text('$status コピー回数：$copies')),
      ],
    );
  }
}

Widget inlineCopySample(Map<String, String> q) {
  final variant = SteyInlineCopyVariant.values.firstWhere(
    (v) => v.name == q['textVariant'],
    orElse: () => SteyInlineCopyVariant.monoSecondary,
  );
  final size = SteyInlineCopySize.values.firstWhere(
    (v) => v.name == q['textSize'],
    orElse: () => SteyInlineCopySize.base,
  );
  final text = q['text'] ?? 'namespace-id';
  final copy = q['rich'] == 'true'
      ? SteyInlineCopyText.rich(
          const Text('Visible resource'),
          value: q['value'] ?? 'complete-resource-id',
          variant: variant,
          size: size,
          bold: q['bold'] == 'true',
          disabled: q['disabled'] == 'true',
          truncate: q['truncate'] != 'false',
          copyActionLabel: 'Copy to clipboard',
          copiedLabel: 'Copied',
          onBeforeCopy: () => q['cancel'] != 'true',
        )
      : SteyInlineCopyText(
          text,
          value: q['value'],
          variant: variant,
          size: size,
          bold: q['bold'] == 'true',
          disabled: q['disabled'] == 'true',
          truncate: q['truncate'] != 'false',
          copyActionLabel: 'Copy to clipboard',
          copiedLabel: 'Copied',
          onBeforeCopy: () => q['cancel'] != 'true',
        );
  return Semantics(
    container: true,
    explicitChildNodes: true,
    label: 'Inline copy preview',
    child: SizedBox(
      width: double.tryParse(q['host'] ?? '') ?? 280,
      child: q['group'] == 'true'
          ? SteyInlineCopyGroup(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    copy,
                    SteyButton(
                      onPressed: () {},
                      child: const Text('Row action'),
                    ),
                  ],
                ),
              ),
            )
          : copy,
    ),
  );
}
