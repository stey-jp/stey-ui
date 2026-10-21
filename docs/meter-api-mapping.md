# MeterのAPI対応

公式 `947065ad39694fdc688b1128cc9c360f566a4f73` のMeterと、公式が依存するBase UI 1.9.0のRoot／Label／Value／Track／Indicatorを参照します。KumoのMeter自体は既存比較SHA `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` から変更されていません。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| value／min／max | SteyMeter(value:, min:, max:) | 既定0〜100。有限のmin・max、max > minを指定 |
| 表示範囲 | clampedValue／fraction | 数値とバーを範囲内へ補正。NaNは下限、±Infinityは各端 |
| label | label | 12px・subtle。従来Flutter APIの省略可能ラベルを維持 |
| showValue | showValue | 既定true。通常値は範囲内位置の百分率、13px・medium・tabular numbers |
| customValue | customValue | 空でない文字列を優先表示。showValue=falseでも表示。読み上げの計算値は変更しない |
| format | NumberFormat? format | Dart intlの書式を渡す。百分率以外では範囲内の測定値を整形 |
| locale | locale | 未指定時はFlutterのlocale。通常の百分率の書式に適用。明示formatはそのlocaleを使用 |
| getAriaValueText | getAriaValueText | 整形済みテキストと補正前の値を渡す。戻り値はSemanticsのhint |
| track／indicatorのCSS | trackColor／color | ネイティブの色指定。既定fill／brand。CSSや任意DOM属性は提供しない |
| 従来のtone | tone | 明示時の色指定を維持。color > tone > brandの順で優先 |

高さ8pxの丸いバー、見出しとの8pxの余白、300msのTailwind ease-out（cubic-bezier(0,0,0.2,1)）に対応する幅変化を独立実装しています。初回は指定値を表示し、値域変更もアニメーション対象です。進行中の変更は現在の幅から開始します。動作低減設定でもアニメーションを実行するユーザー指定を維持します。RTLではバーとラベルを方向の先頭へ配置します。

数値書式のため、すでにワークスペースで使用しているintl 0.20.3をライブラリとデモの直接依存へ追加します。新しい版への更新はありません。`Intl.NumberFormatOptions`そのものや全ECMA-402オプションの移植は行わず、DartのNumberFormatで指定します。

読み上げの差があります。Flutter 3.47にはmeter役割がなく、公開SDKのprogressBarを使い、minValue／maxValue／valueを正しい数値にします。整形された表示やgetAriaValueTextはhintへ渡します。Webでは公式の`role=meter`／`aria-valuetext`と同じ意味情報にはならず、この差を完全対応として扱いません。DOMを書き換えて役割を偽装する処理は追加しません。

未認証範囲は任意の長文構成・全locale／NumberFormatの丸め差・CSS反転時の短縮規則・全画素／全フレーム・screen reader・物理実機です。CSS className／React render／任意DOM属性はFlutter APIに含みません。無効な値域（max <= min、非有限の端点）は対象外です。同期済みSHAと全体の視覚ゲートは進めません。

日本語デモは `?component=meter&mode=light`。比較用 `?sample=meter` はvalue／min／max／custom／hide／format（decimal・currency）／locale／color（green）／long／aria／target／host／direction／modeに対応します。
