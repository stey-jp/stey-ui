# SensitiveInputのAPI対応

公式 `947065ad39694fdc688b1128cc9c360f566a4f73`／Base UI 1.9.0のrender・CSS・コピー処理を参照します。SensitiveInputとuseCopyFeedbackは7e0ff40以降の差分がありません。Flutter TextFieldとClipboardを使い、React・WebViewへの実行時依存はありません。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| SensitiveInput | SteySensitiveInput | masked／revealed／emptyの3状態 |
| value／defaultValue／ref | value／defaultValue／controller | 制御／非制御、初期値、外部controllerの値・選択と所有権 |
| onChange／onValueChange | onChanged／onValueChange | 入力通知。拒否された制御値は復元 |
| size | SteySize.xs／sm／base／lg | 高さ20／26／36／40px、実際の角丸4／6／8／8px |
| variant | SteyInputVariant.standard／error | errorから自動選択。明示variantが優先 |
| label／labelTooltip／description／error／required | 同名引数 | labelがあるときだけField。文字列表示と必須・エラーの意味情報 |
| disabled／readOnly | enabled=false／readOnly | 無効時の操作抑止、読み取り専用時の表示切替 |
| aria-label | semanticLabel | 編集欄の名前。伏字の操作名は表示label、なければSensitive value相当 |
| autoComplete | autofillHints | 既定は空リスト。HTML autocompleteの全値との等価性は未認証 |
| onCopy | onCopy | Clipboard.setData成功時の通知 |
| コピー失敗 | onCopyError | Flutter向けの任意callback。失敗時に成功通知を出さない |

値がある初期状態では実際の長さによらず8個の伏字を表示し、編集欄のSemanticsを隠して、機密値を操作名へ含めません。マウスで伏字に重なるか、グループ内にfocusがあると「クリックして表示」へ切り替えます。クリック／Enter／Spaceで表示し、readOnlyでなければ入力欄へfocusを移します。Escapeは隠したあと外枠へfocusを返します。readOnlyの表示時に、以前focusされていた伏字入力の遅れたblurが状態を上書きしないよう、意図的な外枠へのfocus移動を保護します。SDKだけが移したfocusを編集開始とは扱わず、実際の入力操作・編集開始からのblurを検査します。空欄はpassword状態で編集可能で、最初の入力からrevealedへ移ります。外部値を空にするとmaskedからemptyへ移りますが、その後値を設定しても自動でmaskedへ戻しません。公式の遷移を保持します。

編集欄からグループの外へfocusが移ると再マスクします。コピーや目のボタンへ移る場合は表示を保持します。公式のblurハンドラーは入力欄だけにあるため、コピーへfocusした後、そこから外へ移動しても表示を保持する場合があります。この挙動も対応し、「外へ出れば常に隠れる」とは扱いません。Flutter標準のタッチ時のfocus方針、IME・選択・キャレットの全プラットフォーム一致は未認証です。

コピーは伏字のままでも使えます。上端の1px外・右8pxに、12px文字／行高16px・上下2px／左右8pxのタブを重ねます。hoverまたはfocus-withinで150msの不透明度変化を付け、透明でもTabで移動できます。ネイティブOverlayPortalで枠の外側も操作可能にし、親の寸法へ加算しません。成功表示は2秒。試行順序と破棄状態を検査し、古い非同期結果による通知の上書きと破棄後の通知を防ぎます。ブラウザのexecCommandフォールバックは追加せず、Flutter Clipboardの失敗をcallbackへ返します。

入力値・選択は表示切替で作り直しません。デスクトップのfocus時の自動全選択は無効にし、初期のキャレットとユーザーが設定した選択範囲を保持します。コピーしても値を変更しません。masked時は編集用Semanticsを除外し、読み上げには名前・非表示状態・表示操作を伝えます。日本語環境では表示／非表示／コピー・成功・説明を日本語にします。目の図形はPhosphor RegularのEye／EyeSlashをネイティブPathへ変換し、MIT noticeを保持しています。

旧版は常にpassword欄と目のボタンを表示していました。公式に合わせて、値があるときは外枠によるreveal、空欄は入力開始によるrevealへ変更しました。labelの既定値Secretも公式のlabel未指定へ変更しています。既存controller／onChanged／enabledは維持します。

日本語デモ `?component=sensitive-input` では4サイズ、空欄／サンプル値の再設定、制御／非制御、エラー・無効・読み取り専用・RTL・任意表示、コピーと隣接操作を確認できます。デモの状態表示には文字数と操作回数だけを使います。比較用 `?sample=sensitive-input` は明示した架空の値だけを使い、size／mode／host／direction／value／uncontrolled／frozen／disabled／readOnly／label／description／error／required／variantを受け取ります。

HTML全属性・Form／ValidityState・構造化error.match・rich Field、DOMの全focus／aria属性、ブラウザ拡張、IME・composing・Undo・補完・物理screen reader、全画素・全ブラウザ・全実機の一致は未認証です。公式CSSのoutline-width指定はoutline-style:noneのため、実Chromeでは描画されません。実際に見えるfocus-withinの1.5pxリングへ合わせています。画素比較は診断で、承認済み視覚ゲートや同期済みSHAを進めません。

Flutter WebのOverlayPortalが作る透明な全画面の意味情報レイヤーにより、自動操作の厳密なDOM hit-target検査が編集欄のクリックを拒む場合があります。検証では実際の表示位置をマウスでクリックし、DOM focusと入力結果を確認します。readOnlyもDOM属性だけに依存せず、実際のキー入力で値が変わらないことを確認します。SDKのDOM意味情報モデル全体を修正・認証したものではありません。

コピー操作の読み上げ名は表示と同じ「Copy／コピー」です。公式の長い名前をそのまま渡すと、Flutter Web SDKの透明なHTML要素内で折り返した文字が下の目のボタンのhit areaを覆うため、短く明確な操作名に揃えています。意味情報を隠したり、独自DOMを書き換えたりする対策は製品へ追加していません。

非表示で操作できない目のボタンはSemanticsから除外し、表示から隠す操作後は見える外枠へfocusを返します。コピーは見た目の20pxを維持し、上側に透明な4pxを加えて24pxの操作領域にします。目の図形は12／16pxを保ち、操作領域はグループ内で最大24pxへ広げます（xsは外枠20pxに制約）。これらはネイティブのアクセシビリティ上の調整で、公式DOMの全属性一致を主張しません。
