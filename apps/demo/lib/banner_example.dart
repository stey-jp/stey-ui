import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class BannerExample extends StatefulWidget {
  const BannerExample({super.key});
  @override
  State<BannerExample> createState() => _BannerExampleState();
}

class _BannerExampleState extends State<BannerExample> {
  SteyBannerVariant variant = SteyBannerVariant.defaultValue;
  SteyBannerSize size = SteyBannerSize.base;
  SteyBannerActionVariant actionVariant = SteyBannerActionVariant.primary;
  bool link = false,
      long = false,
      loading = false,
      disabled = false,
      visible = true;
  int calls = 0;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      SteySelect(
        label: '通知の種類',
        value: variant,
        options: const {
          SteyBannerVariant.defaultValue: '情報',
          SteyBannerVariant.alert: '警告',
          SteyBannerVariant.error: 'エラー',
          SteyBannerVariant.secondary: '補足',
        },
        onChanged: (v) {
          if (v != null) setState(() => variant = v);
        },
      ),
      SteySelect(
        label: '表示サイズ',
        value: size,
        options: const {SteyBannerSize.base: '標準', SteyBannerSize.sm: 'コンパクト'},
        onChanged: (v) {
          if (v != null) setState(() => size = v);
        },
      ),
      SteySelect(
        label: '操作ボタンの種類',
        value: actionVariant,
        options: const {
          SteyBannerActionVariant.primary: '塗り',
          SteyBannerActionVariant.secondary: '枠線',
          SteyBannerActionVariant.ghost: '文字のみ',
        },
        onChanged: (v) {
          if (v != null) setState(() => actionVariant = v);
        },
      ),
      Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          SteySwitch(
            value: link,
            label: 'リンクを表示',
            onChanged: (v) => setState(() => link = v),
          ),
          SteySwitch(
            value: long,
            label: '長い説明',
            onChanged: (v) => setState(() => long = v),
          ),
          SteySwitch(
            value: loading,
            label: '処理中',
            onChanged: (v) => setState(() => loading = v),
          ),
          SteySwitch(
            value: disabled,
            label: '操作を無効化',
            onChanged: (v) => setState(() => disabled = v),
          ),
        ],
      ),
      if (visible)
        SteyBanner(
          variant: variant,
          size: size,
          title: '更新があります',
          description: Text(
            long
                ? '保存前にアクセス権限、公開先、プロジェクトの設定を確認してください。変更は確認後に反映されます。'
                : '保存前に設定を確認してください。',
          ),
          icon: const Icon(Icons.info_outline, size: 16),
          action: link
              ? SteyLink(
                  href: Uri.parse('#details'),
                  onPressed: disabled || loading
                      ? null
                      : () => setState(() => calls++),
                  child: const Text('詳細を確認'),
                )
              : SteyBannerAction(
                  variant: actionVariant,
                  loading: loading,
                  semanticLabel: '詳細を確認',
                  onPressed: disabled ? null : () => setState(() => calls++),
                  child: const Text('詳細を確認'),
                ),
          onDismiss: () => setState(() => visible = false),
        )
      else
        SteyButton(
          onPressed: () => setState(() => visible = true),
          child: const Text('通知を再表示'),
        ),
      Semantics(liveRegion: true, child: Text('操作回数：$calls')),
      const SteyText(
        'コンパクト表示ではタイトルと説明が横に並び、リンクは説明の末尾に表示されます。ボタンは通知の色とサイズを引き継ぎます。',
        subtle: true,
      ),
    ],
  );
}

class BannerSample extends StatefulWidget {
  const BannerSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<BannerSample> createState() => _BannerSampleState();
}

class _BannerSampleState extends State<BannerSample> {
  int calls = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final disabled = q['state'] == 'disabled';
    void act() => setState(() => calls++);
    SteyBannerAction button(
      String label, {
      SteyBannerActionVariant? variant,
      bool icon = false,
    }) => SteyBannerAction(
      onPressed: disabled ? null : act,
      loading: q['state'] == 'loading',
      variant:
          variant ??
          SteyBannerActionVariant.values.firstWhere(
            (v) => v.name == q['actionVariant'],
            orElse: () => SteyBannerActionVariant.primary,
          ),
      semanticLabel: label,
      icon: icon ? const Icon(Icons.close, size: 12) : null,
      child: icon ? const SizedBox.shrink() : Text(label),
    );
    final action = switch (q['action']) {
      'none' => null,
      'link' => SteyLink(
        href: Uri.parse('#details'),
        onPressed: disabled ? null : act,
        child: const Text('Details'),
      ),
      'icon' => button(
        'Dismiss',
        variant: SteyBannerActionVariant.ghost,
        icon: true,
      ),
      'multiple' => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          button('Details'),
          button('Later', variant: SteyBannerActionVariant.ghost),
        ],
      ),
      _ => button('Details'),
    };
    return Stack(
      children: [
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: 'Banner preview',
          child: SizedBox(
            width: double.tryParse(q['host'] ?? '') ?? 480,
            child: SteyBanner(
              variant: SteyBannerVariant.values.firstWhere(
                (v) => v.name == q['bannerVariant'],
                orElse: () => SteyBannerVariant.defaultValue,
              ),
              size: q['bannerSize'] == 'sm'
                  ? SteyBannerSize.sm
                  : SteyBannerSize.base,
              title: q['title'] == 'none' || q['legacy'] == 'true'
                  ? null
                  : 'Update available',
              description: q['description'] == 'none' || q['legacy'] == 'true'
                  ? null
                  : Text(
                      q['long'] == 'true'
                          ? 'Review access permissions and project settings before saving changes to your account.'
                          : 'Review your settings before saving.',
                    ),
              text: 'Legacy notice',
              action: action,
              icon: q['icon'] == 'true'
                  ? Builder(
                      builder: (context) => SizedBox(
                        width: 16,
                        height: 16,
                        child: ColoredBox(color: IconTheme.of(context).color!),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        Positioned(
          width: 1,
          height: 1,
          child: Semantics(
            label: 'Action calls: $calls',
            child: const SizedBox(),
          ),
        ),
      ],
    );
  }
}
