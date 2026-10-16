import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class FlowCompositionExample extends StatefulWidget {
  const FlowCompositionExample({super.key});
  @override
  State<FlowCompositionExample> createState() => _FlowCompositionExampleState();
}

class _FlowCompositionExampleState extends State<FlowCompositionExample> {
  bool vertical = false, center = false, end = false, expanded = false;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SteyText('自動レイアウトと分岐', heading: 4),
      const SizedBox(height: 8),
      const Text('内容の大きさを測定して配置し、ListとParallelの構成から接続を自動生成します。'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SteyButton(
            onPressed: () => setState(() => vertical = !vertical),
            child: Text('方向：${vertical ? '縦' : '横'}'),
          ),
          SteyButton(
            onPressed: () => setState(() => center = !center),
            child: Text('配置：${center ? '中央' : '先頭'}'),
          ),
          SteyButton(
            onPressed: () => setState(() => end = !end),
            child: Text('分岐：${end ? '末尾揃え' : '先頭揃え'}'),
          ),
          SteyButton(
            onPressed: () => setState(() => expanded = !expanded),
            child: Text(expanded ? '処理内容を短くする' : '処理内容を長くする'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SteyFlow.composed(
        interactive: false,
        orientation: vertical
            ? SteyFlowOrientation.vertical
            : SteyFlowOrientation.horizontal,
        align: center ? SteyFlowAlign.center : SteyFlowAlign.start,
        children: [
          const SteyFlowNode('start', Text('受信')),
          SteyFlowParallel([
            SteyFlowList([
              SteyFlowNode(
                'validate',
                Text(expanded ? '入力とアクセス権限を確認する' : '入力を確認'),
              ),
              const SteyFlowNode('save', Text('保存')),
            ]),
            const SteyFlowNode('queue', Text('通知キュー')),
          ], alignEnd: end),
          const SteyFlowNode('finish', Text('完了')),
        ],
      ),
      Semantics(
        liveRegion: true,
        child: Text(
          '${vertical ? '縦' : '横'}方向・${center ? '中央' : '先頭'}配置・${end ? '末尾' : '先頭'}揃え・${expanded ? '長い内容' : '短い内容'}',
        ),
      ),
    ],
  );
}

Widget flowCompositionSample(Map<String, String> q) {
  SteyFlowNode node(String id, String label) => SteyFlowNode(id, Text(label));
  final end = q['branchAlign'] == 'end';
  final children = switch (q['scenario']) {
    'parallel' => [
      node('start', 'Start'),
      SteyFlowParallel([
        node('a', 'Branch A'),
        node('b', 'Branch B is wider'),
      ], alignEnd: end),
      node('end', 'End'),
    ],
    'nested' => [
      node('start', 'Start'),
      SteyFlowParallel([
        SteyFlowList([node('check', 'Check'), node('save', 'Save')]),
        node('queue', 'Queue'),
      ], alignEnd: end),
      node('end', 'End'),
    ],
    'adjacent' => [
      SteyFlowParallel([node('a', 'A'), node('b', 'Branch B')]),
      SteyFlowParallel([node('c', 'C'), node('d', 'Branch D')], alignEnd: end),
    ],
    'expanded' => [
      node('start', 'Start'),
      SteyFlowNode(
        'process',
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Process'),
            if (q['expanded'] == 'true')
              const SizedBox(
                width: 180,
                height: 60,
                child: Text('Expanded content'),
              ),
          ],
        ),
      ),
      node('end', 'End'),
    ],
    _ => [
      node('start', 'Start'),
      node('process', 'Process'),
      node('end', 'End'),
    ],
  };
  return SteyFlow.composed(
    canvas: false,
    padding: EdgeInsets.zero,
    orientation: q['orientation'] == 'vertical'
        ? SteyFlowOrientation.vertical
        : SteyFlowOrientation.horizontal,
    align: q['align'] == 'center' ? SteyFlowAlign.center : SteyFlowAlign.start,
    children: children,
  );
}

class FlowCanvasExample extends StatefulWidget {
  const FlowCanvasExample({super.key});
  @override
  State<FlowCanvasExample> createState() => _FlowCanvasExampleState();
}

