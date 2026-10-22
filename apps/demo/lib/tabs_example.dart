import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class TabsExample extends StatefulWidget {
  const TabsExample({super.key});
  @override
  State<TabsExample> createState() => _TabsExampleState();
}

class _TabsExampleState extends State<TabsExample> {
  String value = 'overview';
  int calls = 0, after = 0;
  bool small = false,
      underline = false,
      autoSelect = false,
      many = false,
      rtl = false,
      uncontrolled = false,
      disabled = false,
      rich = false;
  static const names = {
    'overview': '概要',
    'analytics': '分析',
    'settings': '設定',
    'deployments': 'デプロイ',
    'security': 'セキュリティ',
    'members': 'メンバー',
    'billing': '請求',
    'history': '履歴',
  };
  @override
  Widget build(BuildContext context) {
    final entries = names.entries.take(many ? 8 : 3).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final row in <(String, bool, ValueChanged<bool>)>[
              ('小さいサイズ', small, (v) => setState(() => small = v)),
              ('下線で表示', underline, (v) => setState(() => underline = v)),
              ('フォーカスで選択', autoSelect, (v) => setState(() => autoSelect = v)),
              (
                'タブを増やす',
                many,
                (v) => setState(() {
                  many = v;
                  if (!v && !names.keys.take(3).contains(value)) {
                    value = 'overview';
                  }
                }),
              ),
              ('右から左へ', rtl, (v) => setState(() => rtl = v)),
              ('非制御モード', uncontrolled, (v) => setState(() => uncontrolled = v)),
              ('分析を無効にする', disabled, (v) => setState(() => disabled = v)),
              ('図形付きラベル', rich, (v) => setState(() => rich = v)),
            ])
              SteySwitch(label: row.$1, value: row.$2, onChanged: row.$3),
          ],
        ),
        Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: SteyTabs(
            key: ValueKey(uncontrolled),
            label: 'サービスの設定',
            value: uncontrolled ? null : value,
            selectedValue: value,
            tabs: [
              for (final e in entries)
                SteyTab(
                  e.key,
                  e.value,
                  disabled: disabled && e.key == 'analytics',
                  child: rich ? TabsRichLabel(e.value) : null,
                ),
            ],
            variant: underline
                ? SteyTabsVariant.underline
                : SteyTabsVariant.segmented,
            size: small ? SteySize.sm : SteySize.base,
            activateOnFocus: autoSelect,
            onChanged: (v) => setState(() {
              value = v;
              calls++;
            }),
          ),
        ),
        Text('選択中：${names[value] ?? value}'),
        Text('変更：$calls回'),
        SteyButton(
          onPressed: () => setState(() => after++),
          child: const Text('タブの次の操作'),
        ),
        Text('次の操作：$after回'),
        const SteyText(
          '左右矢印・Home／Endでフォーカスを移動し、Enter／Spaceで選択します。「フォーカスで選択」を有効にすると矢印でも選択します。はみ出すタブは横スクロールやマウスドラッグで移動できます。',
          subtle: true,
        ),
      ],
    );
  }
}

class TabsRichLabel extends StatelessWidget {
  const TabsRichLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 6,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: DefaultTextStyle.of(context).style.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      Text(text),
    ],
  );
}

class TabsSample extends StatefulWidget {
  const TabsSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<TabsSample> createState() => _TabsSampleState();
}

class _TabsSampleState extends State<TabsSample> {
  late String value = widget.query['value'] ?? 'overview';
  int calls = 0, after = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final names = q['many'] == 'true'
        ? [
            'Overview',
            'Analytics',
            'Deployments',
            'Settings',
            'Security',
            'Members',
            'Billing',
            'History',
          ]
        : ['Overview', 'Analytics', 'Settings'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: 'Tabs preview',
          child: SizedBox(
            width: double.tryParse(q['host'] ?? '') ?? 320,
            child: SteyTabs(
              label: 'Tabs',
              tabs: q['empty'] == 'true'
                  ? []
                  : [
                      for (final n in names)
                        SteyTab(
                          n.toLowerCase(),
                          n,
                          child: q['rich'] == 'true' ? TabsRichLabel(n) : null,
                        ),
                    ],
              value: q['uncontrolled'] == 'true' ? null : value,
              selectedValue: value,
              size: q['size'] == 'sm' ? SteySize.sm : SteySize.base,
              variant: q['variant'] == 'underline'
                  ? SteyTabsVariant.underline
                  : SteyTabsVariant.segmented,
              labels: const SteyTabsLabels(
                scrollStart: 'Scroll tabs left',
                scrollEnd: 'Scroll tabs right',
              ),
              activateOnFocus: q['activate'] == 'true',
              onValueChange: (v) => setState(() {
                calls++;
                if (q['frozen'] != 'true') {
                  value = v;
                }
              }),
            ),
          ),
        ),
        SteyButton(
          onPressed: () => setState(() => after++),
          child: const Text('After tabs'),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            jsonEncode({'value': value, 'calls': calls, 'after': after}),
          ),
        ),
      ],
    );
  }
}
