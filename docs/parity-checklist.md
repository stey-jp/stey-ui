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
| badge | 全variant、filled/dot、色、beta破線、リンク内hover | 静止サンプルあり。リンク内と全機能待ち |
| banner | variant、icon、本文、action、dismiss、折返し | 全API・機能・視覚比較待ち |
| breadcrumbs | link/current、separator、折返し、狭幅 | 全比較待ち |
| button | 全variant/size/shape、hover/focus、disabled/loading、icon、asChild | サンプルと操作テストあり。複合API・位相比較待ち |
| button-group | orientation、連結border/radius、size伝播、focus | 全比較待ち |
| chart | 全export、ECharts option、legend/tooltip、resize、Chart/Sankey/Globe固有操作 | 汎用option、drilldown、地形を含む実装不足 |
| checkbox | 単体/Item/Group/Legend、mixed、parent/allValues、cardの縦/横結合、error、disabled | ネイティブ描画・グループ・親の部分選択復元をテスト。イベント詳細・子との読み上げ関連付け・拡張hit area・全視覚認証待ち |
| clipboard-text | copy成功/失敗、非同期feedback、選択、tooltip、ellipsis | 全比較待ち |
| cloudflare-logo | 全export、色/size、PoweredBy、ブランド条件 | 書面許可待ち。公式ロゴ未配布 |
| code | Code/CodeBlock/CodeHighlighted、language、highlight、copy、行/折返し | 基本寸法修正済み。構文強調未実装 |
| collapsible | 制御/非制御、Trigger/Panel、hidden focus、mount、transition | 基本テストあり。全比較待ち |
| combobox | 複合parts、選択/複数、filter、portal、入力保持、キーボード、clear | 全API・比較待ち |
| command-palette | 全parts、group、filter、強調、empty/loading、shortcut、close/focus | 一部操作テストあり。全複合API・視覚待ち |
| date-picker | Calendar各mode、年境界、locale、min/max、disabled日、popover/focus | Calendarの一部操作済み。日付制約等の全比較待ち |
| date-range-picker | 開始/終了、range hover、連続月、制約、確定/取消 | 全比較待ち |
| dialog | 全parts、制御/非制御、modal、portal、scroll/focus lock、Escape/外側、復帰 | 基本開閉テストあり。全比較待ち |
| dropdown | Item/Group/Separator/Checkbox/Radio/Submenu、disabled、keyboard、位置/衝突 | 全比較待ち |
| empty | variant、icon、title、description、action、狭幅 | 全比較待ち |
| field | 全parts、validation match、error/helper優先、label、required/optional、ID | 一部読み上げ済み。全validation match待ち |
| flow | 全export、接続/edge、layout、選択、pan/zoom、keyboard | 全比較待ち |
| grid | 全export、columns/gap、breakpoints、overflow | 全比較待ち |
| inline-copy-text | copy、feedback、本文/tooltip、幅制約 | 全比較待ち |
| input | 全type/size、focus/error、readOnly/disabled、addon、validation、制御/非制御 | 描画・読み上げサンプルあり。全API比較待ち |
| input-group | parts、padding、border/ring、icon/addon、disabled/focus | 全比較待ち |
| label | tooltipのkeyboard/touch、optional、asContent、関連付け | 情報ボタンのタッチ・keyboardと読み上げテスト済み。全比較待ち |
| layer-card | 複合parts、nested radius、header/footer、border、responsive | 全比較待ち |
| layer-dialog | 層構造、全parts、modal/focus、scroll、sticky境界 | 全比較待ち |
| link | variant、外部link、visited/hover/focus、disabled、asChild | 全比較待ち |
| loader | 全size、三点の位相/opacity、loop、ラベル | 周期テストあり。公式との位相を揃えた視覚比較待ち |
| menubar | 全parts、左右/上下、Submenu、focus、selection | 全比較待ち |
| meter | 値域、境界、variant、label、読み上げ | 全比較待ち |
| pagination | page/count、境界、ellipsis、size、keyboard、狭幅 | 全比較待ち |
| popover | 全parts、anchor、衝突、開閉、dismiss、focus、portal | 全比較待ち |
| radio | Group/Item/Legend、inline/card/segmented、description、矢印/Tab、generic値、rich label | RawRadioの操作・native描画・縦/二列グループを追加。イベント詳細・フォーム・拡張hit area・全視覚比較待ち |
| select | 全parts、placeholder、groups、disabled、多選択、search/typeahead、position | native overlay、複数選択、group/disabled、readOnly、typeahead、画面端の反転を追加。Form・任意anchor/trigger・SDKのWeb役割制約・全比較待ち |
| sensitive-input | reveal/copy、focus/value保持、type、エラー、disabled | reveal/valueの基本テストあり。全比較待ち |
| sidebar | 全parts、expanded/collapsed、peeking/mobile、resize、sliding views、navigation | resize/状態保持テストあり。peeking/mobile sheet等待ち |
| slider | 値域、step、複数thumb、orientation、keyboard、label/tooltip | 全比較待ち |
| surface | variant、境界、nested構成、padding、theme | 全比較待ち |
| switch | 単体/Item/Group/Legend、default/neutral、3size、busy、150ms遷移 | ネイティブ描画・グループ・操作テスト追加。全API・位相比較待ち |
| table | 全parts、選択、sort、sticky、スクロール、空/忙しい状態 | 全比較待ち |
| table-of-contents | active位置、scroll spy、anchor、sticky、階層/狭幅 | 全比較待ち |
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
