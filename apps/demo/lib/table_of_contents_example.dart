import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class TableOfContentsExample extends StatefulWidget {
  const TableOfContentsExample({super.key, this.onSelected, this.location});
  final ValueChanged<String>? onSelected;
  final Uri? location;
  @override
  State<TableOfContentsExample> createState() => _ExampleState();
}

class _ExampleState extends State<TableOfContentsExample> {
  static const sections = {
    'overview': '概要',
    'analytics': '分析',
    'settings': '設定',
    '50%-off': '割引（50%）',
    'café': 'Unicode（café）',
  };
  final scroll = ScrollController();
  late final anchors = {for (final id in sections.keys) id: GlobalKey()};
  late final tracker = SteyTableOfContentsController(
    scrollController: scroll,
    sections: anchors,
  );

  @override
  void initState() {
    super.initState();
    // Create the tracker before the first layout to honor initial deep links.
    tracker;
  }

  @override
  void dispose() {
    tracker.dispose();
    scroll.dispose();
    super.dispose();
  }

  void select(String id) {
    tracker.scrollToSection(id);
    widget.onSelected?.call(id);
  }

  String href(String id) => Uri.base
      .resolveUri(widget.location ?? Uri())
      .replace(fragment: id)
      .toString();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: [
      const SteyText('目次を選択するか、本文をスクロールしてください。URLからも見出しを開けます。'),
      LayoutBuilder(
        builder: (context, constraints) {
          final toc = ListenableBuilder(
            listenable: tracker,
            builder: (context, _) => SteyTableOfContents(
              label: 'このページの目次',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SteyTableOfContentsTitle('このページの内容'),
                  SteyTableOfContentsList(
                    children: [
                      SteyTableOfContentsItem(
                        label: '概要',
                        href: href('overview'),
                        active: tracker.activeId == 'overview',
                        onPressed: () => select('overview'),
                      ),
                      SteyTableOfContentsGroup(
                        label: '分析',
                        href: href('analytics'),
                        active: tracker.activeId == 'analytics',
                        onPressed: () => select('analytics'),
                        children: [
                          for (final id in ['settings', '50%-off', 'café'])
                            SteyTableOfContentsItem(
                              label: sections[id]!,
                              href: href(id),
                              active: tracker.activeId == id,
                              onPressed: () => select(id),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
          final body = SizedBox(
            height: 280,
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (_) {
                tracker.refresh();
                return false;
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: SteyTheme.colorsOf(context).line),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Scrollbar(
                    controller: scroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: scroll,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final entry in sections.entries) ...[
                            SteyText(
                              entry.value,
                              key: anchors[entry.key],
                              heading: 4,
                            ),
                            const SizedBox(height: 8),
                            SteyText(switch (entry.key) {
                              'overview' => '現在見えている見出しが目次に反映されます。',
                              'analytics' => '子の項目を選んでも、親グループの選択処理は発生しません。',
                              'settings' => 'キーボードのTabとEnterでも目次を操作できます。',
                              '50%-off' => 'URLにエスケープされていない%が含まれても開けます。',
                              _ => 'パーセントエンコードされたUnicodeの見出しにも対応します。',
                            }),
                            const SizedBox(height: 180),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [toc, body],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              SizedBox(width: 190, child: toc),
              Expanded(child: body),
            ],
          );
        },
      ),
    ],
  );
}
