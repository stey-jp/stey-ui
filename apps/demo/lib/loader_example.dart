import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class LoaderExample extends StatefulWidget {
  const LoaderExample({super.key});
  @override
  State<LoaderExample> createState() => _ExampleState();
}

class _ExampleState extends State<LoaderExample> {
  SteyLoaderSize size = SteyLoaderSize.base;
  bool custom = false, colored = false, rtl = false;
  int epoch = 0;
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
          SteyLoaderSize.sm: '小（16px）',
          SteyLoaderSize.base: '標準（24px）',
          SteyLoaderSize.lg: '大（32px）',
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
            value: custom,
            label: '任意サイズ（45px）',
            onChanged: (v) => setState(() => custom = v),
          ),
          SteySwitch(
            value: colored,
            label: '色を変更',
            onChanged: (v) => setState(() => colored = v),
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
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: custom
              ? SteyLoader(
                  size: 45,
                  label: 'プロジェクトを読み込み中',
                  color: colored ? SteyTheme.colorsOf(context).brand : null,
                )
              : SteyLoader.preset(
                  size: size,
                  label: 'プロジェクトを読み込み中',
                  color: colored ? SteyTheme.colorsOf(context).brand : null,
                ),
        ),
      ),
      const SteyText('スケルトン表示', heading: 4),
      SizedBox(
        width: 240,
        child: SteySkeletonLine(key: ValueKey(epoch), blockHeight: 40),
      ),
      SteyButton(
        onPressed: () => setState(() => epoch++),
        child: const Text('スケルトンを再作成'),
      ),
      Text('再作成：$epoch回'),
      const SteyText(
        'スピナーは回転2秒・線の伸縮1.5秒で動きます。スケルトンは幅・周期・開始遅延を作成時に選びます。',
        subtle: true,
      ),
    ],
  );
}

class LoaderSample extends StatelessWidget {
  const LoaderSample(this.query, {super.key});
  final Map<String, String> query;
  @override
  Widget build(BuildContext context) {
    final q = query;
    final c = SteyTheme.colorsOf(context);
    final size =
        double.tryParse(q['size'] ?? '') ??
        switch (q['size']) {
          'sm' => 16.0,
          'lg' => 32.0,
          _ => 24.0,
        };
    final skeleton = q['kind'] == 'skeleton';
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Loader preview',
      child: SizedBox(
        width: 160,
        height: 96,
        child: ColoredBox(
          color: c.base,
          child: Center(
            child: skeleton
                ? SizedBox(
                    width: 120,
                    child: SteySkeletonLine(
                      minWidth: int.tryParse(q['minWidth'] ?? '') ?? 60,
                      maxWidth: int.tryParse(q['maxWidth'] ?? '') ?? 60,
                      minDuration: 1.5,
                      maxDuration: 1.5,
                      minDelay: 0,
                      maxDelay: 0,
                      blockHeight: q['block'] == 'true' ? 40 : null,
                    ),
                  )
                : SteyLoader(
                    size: size,
                    label: q['label'] ?? 'Loading',
                    color: q['color'] == 'red' ? const Color(0x80ff0000) : null,
                  ),
          ),
        ),
      ),
    );
  }
}
