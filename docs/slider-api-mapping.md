# SliderのAPI対応

公式 `947065ad39694fdc688b1128cc9c360f566a4f73` のSliderと、継承元のBase UI 1.9.0を参照します。KumoのSlider本体は既存比較SHA `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` から変更されていません。公式が許可する向きは水平のみです。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| value／defaultValue | SteySlider(value:, defaultValue:) | 制御／非制御。非制御の既定はmin |
| 配列のvalue／defaultValue | SteySlider.range(values:, defaultValues:) | 複数つまみ。値を昇順に並べて範囲内へ補正。rangeの既定は[25,75] |
| min／max／step | 同名の引数 | 既定0／100／1。有限のmin < max、正のstepを指定 |
| 従来のdivisions | divisions | step省略時だけ(max-min)/divisionsを使用 |
| largeStep | largeStep | 既定10。Shift＋矢印・Page Up／Downで使用 |
| minStepsBetweenValues | minStepsBetweenValues | stepに掛けた間隔。つまみ数と値域に収まる非負整数 |
| thumbAlignment | SteySliderThumbAlignment | edge／center／edgeClientOnly。ネイティブではedgeClientOnlyもedgeと同じ |
| thumbCollisionBehavior | SteySliderCollision | push／swap／none。ドラッグ時の押し出し・入替・停止 |
| size | SteySliderSize | base：32px、sm：24px。つまみ幅16px、内側余白3px |
| label | label／labelWidget | 文字列または任意Widget。nullで非表示。従来の既定Valueを維持し日本語では「値」 |
| disabled | disabled | 全体の不透明度50%、ポインター・キー操作を停止 |
| format／locale | NumberFormat? format／locale | Dart intlによる書式。上下限と常時表示の値バッジへ適用 |
| getAriaLabel | getAriaLabel(index) | つまみごとの読み上げラベル。semanticLabelで全体を指定可能 |
| getAriaValueText | getAriaValueText(formatted,value,index) | 読み上げ値。2つまみの既定値には開始／終了の説明を追加 |
| onValueChange | onValueChange(List<double>,details) | scalar／range共通の配列。理由とactiveThumbIndex、cancel()を提供 |
| onValueCommitted | onValueCommitted(List<double>,details) | 変更したポインター操作の終了時に1回、変更したキーごとに1回 |
| 従来のonChanged | onChanged | scalarはdouble、rangeはList<double>。キャンセルされなかった変更で通知 |
| 確定の簡易callback | onChangeCommitted | scalarはdouble、rangeはList<double> |

制御値を渡して変更callbackをすべて省略した場合は、従来APIとの互換性のため無効になります。詳細callbackだけを渡して制御値を更新しない使い方も可能です。初期値・制御値はstepへ強制丸めせず、操作時にminを基準として丸めます。NaNはmin、±Infinityは各端へ補正します。値域の端点は有限値を指定してください。

矢印・Shift＋矢印・Page Up／Down・Home／End、RTL、最近傍つまみの選択、つまみを掴んだ位置の保持、同値時の選択順、変更取消、操作中のつまみ数変更と無効化に対応します。キー操作では隣のつまみを越えず、最小間隔を満たさない変更は通知しません。ドラッグのpushでは押された隣のつまみは戻りません。公式RTLの範囲Indicatorは物理方向の余白で8px左へ寄るため、その配置も保持します。

Material Sliderの全画面OverlayPortalは使わず、Flutterの描画・Focus・Semantics・ポインター入力で実装します。隣のボタンが透明overlayに遮られる問題を解消します。暗黙の初期フォーカスでは枠を表示せず、Tab／矢印のキーボード操作やアクセシビリティフォーカスで表示します。

意味情報には公開SDKの制約が残ります。Flutter Webは内部のrange入力を相対増減用の代理値として作成するため、aria-valuenow／min／maxは実値になりません。実値はaria-valuetextへ渡します。またSDKはポインター操作後500msの間、この入力を一時無効化します。コンポーネントの無効時には増減actionがなくなり、Web DOMではslider役割自体が出力されません。ネイティブのSemanticsにはslider属性を保持します。DOMを書き換える対処は加えていません。ブラウザー比較では代理の数値属性を一致と扱わず、読み上げ文字列・操作後の値と通知回数を確認します。

未認証範囲はHTML Form／name／form連携、ReactのeventDetails・render・任意DOM属性、全NumberFormatオプションとlocaleの丸め、任意の長い値・大量つまみ・文字拡大、タッチスクロールとの全競合、screen reader・物理実機・全画素です。理由はtrackPress／drag／keyboard／accessibilityを提供し、Reactの入力イベントそのものは移植しません。同期済みSHAと全体の承認済み視覚ゲートは進めません。

日本語デモは `?component=slider&mode=light`。範囲・サイズ・小数・最小間隔・RTL・取消・無効・衝突方式を切り替えられます。比較用 `?sample=slider` はvalue／values／min／max／step／largeStep／gap／size／alignment／collision／locale／format=decimal／noLabel／disabled／uncontrolled／cancel／frozen／host／direction／modeに対応します。
