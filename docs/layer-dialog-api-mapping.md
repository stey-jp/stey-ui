# LayerDialogのAPI対応

参照はKumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a`。
旧名Actions.Primaryを同一のActionへ戻す公式変更 `d97d751` も反映しています。

| 公式の仕様 | Flutter側 | 対応範囲 |
| --- | --- | --- |
| Root / Content / Title / Description / Body | SteyLayerDialog.show | title・description・childを専用の多層面へ配置。通常のSteyDialogとは独立 |
| sm / base / lg / xl | SteyLayerDialogSize | desktop幅448 / 576 / 672 / 768px。旧width指定も維持 |
| verticalAlign | SteyLayerDialogVerticalAlign | desktop中央は上下24px、上部は64px・下24pxの余白 |
| モバイルDrawer | 640px未満のshow | 全幅の下部シート、最大85%高さ、通常時のハンドルから下スワイプで終了 |
| Action | SteyLayerDialogAction | primary / destructive、loading、関連操作のsplit menu。主操作は自動で閉じない |
| Actions.Primary | SteyLayerDialogPrimary | 非推奨typedefで同じAction型を公開。別実装は持たない |
| Actions | SteyLayerDialogActions / show(action: ...) | 型付きの主操作1個と自動dismiss。desktopはghost、mobileはsecondary |
| Alert | show(alert: true) | alertDialogの役割、背景押下では閉じない。Escと取消は有効。スワイプハンドルなし |
| dismissDisabled | show / SteyLayerDialogController | 閉じる・取消・背景・Esc・戻る・ハンドル操作を無効化。controller.closeは有効 |
| actionsRef.close | SteyLayerDialogController.close | 型付き結果を返せる。閉じ始めた後の重複closeは無視 |
| ロケール | Flutter Localizations | 閉じる・キャンセル・その他の操作を日本語／英語で切替。個別ラベル上書き可 |
| 固定見出し・操作欄 | 専用レイアウト | 本文だけスクロール。8px超スクロールかつ説明文を畳んだ後も16px超overflowがあれば説明を200msで縮小 |
| 開閉 | PopupRoute | desktopは200ms・8px移動とfade、mobileは450msの下部移動。終了中もmountを維持 |
| Modal / Focus | Flutter PopupRoute | modal barrier、閉じたfocus traversal、Esc・戻る、終了時のfocus復帰をFlutterで処理（Tab循環・復帰とソフトキーボード上の操作欄をテスト済み） |

```dart
final controller = SteyLayerDialogController<String>();
final result = await SteyLayerDialog.show<String>(
  context,
  controller: controller,
  title: 'Workerを編集',
  description: '変更内容を確認して保存してください。',
  action: SteyLayerDialogAction(
    onPressed: () => controller.close('saved'),
    child: const Text('保存する'),
  ),
  child: const Text('設定内容'),
);
controller.dispose();
```

showのFutureは終了アニメーションとrouteの破棄後に完了します。
処理中の終了を防ぐ場合はcontroller.dismissDisabledを更新してください。
loading単独では他のdismissを止めません。旧show(actions: ...)は互換用に維持し、
自動dismissを伴う新しい構成にはactionを使用します。

Reactの任意portal container・render prop・非modal Root・制御openイベントの全理由、
Drawer全体からのスワイプと速度に連動した終了時間、スクロール端のfade mask、
全split buttonの結合境界とhover、全物理実機・screen reader、完全な視覚一致は未認証です。
ハンドル以外からのスワイプは実装していません。診断画像を承認済み視覚ゲートには昇格しません。
動作低減設定時もアニメーションを維持する点は、ユーザーのグローバル指示に従った相違です。
