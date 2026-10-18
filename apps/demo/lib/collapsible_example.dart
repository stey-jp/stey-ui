import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class CollapsibleExample extends StatefulWidget {
  const CollapsibleExample({super.key});
  @override
  State<CollapsibleExample> createState() => _CollapsibleExampleState();
}

class _CollapsibleExampleState extends State<CollapsibleExample> {
  bool open = false,
      disabled = false,
      keep = true,
      custom = false,
      long = false,
      cancel = false;
  int calls = 0;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          SteySwitch(
            value: disabled,
            label: '操作を無効化',
            onChanged: (v) => setState(() => disabled = v),
          ),
          SteySwitch(
            value: keep,
            label: '閉じても内容を保持',
            onChanged: (v) => setState(() => keep = v),
          ),
          SteySwitch(
            value: custom,
            label: 'ボタン型の起点',
            onChanged: (v) => setState(() => custom = v),
          ),
          SteySwitch(
            value: long,
            label: '説明を追加',
            onChanged: (v) => setState(() => long = v),
          ),
          SteySwitch(
            value: cancel,
            label: '開閉要求を取り消す',
            onChanged: (v) => setState(() => cancel = v),
          ),
        ],
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: SteyButton(
          onPressed: () => setState(() => open = !open),
          child: Text(open ? '外から閉じる' : '外から開く'),
        ),
      ),
      SteyCollapsibleRoot(
        open: open,
        disabled: disabled,
        onOpenChange: (v, details) {
          if (cancel) details.cancel();
          setState(() {
            calls++;
            if (!details.isCancelled) open = v;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: custom
                  ? SteyCollapsibleTrigger(
                      builder: (context, data) => SteyButton(
                        focusNode: data.focusNode,
                        onPressed: data.onPressed,
                        trailing: Icon(
                          data.open ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                        ),
                        child: const Text('詳細設定'),
                      ),
                    )
                  : const SteyCollapsibleDefaultTrigger(child: Text('詳細設定')),
            ),
            SteyCollapsibleDefaultPanel(
              keepMounted: keep,
              children: [
                const SteyInput(label: 'キャッシュキー', placeholder: 'default'),
                if (long)
                  const SteyText(
                    'この設定はプロジェクト全体に適用されます。閉じても内容を保持する設定では、入力した値を再表示できます。',
                  ),
                const SteyText('入力してから閉じ、再び開いて値を確認してください。', subtle: true),
              ],
            ),
          ],
        ),
      ),
      Semantics(
        liveRegion: true,
        child: Text('開閉要求：$calls回・${open ? '表示中' : '非表示'}'),
      ),
      const SteyText(
        '標準表示は100msで開閉します。内容の保持を外すと、閉じ終わった時点で入力値を破棄します。',
        subtle: true,
      ),
    ],
  );
}

class CollapsibleSample extends StatefulWidget {
  const CollapsibleSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<CollapsibleSample> createState() => _CollapsibleSampleState();
}

class _CollapsibleSampleState extends State<CollapsibleSample> {
  late bool open = widget.query['open'] == 'true';
  int calls = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final bare = q['kind'] == 'bare', custom = q['kind'] == 'custom';
    final title = q['long'] == 'true'
        ? 'Review access permissions and project settings before saving'
        : 'Details';
    final content = q['input'] == 'true'
        ? const _SampleInput()
        : const Text('Review your settings before saving.');
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Collapsible preview',
      child: SizedBox(
        width: double.tryParse(q['host'] ?? '') ?? 480,
        child: Stack(
          children: [
            SteyCollapsibleRoot(
              open: q['controlled'] == 'true' ? open : null,
              defaultOpen: open,
              disabled: q['state'] == 'disabled',
              panelIdentifier: 'details-panel',
              onOpenChange: (v, d) {
                if (q['cancel'] == 'true') d.cancel();
                setState(() {
                  calls++;
                  if (!d.isCancelled) open = v;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: custom
                        ? SteyCollapsibleTrigger(
                            builder: (context, data) => SteyButton(
                              focusNode: data.focusNode,
                              onPressed: data.onPressed,
                              child: Text(title),
                            ),
                          )
                        : bare
                        ? SteyCollapsibleTrigger(child: Text(title))
                        : SteyCollapsibleDefaultTrigger(child: Text(title)),
                  ),
                  if (bare)
                    SteyCollapsiblePanel(
                      keepMounted: q['keep'] == 'true',
                      child: content,
                    )
                  else
                    SteyCollapsibleDefaultPanel(
                      keepMounted: q['keep'] == 'true',
                      children: [
                        content,
                        if (q['multiple'] == 'true')
                          const Text('Changes are applied to this project.'),
                      ],
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: Semantics(
                    label: 'Change calls: $calls',
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

class _SampleInput extends StatefulWidget {
  const _SampleInput();
  @override
  State<_SampleInput> createState() => _SampleInputState();
}

class _SampleInputState extends State<_SampleInput> {
  int count = 0;
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: SteyButton(
      onPressed: () => setState(() => count++),
      child: Text('Inner count: $count'),
    ),
  );
}
