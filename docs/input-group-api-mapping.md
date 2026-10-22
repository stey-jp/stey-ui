# InputGroupのAPI対応

公式 `947065ad39694fdc688b1128cc9c360f566a4f73`／Base UI 1.9.0の実際のrenderとCSSを参照します。7e0ff40以降のInputGroupソースには差分がありません。未使用のKUMO_INPUT_GROUP_VARIANTSではなく、実際に呼ばれるinputVariantsの高さを採用します。React・WebViewへの実行時依存はありません。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| InputGroup | SteyInputGroup(children: ...) | 直接の子から共有枠／個別枠／混合枠を自動判定 |
| InputGroup.Input | SteyInputGroupInput | TextFieldによる編集・選択。親からsize／disabled／errorを継承 |
| InputGroup.Addon | SteyInputGroupAddon | childまたはchildren、start／end、6px間隔、アイコンサイズ継承 |
| InputGroup.Suffix | SteyInputGroupSuffix | 接尾辞。入力値に応じた入力幅と残り幅、長文の省略、操作の透過 |
| InputGroup.Button | SteyInputGroupButton | variant／size／shape、icon、loading、disabled、focusNode、tooltip、semanticLabel |
| 旧Label／Description | SteyInputGroupLabel／Description | 非推奨の互換名。Labelは公式と同じく混合形式の判定対象外 |
| size | SteySize | 高さ20／26／36／40px、角丸4／6／8／8px |
| label／description／error／required／labelTooltip | 同名引数 | labelがある場合のみField。文字列のエラー・説明・情報表示 |
| value／defaultValue／ref／onValueChange | value／defaultValue／controller／onValueChange | Inputと共通の値管理。切替時の値・focus保持、controllerの外部変更にも追従 |
| readOnly／disabled | readOnly／group.disabled | 読み取り専用の選択とfocus、グループ全体の操作抑止・不透明度50% |
| aria-invalid／required | Semantics | 入力のinvalid／required／名前。DOM属性と同じモデルではない |
| 既存child／addon／suffix | 同名引数 | 既存の8px間隔Rowを互換維持。新しいchildren形式との併用は禁止 |

明示的な非ghostの直接Buttonがなければ共有枠です。直接Buttonだけがあれば個別枠、直接Addonもあれば混合枠になります。混合枠ではAddon／Input／Suffixを先にまとめ、直接Buttonをその後へ配置します。任意のラッパー内部は自動判定しません。公式の直接の子に対する判定に合わせています。

共有枠は外側1px、focus-withinで1.5px・focus色の50%、error時はdanger色です。個別枠と混合枠の実行ボタンは内側1pxの境界を共有し、1px重ねます。入力やキーボードfocusの境界が隣接要素に隠れない順序で描画・hit testします。混合枠の入力ゾーンは1pxのborderを持ち、入力の高さは親より2px小さくなります。

Button.styleの明示値を既定値より優先するよう既存の結合順も修正し、連結ボタンの内側角丸と1pxのborder分の余白を有効にしました。強調色の背景と内側ハイライトも明示した角丸に従います。共有枠内のボタンは1段階小さくし、xs／smはxs、baseはsm、lgはbaseへ対応します。個別ボタンはグループの全高を使います。Addonのアイコンは10／13／18／20pxで、明示したIcon.sizeを優先します。通常の外側余白は6／6／8／10px、ボタン入りは4／4／4px、lgのみstartが6px・endが2pxです。入力のaddon側の余白は4／6／8／10pxです。配置と角丸は公式CSSの物理的な左右指定を基準にしています。

日本語デモ `?component=input-group` では3形式、4サイズ、接尾辞、補助テキスト、消去、実行、error／disabled／readOnly、RTL、任意表記と隣接操作を切り替えられます。比較用 `?sample=input-group` は英語Localeで、layout／size／mode／host／direction／value／frozen／disabled／readOnly／label／description／error／required／textAddon／variantを受け取ります。

公式の入力はfont-sansでOS標準フォント、Addon／ButtonはInterです。Flutterの入力は配布済みInterを使うため、入力文字と内容に応じた幅・キャレット・選択描画に差があります。OSのフォントファイルをライブラリに複製していません。外枠比較と部品の矩形・画素診断を分け、全画素一致の認証とは扱いません。

HTML Form／ValidityState、全type・DOM属性、ReactNodeのlabel／構造化error.match、cancel可能なイベント詳細はInputと同じく未対応です。tooltipは既存のMaterial Tooltipによる文字列・下側優先で、公式のrich content／4方向のtooltipSide・待機時間・衝突処理との完全一致は未認証です。任意Widgetや複数入力、ラッパー越しの配置、極端な固定Addon幅、全キーボード／IME／Undo／補完／タッチ選択・screen readerは残件です。有限の横幅を与えて使用します。

検証環境は実Chromeです。他の主要ブラウザと旧2世代、Linux／macOS／iOSと全物理実機は今回ソースで未検証です。Windows／Androidはリリースビルドまでで、ネイティブ操作の認証ではありません。診断比較ではSDKの初期focusを別に記録し、隣接ボタンへfocusをそろえて各状態を比較します。同期済みSHAと承認済み視覚ゲートは進めません。
