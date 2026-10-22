import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class LinkExample extends StatefulWidget {
  const LinkExample({super.key});
  @override
  State<LinkExample> createState() => _LinkExampleState();
}

class _LinkExampleState extends State<LinkExample> {
  SteyLinkVariant variant = SteyLinkVariant.inline;
  bool external = false, disabled = false, rtl = false, narrow = false;
  double scale = 1;
  int navigations = 0, after = 0;
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
            semanticLabel: '種類：${variant.name}、リンクの種類を変更',
            onPressed: () => setState(
              () => variant = SteyLinkVariant.values[(variant.index + 1) % 3],
            ),
            child: Text('種類：${variant.name}'),
          ),
          SteyButton(
            semanticLabel: '拡大率：${(scale * 100).round()}%、文字の拡大率を変更',
            onPressed: () => setState(() => scale = scale == 1 ? 2 : 1),
            child: Text('拡大率：${(scale * 100).round()}%'),
          ),
          for (final row in <(String, bool, ValueChanged<bool>)>[
            ('外部アイコンを表示', external, (v) => setState(() => external = v)),
            ('リンクを無効にする', disabled, (v) => setState(() => disabled = v)),
            ('幅を狭くする', narrow, (v) => setState(() => narrow = v)),
            ('右から左へ', rtl, (v) => setState(() => rtl = v)),
          ])
            SteySwitch(label: row.$1, value: row.$2, onChanged: row.$3),
        ],
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: narrow ? 160 : 520,
          child: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: scale,
              maxScaleFactor: scale,
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: SteyTheme.colorsOf(context).dark
                      ? const Color(0xffffb18f)
                      : const Color(0xff9f2d00),
                ),
                child: SteyLinkProvider(
                  onNavigate: (href, target) => setState(() => navigations++),
                  child: SteyLink(
                    href: Uri.parse('#link-preview'),
                    variant: variant,
                    external: external,
                    disabled: disabled,
                    child: const Text('リンクの表示と操作を確認する'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Text('リンクの操作：$navigations回'),
      const SteyText(
        'Tabで移動し、Enterで操作します。currentは親の文字色を継承します。外部アイコンの表示と遷移先は個別に指定します。',
      ),
      SteyLink(
        href: Uri.parse('#badge-link'),
        onPressed: () => setState(() => after++),
        variant: SteyLinkVariant.plain,
        child: const SteyBadge(child: Text('Badge付きリンク')),
      ),
      SteyButton(
        onPressed: () => setState(() => after++),
        child: const Text('リンクの次の操作'),
      ),
      Text('次の操作：$after回'),
    ],
  );
}

class LinkSample extends StatefulWidget {
  const LinkSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<LinkSample> createState() => _LinkSampleState();
}

class _LinkSampleState extends State<LinkSample> {
  int calls = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Link preview',
      child: Directionality(
        textDirection: q['direction'] == 'rtl'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: SizedBox(
          width: double.tryParse(q['host'] ?? '') ?? 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: double.tryParse(q['font'] ?? '') ?? 14,
                  height: 1.5,
                  color: q['parent'] == 'true'
                      ? SteyTheme.colorsOf(context).dark
                            ? const Color(0xffffb18f)
                            : const Color(0xff9f2d00)
                      : SteyTheme.colorsOf(context).text,
                ),
                child: MediaQuery.withClampedTextScaling(
                  minScaleFactor: double.tryParse(q['scale'] ?? '') ?? 1,
                  maxScaleFactor: double.tryParse(q['scale'] ?? '') ?? 1,
                  child: SteyLinkProvider(
                    onNavigate: (_, _) => setState(() => calls++),
                    child: SteyLink(
                      href: Uri.parse('#destination'),
                      disabled: q['disabled'] == 'true',
                      variant: SteyLinkVariant.values.firstWhere(
                        (v) => v.name == q['variant'],
                        orElse: () => SteyLinkVariant.inline,
                      ),
                      external: q['external'] == 'true',
                      child: q['badge'] == 'true'
                          ? const SteyBadge(child: Text('Docs'))
                          : Text(q['content'] ?? 'Read documentation'),
                    ),
                  ),
                ),
              ),
              Text('Activations: $calls'),
              SteyButton(
                onPressed: () => setState(() => calls++),
                child: const Text('Next action'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
