import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class EmptyExample extends StatefulWidget {
  const EmptyExample({super.key});
  @override
  State<EmptyExample> createState() => _EmptyExampleState();
}

class _EmptyExampleState extends State<EmptyExample> {
  SteyEmptySize size = SteyEmptySize.base;
  bool description = true,
      illustration = true,
      command = true,
      long = false,
      actions = true;
  int copies = 0, created = 0;
  String? error;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      SteySelect(
        value: size,
        label: '表示サイズ',
        options: const {
          SteyEmptySize.sm: 'コンパクト',
          SteyEmptySize.base: '標準',
          SteyEmptySize.lg: '大きい',
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
            value: description,
            label: '説明を表示',
            onChanged: (v) => setState(() => description = v),
          ),
          SteySwitch(
            value: illustration,
            label: 'アイコンを表示',
            onChanged: (v) => setState(() => illustration = v),
          ),
          SteySwitch(
            value: command,
            label: 'コマンドを表示',
            onChanged: (v) => setState(() => command = v),
          ),
          SteySwitch(
            value: long,
            label: '長い内容',
            onChanged: (v) => setState(() => long = v),
          ),
          SteySwitch(
            value: actions,
            label: '操作を表示',
            onChanged: (v) => setState(() => actions = v),
          ),
        ],
      ),
      SteyEmpty(
        title: 'Workerがまだありません',
        size: size,
        description: description
            ? long
                  ? 'アクセス権限とプロジェクトの設定を確認してから、最初のWorkerを作成してください。コマンドは横にスクロールして全文を確認できます。'
                  : '最初のWorkerを作成してください。'
            : null,
        illustration: illustration
            ? const Icon(Icons.inventory_2_outlined, size: 48)
            : null,
        commandLine: command
            ? long
                  ? 'npm create cloudflare@latest -- worker-example --type hello-world --deploy false'
                  : 'npm create cloudflare@latest'
            : null,
        onCopied: () => setState(() {
          copies++;
          error = null;
        }),
        onCopyError: (_) => setState(() => error = 'コピーできませんでした。もう一度お試しください。'),
        contents: actions
            ? Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  SteyButton(
                    variant: SteyButtonVariant.primary,
                    onPressed: () => setState(() => created++),
                    child: const Text('Workerを作成'),
                  ),
                  SteyButton(
                    onPressed: () => setState(() => description = true),
                    child: const Text('手順を表示'),
                  ),
                ],
              )
            : null,
      ),
      Semantics(
        liveRegion: true,
        child: Text(error ?? 'コピー：$copies回・作成操作：$created回'),
      ),
      const SteyText('コマンド本文だけをコピーします。成功時のチェックは1秒間表示されます。', subtle: true),
    ],
  );
}

class EmptySample extends StatefulWidget {
  const EmptySample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<EmptySample> createState() => _EmptySampleState();
}

class _EmptySampleState extends State<EmptySample> {
  int copies = 0, calls = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Empty preview',
      child: SizedBox(
        width: double.tryParse(q['host'] ?? '') ?? 600,
        child: Stack(
          children: [
            SteyEmpty(
              copyActionLabel: 'Copy command',
              title: q['long'] == 'true'
                  ? 'No project resources have been created yet'
                  : 'No resources found',
              description: q['description'] == 'none'
                  ? null
                  : q['long'] == 'true'
                  ? 'Review your access permissions and project settings before creating the first resource for this account.'
                  : 'Create your first resource to get started.',
              size: SteyEmptySize.values.firstWhere(
                (v) => v.name == q['emptySize'],
                orElse: () => SteyEmptySize.base,
              ),
              illustration: q['icon'] == 'true'
                  ? Builder(
                      builder: (context) => SizedBox(
                        width: 48,
                        height: 48,
                        child: ColoredBox(
                          color: SteyTheme.colorsOf(context).subtle,
                        ),
                      ),
                    )
                  : null,
              commandLine: q['command'] == 'none'
                  ? null
                  : q['command'] == 'long'
                  ? 'flutter create --org stey.jp resource-example --platforms web,windows,macos,linux,android,ios'
                  : 'flutter create resource-example',
              onCopied: () => setState(() => copies++),
              contents: q['actions'] == 'true'
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        SteyButton(
                          onPressed: () => setState(() => calls++),
                          child: const Text('Create resource'),
                        ),
                        if (q['multiple'] == 'true')
                          SteyButton(
                            onPressed: () => setState(() => calls++),
                            child: const Text('Read guide'),
                          ),
                      ],
                    )
                  : null,
            ),
            Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: Semantics(
                    label: 'Copy calls: $copies; Action calls: $calls',
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
