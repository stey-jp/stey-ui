# Kumo再現チェックリスト

参照SHA: `f46e8bc9922c37dc1d3e7da779e589fe171df306`。49コンポーネント群＋3ブロック。
全群は開発中で、完全再現の認証済み群はありません。

[機械抽出](../upstream/api-inventory.json)には、公式ソースの宣言、直接記述されたプロパティ、依存元、テスト名と行番号を記録しています。
これはTypeScriptの型検査ではありません。Base UI・DOM・Reactから継承されたAPI、再export、条件型・generic、動的なテスト名は別途確認します。
CSSのvariant一覧だけでなく、実際のrender分岐・イベント・既定値を正本として照合します。

各行の認証条件は、APIのFlutter側対応表、機能比較、全状態の視覚比較の3点です。
共通の確認軸はLight/Dark、幅320/390/768/1280、LTR/RTL、文字拡大、マウス・タッチ・キーボード、読み上げ名・役割・状態・フォーカスです。
対応する部品には制御／非制御、空・無効・読み取り専用・エラー・busy、複合部品とイベント詳細を追加します。
視覚比較は描画領域を切り出し、アニメーションは開始・中間・終了の位相を揃えます。画面全体の差分率だけでは認証しません。

| 群 | 固有の照合事項 | 現状・残作業 |
| --- | --- | --- |
| autocomplete | 候補、filter、空、無効項目、highlight、キーボード、自由入力 | 継承API・機能・視覚の全比較待ち |
| badge | 全variant、filled/dot、色、beta破線、リンク内hover | 全17variant・dot、リンク祖先hoverの枠、12pxアイコン枠、単一行・空ラベルと日本語デモを追加。[API対応](badge-api-mapping.md)。任意構成・破線・全視覚・実機認証は残る |
| banner | variant、icon、本文、action、dismiss、折返し | 構造化title／description、base／sm、4variant、Banner.Actionのaccent・サイズ継承、compact inline Linkを追加。[API対応](banner-api-mapping.md)。全継承API・任意Widget・全視覚・実機認証は残る |
| breadcrumbs | link/current、separator、コピー、狭幅・省略 | 2サイズ、組み合わせAPI、640px境界の省略、Currentだけの切詰め、125px読み込み枠、2秒コピー通知を追加。[API対応](breadcrumbs-api-mapping.md)。aria-current相当・任意構成・全視覚・実機認証は残る |
| button | 全variant/size/shape、hover/focus、disabled/loading、icon、asChild | 文字位置・iconの補正、空children、全サイズとRTLの5テストを追加。全認証は未完了。[API対応](button-sidebar-api-mapping.md) |
| button-group | orientation、連結border/radius、size伝播、focus | 1pxの境界共有・外側角丸・focus描画順・RTL・wrapped childを追加。5回帰テスト。全視覚・実機認証は未完了。[API対応](group-flow-api-mapping.md) |
| chart | 全export、ECharts option、legend/tooltip、resize、Chart/Sankey/Globe固有操作 | 汎用option、drilldown、地形を含む実装不足 |
| checkbox | 単体/Item/Group/Legend、mixed、parent/allValues、cardの縦/横結合、error、disabled | ネイティブ描画・グループ・親の部分選択復元をテスト。イベント詳細・子との読み上げ関連付け・拡張hit area・全視覚認証待ち |
| clipboard-text | copy成功/失敗、非同期feedback、選択、tooltip、ellipsis | 専用入力欄・3サイズ・別値・1.5秒通知・4方向tooltip/toast・keyboard・画面端補正・追従を追加。[API対応](clipboard-api-mapping.md)。等幅glyph、選択・外部toast manager・全衝突規則・全視覚・実機認証は残る |
| cloudflare-logo | 全export、色/size、PoweredBy、ブランド条件 | 書面許可待ち。公式ロゴ未配布 |
| code | Code/CodeBlock/CodeHighlighted、language、highlight、copy、行/折返し | ネイティブ構文強調・行番号・行強調・コピーを追加。[対応範囲](code-api-mapping.md)。Shiki文法・全色の一致、HCL全文法、全状態・物理実機は未検証 |
| collapsible | 制御/非制御、Trigger/Panel、hidden focus、mount、transition | Root／Trigger／Panel・標準表示、変更取消、keepMounted、100msの高さ・fade・caretを追加。[API対応](collapsible-api-mapping.md)。hiddenUntilFound／beforematch、CSSの反転規則・全視覚・実機認証は残る |
| combobox | 複合parts、選択/複数、filter、portal、入力保持、キーボード、clear | 全API・比較待ち |
| command-palette | 全parts、group、filter、強調、empty/loading、shortcut、close/focus | 一部操作テストあり。全複合API・視覚待ち |
| date-picker | Calendar各mode、年境界、locale、min/max、disabled日、popover/focus | Calendarの一部操作済み。日付制約等の全比較待ち |
| date-range-picker | 開始/終了、range hover、連続月、制約、確定/取消 | 全比較待ち |
| dialog | 全parts、制御/非制御、modal、portal、scroll/focus lock、Escape/外側、復帰 | 基本開閉テストあり。全比較待ち |
| dropdown | Item/Group/Separator/Checkbox/Radio/Submenu、disabled、keyboard、位置/衝突 | native階層・選択・RTL、150msの開閉・即時切替、物理余白・shortcut、横反転・上下回り込み・高さ制約に対応。表示中のresize・祖先scroll・paint transform・項目数変更へ追従。矩形境界・辺ごとの余白、隠れた起点への追従とstickyによる境界内保持を追加。disabled行のfocus・500ms文字検索中のSpaceにも対応。Element／複数境界・全hide規則・継承イベント理由・無効行のWeb DOM focus・全比較は未完了。[API対応](dropdown-api-mapping.md) |
| empty | size、icon、title、description、contents、commandLine、狭幅 | 3サイズ、説明の有無によるh2、任意図版／追加内容、全文コピー・1秒通知・試行順序制御を追加。[API対応](empty-api-mapping.md)。text-balance・等幅文字・全視覚・実機認証は残る |
| field | 全parts、validation match、error/helper優先、label、required/optional、ID | 一部読み上げ済み。全validation match待ち |
| flow | 全export、接続/edge、layout、選択、pan/zoom、keyboard | List/Parallelからの自動接続、内容測定・動的再配置、縦／center／末尾揃えを追加。既存DAG・アンカー維持。背景pan・両軸wheel・overflow通知・scroll表示を追加。maxWidthでの折り返しと再配置を追加。標準ノードの自動幅・初期幅履歴・再作成時の測定を追加。全custom／入力・視覚／実機認証は未完了。[API対応](flow-api-mapping.md) |
| grid | 全export、columns/gap、breakpoints、overflow | 全比較待ち |
| inline-copy-text | copy、feedback、本文/tooltip、幅制約 | 枠なし表示・コピー値・rich child・省略・disabled・keyboard・親group・150ms fade・1.5秒通知を追加。[API対応](inline-copy-api-mapping.md)。等幅glyph、truncate=falseの長い未分割文字列、全視覚・実機認証は未完了 |
| input | 全type/size、focus/error、readOnly/disabled、addon、validation、制御/非制御 | 描画・読み上げサンプルあり。全API比較待ち |
| input-group | parts、padding、border/ring、icon/addon、disabled/focus | 全比較待ち |
| label | tooltipのkeyboard/touch、optional、asContent、関連付け | 情報ボタンのタッチ・keyboardと読み上げテスト済み。全比較待ち |
| layer-card | 複合parts、nested radius、header/footer、border、responsive | 全比較待ち |
| layer-dialog | 層構造、全parts、modal/focus、scroll、sticky境界 | 専用多層面・640pxでのシート切替、Action／Primary alias、alert・pending・split menu、固定見出し／操作欄を追加。14回帰テスト。全portal／Drawer挙動・視覚／実機認証は未完了。[API対応](layer-dialog-api-mapping.md) |
| link | variant、外部link、visited/hover/focus、disabled、asChild | 全比較待ち |
| loader | 全size、円形spinnerの回転/dash位相、SkeletonLine、loop、ラベル | 3サイズpreset・status、SkeletonLineの乱数／遅延／8px／blockHeight、日本語デモを追加。[API対応](loader-api-mapping.md)。widget software rasterの固定位相と公式を比較し、Web動作は別途検査。全Web位相・実機認証は残る |
| menubar | 全parts、左右/上下、Submenu、focus、selection | 全比較待ち |
| meter | 値域、境界、表示値／書式、label、幅変化、読み上げ | 値域・NaN／無限大補正、独自表示・数値非表示・書式・300msの幅変化と日本語デモを追加。[API対応](meter-api-mapping.md)。meter役割／aria-valuetextのSDK制約・全画素・実機認証は残る |
| pagination | compound parts、full/simple、入力/dropdown、件数選択、既知/不明総数、整数検証、境界、keyboard、狭幅 | [部分実装・全比較待ち](pagination-api-mapping.md) |
| popover | 全parts、anchor、衝突、開閉、dismiss、focus、portal | 全比較待ち |
| radio | Group/Item/Legend、inline/card/segmented、description、矢印/Tab、generic値、rich label | RawRadioの操作・native描画・縦/二列グループを追加。イベント詳細・フォーム・拡張hit area・全視覚比較待ち |
| select | 全parts、placeholder、groups、disabled、多選択、search/typeahead、position | native overlay、複数選択、group/disabled、readOnly、typeahead、画面端の反転を追加。Form・任意anchor/trigger・SDKのWeb役割制約・全比較待ち |
| sensitive-input | reveal/copy、focus/value保持、type、エラー、disabled | reveal/valueの基本テストあり。全比較待ち |
| sidebar | 全parts、expanded/collapsed、peeking/mobile、resize、sliding views、navigation | MenuSub/Item/Buttonと装飾ガイドを追加し、階層リスト・選択保持の2テストを追加。resize／sliding views検証も維持。全認証は未完了。[API対応](button-sidebar-api-mapping.md) |
| slider | 値域、step、複数thumb、orientation、keyboard、label/tooltip | 全比較待ち。標準Sliderの透明overlayがWeb意味情報のポインター操作を遮るSDK挙動も要対応。Meterデモは数値入力とボタンで操作 |
| surface | variant、境界、nested構成、padding、theme | 全比較待ち |
| switch | 単体/Item/Group/Legend、default/neutral、3size、busy、150ms遷移 | ネイティブ描画・グループ・操作テスト追加。全API・位相比較待ち |
| table | 全parts、選択、sort、sticky、スクロール、空/忙しい状態 | 全比較待ち |
| table-of-contents | active位置、scroll spy、anchor、sticky、階層/狭幅 | Title/List/Item/Group、native scroll追跡、Web hash、不正%・raw fragment・Unicode対応を追加。12件の回帰テストあり。全実機・視覚認証は未完了。API対応資料を参照 |
| tabs | parts、orientation、activation、disabled、focus、mount、overflow | 基本操作済み。全比較待ち |
| tag-input | add/remove、区切り、重複、IME、keyboard、disabled、overflow | 基本追加削除済み。全比較待ち |
| text | 全variant、element、weight、mono、truncate、折返し | 全比較待ち |
| toast | Provider/Manager/parts、queue、duration/pause、action、swipe、live region | 全比較待ち |
| toolbar | group/separator、roving focus、orientation、toggle/link | 全比較待ち |
| tooltip | 全parts、delay、keyboard/touch、衝突、close、関連付け | 全比較待ち |
| delete-resource | 全parts、確認値、pending/error、取消、focus復帰 | 全比較待ち |
| page-header | title/description/actions/breadcrumb、長文、狭幅 | 全比較待ち |
| resource-list | 全parts、loading/empty/error、選択、actions、pagination、狭幅 | 全比較待ち |

公式サンプルの静止画像がある部品も、`visual_verified` / `behavior_verified` は全仕様の比較が完了するまでfalseのままです。
視覚ゲートの承認済みfixturesへ、診断画像を無条件に昇格しません。
