# Flowの構成・自動レイアウト

参照はKumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` のflow-layout.ts／diagram.tsx／connectors.tsx。
margin付きアンカーは[既存のAPI対応](group-flow-api-mapping.md)も参照してください。

| 公式の仕様 | Flutter側 | 対応範囲 |
| --- | --- | --- |
| Flow / Flow.List | SteyFlow.composed / SteyFlowList | 順序付きの構成から接続を自動生成 |
| Flow.Parallel | SteyFlowParallel | 入れ子のList／Parallel、全entry／exitへの分岐・合流 |
| 隣接Parallel | 自動接続規則 | Parallel同士を直接接続しない。Listは最初／最後のentry／exitだけを外へ接続 |
| 空の構成 | 空List／Parallel | 接続先を作らず、順序上の間隔は公式と同じ規則で計算 |
| orientation | SteyFlowOrientation | horizontalは右端→左端、verticalは下端中央→上端中央 |
| align | SteyFlowAlign | Listの交差軸をstart／centerへ揃える |
| Parallel align=end | alignEnd: true | 横配置は右端、縦配置は下端で分岐を揃える |
| 自動幅 | autoWidth | 初期幅・最小単語幅・直前の図幅を使い、親幅変更後も履歴を保持 |
| DOM寸法測定 | native RenderBox測定 | 内容を同じlayout passで実測して配置。テキスト・custom Widgetの寸法変更へ追従 |
| 明示的な寸法 | Node.width／height、Flow.nodeWidth／nodeHeight | 指定した軸だけ固定。composedの既定は内容サイズ |
| CSS max-width | Node.maxWidth | padding込みの最大幅。短い内容は自然幅、長い内容は折り返す。widthより優先 |
| gap | gap／verticalGap | Listの主軸64px、Parallelの交差軸16px |
| padding | EdgeInsetsGeometry | 既定左右16px・上下64px。論理方向の指定も可 |
| canvasの有無 | canvas: false | canvas操作を挟まず自然寸法の図を返す |
| 固定viewport | viewportHeight | canvasの表示高さを固定。未指定は図の自然な高さ。親の制約を尊重 |
| canvasのパン | 背景のmouse／touch／trackpadドラッグ | ノード上では開始せず、両軸の境界で停止。慣性・zoomなし |
| wheel | PointerScrollEvent | deltaX／deltaYを独立に使用。はみ出し時は消費し、収まるときは親へ渡す |
| はみ出し通知 | onOverflowChange | `(x: bool, y: bool)`。初回と状態変化を通知し、寸法変更で位置を補正 |
| スクロール表示 | native paint | hover時に6pxのtrack、4pxの余白、最小10%のthumbを表示 |
| 読み上げでの移動 | native Semantics scroll actions | 対応軸をページ単位で移動。全screen readerの認証は未完了 |
| 既存DAG API | SteyFlow(nodes: ..., edges: ...) | 明示接続と既定160×44pxを維持。縦方向とcenterも指定可能 |

```dart
SteyFlow.composed(
  orientation: SteyFlowOrientation.vertical,
  align: SteyFlowAlign.center,
  interactive: false,
  children: const [
    SteyFlowNode('start', Text('受信')),
    SteyFlowParallel([
      SteyFlowList([
        SteyFlowNode('check', Text('入力を確認')),
        SteyFlowNode('save', Text('保存')),
      ]),
      SteyFlowNode('queue', Text('通知キュー')),
    ], alignEnd: true),
    SteyFlowNode('end', Text('完了')),
  ],
)
```

ノードIDは図の中で一意にしてください。IDは読み上げず、表示内容をlistItemとして公開します。
ノードのWidget状態・focusをGlobalKeyで保持したまま座標を更新します。
自動寸法の子にExpandedなど有限の幅が必要なWidgetを置く場合はwidthを指定してください。
自然寸法の測定と座標計算はRenderBoxで行い、DOMやFlutter SDKの書き換えは行いません。
標準ノードの影は公式の2層とringを再現し、CSSとFlutterの描画順・blurの定義を補正しています。

自然寸法の既存比較は公式側の幅1000pxホストで行っています。
追加の最大幅比較は160／280／320pxのcanvasで、公式のCSS max-width指定と照合します。
maxWidthは外側の幅（既定paddingを含む）です。widthと併用すると小さい方を使い、
未指定の高さは折り返しに応じて計測します。短い内容を最大幅まで引き伸ばしません。
自然寸法を先に測って必要な場合だけ幅を制限するため、intrinsic APIを持たないcustom Widgetも使用できます。
親幅へ追従させる場合はLayoutBuilderでmaxWidthを計算してください。
composedのautoWidthは既定trueです。標準ノードで幅・最大幅が未指定なら、
初期の利用可能幅・単語を分割しない最小幅・自然幅と直前の図幅から寸法を求めます。
親だけを拡大・縮小しても、既に測定した図幅を保持します。内容変更時はその図幅で再計算し、
keyを変えて図を作り直すと現在の親幅で測定し直します。
公式の初期host 160px→説明128×100px、初期host 320px→288×58pxの履歴依存を再現しています。
横配置では前方のノードが図の拡大に従って自然幅へ戻り、末尾は初期幅を保持します。
計算が長い場合は1フレーム8回まで測定し、次のフレームで収束を続けます。

明示したwidth／maxWidth、customノード、intrinsic非対応の子は従来の測定を優先します。
maxWidthの明示指定は利用側で幅を制御するAPIであり、CSS auto-widthの履歴測定と区別します。
autoWidth: falseは従来の自然幅を使用します。既存DAG APIのautoWidthは既定falseです。
任意のcustom CSS／Widget、非収束レイアウトと全状態の一致は未認証です。

公式canvasの倍率は1倍固定です。旧InteractiveViewerのzoomを廃止し、公式の背景移動へ合わせました。
interactive: falseは既存の横スクロール表示を維持します（この経路ではonOverflowChangeは通知しません）。
スクロール表示は公式と同じインジケーターで、thumbのドラッグ専用操作はありません。
全screen readerと物理実機、狭い親幅・極端なmarginによる接続方向反転、
全canvas入力／視覚状態の認証は未完了です。
完全なKumo parityや同期済みSHAの更新とは扱いません。
