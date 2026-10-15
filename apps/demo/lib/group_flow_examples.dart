import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class ButtonGroupExample extends StatefulWidget {
  const ButtonGroupExample({super.key});
  @override
  State<ButtonGroupExample> createState() => _ButtonGroupExampleState();
}

class _ButtonGroupExampleState extends State<ButtonGroupExample> {
  String result = '操作を選んでください';
  void selected(String value) => setState(() => result = value);
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('関連する操作を、境界と角丸を共有する1つのグループにまとめます。'),
      const SizedBox(height: 16),
      SteyButtonGroup(
        semanticLabel: 'デプロイ操作',
        children: [
          SteyButton(
            variant: SteyButtonVariant.primary,
            onPressed: () => selected('本番へデプロイしました'),
            child: const Text('デプロイ'),
          ),
          SteyDropdownMenu(
            label: 'デプロイ先を選択',
            items: [
              SteyMenuItem(
                'ステージングへデプロイ',
                onPressed: () => selected('ステージングへデプロイしました'),
              ),
              SteyMenuItem(
                '下書きとして保存',
                onPressed: () => selected('下書きとして保存しました'),
              ),
            ],
            triggerBuilder: (context, open, focus) => SteyButton(
              onPressed: open,
              focusNode: focus,
              variant: SteyButtonVariant.primary,
              shape: SteyButtonShape.square,
              semanticLabel: 'デプロイ先を選択',
              icon: const Icon(Icons.expand_more, size: 16),
              child: const SizedBox.shrink(),
            ),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SteyButtonGroup(
        semanticLabel: '編集操作',
        children: [
          Tooltip(
            message: '変更を保存',
            child: SteyButton(
              onPressed: () => selected('変更を保存しました'),
              child: const Text('保存'),
            ),
          ),
          SteyLink(
            onPressed: () => selected('詳細を表示しました'),
            child: const Text('詳細'),
          ),
          SteyButton(
            onPressed: () => selected('変更を取り消しました'),
            child: const Text('取消'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const Text('右から左へ並べる場合も、外側だけに角丸を残します。'),
      const SizedBox(height: 8),
      Directionality(
        textDirection: TextDirection.rtl,
        child: SteyButtonGroup(
          semanticLabel: '右から左の操作',
          children: [
            SteyButton(
              onPressed: () => selected('右端を選択しました'),
              child: const Text('右端'),
            ),
            SteyButton(
              onPressed: () => selected('中央を選択しました'),
              child: const Text('中央'),
            ),
            SteyButton(
              onPressed: () => selected('左端を選択しました'),
              child: const Text('左端'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Semantics(liveRegion: true, child: Text(result)),
    ],
  );
}

class FlowAnchorExample extends StatefulWidget {
  const FlowAnchorExample({super.key});
  @override
  State<FlowAnchorExample> createState() => _FlowAnchorExampleState();
}

class _FlowAnchorExampleState extends State<FlowAnchorExample> {
  double margin = -4;
  bool expanded = false, disabled = false;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('外側の余白と内側の移動を含め、接続先の中央へ線を合わせます。横にスクロールできます。'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SteyButton(
            onPressed: () => setState(() => margin = margin == -4 ? 20 : -4),
            child: Text('外側余白：${margin.toInt()}px'),
          ),
          SteyButton(
            onPressed: () => setState(() => expanded = !expanded),
            child: Text(expanded ? '内容を折りたたむ' : '内容を展開'),
          ),
          SteyButton(
            onPressed: () => setState(() => disabled = !disabled),
            child: Text(disabled ? '接続を有効にする' : '接続を無効にする'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SteyFlow(
        interactive: false,
        nodes: [
          SteyFlowNode(
            '入力',
            _FlowSampleCard(
              label: '入力',
              anchorKey: const ValueKey('flow-input'),
            ),
            custom: true,
            width: 120,
            height: 40,
            margin: EdgeInsets.only(top: margin),
          ),
          SteyFlowNode(
            '処理',
            Transform.translate(
              offset: const Offset(0, -4),
              child: _FlowSampleCard(
                label: '処理',
                expanded: expanded,
                anchorKey: const ValueKey('flow-process'),
              ),
            ),
            custom: true,
            width: 120,
            height: expanded ? 88 : 40,
          ),
          SteyFlowNode(
            '出力',
            const _FlowSampleCard(
              label: '出力',
              anchorKey: ValueKey('flow-output'),
            ),
            custom: true,
            width: 120,
            height: 40,
            margin: const EdgeInsets.only(top: -4),
            disabled: disabled,
          ),
        ],
        edges: const [SteyFlowEdge('入力', '処理'), SteyFlowEdge('処理', '出力')],
      ),
      Text(
        '外側余白：${margin.toInt()}px・処理：${expanded ? '展開中' : '折りたたみ中'}・接続：${disabled ? '無効' : '有効'}',
      ),
    ],
  );
}

class _FlowSampleCard extends StatelessWidget {
  const _FlowSampleCard({
    required this.label,
    this.expanded = false,
    this.anchorKey,
  });
  final String label;
  final bool expanded;
  final Key? anchorKey;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: c.base,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: c.line, spreadRadius: 1)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SteyFlowAnchor(
            key: anchorKey,
            child: SizedBox(
              width: 120,
              height: 40,
              child: Center(child: Text(label)),
            ),
          ),
          if (expanded)
            const SizedBox(height: 48, child: Center(child: Text('詳細な処理内容'))),
        ],
      ),
    );
  }
}

Widget buttonGroupSample(Map<String, String> q) {
  final size = SteySize.values.firstWhere(
    (s) => s.name == q['size'],
    orElse: () => SteySize.base,
  );
  final variant = SteyButtonVariant.values.firstWhere(
    (v) => v.name == q['variant'],
    orElse: () => SteyButtonVariant.secondary,
  );
  return SteyButtonGroup(
    semanticLabel: 'Actions',
    children: [
      for (final label in ['One', 'Two', 'Three'])
        SteyButton(
          onPressed: q['state'] == 'disabled' ? null : () {},
          loading: q['state'] == 'loading' && label == 'Two',
          size: size,
          variant: variant,
          child: Text(label),
        ),
    ],
  );
}

Widget flowAnchorSample(Map<String, String> q) {
  final margin = double.tryParse(q['margin'] ?? '') ?? -4;
  return SizedBox(
    width: 488,
    child: SteyFlow(
      interactive: false,
      padding: EdgeInsets.zero,
      nodes: [
        SteyFlowNode(
          'first',
          const _FlowSampleCard(label: 'Start'),
          custom: true,
          width: 120,
          height: 40,
          margin: EdgeInsets.only(top: margin),
        ),
        SteyFlowNode(
          'middle',
          Transform.translate(
            offset: const Offset(0, -4),
            child: const _FlowSampleCard(label: 'Process'),
          ),
          custom: true,
          width: 120,
          height: 40,
        ),
        SteyFlowNode(
          'last',
          const _FlowSampleCard(label: 'End'),
          custom: true,
          width: 120,
          height: 40,
          margin: const EdgeInsets.only(top: -4),
          disabled: q['state'] == 'disabled',
        ),
      ],
      edges: const [
        SteyFlowEdge('first', 'middle'),
        SteyFlowEdge('middle', 'last'),
      ],
    ),
  );
}
