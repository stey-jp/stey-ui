import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:stey_ui_modern/stey_ui_modern.dart';

import 'demo_labels.dart';

class BadgeExample extends StatefulWidget {
  const BadgeExample({super.key});
  @override
  State<BadgeExample> createState() => _BadgeExampleState();
}

class _BadgeExampleState extends State<BadgeExample> {
  SteyBadgeVariant variant = SteyBadgeVariant.success;
  bool dot = false, icon = false, link = false, rtl = false, long = false;
  int calls = 0;
  @override
  Widget build(BuildContext context) {
    final badge = SteyBadge(
      variant: variant,
      appearance: dot ? SteyBadgeAppearance.dot : SteyBadgeAppearance.filled,
      icon: icon && !dot ? const Icon(Icons.check, size: 24) : null,
      child: Text(long ? '利用可能なプロジェクトを確認' : '利用可能'),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        SteySelect(
          value: variant,
          label: '色と種類',
          options: {
            for (final v in SteyBadgeVariant.values) v: variantLabel(v.name),
          },
          onChanged: (v) {
            if (v != null) setState(() => variant = v);
          },
        ),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            SteySwitch(
              value: dot,
              label: 'ドット表示',
              onChanged: (v) => setState(() => dot = v),
            ),
            SteySwitch(
              value: icon,
              label: 'アイコンを表示',
              onChanged: (v) => setState(() => icon = v),
            ),
            SteySwitch(
              value: link,
              label: 'リンク内に配置',
              onChanged: (v) => setState(() => link = v),
            ),
            SteySwitch(
              value: rtl,
              label: '右から左へ',
              onChanged: (v) => setState(() => rtl = v),
            ),
            SteySwitch(
              value: long,
              label: '長いラベル',
              onChanged: (v) => setState(() => long = v),
            ),
          ],
        ),
        Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: link
                ? SteyLink(
                    onPressed: () => setState(() => calls++),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [const Text('詳細を見る'), badge],
                    ),
                  )
                : badge,
          ),
        ),
        Semantics(liveRegion: true, child: Text('リンク操作：$calls回')),
        const SteyText(
          'ドットが付く種類は成功・警告・エラー・中立です。リンクに重ねると文字色の枠が表示されます。',
          subtle: true,
        ),
        const SteyText('全種類', heading: 4),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final v in SteyBadgeVariant.values)
              SteyBadge(
                variant: v,
                child: Text(variantLabels[v.name] ?? v.name),
              ),
          ],
        ),
      ],
    );
  }
}

class BadgeSample extends StatefulWidget {
  const BadgeSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<BadgeSample> createState() => _BadgeSampleState();
}

class _BadgeSampleState extends State<BadgeSample> {
  int calls = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final variant = SteyBadgeVariant.values.firstWhere(
      (v) =>
          v.name == q['variant'] ||
          v.name == 'tealSubtle' && q['variant'] == 'teal-subtle',
      orElse: () => SteyBadgeVariant.primary,
    );
    final dot = q['appearance'] == 'dot';
    final badge = Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Badge target',
      child: SteyBadge(
        variant: variant,
        appearance: dot ? SteyBadgeAppearance.dot : SteyBadgeAppearance.filled,
        icon: q['icon'] == 'true' && !dot
            ? const ColoredBox(
                color: Color(0xff737373),
                child: SizedBox(width: 24, height: 24),
              )
            : null,
        child: Text(
          q['empty'] == 'true'
              ? ''
              : q['long'] == 'true'
              ? 'Available project with a longer display name'
              : 'Active',
        ),
      ),
    );
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(double.tryParse(q['scale'] ?? '') ?? 1),
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Badge preview',
        child: SizedBox(
          width: double.tryParse(q['host'] ?? '') ?? 320,
          height: 80,
          child: Stack(
            children: [
              Center(
                child: OverflowBox(
                  minWidth: 0,
                  maxWidth: double.infinity,
                  fit: OverflowBoxFit.deferToChild,
                  child: q['link'] == 'true'
                      ? SteyBadgeLinkScope(
                          child: Semantics(
                            container: true,
                            explicitChildNodes: true,
                            link: true,
                            linkUrl: Uri.base.resolve('#badge'),
                            onTap: () => setState(() => calls++),
                            child: GestureDetector(
                              excludeFromSemantics: true,
                              onTap: () => setState(() => calls++),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 8,
                                  children: [const Text('Project'), badge],
                                ),
                              ),
                            ),
                          ),
                        )
                      : badge,
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
                      label: 'Link calls: $calls',
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
