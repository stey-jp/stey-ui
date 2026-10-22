import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class LabelExample extends StatefulWidget {
  const LabelExample({super.key});
  @override
  State<LabelExample> createState() => _LabelExampleState();
}

class _LabelExampleState extends State<LabelExample> {
  final editorFocus = FocusNode();
  bool optional = false,
      help = true,
      rich = false,
      inherit = false,
      narrow = false,
      rtl = false;
  double scale = 1;
  int after = 0;
  @override
  void dispose() {
    editorFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = <(String, bool, ValueChanged<bool>)>[
      ('任意の表示', optional, (v) => setState(() => optional = v)),
      ('詳しい情報を表示', help, (v) => setState(() => help = v)),
      ('装飾付きの内容', rich, (v) => setState(() => rich = v)),
      ('親の文字スタイルを継承', inherit, (v) => setState(() => inherit = v)),
      ('幅を狭くする', narrow, (v) => setState(() => narrow = v)),
      ('右から左へ', rtl, (v) => setState(() => rtl = v)),
    ];
    final label = rich
        ? SteyLabel.rich(
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'プロジェクト',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: '名'),
                ],
              ),
            ),
            showOptional: optional,
            optionalContent: const Text('（入力を省略可）'),
            tooltipContent: help
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '名前の設定',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text('公開される名前を入力します。'),
                    ],
                  )
                : null,
            tooltipSemanticLabel: '名前の設定。公開される名前を入力します。',
            asContent: inherit,
            controlFocusNode: editorFocus,
          )
        : SteyLabel(
            'プロジェクト名',
            showOptional: optional,
            tooltip: help ? '公開される名前を入力します。' : null,
            asContent: inherit,
            controlFocusNode: editorFocus,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final p in properties)
              SteySwitch(label: p.$1, value: p.$2, onChanged: p.$3),
            SteyButton(
              onPressed: () => setState(() => scale = scale == 1 ? 2 : 1),
              semanticLabel: '拡大率：${(scale * 100).round()}%、文字の拡大率を変更',
              child: Text('拡大率：${(scale * 100).round()}%'),
            ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: narrow ? 220 : 520,
            child: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: scale,
                maxScaleFactor: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.75,
                        fontWeight: FontWeight.w600,
                        color: SteyTheme.colorsOf(context).dark
                            ? const Color(0xffffb18f)
                            : const Color(0xff9f2d00),
                      ),
                      child: Semantics(
                        container: true,
                        explicitChildNodes: true,
                        label: 'Label content',
                        child: label,
                      ),
                    ),
                    SteyInput(
                      focusNode: editorFocus,
                      semanticLabel: 'プロジェクト名の入力欄',
                      placeholder: 'プロジェクト名を入力',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SteyText(
          'ラベルや任意表示を押すと入力欄に移動します。情報ボタンはTabで移動し、Escapeで閉じられます。クリック・タップでも説明を表示できます。',
        ),
        SteyButton(
          onPressed: () => setState(() => after++),
          child: const Text('ラベルの次の操作'),
        ),
        Text('次の操作：$after回'),
      ],
    );
  }
}

class LabelSample extends StatefulWidget {
  const LabelSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<LabelSample> createState() => _LabelSampleState();
}

class _LabelSampleState extends State<LabelSample> {
  final focus = FocusNode();
  int after = 0;
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final help = q['help'] == 'true';
    final label = q['rich'] == 'true'
        ? SteyLabel.rich(
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Project',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' name'),
                ],
              ),
            ),
            showOptional: q['optional'] == 'true',
            optionalContent: const Text('(your choice)'),
            tooltipContent: help
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text('Helpful context'), Text('More details')],
                  )
                : null,
            tooltipSemanticLabel: 'Helpful context. More details',
            asContent: q['inherit'] == 'true',
            controlFocusNode: focus,
          )
        : SteyLabel(
            q['content'] ?? 'Project name',
            showOptional: q['optional'] == 'true',
            optionalLabel: q['optionalLabel'],
            tooltip: help ? 'Helpful context' : null,
            tooltipAriaLabel: 'More information',
            asContent: q['inherit'] == 'true',
            controlFocusNode: focus,
          );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Label preview',
      child: SizedBox(
        width: double.tryParse(q['host'] ?? '') ?? 280,
        child: Directionality(
          textDirection: q['direction'] == 'rtl'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              MediaQuery.withClampedTextScaling(
                minScaleFactor: double.tryParse(q['scale'] ?? '') ?? 1,
                maxScaleFactor: double.tryParse(q['scale'] ?? '') ?? 1,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: double.tryParse(q['font'] ?? '') ?? 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff737373),
                  ),
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    label: 'Label content',
                    child: label,
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: TextField(
                  focusNode: focus,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    labelText: 'Editor',
                  ),
                ),
              ),
              SteyButton(
                onPressed: () => setState(() => after++),
                child: const Text('Next action'),
              ),
              Text('Next: $after'),
            ],
          ),
        ),
      ),
    );
  }
}