class _FlowCanvasExampleState extends State<FlowCanvasExample> {
  bool compact = false;
  ({bool x, bool y}) overflow = (x: false, y: false);
  int calls = 0;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SteyText('キャンバスの移動', heading: 4),
      const SizedBox(height: 8),
      const Text('余白をドラッグして移動できます。トラックパッドは縦横のスクロールに対応します。'),
      const SizedBox(height: 12),
      SteyButton(
        onPressed: () => setState(() => compact = !compact),
        child: Text(compact ? '分岐を増やす' : '分岐を減らす'),
      ),
      const SizedBox(height: 8),
      Semantics(
        container: true,
        label: 'フローの移動プレビュー',
        explicitChildNodes: true,
        child: SizedBox(
          width: 320,
          child: SteyFlow.composed(
            viewportHeight: 180,
            padding: const EdgeInsets.all(16),
            onOverflowChange: (value) {
              if (overflow != value) setState(() => overflow = value);
            },
            children: [
              SteyFlowNode(
                'start',
                SizedBox(
                  width: 96,
                  height: 64,
                  child: Center(
                    child: SteyButton(
                      onPressed: () => setState(() => calls++),
                      child: const Text('受信を確認'),
                    ),
                  ),
                ),
              ),
              if (!compact) ...[
                const SteyFlowParallel([
                  SteyFlowNode(
                    'process',
                    SizedBox(
                      width: 96,
                      height: 64,
                      child: Center(child: Text('処理')),
                    ),
                  ),
                  SteyFlowNode(
                    'review',
                    SizedBox(
                      width: 96,
                      height: 64,
                      child: Center(child: Text('確認')),
                    ),
                  ),
                ]),
                const SteyFlowNode(
                  'end',
                  SizedBox(
                    width: 96,
                    height: 64,
                    child: Center(child: Text('完了')),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      Semantics(
        liveRegion: true,
        child: Text(
          'はみ出し：横${overflow.x ? 'あり' : 'なし'}・縦${overflow.y ? 'あり' : 'なし'}／確認 $calls回',
        ),
      ),
    ],
  );
}

Widget flowCanvasSample(Map<String, String> q) {
  SteyFlowNode node(String id, String text) => SteyFlowNode(
    id,
    SizedBox(width: 96, height: 64, child: Center(child: Text(text))),
  );
  return Semantics(
    container: true,
    label: 'Flow canvas preview',
    explicitChildNodes: true,
    child: SizedBox(
      width: double.tryParse(q['viewport'] ?? '') ?? 320,
      child: SteyFlow.composed(
        viewportHeight: 180,
        padding: const EdgeInsets.all(16),
        children: [
          node('start', 'Start'),
          if (q['fit'] != 'true') ...[
            SteyFlowParallel([
              node('process', 'Process'),
              node('review', 'Review'),
            ]),
            node('end', 'End'),
          ],
        ],
      ),
    ),
  );
}

class FlowWrapExample extends StatefulWidget {
  const FlowWrapExample({super.key});
  @override
  State<FlowWrapExample> createState() => _FlowWrapExampleState();
}

class _FlowWrapExampleState extends State<FlowWrapExample> {
  bool wide = false, long = true, vertical = true;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SteyText('ノードの折り返し', heading: 4),
      const SizedBox(height: 8),
      const Text('最大幅を指定すると、説明を折り返した高さに合わせて後続のノードと接続位置も更新されます。'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SteyButton(
            onPressed: () => setState(() => wide = !wide),
            child: Text('最大幅：${wide ? 240 : 120}px'),
          ),
          SteyButton(
            onPressed: () => setState(() => long = !long),
            child: Text(long ? '説明を短くする' : '説明を長くする'),
          ),
          SteyButton(
            onPressed: () => setState(() => vertical = !vertical),
            child: Text('配置方向：${vertical ? '縦' : '横'}'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Semantics(
        container: true,
        explicitChildNodes: true,
        label: '折り返しプレビュー',
        child: SizedBox(
          width: 320,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cap = (wide ? 240.0 : 120.0).clamp(
                0.0,
                (constraints.maxWidth - 32).clamp(0.0, double.infinity),
              );
              return SteyFlow.composed(
                padding: const EdgeInsets.all(16),
                orientation: vertical
                    ? SteyFlowOrientation.vertical
                    : SteyFlowOrientation.horizontal,
                align: SteyFlowAlign.center,
                children: [
                  const SteyFlowNode('start', Text('受信')),
                  SteyFlowNode(
                    'process',
                    SteyFlowAnchor(
                      child: Text(
                        long ? '保存する前に、入力内容とアクセス権限を確認してください。' : '入力を確認',
                      ),
                    ),
                    maxWidth: cap,
                  ),
                  const SteyFlowNode('review', Text('承認')),
                  const SteyFlowNode('end', Text('完了')),
                ],
              );
            },
          ),
        ),
      ),
    ],
  );
}

Widget flowWrapSample(Map<String, String> q) => Semantics(
  container: true,
  explicitChildNodes: true,
  label: 'Flow wrapping preview',
  child: SizedBox(
    width: double.tryParse(q['host'] ?? '') ?? 320,
    child: SteyFlow.composed(
      viewportHeight: 500,
      padding: const EdgeInsets.all(16),
      orientation: q['orientation'] == 'horizontal'
          ? SteyFlowOrientation.horizontal
          : SteyFlowOrientation.vertical,
      align: SteyFlowAlign.center,
      children: [
        const SteyFlowNode('start', Text('Start')),
        SteyFlowNode(
          'process',
          Text(
            q['content'] == 'short'
                ? 'Check'
                : 'Review access permissions before saving changes',
          ),
          maxWidth: double.tryParse(q['cap'] ?? '') ?? 120,
        ),
        const SteyFlowNode('review', Text('Review')),
        const SteyFlowNode('end', Text('End')),
      ],
    ),
  ),
);

class FlowAutoExample extends StatefulWidget {
  const FlowAutoExample({super.key, this.parameters});
  final Map<String, String>? parameters;
  @override
  State<FlowAutoExample> createState() => _FlowAutoExampleState();
}

class _FlowAutoExampleState extends State<FlowAutoExample> {
  late double width;
  bool short = false;
  int epoch = 0;
  bool get fixture => widget.parameters != null;
  @override
  void initState() {
    super.initState();
    width = double.tryParse(widget.parameters?['host'] ?? '') ?? 160;
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!fixture) ...[
        const SteyText('初期幅と自動測定', heading: 4),
        const SizedBox(height: 8),
        const Text('初期表示で測った図の幅を保持します。親幅を変えても折り返しを維持し、図を作り直すと現在の幅で再測定します。'),
        const SizedBox(height: 12),
      ],
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SteyButton(
            onPressed: () => setState(() => width = width == 160 ? 320 : 160),
            child: Text(
              fixture ? 'Resize host' : '親幅：${width == 160 ? '狭い' : '広い'}',
            ),
          ),
          SteyButton(
            onPressed: () => setState(() => short = !short),
            child: Text(
              fixture
                  ? 'Toggle content'
                  : short
                  ? '自動測定の説明を長くする'
                  : '自動測定の説明を短くする',
            ),
          ),
          SteyButton(
            onPressed: () => setState(() => epoch++),
            child: Text(fixture ? 'Reset diagram' : '図を作り直す'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Semantics(
        container: true,
        explicitChildNodes: true,
        label: fixture ? 'Flow auto width preview' : '自動幅プレビュー',
        child: SizedBox(
          width: width,
          child: SteyFlow.composed(
            key: ValueKey(epoch),
            viewportHeight: fixture ? 800 : 500,
            padding: const EdgeInsets.all(16),
            orientation: widget.parameters?['orientation'] == 'horizontal'
                ? SteyFlowOrientation.horizontal
                : SteyFlowOrientation.vertical,
            align: SteyFlowAlign.center,
            children: _autoNodes(
              widget.parameters?['position'] ?? 'middle',
              short: short,
              japanese: !fixture,
            ),
          ),
        ),
      ),
    ],
  );
}

List<SteyFlowElement> _autoNodes(
  String position, {
  required bool short,
  required bool japanese,
}) {
  final labels = japanese
      ? ['受信', '処理', '承認', '完了']
      : ['Start', 'Process', 'Review', 'End'];
  const ids = ['start', 'process', 'review', 'end'];
  final description = japanese
      ? '保存する前に、入力内容とアクセス権限を確認してください。'
      : 'Review access permissions before saving changes';
  SteyFlowNode node(int index, {bool long = false}) => SteyFlowNode(
    ids[index],
    Text(!short && long ? description : labels[index]),
  );
  if (position == 'only') {
    return [node(1, long: true)];
  }
  if (position == 'parallel' || position == 'parallel-last') {
    return [
      node(0),
      SteyFlowParallel(
        position == 'parallel'
            ? [node(1, long: true), node(2)]
            : [node(2), node(1, long: true)],
      ),
      node(3),
    ];
  }
  final target = position == 'first'
      ? 0
      : position == 'last'
      ? 3
      : 1;
  return [
    for (var i = 0; i < 4; i++) node(i, long: position == 'all' || i == target),
  ];
}
