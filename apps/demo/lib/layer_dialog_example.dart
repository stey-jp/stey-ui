import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class LayerDialogExample extends StatefulWidget {
  const LayerDialogExample({super.key});
  @override
  State<LayerDialogExample> createState() => _LayerDialogExampleState();
}

class _LayerDialogExampleState extends State<LayerDialogExample> {
  SteyLayerDialogSize size = SteyLayerDialogSize.base;
  SteyLayerDialogVerticalAlign align = SteyLayerDialogVerticalAlign.center;
  String result = 'まだ操作していません';

  Future<void> open({
    bool alert = false,
    bool pending = false,
    bool long = false,
    bool noActions = false,
  }) async {
    final controller = SteyLayerDialogController<String>(
      dismissDisabled: pending,
    );
    Timer? timer;
    final future = SteyLayerDialog.show<String>(
      context,
      controller: controller,
      title: alert ? 'Workerを削除しますか？' : 'Workerを編集',
      description: alert
          ? 'この操作は取り消せません。対象のWorkerを確認してください。'
          : 'Workerの設定を変更します。変更内容を確認して保存してください。',
      size: size,
      verticalAlign: align,
      alert: alert,
      action: noActions
          ? null
          : SteyLayerDialogAction(
              loading: pending,
              variant: alert
                  ? SteyLayerDialogActionVariant.destructive
                  : SteyLayerDialogActionVariant.primary,
              onPressed: () =>
                  controller.close(alert ? 'Workerを削除しました' : '設定を保存しました'),
              menu: alert || pending
                  ? const []
                  : [
                      SteyMenuItem(
                        '下書きとして保存',
                        onPressed: () => controller.close('下書きとして保存しました'),
                      ),
                    ],
              child: Text(
                pending
                    ? '保存しています'
                    : alert
                    ? '削除する'
                    : '保存する',
              ),
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pending)
            const Text('処理中は閉じる・Esc・背景操作を無効にします。2秒後に完了します。')
          else if (alert)
            const Text('削除するWorker：my-worker')
          else
            const SteyInput(label: 'Worker名', placeholder: 'my-worker'),
          if (long)
            for (var i = 1; i <= 30; i++)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('設定項目$i：スクロールしても見出しと操作ボタンは固定されます。'),
              ),
        ],
      ),
    );
    if (pending) {
      timer = Timer(
        const Duration(seconds: 2),
        () => controller.close('処理が完了しました'),
      );
    }
    final value = await future;
    timer?.cancel();
    controller.dispose();
    if (mounted) setState(() => result = value ?? 'ダイアログを閉じました');
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('640px未満は下部シート、640px以上は多層ダイアログになります。'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in SteyLayerDialogSize.values)
            SteyButton(
              onPressed: () => setState(() => size = value),
              variant: size == value
                  ? SteyButtonVariant.primary
                  : SteyButtonVariant.secondary,
              child: Text('${value.name}・${value.width.toInt()}px'),
            ),
        ],
      ),
      const SizedBox(height: 12),
      SteyButton(
        onPressed: () => setState(
          () => align = align == SteyLayerDialogVerticalAlign.center
              ? SteyLayerDialogVerticalAlign.top
              : SteyLayerDialogVerticalAlign.center,
        ),
        child: Text(
          '配置：${align == SteyLayerDialogVerticalAlign.center ? '中央' : '上部'}',
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SteyButton(onPressed: open, child: const Text('多層ダイアログを開く')),
          SteyButton(
            onPressed: () => open(long: true),
            child: const Text('長い内容を確認'),
          ),
          SteyButton(
            onPressed: () => open(alert: true),
            child: const Text('削除の確認'),
          ),
          SteyButton(
            onPressed: () => open(pending: true),
            child: const Text('処理中の終了制御を確認'),
          ),
          SteyButton(
            onPressed: () => open(noActions: true),
            child: const Text('閉じるアイコンを確認'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Semantics(liveRegion: true, child: Text(result)),
    ],
  );
}

/// English, deterministic content used only for official-source comparisons.
class LayerDialogSample extends StatefulWidget {
  const LayerDialogSample({super.key, required this.parameters});
  final Map<String, String> parameters;
  @override
  State<LayerDialogSample> createState() => _LayerDialogSampleState();
}

class _LayerDialogSampleState extends State<LayerDialogSample> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final q = widget.parameters;
      SteyLayerDialog.show(
        context,
        title: 'Edit worker',
        description: q['description'] == 'none'
            ? null
            : 'Review your changes before saving.',
        size: SteyLayerDialogSize.values.firstWhere(
          (v) => v.name == q['dialogSize'],
          orElse: () => SteyLayerDialogSize.base,
        ),
        verticalAlign: q['align'] == 'top'
            ? SteyLayerDialogVerticalAlign.top
            : SteyLayerDialogVerticalAlign.center,
        alert: q['state'] == 'alert',
        dismissLabel: q['state'] == 'alert' ? 'Cancel' : 'Close',
        closeLabel: 'Close',
        action: q['state'] == 'no-actions'
            ? null
            : SteyLayerDialogAction(
                onPressed: () {},
                loading: q['state'] == 'loading',
                variant: q['state'] == 'alert'
                    ? SteyLayerDialogActionVariant.destructive
                    : SteyLayerDialogActionVariant.primary,
                child: const Text('Save changes'),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Worker settings are ready to deploy.'),
            if (q['state'] == 'long')
              for (var i = 1; i <= 30; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Setting $i: ready to deploy.'),
                ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
