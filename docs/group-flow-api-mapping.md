# ButtonGroup・FlowアンカーのAPI対応

参照はKumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a`。

| 公式の仕様 | Flutter側 | 対応範囲 |
| --- | --- | --- |
| ButtonGroup | SteyButtonGroup | 内容幅、1pxの境界共有、外側だけの角丸 |
| primary / destructiveの上辺 | SteyButton | 公式の1px inset highlightを描画。グループ内でも保持 |
| focus-visibleの重なり | 専用RenderBox | フォーカスした子を最後に描画・優先してhit test。子とTabの順序は維持 |
| Tooltip / LinkButtonを含む子 | SteyButtonを内部に持つWidget | Tooltip・SteyLink・Dropdown triggerへ形状を継承 |
| group / aria-label | Semanticsのcontainer / label | nativeのグループと名前を公開。実Chromeでもrole=groupを確認 |
| 縦配置 | vertical: true | 既存Flutter APIを維持する拡張。公式の標準は横配置 |
| Flow.Anchor start / end / both | SteyFlowAnchorType | 送出／受入／両方の接続を実際のアンカー中央へ合わせる |
| margin付きNode | SteyFlowNode.margin | 正負の外側余白・内部移動を含めdiagram座標へ1回だけ変換 |
| custom render | SteyFlowNode(custom: true) | 任意のnative Widget。width / heightでフレーム寸法を指定 |
| 内容変更 | アンカーのRenderBox計測 | アンカーのサイズ変更・登録解除とノード寸法更新へ追従 |
| connector | CustomPainter | 線幅2px、最大角丸8px、2px以内は直線、8px手前の丸い矢印、disabledは40% opacity |
| ノードの読み上げ | Semanticsのlist / listItem | 技術IDを読まず、見える内容を階層として公開 |
| 配置間隔 | gap / verticalGap / padding | 既定64px / 16px / 左右16px・上下64px |

ButtonGroupはWidgetの順序を変えずに描画とhit testの順序を変えるため、状態と意味情報を保持します。
LayerDialogのsplit actionにも同じ連結表示を適用します。
任意のMaterialボタンや独自装飾の内部までは自動で再設計しません。

```dart
SteyFlowNode(
  'service',
  const SteyFlowAnchor(
    type: SteyFlowAnchorType.start,
    child: SizedBox(height: 40, child: Text('サービス')),
  ),
  custom: true,
  width: 120,
  height: 40,
  margin: const EdgeInsets.only(top: -4),
)
```

Flowは既存のnodes / edgesによるDAG APIを維持しています。
公式のList / Parallelの全構成、隣接Parallel間の接続規則、内容からの自動寸法決定、
vertical / align=end、canvasの全pan・scrollbar挙動は未完了です。
今回の画像比較は寸法を固定したカスタムアンカーのcanvas表示とButtonGroupであり、
Flow全体・全物理実機・全screen readerの完全一致認証ではありません。
