import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class TextExample extends StatefulWidget {
  const TextExample({super.key});
  @override
  State<TextExample> createState() => _TextExampleState();
}

class _TextExampleState extends State<TextExample> {
  SteyTextVariant variant = SteyTextVariant.body;
  SteyTextSize size = SteyTextSize.base;
  bool bold = false,
      truncate = false,
      narrow = false,
      rtl = false,
      rich = false;
  int level = 0, after = 0;
  double scale = 1;
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
            semanticLabel: '種類：${variant.name}、文字の種類を変更',
            onPressed: () => setState(
              () => variant = SteyTextVariant
                  .values[(variant.index + 1) % SteyTextVariant.values.length],
            ),
            child: Text('種類：${variant.name}'),
          ),
          SteyButton(
            semanticLabel: 'サイズ：${size.name}、文字サイズを変更',
            onPressed: () => setState(
              () => size = SteyTextSize.values[(size.index + 1) % 4],
            ),
            child: Text('サイズ：${size.name}'),
          ),
          SteyButton(
            semanticLabel:
                '${level == 0 ? '意味情報：通常の文字' : '意味情報：見出し$level'}、見出しレベルを変更',
            onPressed: () => setState(() => level = (level + 1) % 7),
            child: Text(level == 0 ? '意味情報：通常の文字' : '意味情報：見出し$level'),
          ),
          SteyButton(
            semanticLabel: '拡大率：${(scale * 100).round()}%、拡大率を変更',
            onPressed: () => setState(() => scale = scale == 1 ? 2 : 1),
            child: Text('拡大率：${(scale * 100).round()}%'),
          ),
          for (final row in <(String, bool, ValueChanged<bool>)>[
            ('本文を中太にする', bold, (v) => setState(() => bold = v)),
            ('長文を省略', truncate, (v) => setState(() => truncate = v)),
            ('幅を狭くする', narrow, (v) => setState(() => narrow = v)),
            ('右から左へ', rtl, (v) => setState(() => rtl = v)),
            ('一部を強調する', rich, (v) => setState(() => rich = v)),
          ])
            SteySwitch(label: row.$1, value: row.$2, onChanged: row.$3),
        ],
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: narrow ? 160 : 520,
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: scale,
            maxScaleFactor: scale,
            child: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: rich
                  ? SteyText.rich(
                      const TextSpan(
                        children: [
                          TextSpan(text: 'Kumoの文字を'),
                          TextSpan(
                            text: '部分的に強調',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          TextSpan(text: 'して、長い文章の折り返しと省略表示を確認できます。'),
                        ],
                      ),
                      variant: variant,
                      size: size,
                      bold: bold,
                      truncate: truncate,
                      headingLevel: level,
                    )
                  : SteyText(
                      'Kumoの文字を表示します。長い文章の折り返しと省略表示、色とサイズ、見出しの意味情報を確認できます。',
                      variant: variant,
                      size: size,
                      bold: bold,
                      truncate: truncate,
                      headingLevel: level,
                    ),
            ),
          ),
        ),
      ),
      const SteyText(
        '本文・補足・成功・エラー・等幅・見出しを切り替えられます。見た目の種類と読み上げ用の見出しレベルは個別に設定します。',
        subtle: true,
      ),
      SteyButton(
        onPressed: () => setState(() => after++),
        child: const Text('文字の次の操作'),
      ),
      Text('次の操作：$after回'),
    ],
  );
}

class TextSample extends StatelessWidget {
  const TextSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  Widget build(BuildContext context) {
    final q = query;
    final variant = SteyTextVariant.values.firstWhere(
      (v) => v.name == q['variant'],
      orElse: () => SteyTextVariant.body,
    );
    final line = double.tryParse(q['line'] ?? '') ?? 21;
    final content = q['content'] ?? 'Workers process requests';
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Text preview',
      child: SizedBox(
        width: double.tryParse(q['host'] ?? '') ?? 280,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 14,
              height: line / 14,
              fontWeight: q['inheritBold'] == 'true'
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  double.tryParse(q['scale'] ?? '') ?? 1,
                ),
              ),
              child: Directionality(
                textDirection: q['direction'] == 'rtl'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: q['rich'] == 'true'
                    ? SteyText.rich(
                        const TextSpan(
                          children: [
                            TextSpan(text: 'Workers '),
                            TextSpan(
                              text: 'process',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            TextSpan(text: ' requests'),
                          ],
                        ),
                        variant: variant,
                        size: SteyTextSize.values.firstWhere(
                          (s) => s.name == q['size'],
                          orElse: () => SteyTextSize.base,
                        ),
                        bold: q['bold'] == 'true',
                        truncate: q['truncate'] == 'true',
                        headingLevel: int.tryParse(q['level'] ?? '') ?? 0,
                      )
                    : SteyText(
                        content,
                        variant: variant,
                        size: SteyTextSize.values.firstWhere(
                          (s) => s.name == q['size'],
                          orElse: () => SteyTextSize.base,
                        ),
                        bold: q['bold'] == 'true',
                        truncate: q['truncate'] == 'true',
                        headingLevel: int.tryParse(q['level'] ?? '') ?? 0,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
