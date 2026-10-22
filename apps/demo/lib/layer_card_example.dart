// Surface is intentionally shown as the upstream deprecated compatibility API.
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class LayerCardExample extends StatefulWidget {
  const LayerCardExample({super.key, this.surface = false});
  final bool surface;
  @override
  State<LayerCardExample> createState() => _LayerCardExampleState();
}

class _LayerCardExampleState extends State<LayerCardExample> {
  String mode = 'layered';
  bool footer = true, long = false, rtl = false, rounded = false;
  int count = 0, after = 0;
  SteySurfaceColor color = SteySurfaceColor.primary;
  @override
  void initState() {
    super.initState();
    if (widget.surface) mode = 'simple';
  }

  @override
  Widget build(BuildContext context) {
    final title = long ? '新しいサービスをチーム全員で安全に公開するための次の手順' : '次の手順';
    final body = long
        ? '表示する内容が長い場合も、カードの幅に合わせて折り返します。設定を確認し、変更を保存してから公開してください。'
        : '設定を確認して、サービスを公開できます。';
    final header = Text(title), description = Text(body);
    final action = SteyButton(
      onPressed: () => setState(() => count++),
      child: const Text('カード内の操作'),
    );
    final radius = rounded ? BorderRadius.circular(16) : null;
    final parts = <Widget>[
      SteyLayerCardSecondary(child: header),
      SteyLayerCardPrimary(children: [description, action]),
      if (footer) const SteyLayerCardSecondary(child: Text('最終更新：たった今')),
    ];
    Widget card;
    if (mode == 'legacy') {
      card = widget.surface
          ? SteySurface(
              header: header,
              footer: footer ? const Text('最終更新：たった今') : null,
              borderRadius: radius ?? BorderRadius.zero,
              color: color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [description, action],
              ),
            )
          : SteyLayerCard(
              header: header,
              footer: footer ? const Text('最終更新：たった今') : null,
              borderRadius: radius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [description, action],
              ),
            );
    } else if (mode == 'layered') {
      card = widget.surface
          ? SteySurface.layers(
              borderRadius: radius ?? BorderRadius.zero,
              color: color,
              children: parts,
            )
          : SteyLayerCard.layers(borderRadius: radius, children: parts);
    } else {
      final child = mode == 'overflow'
          ? const _OverflowExample()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [header, description, action],
            );
      card = widget.surface
          ? SteySurface(
              padding: mode == 'overflow'
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(16),
              borderRadius: radius ?? BorderRadius.zero,
              color: color,
              child: child,
            )
          : SteyLayerCard(
              padding: mode == 'overflow'
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(16),
              borderRadius: radius,
              child: child,
            );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        SteySelect<String>(
          label: 'カードの構成',
          value: mode,
          options: const {
            'simple': '単層',
            'layered': 'Primary／Secondary',
            'legacy': '既存のheader／footer',
            'overflow': 'はみ出す内容',
          },
          onChanged: (v) {
            if (v != null) setState(() => mode = v);
          },
        ),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SteySwitch(
              label: 'フッターを表示',
              value: footer,
              onChanged: (v) => setState(() => footer = v),
            ),
            SteySwitch(
              label: '長い内容',
              value: long,
              onChanged: (v) => setState(() => long = v),
            ),
            SteySwitch(
              label: '右から左へ',
              value: rtl,
              onChanged: (v) => setState(() => rtl = v),
            ),
            SteySwitch(
              label: '角丸を指定',
              value: rounded,
              onChanged: (v) => setState(() => rounded = v),
            ),
          ],
        ),
        if (widget.surface)
          SteySelect<SteySurfaceColor>(
            label: '互換用のcolor',
            value: color,
            options: const {
              SteySurfaceColor.primary: 'primary',
              SteySurfaceColor.secondary: 'secondary',
            },
            onChanged: (v) {
              if (v != null) setState(() => color = v);
            },
          ),
        Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: card,
        ),
        Text('カード内の操作：$count回'),
        SteyButton(
          onPressed: () => setState(() => after++),
          child: const Text('カードの次の操作'),
        ),
        Text('次の操作：$after回'),
        const SteyText(
          '単層はbase背景、多層はelevated背景とPrimaryの領域を使います。Surfaceは公式でも非推奨の互換APIで、colorの2値は同じ描画です。',
          subtle: true,
        ),
      ],
    );
  }
}

class _OverflowExample extends StatelessWidget {
  const _OverflowExample();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: LayoutBuilder(
      builder: (context, c) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: c.maxWidth - 20,
            top: 4,
            width: 40,
            height: 40,
            child: const ColoredBox(color: Color(0xff056dff)),
          ),
        ],
      ),
    ),
  );
}

class LayerCardSample extends StatelessWidget {
  const LayerCardSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  Widget build(BuildContext context) {
    final q = query,
        surface = q['kind'] == 'surface',
        mode = q['layout'] ?? 'layered';
    final title = q['long'] == 'true'
        ? 'Next steps for a safe release across the entire team'
        : 'Next steps';
    final text = q['long'] == 'true'
        ? 'Review the configuration and save the changes before publishing this service to every user.'
        : 'Get started with Kumo';
    final p = q['padding'] == null
        ? null
        : EdgeInsets.all(double.parse(q['padding']!));
    final r = q['radius'] == null
        ? null
        : BorderRadius.circular(double.parse(q['radius']!));
    final primary = SteyLayerCardPrimary(
      semanticLabel: 'Primary section',
      children: [
        Text(text),
        if (q['multiple'] == 'true') const Text('Review the configuration'),
      ],
    );
    final parts = <Widget>[
      if (q['header'] != 'false')
        SteyLayerCardSecondary(
          semanticLabel: 'Header section',
          child: Text(title),
        ),
      primary,
      if (q['footer'] == 'true')
        const SteyLayerCardSecondary(
          semanticLabel: 'Footer section',
          child: Text('Updated just now'),
        ),
    ];
    final child = mode == 'overflow' ? const _OverflowExample() : Text(text);
    Widget card;
    if (mode == 'layered') {
      card = surface
          ? SteySurface.layers(
              padding: p,
              borderRadius: r ?? BorderRadius.zero,
              children: parts,
            )
          : SteyLayerCard.layers(padding: p, borderRadius: r, children: parts);
    } else if (mode == 'primary') {
      card = surface
          ? SteySurface(child: primary)
          : SteyLayerCard(child: primary);
    } else if (mode == 'legacy') {
      card = surface
          ? SteySurface(
              padding: p,
              header: Text(title),
              footer: q['footer'] == 'true'
                  ? const Text('Updated just now')
                  : null,
              child: child,
            )
          : SteyLayerCard(
              padding: p,
              header: Text(title),
              footer: q['footer'] == 'true'
                  ? const Text('Updated just now')
                  : null,
              child: child,
            );
    } else {
      card = surface
          ? SteySurface(
              padding: p,
              borderRadius: r ?? BorderRadius.zero,
              color: q['color'] == 'secondary'
                  ? SteySurfaceColor.secondary
                  : SteySurfaceColor.primary,
              child: child,
            )
          : SteyLayerCard(padding: p, borderRadius: r, child: child);
    }
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: double.tryParse(q['font'] ?? '') ?? 14,
        height: 1.5,
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Card preview',
        child: SizedBox(
          width: double.tryParse(q['host'] ?? '') ?? 320,
          child: card,
        ),
      ),
    );
  }
}
