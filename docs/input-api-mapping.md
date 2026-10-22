# Input／InputAreaのAPI対応

公式 `947065ad39694fdc688b1128cc9c360f566a4f73` とBase UI 1.9.0を参照します。実際のrender・CSSを正本とし、ソース内の旧KUMO_INPUT_STYLING定数にある16pxや固定幅は採用しません。React・WebViewへの実行時依存はありません。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| Input | SteyInput | Flutter TextFieldによる単一行の編集・選択・コピー |
| InputArea／Textarea | SteyInputArea | 既定2行。ネイティブの複数行編集 |
| 既存SteyTextarea | SteyTextarea | 既定4行を互換のため保持。新規APIはInputAreaと共通 |
| size | SteySize.xs／sm／base／lg | 高さ20／26／36／40px、左右余白6／8／12／16px、角丸2／6／8／8px |
| variant | SteyInputVariant.standard／error | 省略時は非空errorで自動的にエラー色。明示standardは自動色より優先 |
| value | value | 制御モード。親からの更新を反映し、拒否された編集値はフレーム末尾で戻す |
| defaultValue | defaultValue | 非制御の初期値。後の変更だけでは既存入力値を書き換えない |
| refでの値・選択操作 | controller | 呼出側が所有するTextEditingController。valueとの同時指定は禁止 |
| onChange／onValueChange | onChanged／onValueChange | Formatter適用後の文字列。両方指定すればそれぞれ1回通知 |
| Enter | onSubmitted／textInputAction | 単一行の確定。複数行は既定で改行 |
| disabled／readOnly | enabled=false／readOnly | 無効はfocus不可、読み取り専用はfocus・選択可能 |
| required | required | Semanticsの必須状態。明示falseのみ任意表記を付ける |
| label／labelTooltip | label／labelTooltip | 文字列。ラベルのクリックで入力欄へfocus。情報ボタンは独立 |
| description／error | description／error | 説明と文字列エラー。エラー優先で説明を隠す |
| aria-label | semanticLabel | 既定はlabel、なければplaceholder。明示名が表示labelより優先 |
| aria-invalid相当 | validationResult | 非空errorでinvalidを通知。variantだけではinvalidを立てない |
| native type／autocomplete | keyboardType／obscureText／autofillHints | Flutterの入力設定。HTMLの全type・属性の等価置換ではない |
| rows | maxLines | 固定表示の行数。InputAreaでは2、既存Textareaでは4 |
| autoResize／minRows／maxRows | 同名引数 | 内容と利用可能幅に応じた伸縮、最小行数、最大行数と内部スクロール |
| 旧prefix／suffix | prefix／suffix | Flutterの拡張を保持。独立した操作ボタンも置ける |

文字はInter Regular。xs／smは12px・行高16px、base／lgは14px・行高21pxです。外側1pxのlineリングは内容幅を消費せず、focus時は1.5px・focusの50%になります。エラー色はtext-dangerではなくcolor-dangerを使い、公式の重要指定に合わせてfocus時もdangerの全不透明度を維持します。disabledでは文字をinactive色へ変え、背景・リング・placeholderを一律に薄くしません。Materialの枠アニメーションに依存せず、状態変更を即時に描画します。

Fieldのラベル・説明・エラーは8px間隔です。公式はlabel未指定でもdescription／errorでFieldを作り、空のlabelにも21pxの行とその後の8px間隔が残るため、その高さも保持します。既定の任意表記と情報ボタン名は日本語環境で「（任意）」「詳しい情報」へ切り替えます。Inputの意味情報では明示semanticLabelが最優先です。HTMLのaria-labelledbyがaria-labelより優先される規則と同じ属性モデルではありません。

InputAreaは上下8pxの余白と固定行高で伸縮します。自動調整を無効へ戻しても値を保持します。上限なしの自動調整はmaxRows未指定、上限ありは超過内容を入力欄内でスクロールします。固定行数で長文を入れた場合も値は省略・破棄しません。Flutterのスクロールバーと選択・キャレットはプラットフォーム依存で、ブラウザの手動resizeハンドルやtextarea固有のscrollbar CSSは再現しません。

公開Widgetには有限の横幅を与えて使用します。prefix／suffix・任意の複合構成、文字拡大時の切れ方、IME変換・候補UI、controlledの拒否時とcomposingの競合、Undo／Redo・入力補完、タッチ選択・物理screen readerは未認証です。Flutterの公開Semantics APIを使い、独自のDOM編集・WebView・Reactは追加しません。デモに以前から存在する入力要素への識別ID付与は今回変更していません。

HTMLの全type（date／color／file／number等）、name付きのネイティブForm送信、pattern・min／max／step・minLength／maxLength、ブラウザValidityStateによる構造化error.match、cancel可能なイベント詳細、passwordManagerIgnoreの拡張機能向けdata属性・keeper-ignore、任意のReactNodeやCSSクラスは未対応です。requiredとerrorは意味情報・表示へ反映しますが、ブラウザのForm検証を代替しません。Label／Field／InputGroup全体のAPI認証とは分けます。

日本語デモは `?component=input`。4サイズ、エラー・disabled・readOnly・制御モード・文字の秘匿・複数行自動調整・RTL・任意表記と隣接ボタンを操作できます。比較用 `?sample=input` はsize／label／description／error／required／variant／disabled／readOnly／value／controlled／frozen／area／auto／minRows／maxRows／rows／host／direction／modeに対応します。password／type／tooltipもサンプルへ渡せます。公式との比較用サンプルは英語Localeへ固定し、ギャラリーの日本語表示と分けます。視覚比較は診断用で、同期済みSHA・承認済み視覚ゲートは進めません。

7e0ff40以降の公式Inputの差分はdisabledの文字クラスがkumo-disabledからkumo-inactiveへ変更された点です。InputArea・Field・styleソースの差分はありません。最新のinactiveトークンを生成元にも登録しています。

実Chromeの比較では隣接ボタンへfocusをそろえてから各状態を操作します。Flutter Webのroute既定focusが最初の入力へ移る場合があるため、初期focusは別項目に保持します。HTMLの初期focus・autofocusとの完全一致は認証しません。

実行したブラウザ検証は実Chromeです。Firefox／Safari／Edge固有の動作や主要ブラウザの旧2世代は未検証です。Windows／Androidはリリースビルド確認までで、Linux／macOS／iOSと全物理実機も今回ソースでは未検証です。
