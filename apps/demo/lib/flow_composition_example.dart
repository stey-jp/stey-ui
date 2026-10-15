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
