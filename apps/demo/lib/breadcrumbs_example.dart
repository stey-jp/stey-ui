import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class BreadcrumbsExample extends StatefulWidget {
  const BreadcrumbsExample({super.key});
  @override
  State<BreadcrumbsExample> createState() => _BreadcrumbsExampleState();
}

class _BreadcrumbsExampleState extends State<BreadcrumbsExample> {
  SteyBreadcrumbsSize size = SteyBreadcrumbsSize.base;
  bool loading = false, icons = false, long = false, rtl = false, copy = true;
  int navigations = 0, copies = 0;
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
          SteyBreadcrumbsSize.sm: 'コンパクト',
          SteyBreadcrumbsSize.base: '標準',
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
            value: loading,
            label: '読み込み中',
            onChanged: (v) => setState(() => loading = v),
          ),
          SteySwitch(
            value: icons,
            label: 'アイコンを表示',
            onChanged: (v) => setState(() => icons = v),
          ),
          SteySwitch(
            value: long,
            label: '長いページ名',
            onChanged: (v) => setState(() => long = v),
          ),
          SteySwitch(
            value: rtl,
            label: '右から左へ',
            onChanged: (v) => setState(() => rtl = v),
          ),
          SteySwitch(
            value: copy,
            label: 'コピーを表示',
            onChanged: (v) => setState(() => copy = v),
          ),
        ],
      ),
      Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SteyBreadcrumbs(
          size: size,
          children: [
            SteyBreadcrumbsLink(
              href: Uri.parse('#account'),
              onPressed: () => setState(() => navigations++),
              icon: icons ? const Icon(Icons.home_outlined, size: 16) : null,
              child: const Text('アカウント'),
            ),
            const SteyBreadcrumbsSeparator(),
            SteyBreadcrumbsLink(
              href: Uri.parse('#projects'),
              onPressed: () => setState(() => navigations++),
              icon: icons ? const Icon(Icons.folder_outlined, size: 16) : null,
              child: const Text('プロジェクト'),
            ),
            const SteyBreadcrumbsSeparator(),
            SteyBreadcrumbsCurrent(
              loading: loading,
              icon: icons
                  ? const Icon(Icons.description_outlined, size: 16)
                  : null,
              child: Text(long ? 'アクセス権限と公開先を確認するプロジェクト設定ページ' : '設定'),
            ),
            if (copy)
              SteyBreadcrumbsClipboard(
                text: 'https://example.com/projects/settings',
                onCopied: () => setState(() {
                  copies++;
                  error = null;
                }),
                onCopyError: (_) =>
                    setState(() => error = 'コピーできませんでした。再度お試しください。'),
              ),
          ],
        ),
      ),
      Semantics(
        liveRegion: true,
        child: Text(error ?? '移動操作：$navigations回・コピー：$copies回'),
      ),
      const SteyText(
        '画面幅が640px未満では、親ページと現在のページを残して先頭を省略します。長い現在ページ名だけを切り詰めます。',
        subtle: true,
      ),
    ],
  );
}

class BreadcrumbsSample extends StatefulWidget {
  const BreadcrumbsSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<BreadcrumbsSample> createState() => _SampleState();
}

class _SampleState extends State<BreadcrumbsSample> {
  int links = 0, copies = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query,
        count = int.tryParse(q['count'] ?? '') ?? 3,
        withIcon = q['icon'] == 'true';
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Breadcrumbs preview',
      child: SizedBox(
        width: double.tryParse(q['host'] ?? '') ?? 480,
        child: Stack(
          children: [
            SteyBreadcrumbs(
              semanticLabel: 'breadcrumb',
              size: q['crumbSize'] == 'sm'
                  ? SteyBreadcrumbsSize.sm
                  : SteyBreadcrumbsSize.base,
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SteyBreadcrumbsSeparator(),
                  if (i == count - 1)
                    SteyBreadcrumbsCurrent(
                      loading: q['loading'] == 'true',
                      icon: withIcon
                          ? const ColoredBox(
                              color: Color(0xff737373),
                              child: SizedBox.square(dimension: 16),
                            )
                          : null,
                      child: Text(
                        q['long'] == 'true'
                            ? 'Current resource with a very long display name'
                            : 'Current resource',
                      ),
                    )
                  else
                    SteyBreadcrumbsLink(
                      href: Uri.parse('#level-$i'),
                      onPressed: () => setState(() => links++),
                      icon: withIcon
                          ? const ColoredBox(
                              color: Color(0xff737373),
                              child: SizedBox.square(dimension: 16),
                            )
                          : null,
                      child: Text(
                        i == 0
                            ? 'Account'
                            : i == 1
                            ? 'Projects'
                            : 'Section $i',
                      ),
                    ),
                ],
                if (q['copy'] != 'false')
                  SteyBreadcrumbsClipboard(
                    text: q['empty'] == 'true'
                        ? ''
                        : 'https://example.com/projects/settings',
                    copyActionLabel: 'Copy',
                    tooltip: 'Click to copy',
                    onCopied: () => setState(() => copies++),
                  ),
                if (q['extra'] == 'true') const Text('Extra'),
              ],
            ),
            Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: Semantics(
                    label: 'Link calls: $links; Copy calls: $copies',
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
