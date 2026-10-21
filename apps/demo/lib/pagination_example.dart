import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class PaginationExample extends StatefulWidget {
  const PaginationExample({super.key});
  @override
  State<PaginationExample> createState() => _ExampleState();
}

class _ExampleState extends State<PaginationExample> {
  int page = 3, perPage = 10, calls = 0;
  bool unknown = false,
      next = true,
      simple = false,
      dropdown = false,
      empty = false,
      rtl = false;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          SteySwitch(
            value: unknown,
            label: '総件数が不明',
            onChanged: (v) => setState(() => unknown = v),
          ),
          SteySwitch(
            value: next,
            label: '次のページあり',
            onChanged: (v) => setState(() => next = v),
          ),
          SteySwitch(
            value: simple,
            label: '前後移動のみ',
            onChanged: (v) => setState(() => simple = v),
          ),
          SteySwitch(
            value: dropdown,
            label: 'ページを選択',
            onChanged: (v) => setState(() => dropdown = v),
          ),
          SteySwitch(
            value: empty,
            label: '検索結果なし',
            onChanged: (v) => setState(() {
              empty = v;
              page = 1;
            }),
          ),
          SteySwitch(
            value: rtl,
            label: '右から左へ',
            onChanged: (v) => setState(() => rtl = v),
          ),
        ],
      ),
      Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SteyPagination(
          page: page,
          perPage: perPage,
          totalCount: unknown
              ? null
              : empty
              ? 0
              : 100,
          hasNextPage: next,
          onChanged: (v) => setState(() {
            page = v;
            calls++;
          }),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const SteyPaginationInfo(),
              SteyPaginationPageSize(
                value: perPage,
                options: const [10, 25, 50],
                onChanged: (v) => setState(() {
                  perPage = v;
                  page = 1;
                }),
              ),
              SteyPaginationControls(
                controls: simple
                    ? SteyPaginationMode.simple
                    : SteyPaginationMode.full,
                pageSelector: dropdown
                    ? SteyPaginationSelector.dropdown
                    : SteyPaginationSelector.input,
              ),
            ],
          ),
        ),
      ),
      Semantics(liveRegion: true, child: Text('現在のページ：$page・移動操作：$calls回')),
      const SteyText(
        'ページ番号はEnterまたは入力欄からの移動で確定します。範囲外は端へ補正し、数字以外・小数・符号付き入力は元のページへ戻します。',
        subtle: true,
      ),
    ],
  );
}

class PaginationSample extends StatefulWidget {
  const PaginationSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  State<PaginationSample> createState() => _SampleState();
}

class _SampleState extends State<PaginationSample> {
  late int page = int.tryParse(widget.query['page'] ?? '') ?? 3,
      perPage = int.tryParse(widget.query['perPage'] ?? '') ?? 10;
  int calls = 0;
  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final controls = SteyPaginationControls(
      controls: q['controls'] == 'simple'
          ? SteyPaginationMode.simple
          : SteyPaginationMode.full,
      pageSelector: q['selector'] == 'dropdown'
          ? SteyPaginationSelector.dropdown
          : SteyPaginationSelector.input,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Pagination preview',
      child: SizedBox(
        width: double.tryParse(q['host'] ?? '') ?? 600,
        height: 120,
        child: Stack(
          children: [
            Center(
              child: SteyPagination(
                page: page,
                perPage: perPage,
                totalCount: q['unknown'] == 'true'
                    ? null
                    : int.tryParse(q['total'] ?? '') ?? 100,
                hasNextPage: q.containsKey('next') ? q['next'] == 'true' : null,
                onChanged: (v) => setState(() {
                  page = v;
                  calls++;
                }),
                labels: const SteyPaginationLabels(
                  navigation: 'Pagination',
                  firstPage: 'First page',
                  previousPage: 'Previous page',
                  nextPage: 'Next page',
                  lastPage: 'Last page',
                  pageNumber: 'Page number',
                  pageSize: 'Page size',
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    if (q['compound'] == 'true') ...[
                      SteyPaginationInfo(
                        builder: (_, d) => Text(
                          d.totalCount != null && d.totalCount! > 0
                              ? 'Showing ${d.pageShowingRange} of ${d.totalCount}'
                              : '',
                        ),
                      ),
                      const SteyPaginationSeparator(),
                      SteyPaginationPageSize(
                        value: perPage,
                        options: const [10, 25, 50],
                        label: const Text('Per page:'),
                        onChanged: (v) => setState(() => perPage = v),
                      ),
                    ],
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: controls,
                      ),
                    ),
                  ],
                ),
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
                    label: 'Page: $page; Calls: $calls',
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
