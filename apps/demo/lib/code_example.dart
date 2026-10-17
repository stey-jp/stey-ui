import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

const codeSamples = <String, String>{
  'javascript': 'const greeting = "Hello";\nconsole.log(greeting);',
  'typescript': 'interface Worker { name: string }\nconst worker: Worker = { name: "Stey" };',
  'jsx': 'const view = <button disabled={false}>Save</button>;\nexport default view;',
  'tsx':
      'const view = (name: string) => <h1>{name}</h1>;\nexport default view;',
  'json': '{\n  "name": "Stey",\n  "enabled": true\n}',
  'jsonc': '{\n  // Worker settings\n  "enabled": true\n}',
  'html': '<main>\n  <button type="button">Save</button>\n</main>',
  'css': '.button {\n  color: #005cc5;\n  padding: 16px;\n}',
  'python':
      'def greet(name):\n    return f"Hello, {name}"\nprint(greet("Stey"))',
  'yaml': 'name: Stey\nworkers:\n  - enabled: true',
  'markdown': '# Stey UI\n\n**Native Flutter** components with `code`.',
  'graphql': 'query Worker {\n  worker(id: "stey") { name }\n}',
  'sql': 'SELECT name, enabled\nFROM workers\nWHERE enabled = true;',
  'bash': '# Deploy a Worker\nexport NAME="stey"\necho "\$NAME"',
  'shell': '\$ echo "Stey"\nStey',
  'diff': '--- before\n+++ after\n-old value\n+new value',
  'hcl': 'resource "worker" "stey" {\n  enabled = true\n  count = 2\n}',
  'toml': '[worker]\nname = "stey"\nenabled = true',
};

class CodeExample extends StatefulWidget {
  const CodeExample({super.key});
  @override
  State<CodeExample> createState() => _CodeExampleState();
}

class _CodeExampleState extends State<CodeExample> {
  String language = 'javascript';
  bool numbers = true, lines = true, plain = false, highlighting = true;
  final highlighter = SteyCodeHighlighter();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: [
      SteySelect<String>(
        label: 'コードの言語',
        value: language,
        options: {for (final value in steyCodeLanguages) value: value},
        onChanged: (value) {
          if (value != null) setState(() => language = value);
        },
      ),
      Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          SteySwitch(
            value: numbers,
            label: '行番号',
            onChanged: (v) => setState(() => numbers = v),
          ),
          SteySwitch(
            value: lines,
            label: '2行目を強調',
            onChanged: (v) => setState(() => lines = v),
          ),
          SteySwitch(
            value: plain,
            label: '枠なし',
            onChanged: (v) => setState(() => plain = v),
          ),
          SteySwitch(
            value: highlighting,
            label: '構文強調',
            onChanged: (v) => setState(() => highlighting = v),
          ),
        ],
      ),
      SteyCodeHighlighting(
        highlighter: highlighting ? highlighter : null,
        copyLabel: 'コピー',
        copiedLabel: 'コピーしました',
        child: SteyCodeHighlighted(
          codeSamples[language]!,
          lang: language,
          showLineNumbers: numbers,
          highlightLines: lines ? const [2] : const [],
          showCopyButton: true,
          variant: plain
              ? SteyCodeHighlightedVariant.plain
              : SteyCodeHighlightedVariant.standard,
        ),
      ),
      const SteyText('横長のコードは横にスクロールできます。コピーすると元のコードを取得できます。', subtle: true),
      const SteyText(
        '構文解析にはDart製のエンジンを使っています。公式Shikiとの色分け、HCLのヒアドキュメントなどに差があります。',
        subtle: true,
      ),
      const SteyText('構文強調なしのコードブロック'),
      const SteyCodeBlock('SteyButton(onPressed: save, child: Text(\'保存\'))'),
    ],
  );
}

Widget codeSample(Map<String, String> parameters) {
  final lang = parameters['lang'] ?? 'javascript';
  final code =
      parameters['code'] ??
      (parameters['single'] == 'true'
          ? 'const answer = 42;'
          : codeSamples[lang] ?? codeSamples['javascript']!);
  return Semantics(
    container: true,
    explicitChildNodes: true,
    label: 'Code preview',
    child: SizedBox(
      width: double.tryParse(parameters['width'] ?? '') ?? 480,
      child: SteyCodeHighlighting(
        highlighter: parameters['fallback'] == 'true'
            ? null
            : SteyCodeHighlighter.standard,
        child: SteyCodeHighlighted(
          code,
          lang: lang,
          variant: parameters['variant'] == 'plain'
              ? SteyCodeHighlightedVariant.plain
              : SteyCodeHighlightedVariant.standard,
          showLineNumbers: parameters['numbers'] != 'false',
          highlightLines: parameters['highlight'] == 'false'
              ? const []
              : const [2],
          showCopyButton: parameters['copy'] != 'false',
        ),
      ),
    ),
  );
}
