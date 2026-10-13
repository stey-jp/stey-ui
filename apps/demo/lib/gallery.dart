import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalog.g.dart';

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
      Uri(path: '/', queryParameters: Uri.base.queryParameters),
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
    title: 'Stey UI — Flutter component gallery',
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
              'badge' => SteyBadge(
                appearance: router.uri.queryParameters['appearance'] == 'dot'
                    ? SteyBadgeAppearance.dot
                    : SteyBadgeAppearance.filled,
                variant: SteyBadgeVariant.values.firstWhere(
                  (v) => v.name == variant,
                  orElse: () => SteyBadgeVariant.secondary,
                ),
                child: const Text('Active'),
              ),
              'input' => const SizedBox(
                width: 280,
                child: SteyInput(
                  placeholder: 'Project name',
                  semanticLabel: 'Name',
                ),
              ),
              _ => SteyButton(
                onPressed: sampleState == 'disabled' ? null : () {},
                loading: sampleState == 'loading',
                semanticLabel: 'Save',
                size: sampleSize,
                shape: sampleShape,
                variant: SteyButtonVariant.values.firstWhere(
                  (v) => v.name == variant,
                  orElse: () => SteyButtonVariant.secondary,
                ),
                child: Text(sampleShape == SteyButtonShape.base ? 'Save' : '+'),
              ),
            };
            return Scaffold(
              backgroundColor: c.base,
              body: Center(child: child),
            );
          }
          if (router.uri.queryParameters['fixture'] == '1') {
            return Scaffold(
              backgroundColor: c.base,
              body: Center(
                child: SizedBox(
                  width: 600,
                  child: ComponentExample(id: selected),
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
                      .where((id) => id.contains(filter.toLowerCase()))
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
                                  ? 'Switch to light mode'
                                  : 'Switch to dark mode',
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
                                        placeholder: 'Search components',
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
                                                title(id),
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
                                                id: title(id),
                                            },
                                            onChanged: (v) {
                                              if (v != null) select(v);
                                            },
                                            label: 'Component',
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                        SteyBreadcrumbs(
                                          items: [
                                            SteyBreadcrumb(
                                              'Components',
                                              onPressed: () => select('button'),
                                            ),
                                            SteyBreadcrumb(title(selected)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        SteyText(title(selected), heading: 1),
                                        const SizedBox(height: 6),
                                        const SteyText(
                                          'Native Flutter components inspired by Cloudflare Kumo.',
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
                                              child: const Text(
                                                'Compare with Kumo',
                                              ),
                                            ),
                                            SteyLink(
                                              external: true,
                                              onPressed: () => launchUrl(
                                                Uri.parse(
                                                  'https://github.com/cloudflare/kumo/tree/f46e8bc9922c37dc1d3e7da779e589fe171df306/packages/kumo/src/${{'page-header', 'resource-list', 'delete-resource'}.contains(selected) ? 'blocks' : 'components'}/$selected',
                                                ),
                                              ),
                                              child: const Text(
                                                'Reference source',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        SteyLayerCard(
                                          header: const Row(
                                            children: [
                                              Expanded(
                                                child: SteyText(
                                                  'Interactive preview',
                                                  bold: true,
                                                ),
                                              ),
                                              Spacer(),
                                              SteyBadge(child: Text('Preview')),
                                            ],
                                          ),
                                          child: ComponentExample(
                                            key: ValueKey(selected),
                                            id: selected,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const SteyBanner(
                                          tone: SteyTone.warning,
                                          child: Text(
                                            'Development preview. Complete visual and behavior parity with Kumo has not been certified.',
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const SteyText(
                                          'Independent MIT project. Cloudflare and Kumo are trademarks of their respective owners. No affiliation or endorsement.',
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
      RouteInformation(uri: configuration);
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
  final value = id.replaceAll('-', ' ');
  return value[0].toUpperCase() + value.substring(1);
}

class ComponentExample extends StatefulWidget {
  const ComponentExample({super.key, required this.id});
  final String id;
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
  List<String> tags = ['production', 'staging'];
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
    columns: const ['Name', 'Status', 'Requests'],
    rows: const [
      [
        Text('api.example.com'),
        SteyBadge(tone: SteyTone.success, dot: true, child: Text('Active')),
        Text('24,812'),
      ],
      [
        Text('cdn.example.com'),
        SteyBadge(tone: SteyTone.warning, dot: true, child: Text('Pending')),
        Text('12,036'),
      ],
    ],
    selectedRows: rows,
    onSelect: (i, v) => setState(() => v ? rows.add(i) : rows.remove(i)),
  );
  @override
  Widget build(BuildContext context) {
    const options = {
      'automatic': 'Automatic',
      'manual': 'Manual',
      'disabled': 'Disabled',
    };
    final buttons = [
      for (final variant in SteyButtonVariant.values)
        SteyButton(
          onPressed: action,
          variant: variant,
          child: Text(variant.name),
        ),
    ];
    return switch (widget.id) {
      'button' => form([
        group(buttons),
        group([
          for (final size in SteySize.values)
            SteyButton(onPressed: action, size: size, child: Text(size.name)),
          const SteyButton(child: Text('Disabled')),
          SteyButton(
            onPressed: action,
            loading: true,
            child: const Text('Saving'),
          ),
        ]),
        group([
          SteyRefreshButton(onPressed: action),
          SteyButton(
            onPressed: action,
            shape: SteyButtonShape.circle,
            semanticLabel: 'Add item',
            child: const Icon(Icons.add, size: 16),
          ),
        ]),
        SteyText('Activated $clicks times'),
      ]),
      'button-group' => SteyButtonGroup(children: buttons.take(3).toList()),
      'badge' => group([
        for (final variant in SteyBadgeVariant.values)
          SteyBadge(variant: variant, child: Text(variant.name)),
        for (final tone in SteyTone.values)
          SteyBadge(tone: tone, child: Text(tone.name)),
        for (final tone in SteyTone.values)
          SteyBadge(tone: tone, dot: true, child: Text(tone.name)),
        for (final variant in [
          SteyBadgeVariant.success,
          SteyBadgeVariant.warning,
          SteyBadgeVariant.error,
          SteyBadgeVariant.neutral,
        ])
          SteyBadge(
            variant: variant,
            appearance: SteyBadgeAppearance.dot,
            child: Text(variant.name),
          ),
      ]),
      'banner' => form([
        for (final tone in SteyTone.values)
          SteyBanner(
            tone: tone,
            child: Text('${title(tone.name)} notification'),
          ),
      ]),
      'input' => form([
        const SteyInput(
          label: 'Project name',
          placeholder: 'my-project',
          required: true,
          description: 'Choose a unique name.',
        ),
        const SteyInput(
          label: 'Email',
          error: 'Enter a valid email address',
          placeholder: 'name@example.com',
        ),
        const SteyTextarea(
          label: 'Description',
          placeholder: 'Describe your project',
        ),
        const SteyInput(
          label: 'Disabled field',
          enabled: false,
          placeholder: 'Unavailable',
        ),
      ]),
      'input-group' => const SteyInputGroup(
        addon: Text('https://'),
        suffix: Text('.com'),
        child: SteyInput(label: 'Domain', placeholder: 'example.com'),
      ),
      'sensitive-input' => SteySensitiveInput(
        controller: controller,
        label: 'API token',
      ),
      'field' => const SteyField(
        label: 'Account name',
        description: 'This name is public.',
        required: true,
        child: SteyInput(semanticLabel: 'Account name', placeholder: 'Account'),
      ),
      'label' => group([
        const SteyLabel('Project name'),
        const SteyLabel('Required field', required: true),
      ]),
      'checkbox' => form([
        SteyCheckbox(
          value: checked,
          onChanged: (v) => setState(() => checked = v ?? false),
          label: 'Enable analytics',
          description: 'Collect usage statistics.',
        ),
        const SteyCheckbox(
          value: null,
          tristate: true,
          onChanged: null,
          label: 'Indeterminate',
        ),
        const SteyCheckbox(value: false, onChanged: null, label: 'Disabled'),
        const SteyCheckbox(
          variant: SteyCheckboxVariant.error,
          label: 'Required selection',
          required: true,
        ),
        const SteyCheckboxGroup(
          legend: 'Select multiple channels',
          allValues: ['email', 'sms'],
          children: [
            SteyCheckbox(parent: true, label: 'Select all'),
            SteyCheckboxItem(value: 'email', label: 'Email'),
            SteyCheckboxItem(value: 'sms', label: 'SMS'),
          ],
        ),
        const SteyCheckboxGroup(
          legend: 'Notification channels',
          description: 'Select the channels you use.',
          defaultValue: ['email'],
          appearance: SteyCheckboxAppearance.card,
          children: [
            SteyCheckboxItem(
              value: 'email',
              label: 'Email',
              description: 'Receive notifications in your inbox.',
            ),
            SteyCheckboxItem(
              value: 'sms',
              label: 'SMS',
              description: 'Receive text messages.',
            ),
          ],
        ),
      ]),
      'switch' => form([
        SteySwitch(
          value: checked,
          onChanged: (v) => setState(() => checked = v),
          label: 'Enable notifications',
        ),
        const SteySwitch(
          label: 'Neutral switch',
          variant: SteySwitchVariant.neutral,
        ),
        const SteySwitch(label: 'Small switch', size: SteySwitchSize.sm),
        const SteySwitch(label: 'Large switch', size: SteySwitchSize.lg),
        const SteySwitchGroup(
          legend: 'Channels',
          children: [
            SteySwitchItem(label: 'Email', defaultValue: true),
            SteySwitchItem(label: 'SMS', disabled: true),
          ],
        ),
      ]),
      'radio' => form([
        SteyRadioGroup(
          value: option,
          options: options,
          onChanged: (v) => setState(() => option = v ?? option),
          label: 'Deployment mode',
          card: true,
        ),
        const SteyRadioGroup<String>(
          legend: 'Billing period',
          appearance: SteyRadioAppearance.segmented,
          defaultValue: 'monthly',
          options: {'monthly': 'Monthly', 'yearly': 'Yearly'},
        ),
        const SteyRadioGroup<int>(
          legend: 'Plan',
          orientation: Axis.horizontal,
          appearance: SteyRadioAppearance.card,
          children: [
            SteyRadioLegend('Choose a plan', visuallyHidden: true),
            SteyRadioItem(
              value: 1,
              label: 'Free',
              description: 'For personal projects.',
            ),
            SteyRadioItem(
              value: 2,
              label: 'Pro',
              description: 'For professional use.',
            ),
            SteyRadioItem(value: 3, label: 'Enterprise', disabled: true),
          ],
        ),
      ]),
      'select' => SteySelect(
        value: option,
        options: options,
        onChanged: (v) => setState(() => option = v ?? option),
        label: 'Deployment mode',
      ),
      'autocomplete' || 'combobox' => form([
        SteyCombobox(
          options: const [
            'Workers',
            'R2 storage',
            'Pages',
            'D1 database',
            'Queues',
          ],
          label: 'Product',
          onSelected: (v) => setState(() => option = v),
        ),
        SteyText('Selected: $option'),
      ]),
      'slider' => form([
        SteySlider(
          value: value,
          onChanged: (v) => setState(() => value = v),
          divisions: 100,
          label: 'Cache duration',
        ),
        SteyText('${value.round()} minutes'),
      ]),
      'tabs' || 'menubar' => form([
        SteyTabs(
          tabs: const [
            SteyTab('overview', 'Overview'),
            SteyTab('analytics', 'Analytics'),
            SteyTab('settings', 'Settings'),
          ],
          value: tab,
          onChanged: (v) => setState(() => tab = v),
        ),
        SteyTabs(
          tabs: const [
            SteyTab('overview', 'Overview'),
            SteyTab('analytics', 'Analytics'),
            SteyTab('settings', 'Settings'),
          ],
          value: tab,
          onChanged: (v) => setState(() => tab = v),
          variant: SteyTabsVariant.underline,
        ),
        SteyText('Current tab: $tab'),
      ]),
      'pagination' => form([
        SteyPagination(
          page: page,
          totalPages: 20,
          onChanged: (v) => setState(() => page = v),
        ),
        SteyText('Page $page of 20'),
      ]),
      'breadcrumbs' => SteyBreadcrumbs(
        items: [
          SteyBreadcrumb('Account', onPressed: action),
          SteyBreadcrumb('Workers', onPressed: action),
          const SteyBreadcrumb('my-worker'),
        ],
      ),
      'collapsible' => SteyCollapsible(
        open: open,
        onChanged: (v) => setState(() => open = v),
        title: const Text('Advanced settings'),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: SteyInput(label: 'Cache key', placeholder: 'default'),
        ),
      ),
      'toolbar' => SteyToolbar(
        children: [
          SteyButton(onPressed: action, child: const Text('Create')),
          SteyButton(onPressed: action, child: const Text('Filter')),
          SteyRefreshButton(onPressed: action),
        ],
      ),
      'table' => table(),
      'resource-list' => SteyResourceList<String>(
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
          series: const [
            SteyChartSeries(
              name: 'Requests',
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
              name: 'Cached',
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
          thresholds: const [
            SteyChartThreshold(40, 'Threshold', Color(0xffd97706)),
          ],
          onPointSelected: (_, point) => setState(() => value = point.y),
        ),
        SteySankeyChart(
          nodes: const [
            SteySankeyNode('edge', 'Edge'),
            SteySankeyNode('cache', 'Cache'),
            SteySankeyNode('origin', 'Origin'),
          ],
          links: const [
            SteySankeyLink('edge', 'cache', 80),
            SteySankeyLink('edge', 'origin', 20),
          ],
          onNodeClick: (_) => action(),
        ),
        const SteyBubbleMap(
          markers: [
            SteyMapMarker(
              id: 'tokyo',
              name: 'Tokyo',
              latitude: 35.68,
              longitude: 139.69,
              value: 64,
            ),
            SteyMapMarker(
              id: 'london',
              name: 'London',
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
              name: 'London',
              latitude: 51.5,
              longitude: -.12,
            ),
            SteyMapMarker(
              id: 'tokyo',
              name: 'Tokyo',
              latitude: 35.68,
              longitude: 139.69,
            ),
          ],
        ),
      ]),
      'flow' => SteyFlow(
        nodes: [
          SteyFlowNode('start', const Text('Request'), onPressed: action),
          SteyFlowNode('cache', const Text('Cache'), onPressed: action),
          SteyFlowNode('origin', const Text('Origin'), onPressed: action),
          SteyFlowNode('response', const Text('Response'), onPressed: action),
        ],
        edges: const [
          SteyFlowEdge('start', 'cache'),
          SteyFlowEdge('start', 'origin'),
          SteyFlowEdge('cache', 'response'),
          SteyFlowEdge('origin', 'response'),
        ],
      ),
      'sidebar' => form([
        group([
          SteyButton(
            onPressed: () =>
                setState(() => sidebarCollapsed = !sidebarCollapsed),
            child: Text(
              sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
            ),
          ),
          SteyButton(
            onPressed: () => setState(
              () => sidebarSurface = sidebarSurface == 'account'
                  ? 'zone'
                  : 'account',
            ),
            child: const Text('Switch navigation view'),
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
                      'Overview',
                      icon: Icons.home_outlined,
                    ),
                    SteySidebarItem(
                      'analytics',
                      'Analytics',
                      icon: Icons.bar_chart,
                    ),
                    SteySidebarItem(
                      'settings',
                      'Settings',
                      icon: Icons.settings_outlined,
                      children: [SteySidebarItem('profile', 'Profile')],
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
                  label: 'Account name',
                  placeholder: 'Text is retained when switching views',
                ),
              ),
              SteySidebarSlidingView(
                value: 'zone',
                child: SteyInput(
                  label: 'Zone name',
                  placeholder: 'example.com',
                ),
              ),
            ],
          ),
        ),
      ]),
      'table-of-contents' => SteyTableOfContents(
        items: const {
          'overview': 'Overview',
          'analytics': 'Analytics',
          'settings': 'Settings',
        },
        activeId: tab,
        onSelected: (v) => setState(() => tab = v),
      ),
      'tag-input' => SteyTagInput(
        value: tags,
        onChanged: (v) => setState(() => tags = v),
        label: 'Environment tags',
      ),
      'layer-card' || 'surface' => const SteyLayerCard(
        header: SteyText('Deployment', bold: true),
        footer: SteyText('Last updated just now', subtle: true),
        child: SteyText('Your worker is ready to deploy.'),
      ),
      'empty' => SteyEmpty(
        title: 'No workers yet',
        description: 'Create your first worker to get started.',
        action: SteyButton(
          onPressed: action,
          child: const Text('Create worker'),
        ),
      ),
      'meter' => form([
        SteyMeter(value: value, label: 'Requests used'),
        SteySlider(value: value, onChanged: (v) => setState(() => value = v)),
      ]),
      'loader' => group([
        const SteyLoader(),
        const SteyLoader(size: 24),
        const SizedBox(width: 180, child: SteySkeletonLine()),
        const SteySkeletonLine(width: 100),
      ]),
      'clipboard-text' => const SteyClipboardText(
        'npm install @cloudflare/kumo',
      ),
      'inline-copy-text' => const SteyInlineCopyText('account_12345'),
      'code' => const SteyCodeBlock(
        'SteyButton(onPressed: save, child: Text(\'Save\'))',
        copyable: true,
      ),
      'grid' => SteyGrid(
        minWidth: 120,
        children: [
          for (var i = 1; i <= 6; i++)
            Container(
              padding: const EdgeInsets.all(20),
              color: SteyTheme.colorsOf(context).tint,
              child: Text('Item $i'),
            ),
        ],
      ),
      'text' => form([
        const SteyText('Heading one', heading: 1),
        const SteyText('Heading two', heading: 2),
        const SteyText('Heading three', heading: 3),
        const SteyText('Body content is 14px.'),
        const SteyText('Subtle supporting text.', subtle: true),
      ]),
      'link' => SteyLink(
        onPressed: () => launchUrl(Uri.parse('https://kumo-ui.com')),
        external: true,
        child: const Text('Kumo documentation'),
      ),
      'dialog' || 'layer-dialog' => SteyButton(
        onPressed: () => SteyDialog.show(
          context,
          title: 'Edit worker',
          description: 'Update your worker configuration.',
          child: const SteyInput(
            label: 'Worker name',
            placeholder: 'my-worker',
          ),
        ),
        child: const Text('Open dialog'),
      ),
      'dropdown' => SteyDropdownMenu(
        items: [
          SteyMenuItem('Edit', onPressed: action, icon: Icons.edit_outlined),
          SteyMenuItem('Duplicate', onPressed: action),
          const SteyMenuItem('Unavailable', disabled: true),
          SteyMenuItem('Delete', onPressed: action, destructive: true),
        ],
        child: const Text('Actions'),
      ),
      'popover' => const SteyPopover(
        trigger: Text('Open popover'),
        title: 'Deployment details',
        child: Text('Deployed to 330 cities worldwide.'),
      ),
      'tooltip' => SteyTooltip(
        message: 'Deploy your worker globally',
        child: SteyButton(
          onPressed: action,
          child: const Text('Hover or focus'),
        ),
      ),
      'toast' => SteyButton(
        onPressed: () => SteyToast.show(
          context,
          message: 'Worker deployed successfully',
          tone: SteyTone.success,
        ),
        child: const Text('Show toast'),
      ),
      'command-palette' => SteyButton(
        onPressed: () => SteyCommandPalette.show(
          context,
          commands: [
            SteyCommand(
              'Create worker',
              action,
              group: 'Compute',
              icon: const Icon(Icons.cloud_outlined, size: 16),
              breadcrumbs: const ['Workers'],
              description: 'Deploy a serverless application',
              highlights: const [(0, 5)],
            ),
            SteyCommand(
              'Open settings',
              action,
              group: 'Account',
              icon: const Icon(Icons.settings_outlined, size: 16),
              onSelect: (newTab) => SteyToast.show(
                context,
                message: newTab
                    ? 'Open settings in a new tab'
                    : 'Open settings',
              ),
            ),
            SteyCommand(
              'View analytics',
              action,
              group: 'Account',
              external: true,
            ),
            SteyCommand(
              'Unavailable action',
              action,
              group: 'Account',
              disabled: true,
            ),
          ],
          footer: const Text(
            '↑↓ Navigate · Enter Select · Ctrl/Cmd+Enter New tab',
          ),
        ),
        child: const Text('Open commands'),
      ),
      'date-picker' => SteyDatePicker(
        value: date,
        onChanged: (v) => setState(() => date = v),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      ),
      'date-range-picker' => SteyDateRangePicker(
        value: range,
        onChanged: (v) => setState(() => range = v),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      ),
      'delete-resource' => SteyDeleteResource(
        resourceName: 'my-worker',
        onDelete: () =>
            SteyToast.show(context, message: 'Demo resource deleted'),
      ),
      'page-header' => SteyPageHeader(
        breadcrumbs: [
          SteyBreadcrumb('Account', onPressed: action),
          const SteyBreadcrumb('Workers'),
        ],
        title: 'Workers and Pages',
        description: 'Deploy serverless applications globally.',
        actions: [
          SteyButton(
            onPressed: action,
            variant: SteyButtonVariant.primary,
            child: const Text('Create application'),
          ),
        ],
      ),
      'cloudflare-logo' => const SteyBanner(
        tone: SteyTone.warning,
        child: Text(
          'Cloudflare logo distribution is withheld pending written trademark permission. View the official reference to inspect this component.',
        ),
      ),
      _ => const SteyEmpty(
        title: 'Implementation pending',
        description: 'This component is tracked in the upstream inventory. Open the reference to inspect its official behavior.',
      ),
    };
  }
}
