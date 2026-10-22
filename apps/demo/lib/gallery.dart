import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalog.g.dart';
import 'code_example.dart';
import 'clipboard_example.dart';
import 'banner_example.dart';
import 'collapsible_example.dart';
import 'empty_example.dart';
import 'breadcrumbs_example.dart';
import 'badge_example.dart';
import 'loader_example.dart';
import 'pagination_example.dart';
import 'meter_example.dart';
import 'slider_example.dart';
import 'layer_card_example.dart';
import 'tabs_example.dart';
import 'input_example.dart';
import 'input_group_example.dart';
import 'sensitive_input_example.dart';
import 'tag_input_example.dart';
import 'text_example.dart';
import 'link_example.dart';
import 'label_example.dart';
import 'inline_copy_example.dart';
import 'demo_labels.dart';
import 'dropdown_example.dart';
import 'dropdown_tracking_sample.dart';
import 'gallery_route_uri.dart';
import 'table_of_contents_example.dart';
import 'layer_dialog_example.dart';
import 'group_flow_examples.dart';
import 'flow_composition_example.dart';

const pendingComponents = {'cloudflare-logo'};

class SteyGallery extends StatefulWidget {
  const SteyGallery({super.key});
  @override
  State<SteyGallery> createState() => _SteyGalleryState();
}

class _SteyGalleryState extends State<SteyGallery> {
  late bool dark = Uri.base.queryParameters['mode'] == 'dark';
  late String selected =
      componentIds.contains(Uri.base.queryParameters['component'])
      ? Uri.base.queryParameters['component']!
      : 'button';
  String filter = '';
  late final _GalleryRouter router;
  @override
  void initState() {
    super.initState();
    router = _GalleryRouter(
      Uri(
        path: '/',
        queryParameters: Uri.base.queryParameters,
        fragment: Uri.base.hasFragment ? Uri.base.fragment : null,
      ),
      (uri) => setState(() {
        selected = componentIds.contains(uri.queryParameters['component'])
            ? uri.queryParameters['component']!
            : 'button';
        dark = uri.queryParameters['mode'] == 'dark';
      }),
      content,
    );
  }

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  void select(String value) => router.navigate(
    router.uri.replace(
      fragment: '',
      queryParameters: {
        ...router.uri.queryParameters,
        'component': value,
        'mode': dark ? 'dark' : 'light',
      },
    ),
  );

