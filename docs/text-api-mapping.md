# TextのAPI対応

参照：Cloudflare Kumo `947065ad39694fdc688b1128cc9c360f566a4f73` の`text.tsx`と公式のCSS。
Textと該当スタイルは`7e0ff40`から差分なしです。型メタデータに古いサイズ表があるため、実際のCSS変数と実Chromeのcomputed styleを正本として照合します。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| body / secondary / success / error | SteyTextVariantの同名 | 通常・補足・link色・danger色。successは緑ではなく公式のlink色 |
| xs / sm / base / lg | SteyTextSizeの同名 | 本文12／13／14／16px。boldはfont-mediumに相当する500 |
| heading | SteyTextVariant.heading | 既定16px／24px行高、lgは20px／28px行高。600の太さ |
| heading1 / heading2 / heading3 | 同名のvariant | 非推奨互換の30／24／16px、行高36／32／24px。外観だけでは意味情報の見出しにならない |
| mono / mono-secondary | mono / monoSecondary | 既定13px、lgは14px。boldは適用せず親の太さを保持。既存のOFLフォントRoboto Monoを使用し、公式のOS別等幅フォントとの差は残る |
| line-height:inherit | DefaultTextStyle | 本文と等幅は親のfontSize×heightの計算済み行高を保持。子のサイズへ親の倍率を掛け直さない。親がnormal相当で行高未指定の場合は1.5で補完 |
| as=h1..h6 / 装飾用span | headingLevel=1..6 / 0 | FlutterのheadingLevelで意味情報を付与。見出しの外観と階層を分離。Web SDKが生成済みの見出し要素のレベルを変えないため、変更時はSemantics境界を再作成。元のHTMLタグを指定するAPIではない |
| children | String / SteyText.rich(InlineSpan) | 複数の文字装飾を組み合わせる。任意ReactNodeのDOM構造とは異なる |
| truncate | truncate | 一行・ellipsis・狭幅。読み上げには元の全文を保持。空文字は行の高さを確保しない |
| aria-label | semanticLabel | 表示と異なる読み上げ名。省略表示でも全文の意味情報を保持できる |
| direction / alignment | Directionality / textAlign | RTL・折り返し・文字方向、親のTextScalerで拡大 |
| default font / weight / tracking | DefaultTextStyle | 通常の書体・太さ・字間を継承。コンポーネント自身で字間を詰めない |
| as=p/span/label/dt/dd/li/figcaption/legend/pre/code/em/strong/small/abbr/time | 未対応 | HTMLの役割・inline/block formatting、label関連付け、日時・略語の属性、em/strongのUA装飾等はDOM互換でない |
| DANGEROUS_className / style / ref | 未対応 | 任意CSS・HTMLElementは扱わず、Flutterの親Widget・InlineSpan・キーで構成 |

旧Steyの`heading`（1〜4の30／24／20／16px、行高1.5）と`subtle`を維持します。`variant`明示時は新しい仕様を優先し、`headingLevel`は旧APIの意味情報も上書きできます。新しいheading系variantで`headingLevel`を省略すると装飾用の文字として扱います。公式の旧heading variantで必須の`as`を型で強制する仕様と、Dartのenum引数の型は同一ではありません。

選択はFlutter標準のSelectionAreaを親に置く構成であり、HTMLの通常選択、コピー・選択時の意味情報・DOMの空白圧縮／preformatted等との全一致は未認証です。全画素・任意フォント／rich span／長文・物理screen reader・他ブラウザ／全プラットフォームは残件です。検証範囲と実測値は[検証結果](verification.md)に保持します。