  void toggleMode() => router.navigate(
    router.uri.replace(
      queryParameters: {
        ...router.uri.queryParameters,
        'mode': dark ? 'light' : 'dark',
      },
    ),
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Stey UI — Flutterコンポーネント一覧',
    locale: const Locale('ja'),
    supportedLocales: const [Locale('ja')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    debugShowCheckedModeBanner: false,
    theme: SteyTheme.material(dark ? Brightness.dark : Brightness.light),
    routerDelegate: router,
    routeInformationParser: const _GalleryRouteParser(),
  );

  Widget content(BuildContext context) {
    final brightness = dark ? Brightness.dark : Brightness.light;
    return SteyTheme(
      brightness: brightness,
      child: Builder(
        builder: (context) {
          final c = SteyTheme.colorsOf(context);
          final sample = router.uri.queryParameters['sample'];
          if (sample != null) {
            final variant =
                router.uri.queryParameters['variant'] ?? 'secondary';
            final sampleState = router.uri.queryParameters['state'] ?? 'idle';
            final sampleSize = SteySize.values.firstWhere(
              (value) => value.name == router.uri.queryParameters['size'],
              orElse: () => SteySize.base,
            );
            final sampleShape = SteyButtonShape.values.firstWhere(
              (value) => value.name == router.uri.queryParameters['shape'],
              orElse: () => SteyButtonShape.base,
            );
            final child = switch (sample) {
              'text' => TextSample(router.uri.queryParameters),
              'link' => LinkSample(router.uri.queryParameters),
              'label' => LabelSample(router.uri.queryParameters),
              'tag-input' => TagInputSample(router.uri.queryParameters),
              'banner' => BannerSample(router.uri.queryParameters),
              'collapsible' => CollapsibleSample(router.uri.queryParameters),
              'empty' => EmptySample(router.uri.queryParameters),
              'breadcrumbs' => BreadcrumbsSample(router.uri.queryParameters),
              'clipboard-text' => Transform.translate(
                offset: Offset(
                  0,
                  double.tryParse(
                        router.uri.queryParameters['offsetY'] ?? '',
                      ) ??
                      0,
                ),
                child: clipboardSample(router.uri.queryParameters),
              ),
              'inline-copy-text' => inlineCopySample(
                router.uri.queryParameters,
              ),
              'code-highlighted' => codeSample(router.uri.queryParameters),
              'button-group' => buttonGroupSample(router.uri.queryParameters),
              'flow-anchor' => flowAnchorSample(router.uri.queryParameters),
              'flow-composed' => flowCompositionSample(
                router.uri.queryParameters,
              ),
              'flow-canvas' => flowCanvasSample(router.uri.queryParameters),
              'flow-wrap' => flowWrapSample(router.uri.queryParameters),
              'flow-auto' => FlowAutoExample(
                parameters: router.uri.queryParameters,
              ),
              'layer-dialog' => LayerDialogSample(
                parameters: router.uri.queryParameters,
              ),
              'sidebar-menu-sub' => SizedBox(
                width: 240,
                child: SteySidebarMenuSub(
                  semanticLabel: 'Projects',
                  children: [
                    SteySidebarMenuSubButton(
                      onPressed: () {},
                      selected: sampleState == 'active',
                      child: const Text('Workers'),
                    ),
                    SteySidebarMenuSubButton(
                      onPressed: () {},
                      child: const Text('Pages'),
                    ),
                  ],
                ),
              ),
              'dropdown' => Transform.translate(
                offset: Offset(
                  0,
                  double.tryParse(
                        router.uri.queryParameters['anchorY'] ?? '',
                      ) ??
                      0,
                ),
                child: DropdownExample(
                  fixture: true,
                  extraItems:
                      (int.tryParse(
                                router.uri.queryParameters['extraItems'] ?? '',
                              ) ??
                              0)
                          .clamp(0, 30),
                ),
              ),
              'dropdown-tracking' => const DropdownTrackingSample(),
              'select' => SizedBox(
                width: 280,
                child: SteySelect<String>(
                  value: 'a',
                  options: const {'a': 'Alpha', 'b': 'Beta', 'c': 'Gamma'},
                  onChanged: (_) {},
                  semanticLabel: 'Choice',
                  size: sampleSize,
                  disabled: sampleState == 'disabled',
                  loading: sampleState == 'loading',
                  readOnly: sampleState == 'readonly',
                  error: sampleState == 'error' ? 'Please select' : null,
                ),
              ),
              'radio' => SteyRadioGroup<String>(
                value: router.uri.queryParameters['checked'] == 'true'
                    ? 'toggle'
                    : '',
                onChanged: (_) {},
                disabled: sampleState == 'disabled',
                children: [
                  SteyRadioItem(
                    value: 'toggle',
                    label: 'Toggle',
                    variant: variant == 'error'
                        ? SteyRadioVariant.error
                        : SteyRadioVariant.standard,
                  ),
                ],
              ),
              'checkbox' => SteyCheckbox(
                value: router.uri.queryParameters['checked'] == 'true',
                indeterminate: router.uri.queryParameters['checked'] == 'mixed',
                enabled: sampleState != 'disabled',
                onChanged: (_) {},
                semanticLabel: 'Toggle',
                variant: variant == 'error'
                    ? SteyCheckboxVariant.error
                    : SteyCheckboxVariant.standard,
              ),
              'switch' => SteySwitch(
                value: router.uri.queryParameters['checked'] == 'true',
                enabled: sampleState != 'disabled',
                onChanged: (_) {},
                semanticLabel: 'Toggle',
                variant: variant == 'neutral'
                    ? SteySwitchVariant.neutral
                    : SteySwitchVariant.standard,
                size: SteySwitchSize.values.firstWhere(
                  (value) => value.name == router.uri.queryParameters['size'],
                  orElse: () => SteySwitchSize.base,
                ),
              ),
              'pagination' => PaginationSample(router.uri.queryParameters),
              'meter' => MeterSample(router.uri.queryParameters),
              'slider' => SliderSample(router.uri.queryParameters),
              'tabs' => TabsSample(router.uri.queryParameters),
              'layer-card' => LayerCardSample(router.uri.queryParameters),
              'surface' => LayerCardSample({
                ...router.uri.queryParameters,
                'kind': 'surface',
              }),
              'loader' => LoaderSample(router.uri.queryParameters),
              'badge' => BadgeSample(router.uri.queryParameters),
              'input' => InputSample(router.uri.queryParameters),
              'input-group' => InputGroupSample(router.uri.queryParameters),
              'sensitive-input' => SensitiveInputSample(
                router.uri.queryParameters,
              ),
              'table-of-contents' => SizedBox(
                width: 280,
                child: SteyTableOfContents(
                  activeId: sampleState == 'active' ? 'intro' : null,
                  onSelected: (_) {},
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SteyTableOfContentsTitle('On this page'),
                      SteyTableOfContentsList(
                        children: [
                          SteyTableOfContentsItem(
                            label: 'Introduction',
                            href: '#intro',
                            active: sampleState == 'active',
                            onPressed: () {},
                          ),
                          SteyTableOfContentsGroup(
                            label: 'API',
                            href: '#api',
                            onPressed: () {},
                            children: [
                              SteyTableOfContentsItem(
                                label: 'Methods',
                                href: '#methods',
                                onPressed: () {},
                              ),
                            ],
                          ),
                          SteyTableOfContentsGroup(
                            label: 'More',
                            children: [
                              SteyTableOfContentsItem(
                                label: 'A very long heading that must truncate at the available width',
                                href: '#long',
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _ => SteyButton(
                onPressed: sampleState == 'disabled' ? null : () {},
                loading: sampleState == 'loading',
                semanticLabel: 'Save',
                size: sampleSize,
                shape: sampleShape,
                icon: router.uri.queryParameters['icon'] == 'leading'
                    ? const Icon(Icons.add, size: 16)
                    : router.uri.queryParameters['icon'] == 'default'
                    ? const Icon(Icons.add)
                    : null,
                variant: SteyButtonVariant.values.firstWhere(
                  (v) => v.name == variant,
                  orElse: () => SteyButtonVariant.secondary,
                ),
                child:
                    router.uri.queryParameters['content'] == 'empty' ||
                        sampleShape != SteyButtonShape.base &&
                            [
                              'leading',
                              'default',
                            ].contains(router.uri.queryParameters['icon'])
                    ? const SizedBox.shrink()
                    : Text(sampleShape == SteyButtonShape.base ? 'Save' : '+'),
              ),
            };
            return Scaffold(
              backgroundColor: c.base,
              body: Center(
                child: Directionality(
                  textDirection:
                      router.uri.queryParameters['direction'] == 'rtl'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: child,
                ),
              ),
            );
          }
          if (router.uri.queryParameters['fixture'] == '1') {
            return Scaffold(
              backgroundColor: c.base,
              body: Center(
                child: SizedBox(
                  width: 600,
                  child: ComponentExample(
                    id: selected,
                    sectionLocation: router.uri,
                    onSectionSelected: (id) =>
                        router.navigate(router.uri.replace(fragment: id)),
                  ),
                ),
              ),
            );
          }
          return Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final ids = componentIds
                      .where(
                        (id) =>
                            id.contains(filter.trim().toLowerCase()) ||
                            componentTitle(id)
                                .toLowerCase()
                                .contains(filter.trim().toLowerCase()),
                      )
                      .toList();
                  return Column(
                    children: [
                      Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: c.base,
                          border: Border(bottom: BorderSide(color: c.line)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.contrast,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                's',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: c.inverse,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const SteyText('Stey UI', heading: 4),
                            if (wide) ...[
                              const SizedBox(width: 12),
                              const SteyBadge(child: Text('Flutter')),
                            ],
                            const Spacer(),
                            SteyButton(
                              onPressed: toggleMode,
                              semanticLabel: dark
                                  ? 'ライトモードに切り替え'
                                  : 'ダークモードに切り替え',
                              shape: SteyButtonShape.square,
                              variant: SteyButtonVariant.ghost,
                              child: Icon(
                                dark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SteyButton(
                              onPressed: () => launchUrl(
                                Uri.parse('https://github.com/stey-jp/stey-ui'),
                              ),
                              child: const Text('GitHub'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            if (wide)
                              SizedBox(
                                width: 240,
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: SteyInput(
                                        placeholder: 'コンポーネントを検索',
                                        prefix: const Icon(
                                          Icons.search,
                                          size: 16,
                                        ),
                                        onChanged: (v) =>
                                            setState(() => filter = v),
                                      ),
                                    ),
                                    Expanded(
                                      child: SteySidebar(
                                        items: ids
                                            .map(
                                              (id) => SteySidebarItem(
                                                id,
                                                componentLabels[id] ?? id,
                                              ),
                                            )
                                            .toList(),
                                        selected: selected,
                                        onSelected: select,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(wide ? 40 : 20),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1000,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (!wide) ...[
                                          SteySelect(
                                            value: selected,
                                            options: {
                                              for (final id in componentIds)
                                                id: componentLabels[id] ?? id,
                                            },
                                            onChanged: (v) {
                                              if (v != null) select(v);
                                            },
                                            label: 'コンポーネント',
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                        SteyBreadcrumbs(
                                          items: [
                                            SteyBreadcrumb(
                                              'コンポーネント一覧',
                                              onPressed: () => select('button'),
                                            ),
                                            SteyBreadcrumb(title(selected)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        SteyText(title(selected), heading: 1),
                                        const SizedBox(height: 6),
                                        const SteyText(
                                          'Cloudflare Kumoを参考にしたFlutterネイティブのUIコンポーネントです。',
                                          subtle: true,
                                        ),
                                        const SizedBox(height: 20),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            SteyLink(
                                              external: true,
                                              onPressed: () => launchUrl(
                                                Uri.parse(
                                                  'https://kumo-ui.com/components/${selected == 'dropdown' ? 'dropdown-menu' : selected}/',
                                                ),
                                              ),
                                              child: const Text('Kumo公式と比較'),
                                            ),
                                            SteyLink(
                                              external: true,
                                              onPressed: () => launchUrl(
                                                Uri.parse(
                                                  'https://github.com/cloudflare/kumo/tree/f46e8bc9922c37dc1d3e7da779e589fe171df306/packages/kumo/src/${{'page-header', 'resource-list', 'delete-resource'}.contains(selected) ? 'blocks' : 'components'}/$selected',
                                                ),
                                              ),
                                              child: const Text('参照ソース'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        Builder(
                                          builder: (context) {
                                            const heading = Row(
                                              children: [
                                                Expanded(
                                                  child: SteyText(
                                                    '操作プレビュー',
                                                    bold: true,
                                                  ),
                                                ),
                                                SteyBadge(child: Text('プレビュー')),
                                              ],
                                            );
                                            final example = ComponentExample(
                                              key: ValueKey(selected),
                                              id: selected,
                                              sectionLocation: router.uri,
                                              onSectionSelected: (id) =>
                                                  router.navigate(
                                                    router.uri.replace(
                                                      fragment: id,
                                                    ),
                                                  ),
                                            );
                                            if (selected == 'layer-card' ||
                                                selected == 'surface') {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  heading,
                                                  const SizedBox(height: 16),
                                                  example,
                                                ],
                                              );
                                            }
                                            return SteyLayerCard(
                                              header: heading,
                                              child: example,
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        const SteyBanner(
                                          tone: SteyTone.warning,
                                          child: Text(
                                            '開発プレビューです。Kumoとのデザイン・機能・挙動の完全な一致はまだ検証できていません。',
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const SteyText(
                                          'MITライセンスの独立したプロジェクトです。CloudflareとKumoは各権利者の商標です。提携・推奨関係はありません。',
                                          subtle: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryRouteParser extends RouteInformationParser<Uri> {
  const _GalleryRouteParser();
  @override
  Future<Uri> parseRouteInformation(RouteInformation information) =>
      SynchronousFuture(information.uri);
  @override
  RouteInformation restoreRouteInformation(Uri configuration) =>
      RouteInformation(uri: galleryRouteUri(configuration));
}

class _GalleryRouter extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  _GalleryRouter(this.uri, this.onChanged, this.builder);
  Uri uri;
  final ValueChanged<Uri> onChanged;
  final WidgetBuilder builder;
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  @override
  Uri get currentConfiguration => uri;
  void navigate(Uri next) {
    if (uri == next) return;
    uri = next;
    onChanged(uri);
    notifyListeners();
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) =>
      Future<void>.microtask(() => navigate(configuration));

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: [
      MaterialPage<void>(
        key: const ValueKey('gallery'),
        child: builder(context),
      ),
    ],
    onDidRemovePage: (_) {},
  );
}

String title(String id) {
  return componentTitle(id);
}

class ComponentExample extends StatefulWidget {
  const ComponentExample({
    super.key,
    required this.id,
    this.onSectionSelected,
    this.sectionLocation,
  });
  final String id;
  final ValueChanged<String>? onSectionSelected;
  final Uri? sectionLocation;
  @override
  State<ComponentExample> createState() => _ComponentExampleState();
}

class _ComponentExampleState extends State<ComponentExample> {
  bool checked = false, open = false;
  bool sidebarCollapsed = false;
  String sidebarSurface = 'account';
  String tab = 'overview', option = 'automatic';
  int page = 1, clicks = 0;
  double value = 36;
  DateTime? date;
  DateTimeRange? range;
  List<String> tags = ['本番', 'ステージング'];
  Set<int> rows = {};
  final controller = TextEditingController(text: 'demo-not-a-real-secret');
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void action() => setState(() => clicks++);
  Widget group(List<Widget> children) => Wrap(
    spacing: 12,
    runSpacing: 16,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
  Widget form(List<Widget> children) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final child in children)
        Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
    ],
  );
  Widget table() => SteyTable(
    columns: const ['名前', '状態', 'リクエスト'],
    rows: const [
      [
        Text('api.example.com'),
        SteyBadge(tone: SteyTone.success, dot: true, child: Text('稼働中')),
        Text('24,812'),
      ],
      [
        Text('cdn.example.com'),
        SteyBadge(tone: SteyTone.warning, dot: true, child: Text('保留中')),
        Text('12,036'),
      ],
    ],
    selectedRows: rows,
    onSelect: (i, v) => setState(() => v ? rows.add(i) : rows.remove(i)),
  );
  @override
  Widget build(BuildContext context) {
    const options = {'automatic': '自動', 'manual': '手動', 'disabled': '無効'};
    final buttons = [
      for (final variant in SteyButtonVariant.values)
        SteyButton(
          onPressed: action,
          variant: variant,
          child: Text(variantLabel(variant.name)),
        ),
    ];
    return switch (widget.id) {
      'button' => form([
        group(buttons),
        const SteyText('文字とアイコンの位置'),
        group([
          for (final size in SteySize.values)
            SteyButton(
              onPressed: action,
              size: size,
              icon: const Icon(Icons.add, size: 16),
              child: Text('${sizeLabel(size.name)}で追加'),
            ),
          SteyButton(
            onPressed: action,
            semanticLabel: 'アイコンのみで追加',
            icon: const Icon(Icons.add, size: 16),
            child: const SizedBox.shrink(),
          ),
        ]),
        group([
          for (final size in SteySize.values)
            SteyButton(
              onPressed: action,
              size: size,
              child: Text(sizeLabel(size.name)),
            ),
          const SteyButton(child: Text('無効')),
          SteyButton(
            onPressed: action,
            loading: true,
            child: const Text('保存中'),
          ),
        ]),
        group([
          SteyRefreshButton(onPressed: action, label: '更新'),
          SteyButton(
            onPressed: action,
            shape: SteyButtonShape.circle,
            semanticLabel: '項目を追加',
            child: const Icon(Icons.add, size: 16),
          ),
        ]),
        SteyText('操作回数：$clicks回'),
      ]),
      'button-group' => const ButtonGroupExample(),
      'badge' => const BadgeExample(),
      'banner' => const BannerExample(),
      'input' => const InputExample(),
      'input-group' => const InputGroupExample(),
      'sensitive-input' => const SensitiveInputExample(),
      'field' => const SteyField(
        label: 'アカウント名',
        description: 'この名前は公開されます。',
        required: true,
        child: SteyInput(semanticLabel: 'アカウント名', placeholder: 'アカウント'),
      ),
      'label' => const LabelExample(),
      'checkbox' => form([
        SteyCheckbox(
          value: checked,
          onChanged: (v) => setState(() => checked = v ?? false),
          label: 'アクセス分析を有効にする',
          description: '利用状況を集計します。',
        ),
        const SteyCheckbox(
          value: null,
          tristate: true,
          onChanged: null,
          label: '部分選択',
        ),
        const SteyCheckbox(value: false, onChanged: null, label: '無効'),
        const SteyCheckbox(
          variant: SteyCheckboxVariant.error,
          label: '必須の選択項目',
          required: true,
        ),
        const SteyCheckboxGroup(
          legend: '通知方法を複数選択',
          allValues: ['email', 'sms'],
          children: [
            SteyCheckbox(parent: true, label: 'すべて選択'),
            SteyCheckboxItem(value: 'email', label: 'メール'),
            SteyCheckboxItem(value: 'sms', label: 'SMS'),
          ],
        ),
        const SteyCheckboxGroup(
          legend: '通知方法',
          description: '使用する通知方法を選択してください。',
          defaultValue: ['email'],
          appearance: SteyCheckboxAppearance.card,
          children: [
            SteyCheckboxItem(
              value: 'email',
              label: 'メール',
              description: '受信トレイに通知を送ります。',
            ),
            SteyCheckboxItem(
              value: 'sms',
              label: 'SMS',
              description: 'SMSで通知を送ります。',
            ),
          ],
        ),
      ]),
      'switch' => form([
        SteySwitch(
          value: checked,
          onChanged: (v) => setState(() => checked = v),
          label: '通知を有効にする',
        ),
        const SteySwitch(label: '中立色のスイッチ', variant: SteySwitchVariant.neutral),
        const SteySwitch(label: '小さいスイッチ', size: SteySwitchSize.sm),
        const SteySwitch(label: '大きいスイッチ', size: SteySwitchSize.lg),
        const SteySwitchGroup(
          legend: '通知方法',
          children: [
            SteySwitchItem(label: 'メール', defaultValue: true),
            SteySwitchItem(label: 'SMS', disabled: true),
          ],
        ),
      ]),
      'radio' => form([
        SteyRadioGroup(
          value: option,
          options: options,
          onChanged: (v) => setState(() => option = v ?? option),
          label: 'デプロイ方法',
          card: true,
        ),
        const SteyRadioGroup<String>(
          legend: '請求期間',
          appearance: SteyRadioAppearance.segmented,
          defaultValue: 'monthly',
          options: {'monthly': '月払い', 'yearly': '年払い'},
        ),
        const SteyRadioGroup<int>(
          legend: 'プラン',
          orientation: Axis.horizontal,
          appearance: SteyRadioAppearance.card,
          children: [
            SteyRadioLegend('プランを選択', visuallyHidden: true),
            SteyRadioItem(value: 1, label: '無料', description: '個人のプロジェクト向け。'),
            SteyRadioItem(value: 2, label: 'プロ', description: '業務での利用向け。'),
            SteyRadioItem(value: 3, label: '企業向け', disabled: true),
          ],
        ),
      ]),
      'select' => form([
        SteySelect(
          value: option,
          options: options,
          onChanged: (v) => setState(() => option = v ?? option),
          label: 'デプロイ方法',
          description: 'デプロイ先の環境を選択してください。',
        ),
        const SteySelect<String>(
          placeholder: '選択してください',
          controlled: false,
          multiple: true,
          defaultValues: ['eu'],
          label: '地域',
          entries: [
            SteySelectGroup(
              label: '選択可能',
              entries: [
                SteySelectOption(value: 'eu', label: 'ヨーロッパ'),
                SteySelectOption(value: 'us', label: '米国'),
              ],
            ),
            SteySelectSeparator(),
            SteySelectOption(value: 'ap', label: 'アジア太平洋', disabled: true),
          ],
        ),
        const SteySelect<String>(
          value: 'preview',
          options: {'preview': 'プレビュー', 'production': '本番'},
          readOnly: true,
          label: '読み取り専用',
        ),
        const SteySelect<String>(
          label: '環境を読み込み中',
          placeholder: '選択してください',
          loading: true,
        ),
      ]),
      'autocomplete' || 'combobox' => form([
        SteyCombobox(
          options: const ['Workers', 'R2ストレージ', 'Pages', 'D1データベース', 'Queues'],
          label: '製品',
          placeholder: '製品を検索',
          onSelected: (v) => setState(() => option = v),
        ),
        SteyText('選択中：${exampleValues[option] ?? option}'),
      ]),
      'slider' => const SliderExample(),
      'tabs' || 'menubar' => const TabsExample(),
      'pagination' => const PaginationExample(),
      'breadcrumbs' => const BreadcrumbsExample(),
      'collapsible' => const CollapsibleExample(),
      'toolbar' => SteyToolbar(
        children: [
          SteyButton(onPressed: action, child: const Text('作成')),
          SteyButton(onPressed: action, child: const Text('絞り込み')),
          SteyRefreshButton(onPressed: action, label: '更新'),
        ],
      ),
      'table' => table(),
      'resource-list' => SteyResourceList<String>(
        emptyTitle: 'リソースがありません',
        items: const [
          'api.example.com',
          'cdn.example.com',
          'worker.example.com',
        ],
        labelOf: (value) => value,
        onCreate: action,
        itemBuilder: (context, value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SteyButton(onPressed: action, child: Text(value)),
        ),
      ),
      'chart' => form([
        SteyTimeseriesChart(
          label: '時系列チャート',
          series: const [
            SteyChartSeries(
              name: 'リクエスト',
              color: Color(0xff2563eb),
              points: [
                SteyChartPoint(0, 12),
                SteyChartPoint(1, 28),
                SteyChartPoint(2, 18),
                SteyChartPoint(3, 42),
                SteyChartPoint(4, 36),
              ],
            ),
            SteyChartSeries(
              name: 'キャッシュ',
              color: Color(0xff059669),
              points: [
                SteyChartPoint(0, 6),
                SteyChartPoint(1, 20),
                SteyChartPoint(2, 14),
                SteyChartPoint(3, 32),
                SteyChartPoint(4, 28),
              ],
            ),
          ],
          thresholds: const [SteyChartThreshold(40, 'しきい値', Color(0xffd97706))],
          onPointSelected: (_, point) => setState(() => value = point.y),
        ),
        SteySankeyChart(
          nodes: const [
            SteySankeyNode('edge', 'エッジ'),
            SteySankeyNode('cache', 'キャッシュ'),
            SteySankeyNode('origin', 'オリジン'),
          ],
          links: const [
            SteySankeyLink('edge', 'cache', 80),
            SteySankeyLink('edge', 'origin', 20),
          ],
          onNodeClick: (_) => action(),
        ),
        const SteyBubbleMap(
          label: '地図上の拠点',
          markers: [
            SteyMapMarker(
              id: 'tokyo',
              name: '東京',
              latitude: 35.68,
              longitude: 139.69,
              value: 64,
            ),
            SteyMapMarker(
              id: 'london',
              name: 'ロンドン',
              latitude: 51.5,
              longitude: -.12,
              value: 36,
            ),
          ],
        ),
        const SteyGlobeMap(
          markers: [
            SteyMapMarker(
              id: 'london',
              name: 'ロンドン',
              latitude: 51.5,
              longitude: -.12,
            ),
            SteyMapMarker(
              id: 'tokyo',
              name: '東京',
              latitude: 35.68,
              longitude: 139.69,
            ),
          ],
        ),
      ]),
      'flow' => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowCompositionExample(),
          SizedBox(height: 24),
          FlowCanvasExample(),
          SizedBox(height: 24),
          FlowWrapExample(),
          SizedBox(height: 24),
          FlowAutoExample(),
          SizedBox(height: 24),
          FlowAnchorExample(),
        ],
      ),
      'sidebar' => form([
        group([
          SteyButton(
            onPressed: () =>
                setState(() => sidebarCollapsed = !sidebarCollapsed),
            child: Text(sidebarCollapsed ? 'サイドバーを展開' : 'サイドバーを折りたたむ'),
          ),
          SteyButton(
            onPressed: () => setState(
              () => sidebarSurface = sidebarSurface == 'account'
                  ? 'zone'
                  : 'account',
            ),
            child: const Text('ナビゲーション画面を切り替え'),
          ),
        ]),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.clamp(58.0, 480.0);
            return Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 300,
                child: SteySidebar(
                  width: 256,
                  resizable: true,
                  minWidth: maxWidth < 200 ? maxWidth : 200,
                  maxWidth: maxWidth,
                  collapsed: sidebarCollapsed,
                  onCollapsedChanged: (value) =>
                      setState(() => sidebarCollapsed = value),
                  items: const [
                    SteySidebarItem(
                      'overview',
                      '概要',
                      icon: Icons.home_outlined,
                    ),
                    SteySidebarItem('analytics', '分析', icon: Icons.bar_chart),
                    SteySidebarItem(
                      'settings',
                      '設定',
                      icon: Icons.settings_outlined,
                      children: [
                        SteySidebarItem('profile', 'プロフィール'),
                        SteySidebarItem('notifications', '通知'),
                        SteySidebarItem(
                          'security',
                          'セキュリティ',
                          children: [
                            SteySidebarItem('keys', 'APIキー'),
                            SteySidebarItem('tokens', 'トークン'),
                          ],
                        ),
                      ],
                    ),
                  ],
                  selected: tab,
                  onSelected: (v) => setState(() => tab = v),
                ),
              ),
            );
          },
        ),
        SizedBox(
          height: 140,
          child: SteySidebarSlidingViews(
            activeKey: sidebarSurface,
            views: const [
              SteySidebarSlidingView(
                value: 'account',
                child: SteyInput(
                  label: 'アカウント名',
                  placeholder: '画面を切り替えても入力内容を保持します',
                ),
              ),
              SteySidebarSlidingView(
                value: 'zone',
                child: SteyInput(label: 'ゾーン名', placeholder: 'example.com'),
              ),
            ],
          ),
        ),
      ]),
      'table-of-contents' => TableOfContentsExample(
        onSelected: widget.onSectionSelected,
        location: widget.sectionLocation,
      ),
      'tag-input' => const TagInputExample(),
      'layer-card' => const LayerCardExample(),
      'surface' => const LayerCardExample(surface: true),
      'empty' => const EmptyExample(),
      'meter' => const MeterExample(),
      'loader' => const LoaderExample(),
      'clipboard-text' => const ClipboardExample(),
      'inline-copy-text' => const InlineCopyExample(),
      'code' => const CodeExample(),
      'grid' => SteyGrid(
        minWidth: 120,
        children: [
          for (var i = 1; i <= 6; i++)
            Container(
              padding: const EdgeInsets.all(20),
              color: SteyTheme.colorsOf(context).tint,
              child: Text('項目$i'),
            ),
        ],
      ),
      'text' => const TextExample(),
      'link' => const LinkExample(),
      'layer-dialog' => const LayerDialogExample(),
      'dialog' => SteyButton(
        onPressed: () => SteyDialog.show(
          context,
          title: 'Workerを編集',
          description: 'Workerの設定を変更します。',
          child: const SteyInput(label: 'Worker名', placeholder: 'my-worker'),
        ),
        child: const Text('ダイアログを開く'),
      ),
      'dropdown' => const DropdownExample(),
      'popover' => const SteyPopover(
        trigger: Text('ポップオーバーを開く'),
        title: 'デプロイの詳細',
        child: Text('世界330都市へデプロイ済みです。'),
      ),
      'tooltip' => SteyTooltip(
        message: 'Workerを世界中へデプロイします',
        child: SteyButton(onPressed: action, child: const Text('ホバーまたはフォーカス')),
      ),
      'toast' => SteyButton(
        onPressed: () => SteyToast.show(
          context,
          message: 'Workerをデプロイしました',
          tone: SteyTone.success,
        ),
        child: const Text('トーストを表示'),
      ),
      'command-palette' => SteyButton(
        onPressed: () => SteyCommandPalette.show(
          context,
          commands: [
            SteyCommand(
              'Workerを作成',
              action,
              group: 'コンピューティング',
              icon: const Icon(Icons.cloud_outlined, size: 16),
              breadcrumbs: const ['Workers'],
              description: 'サーバーレスアプリをデプロイ',
              highlights: const [(0, 5)],
            ),
            SteyCommand(
              '設定を開く',
              action,
              group: 'アカウント',
              icon: const Icon(Icons.settings_outlined, size: 16),
              onSelect: (newTab) => SteyToast.show(
                context,
                message: newTab ? '新しいタブで設定を開く' : '設定を開く',
              ),
            ),
            SteyCommand('アクセス分析を表示', action, group: 'アカウント', external: true),
            SteyCommand('利用できない操作', action, group: 'アカウント', disabled: true),
          ],
          footer: const Text('↑↓ 移動 · Enter 選択 · Ctrl/Cmd+Enter 新しいタブ'),
        ),
        child: const Text('コマンドを開く'),
      ),
      'date-picker' => SteyDatePicker(
        label: '日付を選択',
        value: date,
        onChanged: (v) => setState(() => date = v),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      ),
      'date-range-picker' => SteyDateRangePicker(
        label: '日付の範囲を選択',
        value: range,
        onChanged: (v) => setState(() => range = v),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      ),
      'delete-resource' => SteyDeleteResource(
        resourceName: 'my-worker',
        onDelete: () => SteyToast.show(context, message: 'デモのリソースを削除しました'),
      ),
      'page-header' => SteyPageHeader(
        breadcrumbs: [
          SteyBreadcrumb('アカウント', onPressed: action),
          const SteyBreadcrumb('Workers'),
        ],
        title: 'WorkersとPages',
        description: 'サーバーレスアプリを世界中へデプロイします。',
        actions: [
          SteyButton(
            onPressed: action,
            variant: SteyButtonVariant.primary,
            child: const Text('アプリを作成'),
          ),
        ],
      ),
      'cloudflare-logo' => const SteyBanner(
        tone: SteyTone.warning,
        child: Text(
          'Cloudflareロゴは、商標利用に関する書面での許可を得るまで配布していません。このコンポーネントは公式の参照先で確認してください。',
        ),
      ),
      _ => const SteyEmpty(
        title: '実装準備中',
        description: '対応表で管理しているコンポーネントです。公式の挙動は参照先で確認してください。',
      ),
    };
  }
}
