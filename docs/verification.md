# 検証結果（Link：2026-10-22）

これは開発プレビューの検証記録です。依頼の全完了条件は未達です。

## 過去の検証（各ソースSHA時点）

- Flutter 3.47.0 / Dart 3.13.0で `flutter analyze`：指摘0。
- ライブラリのWidget test：52件成功。キーボード、無効／loading、入力の重複しない読み上げ、フォームのrequired／optionalとエラー、Loaderの合成周期と動作低減設定、秘密表示、タグ、タブ、検索候補、ダイアログ、折り畳み、カレンダー3モードと年境界、Sidebarの読み上げ名・ドラッグの上下限・左右のキーボード操作・sliding viewsの入力保持と非表示画面のフォーカス／読み上げ除外、CommandPaletteのグループ・無効項目・Ctrl+Enter・検索・強調・loading・Escapeを検証。
- デモtest：9件成功。日本語の52群をLight/Dark・320px/390px/1280pxで描画し、例外とoverflowを検査。
- Python同期テスト：18件成功。予約前保存、再試行を合算した予算上限、受付不明時停止、失敗要求だけの再処理と成功結果の保存、競合とパス制限、ドキュメント更新時のAI不使用、再処理防止、ライセンス変更時停止、提案適用からPR作成までの模擬フロー。
- Webリリースビルド成功。Wasm＋JavaScriptフォールバック、ローカル配信、ソースマップ、`-O4`。生成mapへビルド入力ソースを埋め込み、Flutter loader mapも配信。
- Windowsリリースビルド成功。このWindows PCで起動、ボタンの反応、disabled／loadingの無反応、Light/Dark、状態保持を実操作で確認。
- AndroidリリースAPK成功（開発用署名、49.6MB）。API 36エミュレーターで起動、ボタンの反応、disabled／loadingの無反応、Light/Dark、状態保持、実行時エラー0件を確認。
- Linuxリリースビルド成功。Ubuntu 24.04.5 x64の専用コンテナ／Xvfb仮想画面／ソフトウェア描画で起動、ボタンの反応、disabled／loadingの無反応、Light/Dark、状態保持を操作して確認。GTKの設定スキーマとアクセシビリティbusを用意した後は、実行ログにエラーはありません。物理Linux PCや全機能・screen readerの実操作検証は未実施です。

Selectの追加9テストで、単一／複数選択・グループ・無効項目・文字検索・readOnly・Escape／Tab・フォーカス復帰・戻る操作・画面端の反転・SafeArea／キーボード領域回避を確認しました。

Checkbox／Switchの追加10テストとRadioの追加5テストで、親の部分選択復元・無効な子の扱い・混合状態・ラベルtooltip・Space／Enter、150msの遷移、カードとsegmented、制御状態、RTLと文字拡大を検査しています。

実ChromeでもLight/Darkで、Checkbox／SwitchのpointerとSpace、Radioのカード／segmented・左右矢印・無効項目スキップ・循環を確認しました。
Selectは開いた一覧を含めて実ChromeのLight/Darkで単一／複数選択・無効項目・readOnly・End／Enter・Escapeを確認しました。開いた一覧の追加IssuesはSDKの既知Deprecation以外0件です。
混合CheckboxのWeb読み上げ状態は後述のSDK問題が残ります。

Androidではギャラリーのコンポーネント選択（SteySelect）を開き、下端がシステム操作領域の手前で止まることと、戻る操作で一覧だけが閉じることを追加確認しました。続く項目選択の検証中にエミュレーターが終了したため、Selectの全操作確認済みとは扱いません。

最新のビルド・起動・操作は同じ範囲ではありません。各検証のソースSHAは別添JSONに記録しています。WindowsのCheckbox操作とLinuxのボタン操作は過去SHAで、Androidのボタン操作もSelectの外枠・行高修正前です。最新のRadio／Selectを全native環境で操作確認済みとは扱いません。

模擬フローではネットワーク／課金／GitHub書き込みをfakeにしているため、実OpenAI APIや実同期PRの成功は示しません。

## 完全再現の未達

49コンポーネント群＋3ブロックの一覧は upstream/inventory.json に記録。
51群に基本のネイティブ実装と操作例を用意しましたが、全プロパティ・全状態・全複合部品との一致は未認証です。
特にSidebarのpeeking・mobile sheet・全複合API、CommandPaletteの全複合API、汎用ChartのECharts全option、Sankeyのdrilldown、Globeの地形、CodeHighlightedの構文強調、フォームの全検証match等が残っています。Sidebarのリサイズとsliding viewsは実装・操作テスト済みですが、全仕様の再現とは扱いません。旧Code／CodeBlockは公式の透明背景／10px padding・6px radius・borderへ修正。
CloudflareLogo／PoweredByCloudflareのアセットは公式商標ガイドラインにより書面許可待ちです。

公式固定SHAのButton/Badge/Inputを152サンプル（Buttonの6variant×5状態とサイズ／形状、Badge全variantのfilled／dotを含む）で描画し、実Flutter描画とピクセル比較しました。
この旧152サンプルは比較環境のReactが19.3.0で、公式lockfileの19.2.0より新しい版でした。予備比較として記録を保持しますが、公式固定依存での全認証とは扱いません。
今回のCheckbox／Switchの144サンプル、Radioの32サンプル、Selectの64サンプルでは、React／React DOM 19.2.0、Base UI 1.9.0、Phosphor 2.1.10、Tailwind 4.3.3を公式lockfileと一致させています。主要依存と候補ソースSHA・Wasmのハッシュを記録し、Selectでは比較画像のハッシュも記録しました。
Checkbox／Switchの描画領域の差分は最大約8.95%、Radioは最大約21.6%で、完全一致の認証ではありません。Radioはグループ無効化時の濃さと、円の物理pixel位置を公式描画に合わせて修正しました。文字・線のラスタライズを含む差分が残ります。
Selectは4サイズ×8状態×Light/Darkを比較しました。描画領域の最大差分は約15.2%から約5.73%へ減少しました。外枠の物理pixel位置・半pixel時の丸め・角の半径、ポップアップの影、pointer／keyboardのfocus状態、xs/smの16px行高を修正しています。文字・細線の描画差と、位相を同期していないloadingの差分が残るため、全視覚認証とは扱いません。比較した最新のソースSHAは `78d9a277b7a7bc8fd523274ea29e721aad3cc9be` です。

フォント、ボタンのグラデーション、色の混合、寸法、外側ring、Hintの標準文字間隔を修正しました。43色×Light/Darkの86トークンを公式CSSのブラウザ描画と比較し、背景へ合成後の各色成分は1以内の差でした。Tailwindの値は公式lockfileと同じ4.3.3のpaletteを参照し、var()のfallbackを誤って優先しないよう修正しました。
Browserの標準root font-sizeは16pxを維持し、Flutterの文字スケール計算が誤って0.875倍になる問題を修正しました。標準font-sizeを20pxへ変更した場合にも、文字とボタンが拡大することを実Chromeで確認済みです。
loading画像は公式とFlutterのアニメーション位相を同期しておらず、周期と操作性は別のWidget testで検査しています。静止画像の差分には描画エンジンの文字・線のラスタライズ差も含みます。
最終差分と品質監査は [計測記録](verification-record.json) を参照。
全面積に対する差分比率だけでは小さなコンポーネントの一致を証明できず、全状態の機能比較も必要です。
背景以外の描画を囲む領域でも差分を算出しました。文字だけのghostボタンでは、その狭い領域の差分が約21%あり、画像全体の差分率が小さいことを「完全一致」とは扱いません。
承認済みの全コンポーネント視覚基準は未整備で、upstream/visual-fixtures.json は空です。
この状態の自動同期は視覚ゲートで停止することを確認しています。全52群×Light/Darkの104組が揃わない場合も失敗として扱い、一部の基準だけでは成功にしません。104組の揃いだけで全状態の再現を認証するものではありません。

## Web品質

実Google Chromeで52群×Light/Darkとトップページの106 URLをCDP Audits.issueAddedで監査しました。トップページのモバイルLight/Darkも含め、計108画面条件です。
読み上げ名の自社実装、生成入力要素の一意ID、URL履歴を修正し、Mobileアクセシビリティ100／SEO100を確認。
コンポーネント／テーマのURL保存とブラウザの戻る／進むを実操作で確認。
日本語化前のLighthouseはMobile：Performance 84 / Accessibility 100 / Best practices 81 / SEO 100、Desktop：84 / 96 / 81 / 100です。実行警告はありません。非スコア項目を含む全監査指摘を別添JSONに記録しています。監査内の画像本体はハッシュとサイズへ置き換え、指摘・診断値は保持しています。

残るエンジン由来の指摘：Flutter 3.47.0のbrowser detectionがIntl.v8BreakIteratorを参照するためDeprecationIssueが出ます。
混合CheckboxもnativeのCheckedState.mixedを設定していますが、Flutter WebのSemanticCheckable.updateがaria-checkedをtrue／falseで上書きし、実Chromeではfalseになります。DOMの後付け変更は採用していません。
Wasm／フォントの配信サイズとSkWasmの未同梱source mapは、製品機能・フォント・デバッグ情報を保持する条件で残っています。生成JavaScriptのglueとbootstrapは圧縮し、実際の元コードを含むソースマップを配信しています。
Desktopのアクセシビリティ96は、36pxのSidebar行がviewportの下端で2pxだけ表示される際、Flutterの意味情報DOMがその部分を操作領域として公開することによります。非表示化や間隔の拡大で公式の操作・デザインを変える対策はしていません。
新しいstable SHA `abaf9c523780a608bd46686fd5e53740a07077f8` の公式ソースにもv8BreakIterator参照が残っていることを確認しました。SDKの更新は行っていません。
Flutter SDK改造や計測時だけの起動抑止、アクセシビリティ無効化はしていません。
4カテゴリ100／対応可能な全指摘0は未達です。

## プラットフォームと運用の未検証

macOS・Linux・Android・iOSのrunnerは生成済みで、ライブラリにdart:io/WebView/React依存はありません。
macOS/iOSのbuild／画面操作、Android／macOS／Linux／iOSの物理実機操作は未検証。
Android SDKライセンスはユーザー承認後に受諾済み。新しいクラウド接続は実行していません。
Androidビルドには既存SDK command-line toolsとAndroid Studioの世代差によるXML処理警告が残りますが、ビルドとFlutter doctorのAndroid toolchain確認は成功しています。

OpenAIの制限付きキーをGitHub SecretsのOPENAI_API_KEYへ保存済み。
実Batch送信→回収→PR作成は、クラウド実行が未接続のため未検証・無効です。
公式mainの更新 `dc7c513f6f2db54aa6a0b58555b7fd9e413ee3b1` をCLIで検出・解析しました。Table of Contentsの不正なURLハッシュ処理の修正です。当時未実装だったURLハッシュ／スクロール追跡は、2026-10-15に追加しました。全状態の認証は未完了です。同期済みSHAは進めていません。[差分レビュー](../upstream/latest-review.json)を記録し、Batch APIは呼んでいません。
Webデモはローカルで検証済み、公開ホスティングは未設定です。pub.devへは公開していません。

## 日本語デモの追加検証（2026-10-14）

表示・操作・読み上げラベル、起動中のHTML、manifest、カレンダーの年月・曜日を日本語化しました。日本語／英語名の検索、単一選択、コピー値と通知、削除の確認、ダイアログ、コマンドの検索・空状態、テーマ切替とURL履歴を実Chromeで確認しました。カレンダーの二桁の日付の折り返しと、320pxのプレビュー見出しの折り返しも修正・画像確認済みです。

ソースSHAは `46d778038550a293786d1151e5c8f63e516d27be`。静的解析0件、ライブラリ52件・デモ9件、Webリリースビルド成功。106 URL・108画面条件のChrome監査は実行時エラー0件、自社実装由来Issues 0件で、SDKのIntlV8BreakIteratorが108件残っています。

日本語版Lighthouse（Performance / Accessibility / Best practices / SEO）はMobile：73 / 100 / 81 / 100、Desktop：89 / 96 / 81 / 100。全カテゴリ100点は未達です。非スコア項目を含む診断はJSONの `japanese_demo` に記録しています。英語の公式比較サンプルと過去のnative検証は、それぞれのソースSHAの記録として保持しています。今回の本番反映先はユーザー指定のGitHub mainです。公開Webホスティングや新しいクラウド接続は追加していません。

forced reflowの追加診断は、生成された `main.dart.mjs` のDOM focus・幅・scroll取得に対応していました。アプリ独自のbootstrapは入力IDの付与だけを行い、layout値を読みません。SDKのフォーカス／意味情報の処理を無効化する対策は採用していません。日本語フォントと標準ローカライズを保持した状態で、エンジン起動・配信量・実行負荷の指摘が残っています。

## 目次の追加検証（2026-10-15）

ソースSHAは `3c42e158f92a85f4a6f0ae44882318d3e8c288cd`。静的解析0件、ライブラリ64件・デモ11件が成功し、Web・Windows・Androidのリリースビルドが成功しました。目次12件とRouter通知2件の回帰テストを追加しています。今回のnative実機操作とLinux／macOS／iOSビルドは未検証です。

Title／List／Item／Group、文書順の見出し追跡、150msの選択固定、offset、キー変更、破棄時の購読解除、raw %・Unicode・不正UTF-8のhashに対応しました。日本語デモでスクロール・階層・リンクを操作できます。[API対応](table-of-contents-api-mapping.md)に利用方法と制限を記載しています。

実Chromeの14項目で初期deep link、子から親への誤選択防止、履歴、キーボード、ホイール、テーマ保持、320／390pxのLight/Darkとタッチを確認し、実行時エラーは0件です。既存のギャラリーURL・入力操作の回帰確認も成功しました。Flutter Webの既定URL設定によるhash消失、base hrefによるquery脱落、engineの不正UTF-8デコードは、標準設定とデモの通知境界で修正しています。

全URLの実Chrome監査は106 URL・108画面条件、実行時エラー0件です。SDKのIntlV8BreakIteratorが108件残ります。追加の不正hash操作ではChromeのNavigationEntryMarkedSkippableが1件記録されました。スクリプトによる自動履歴へのブラウザ介入で、実際の戻る／進むと最終hash保持は成功しています。警告を無効化・除外していません。

公式固定SHAとの6状態の描画領域はすべて280×180pxで一致しています。文字サイズ・字間・字下げ・長文のclipを修正後のpixelmatch差分は1.17〜1.36%（threshold 0.1）。残る文字描画等の差分があり、全状態の視覚認証・完全一致とは扱いません。承認済み視覚ゲートへの昇格、同期済みSHAの更新は行っていません。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：70 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：91 / 96 / 81 / 100。実行警告0件。
- toc_mobile：65 / 100 / 81 / 100。実行警告0件。
- toc_desktop：92 / 96 / 81 / 100。実行警告0件。

非スコア項目を含む全監査値はJSONのtable_of_contentsへ保持しています。Flutter engineの起動・配信量、Intl.v8BreakIterator、SkWasmの未同梱source map、viewport端で切れたSidebar行の意味情報などの制限が残り、全カテゴリ100点は未達です。SDK・意味情報を改造／抑止する対策は採用していません。

新たな公式main `1846759162f8dd1cd6028738fceefd2e0cd97d66` までの更新も検出しています。LayerDialogのalias、Sidebarの意味情報、Buttonの光学的な余白、Dropdownのsubmenu更新は対応待ちです。クラウド同期は引き続き無効で、Batch APIは呼び出していません。共有CIの最新設定も公開リポジトリを対象外としています。公開Webホスティングとpub.dev公開は行っていません。

## Dropdownの追加検証（2026-10-15）

ソースSHAは `292aa0a1bd1814e5b89e9cf794677f50b2af737a`。静的解析0件、ライブラリ78件・デモ11件が成功し、Web・Windows・Androidのリリースビルドが成功しました。Dropdownの回帰テスト14件を追加しています。物理実機・screen reader、今回のLinux／macOS／iOSビルドは未検証です。

3階層のsubmenu、Group／Label／Separator、制御Checkbox／Radio、shortcut、icon slotとpopup内の自動字下げ、33px行、root 8px／横submenu 2pxの間隔、左右反転、上下矢印・Home／End・文字検索・Escape／Tab・RTLを実装しました。日本語デモで選択状態と最後の操作を確認できます。[API対応](dropdown-api-mapping.md)に制限を記録しています。

nested OverlayPortalでは画面にある子メニューの意味情報DOMが消える問題を再現したため、子メニューを独立したOverlayEntryで表示し、TapRegionをrootと共有しました。全階層のmenu／menuitem／menuitemcheckbox／menuitemradioとchecked／expandedが実Chromeに保持されます。DOM／SDKの改造や意味情報の無効化はしていません。

実Chromeの12項目で1280px Light/Dark、320px Light/Dark、390px Lightの選択・排他選択・3階層の操作1回だけの発火・開き直した状態保持・Escape・矢印とEnd／Enter・画面内のpopup位置を確認しました。実行時エラーは0件です。

全URL監査は106 URL・108画面条件、実行時エラー0件。Flutter SDKのIntlV8BreakIteratorが108件残ります。Dropdown操作監査にも同じSDK警告が5件記録され、抑止していません。

公式Dropdown SHA `1846759` と6状態を比較しました。CSS／依存は固定baseline `f46e8bc`。root 224×360px、submenu 224×111pxの寸法は一致し、threshold 0.1の差分は2.28〜2.94%です。icon・文字・影等の差分と未検証状態が残り、完全一致や承認済み視覚ゲートとは扱いません。同期済みSHAは進めていません。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：73 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：97 / 96 / 81 / 100。実行警告0件。
- dropdown_mobile：84 / 100 / 81 / 100。実行警告0件。
- dropdown_desktop：93 / 96 / 81 / 100。実行警告0件。

非スコア項目・Diagnosticsを含む監査値はJSONのdropdownへ保持しています。SDKの起動・配信量、Intl.v8BreakIterator、SkWasmの未同梱source map、viewport端で切れたSidebar行の意味情報等が残り、全カテゴリ100点は未達です。共有CIの最新設定で公開repoは対象外です。クラウド同期・実Batch往復は引き続き無効／未検証で、API費用は発生していません。本番反映先はGitHub main、公開Webホスティングとpub.dev公開は未実施です。

## Button・Sidebarの追加検証（2026-10-16）

最終ソースSHAは `00338bd4308021f053a3ac53270a0441fd7da8b9`。静的解析0件、ライブラリ86件・デモ11件が成功し、Web・Windows・Androidのリリースビルドが成功しました。新規8件で文字とiconの位置・空children・compact形状・RTL・loading、階層の意味情報／選択保持と640px境界を検査しています。Linux／macOS／iOSの今回ビルドと、全物理実機・screen reader操作は未検証です。Androidには既存SDK tools／Android StudioのXML世代差の警告が残ります。

Buttonの文字を0.5／1px上げ、先頭iconを中央へ戻し、icon＋文字の左paddingを2px減らしました。既定iconは文字の12／14pxに追従し、明示サイズは保持します。Sidebar.MenuSub／Item／Buttonに相当するnative Widgetを追加し、装飾線を入力・読み上げ対象から除外しました。展開・現在項目はボタン自身へまとめています。[API対応](button-sidebar-api-mapping.md)を参照してください。

Mobile監査で12pxのresize操作領域を検出したため、公式のhidden／sm:blockと同じ640px境界を適用しました。デスクトップの12px領域・2px線は維持し、Mobileでは実際のハンドルを描画しません。意味情報だけを消した対策ではありません。320／639pxの非表示、640／1280pxの表示とナビゲーション維持をWidget testで確認しました。

実Chromeの10項目で1280px Light/Dark、320px Light/Dark、390px Lightの空childrenボタン、階層リスト、選択保持、開閉とkeyboardを確認し、実行時エラーは0件です。全URL監査は106 URL・108条件、実行時エラー0件。残る108件のIssueはFlutter SDKのIntlV8BreakIteratorです。

公式SHA `7e0ff40` とButton 70状態・Sidebar.MenuSub 8状態を比較し、全78組で幅・高さが0.1 CSS px以内でした。Sidebarは240×69px。threshold 0.1の画像差分はButton 0.00〜16.81%、Sidebar 0.93〜1.24%です。icon・文字・影・gradient等の差分と、位相未同期のloadingが残り、完全一致の認証ではありません。画像は `e44e164db77f660859bc756967b387fc34e334b8` 時点で、後続のroot resizeハンドル切替はこのfixtureのWidgetを変えていません。比較用ページのDOCTYPE不足を修正して公式側を標準モードで再取得し、公式側のIssueは0件です。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- button_mobile：80 / 100 / 81 / 100。実行警告0件。
- button_desktop：93 / 96 / 81 / 100。実行警告0件。
- sidebar_mobile：74 / 100 / 81 / 100。実行警告0件。
- sidebar_desktop：88 / 96 / 81 / 100。実行警告0件。

非スコア項目・Diagnosticsと修正前の測定値もJSONのbutton_sidebarへ保持しています。Desktopでviewport端に2pxだけ見えるSidebar行、SDKのIntl.v8BreakIterator、SkWasmの未同梱source map、Wasm／フォントの配信と起動処理などが残り、全カテゴリ100点は未達です。SDK／DOM改造や検査時だけの機能抑止はしていません。

公式の新しいFlow更新 `7e0ff40`（margin付きanchorとconnectorの位置補正）も検出し、LayerDialog aliasと併せて対応待ちに記録しました。同期済みSHAと承認済み視覚ゲートは進めていません。公開repoは共有CIの最新設定でも対象外です。クラウド同期と実Batch往復は無効／未検証、API呼出・費用は0です。本番反映先はGitHub mainで、Webホスティングとpub.dev公開は行っていません。

## LayerDialogの追加検証（2026-10-16）

ソースSHAは `60d839ba435af18fae9a0db4408562b93f50f9a3`。静的解析0件、ライブラリ100件・デモ11件が成功し、Web・Windows・Androidのリリースビルドが成功しました。専用14テストで4サイズと640px境界、通常／alert／pendingの終了、split menu、固定見出し・操作欄と説明の縮小、短いoverflowの安定性、ハンドル操作、動作低減設定、重複close、Tab循環とfocus復帰、ソフトキーボード上への配置を検証しています。入力欄を含むdebug検証で必要なMaterial祖先も確認しました。

通常Dialogへの委譲を専用の多層面・モバイルシートへ置き換えました。Action／Actionsと非推奨Primary alias、関連操作メニュー、削除確認、処理中のdismiss禁止とprogrammatic closeを追加し、日本語デモを実装しています。[API対応と未対応範囲](layer-dialog-api-mapping.md)を参照してください。showのFutureは終了アニメーション後に完了します。

実Chromeの24項目で1280px Light/Dark、320px Light/Dark、639px・640px Lightを確認し、実行時エラーは0件です。全URL監査は106 URL・108条件、実行時エラー0件。残る108件のIssueと操作監査の6件はFlutter SDKのIntlV8BreakIteratorです。

公式SHA `7e0ff40` の28画面（4サイズ、320／390／639／640px、Light/Dark、上部配置、説明なし、操作なし、alert）と比較し、全組で幅・高さが0.1 CSS px以内でした。threshold 0.1の画像差分は0.59〜1.75%です。文字・icon・影・描画方式などの差分が残り、全状態の完全一致や承認済み視覚ゲートとは扱いません。公式fixtureは標準モードで、公式側のIssue・実行時エラーは0件です。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：84 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：99 / 96 / 81 / 100。実行警告0件。
- open_mobile：89 / 100 / 81 / 100。実行警告0件。
- open_desktop：93 / 100 / 81 / 100。実行警告0件。

非スコア項目・Diagnosticsを含む監査値をJSONのlayer_dialogへ保持しています。SDKのIntl.v8BreakIterator、SkWasm未同梱source map、Wasm／フォントの配信・起動処理、gallery desktopのviewport端で切れたSidebar行などが残り、全カテゴリ100点は未達です。SDK／DOM改造や意味情報の抑止は行っていません。

Linux／macOS／iOSの今回ビルドと、全物理実機・screen reader操作は未検証です。Drawerの全体スワイプ・速度連動時間・scroll fade・任意portal／Root APIなども未完了です。Flowのanchor margin補正が対応待ちです。同期済みSHA・承認済み視覚ゲートは進めていません。共有CIは最新設定で公開repoを対象外としており、クラウド同期と実Batch往復は無効／未検証、API呼出・費用は0です。本番反映先はGitHub mainで、Webホスティング・pub.dev公開は行っていません。

## ButtonGroup・Flowアンカーの追加検証（2026-10-16）

ソースSHAは `00e26b98bc213fe6d5fa3381c877297f836420d9`。静的解析0件、ライブラリ111件・デモ11件が成功し、Web・Windows・Androidのリリースビルドが成功しました。ButtonGroup 5件・Flowアンカー6件の回帰テストを追加しました。

ButtonGroupは外側だけの角丸・1px境界共有・RTLとwrapped controlを実装し、focus時もWidget／Tabの順序を変えずに描画・hit testの順序を調整します。Flowはstart／end／bothの実座標を計測し、正負の外側余白・内側移動・サイズ変更・登録解除・canvas変換へ追従します。2pxの丸い経路・矢印・disabled opacityを追加し、技術IDを読まずにlist／listItemを公開します。[API対応と未対応範囲](group-flow-api-mapping.md)を参照してください。

実ChromeでButtonGroup／Flowの12項目（1280px Light/Dark、320px Light/Dark、390px Light）とLayerDialogの24回帰項目が成功しました。グループ名とrole=group、Flowのlistと3つのlistItemを確認しています。全URL監査は106 URL・108条件、実行時エラー0件。残る108件のIssueと操作検証の10／6件はSDKのIntlV8BreakIteratorです。

公式SHA `7e0ff40` とButtonGroup 24画面・Flowアンカー 10画面を比較し、全組で幅・高さが0.1 CSS px以内でした。threshold 0.1の差分はButtonGroup 0.69〜9.18%、Flow 0.75〜2.35%です。Flowは120×40pxの明示寸法・padding 0・488×40pxのclipped canvas条件で比較し、見える範囲外も含む接続位置は別のRenderBoxテストで確認しています。公式fixtureは標準モード、公式側のIssue・実行時エラーは0件です。完全一致・全状態認証・承認済み視覚ゲートとは扱いません。

小さいprimaryボタンの比較で上辺1pxのinset highlight不足を検出して修正しました。Button／Sidebarの既存78画面も再比較し、78組で寸法が一致しました。通常Buttonのicon・文字・描画差と位相未同期のloadingは残り、完全一致とは扱いません。修正前の画像・Lighthouse結果もJSONへ保持しています。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- button_group_mobile：83 / 100 / 81 / 100。実行警告0件。
- button_group_desktop：99 / 96 / 81 / 100。実行警告0件。
- flow_mobile：77 / 100 / 81 / 100。実行警告0件。
- flow_desktop：93 / 96 / 81 / 100。実行警告0件。

非スコア項目・DiagnosticsもJSONのgroup_flowへ保持しています。SDKのIntl.v8BreakIterator、SkWasm source map、配信・起動負荷、gallery desktopでviewport端に切れたSidebar行などが残り、全100点は未達です。意味情報やSDKを改造・抑止していません。Linux／macOS／iOSの今回ビルドと物理実機・screen reader操作は未検証です。

FlowのList／Parallel全構成、自動寸法・縦配置・canvas挙動、ButtonGroupの全任意Widget／intrinsic制約などは継続対応です。6工程の進行状況は[完成までの工程](completion-plan.md)に記録しました。同期済みSHAは進めず、共有CIの公開repo除外・クラウド接続保留を維持しています。実Batch往復は未検証、API呼出・費用は0です。本番反映先はGitHub mainで、Webホスティング・pub.dev公開は行っていません。

## Flow構成・自動レイアウトの追加検証（2026-10-16）

ソースSHAは `f2181caa553fc6c2e300b934b9a5de9ad86a4737`。静的解析0件、ライブラリ119件・デモ11件が成功し、Web・Windows・Androidのリリースビルドが成功しました。構成／配置／動的内容／文字拡大の8テストを追加し、既存アンカー6テストも維持しています。

SteyFlow.composed／SteyFlowList／SteyFlowParallelを追加し、内容寸法の測定・自動接続・入れ子・空構成・隣接Parallelの規則、縦横・中央／末尾揃えと動的な再配置を実装しました。子Widgetの状態を保持し、既存の明示DAG APIも維持しています。ノードの影は公式の2層とringの重ね順・blurを補正しました。日本語デモで方向・配置・分岐の揃え・内容の長さを操作できます。[API対応と制限](flow-api-mapping.md)を参照してください。

実Chromeの新規10項目とButtonGroup／アンカーの既存12項目が成功しました。1280px Light/Dark、320px Light/Dark、390px Lightで5ノードの維持と自動寸法変更を確認し、実行時エラーは0件です。操作中のSDK警告はそれぞれ5／10件。全URL監査は106 URL・108条件、実行時エラー0件、SDKのIntlV8BreakIteratorが108件残っています。

公式SHA `7e0ff40` とLight/Dark・縦横・start/center/end・直列／分岐／入れ子／隣接Parallel／内容展開の48条件を比較しました。全組で図全体の寸法と各ノードの位置・寸法が0.1 CSS px以内でした。threshold 0.1の画像差分は0.45〜1.78%です。公式側は標準モード・幅1000pxのホスト・padding 0、1200×1000pxのviewportです。初期の絶対配置の縮小測定が折り返しへ影響するため、狭い親幅のCSS shrink-to-fitは別途未認証と記録しました。文字描画等の差があり、全状態の完全一致・承認済み視覚ゲートとは扱いません。同期済みSHAも進めていません。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- flow_gallery_mobile：79 / 100 / 81 / 100。実行警告0件。
- flow_gallery_desktop：98 / 96 / 81 / 100。実行警告0件。
- flow_composed_mobile：92 / 100 / 81 / 100。実行警告0件。
- flow_composed_desktop：100 / 100 / 81 / 100。実行警告0件。

非スコア項目・DiagnosticsもJSONのflow_compositionへ保持しています。SDKのIntl.v8BreakIterator、SkWasm source map、配信・起動負荷、gallery desktopでviewport端に切れたSidebar行などが残り、全100点は未達です。意味情報やSDKを改造・抑止していません。Linux／macOS／iOSの今回ビルドと全物理実機・screen reader操作は未検証です。

次の不足はFlowのcanvas全操作・狭い親幅での測定・極端なmarginと全視覚状態です。他の群も含む[6工程](completion-plan.md)は継続中です。共有CIの公開repo除外とクラウド接続保留を維持し、実Batch往復は未検証です。API呼出・費用は0、本番反映先はGitHub mainです。Webホスティング・pub.dev公開は行っていません。

残る指摘の内訳：Intlの非推奨呼出はFlutter SDK、SkWasm mapは公式配布物の不足です。アプリとloaderのmapは配信済みで、SDK改造・警告抑止・架空mapの追加は行いません。Desktopのtarget-sizeはviewport端で224×2pxだけ見える「グリッド」行の意味情報が原因です。スクロール・focus・読み上げを保持する修正は未解決です。Wasm／renderer／fontの配信量と初期処理の最適化も継続課題です。

## Flow canvasの追加検証（2026-10-16）

ソースSHAは `0d5ef64f954ddd7c26d056e4fe32787417087993`。静的解析0件、ライブラリ131件・デモ11件が成功し、Web・Windows・Androidのリリースビルドが成功しました。canvas専用12テストで独立したwheel軸・両端clamp・背景mouse/touch drag・ノード操作除外・trackpadの倍率固定・resize補正・親スクロールへの委譲・native Semantics移動・pointer cancel・ノードと背景のcursor・自然寸法を確認しました。

従来のInteractiveViewerを公式と同じ1倍固定の背景パンに置き換え、hover時の6pxスクロール表示・10%以上のthumb・overflow通知を追加しました。ノード上のdragではcanvasを動かさず、ノード自身の操作を保持します。interactive: falseの既存横スクロールとcanvas: falseを維持します。[API対応と制限](flow-api-mapping.md)を参照してください。

実Chromeの新規10項目、既存の構成10項目・ButtonGroup／アンカー12項目が成功しました。1280px Light/Dark、320px Light/Dark、390px Lightで、背景drag／wheel復帰・ノードdragの非移動・内容縮小後のclamp・callback・クリック状態保持を確認しています。狭幅ではcanvas全体をviewport内へスクロールして操作し、live-regionの読み上げ用複製を画面のstatusから区別しています。全URL監査は106 URL・108条件、実行時エラー0件、SDKのIntlV8BreakIteratorが108件です。各操作監査の同警告は5／5／10件、実行時エラー0件でした。

公式SHA `7e0ff40` と320×180px／280×180px・Light/Dark・初期／wheel／末端／収まる内容の16条件を比較しました。viewportの寸法は全組で0.1 CSS px以内、threshold 0.1の画像差分は0.08〜0.50%でした。paddingは16px、通常ノードは120×80px、hover表示ありです。公式側は標準モードでIssue・実行時エラー0件。clipされた意味情報を完全なノード座標の測定とは扱わず、全状態認証・承認済み視覚ゲート・同期済みSHAは進めていません。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- flow_gallery_mobile：74 / 100 / 81 / 100。実行警告0件。
- flow_gallery_desktop：97 / 96 / 81 / 100。実行警告0件。
- flow_canvas_mobile：95 / 100 / 81 / 100。実行警告0件。
- flow_canvas_desktop：98 / 100 / 81 / 100。実行警告0件。

非スコア項目・DiagnosticsもJSONのflow_canvasへ保持しています。SDKのIntl呼出・未配布のSkWasm map、配信／起動負荷、Desktopでviewport端に切れたSidebarの意味情報などが残り、全100点は未達です。機能・意味情報の抑制やSDK改造は行いません。Linux／macOS／iOSの今回ビルド、全物理実機とscreen readerは未検証です。

残りは狭幅のCSS縮小測定、極端なmargin、全入力／視覚状態と他コンポーネントの不足です。[6工程](completion-plan.md)を継続します。共有CIの最新main設定でも公開repoは対象外で、クラウド接続保留を維持しています。Workflow起動・実Batch往復は未実施、API呼出・費用は0です。GitHub mainが本番反映先で、Webホスティング・pub.dev公開は行っていません。

## Flow最大幅・折り返しの追加検証（2026-10-16）

ソースSHAは `33014820b5f786a4a58f61247a196fc422533c8c`。静的解析0件、ライブラリ138件・デモ11件が成功し、Web・Windows・Androidのリリースビルドが成功しました。追加7テストでpadding込みの最大幅、短い自然幅、明示／global幅との優先順位、固定高さ、幅の伸縮・状態保持、縦接続とアンカー、intrinsic不要のcustom Widget、文字拡大・RTLを検証しました。

SteyFlowNode.maxWidthを追加し、必要な場合だけ自然幅を制限して折り返し、高さと後続の配置を再計測します。幅未指定時の従来の自然寸法は維持しています。日本語デモでは画面幅に合わせた上限・説明の長さ・配置方向を操作できます。[API対応と制限](flow-api-mapping.md)を参照してください。

実Chromeの新規10項目と既存canvas 10・構成10・ButtonGroup／アンカー12項目が成功しました。1280px Light/Dark、320px Light/Dark、390px Lightで幅と高さの変化・復帰・ノード保持を確認し、実行時エラー0件。全URL監査は106 URL・108条件、実行時エラー0件、SDKのIntlV8BreakIteratorが108件です。操作監査にも5／5／5／10件の同警告が残ります。

公式SHA `7e0ff40` と、160／280／320pxの親幅・120／200pxの最大幅・長短の説明・縦横・Light/Darkの24条件を比較しました。canvas寸法は24組すべて、全ノードが見える縦配置12組のノード位置・寸法も0.1 CSS px以内でした。threshold 0.1の画像差分は0.05〜1.16%です。公式の未変更Flow.Nodeへ利用側のCSS max-widthを適用した比較です。横配置でclipされた意味情報を全ノードの座標とは扱いません。公式側は標準モード、Issue・実行時エラー0件。完全一致・全状態認証・承認済み視覚ゲートではありません。

最大幅が実質無制限の公式縦配置では、初期host 160pxの説明が128×100px、初期host 320pxでは288×58pxになり、親幅を後から入れ替えてもそれぞれの寸法を保ちました。この履歴依存のCSS auto-widthはFlutterの既定自然幅と異なり、今回は未対応です。明示したmaxWidthでの折り返し成功と区別し、測定値をJSONへ保存しました。同期済みSHAは進めていません。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- flow_gallery_mobile：78 / 100 / 81 / 100。実行警告0件。
- flow_gallery_desktop：98 / 96 / 81 / 100。実行警告0件。
- flow_wrap_mobile：96 / 100 / 81 / 100。実行警告0件。
- flow_wrap_desktop：100 / 100 / 81 / 100。実行警告0件。

非スコア項目・DiagnosticsもJSONのflow_wrapへ保持しています。SDKのIntl呼出・未配布のSkWasm map、配信／起動負荷、Desktopでviewport端に切れたSidebarの意味情報などが残り、全100点は未達です。機能・意味情報の抑制やSDK改造は行いません。Linux／macOS／iOSの今回ビルド、全物理実機・screen readerは未検証です。

既定のCSS縮小測定・全入力／視覚状態と他コンポーネントの不足は[6工程](completion-plan.md)で継続します。共有CIの最新mainでも公開repoは対象外で、クラウド接続保留を維持しています。Workflow起動・実Batch往復は未実施、API呼出・費用は0です。GitHub mainが本番反映先で、Webホスティング・pub.dev公開は行っていません。

## Flow自動幅・履歴測定の追加検証（2026-10-16）

ソースSHAは `0e32bcf1edba7acdb632519fc9b3069a7cfe151e`。静的解析0件、ライブラリ149件・デモ11件が成功し、Web・Windows・Androidのリリースビルドが成功しました。追加11テストで同梱Interを読み込み、初期幅・親幅変更後の保持・再作成・単独／先頭／中間／末尾／全ノード・分岐順序・方向・内容変更・最小単語幅・複数フレームの収束・unsupported intrinsic・空の末尾群を確認しています。収まるノードは最小幅計算0回、縮小が必要なノードはlayout内で1回と検証しました。

composedの標準ノードはautoWidth既定trueとし、自然幅・単語を分割しない最小幅・初期の利用可能幅・直前の図幅／座標を使って測定します。親だけを変更しても幅を保持し、内容変更時は図を再計算、keyを変えた再作成では現在幅から測定し直します。明示width／maxWidth、custom／intrinsic非対応の子は既存測定を優先し、autoWidth: falseとDAG API既定falseで従来の自然幅を保持します。1フレーム8回まで測り、必要なら次フレームで収束を継続します。[API対応と制限](flow-api-mapping.md)を参照してください。

実Chromeの新規10項目と既存の最大幅・canvas・構成各10項目、ButtonGroup／アンカー12項目、合計52項目が成功しました。1280px Light/Dark、320px Light/Dark、390px Lightで日本語の幅保持・再作成・内容変更を操作し、実行時エラー0件。全URL監査は106 URL・108条件、実行時エラー0件、SDKのIntlV8BreakIteratorが108件です。操作監査にも5／5／5／5／10件の同警告が残ります。

公式SHA `7e0ff40` と64条件を比較しました。160／320pxの初期親幅、800pxのcanvas高さ、padding 16px、幅・最大幅未指定の公式Flow.Nodeを用い、縦横・Light/Dark・単独／前後／全ノード・分岐順序・親幅変更・内容の短縮／復帰・再作成を含みます。canvas寸法は64組すべて、全ノードが見える38組の位置・寸法も0.1 CSS px以内でした。threshold 0.1の画像差分は0.17〜3.25%です。元の外側8pxの画像・fixture操作欄とcomponent viewportを区別し、両方の画像hash・生データを保持しています。切れた意味情報の矩形は全ノード座標とは比較しません。公式側は標準モードでIssue・実行時エラー0件。文字・影の描画差は残り、全状態認証・承認済み視覚ゲートとは扱いません。

過去に記録した初期host 160px→説明128×100px、初期host 320px→288×58pxの幅保持を標準ノードで再現しました。横配置では先頭／中間の説明が自然幅360.72pxへ広がり、末尾は初期幅を保つ条件も一致しています。以前の検証節は各SHA時点の結果として保持しています。同期済みSHAは進めていません。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- flow_gallery_mobile：68 / 100 / 81 / 100。実行警告0件。
- flow_gallery_desktop：95 / 96 / 81 / 100。実行警告0件。
- flow_auto_mobile：88 / 100 / 81 / 100。実行警告0件。
- flow_auto_desktop：100 / 100 / 81 / 100。実行警告0件。

非スコア項目・DiagnosticsもJSONのflow_auto_widthへ保持しています。必要なノードだけ最小幅を求める最適化前の4測定値も別SHA／artifactで保持しました。SDKのIntl呼出・未配布のSkWasm map、配信／起動負荷と追加デモの処理、Desktopでviewport端に切れたSidebarの意味情報などが残り、全100点は未達です。機能・意味情報の抑制やSDK改造は行いません。Linux／macOS／iOSの今回ビルド、全物理実機・screen readerは未検証です。

任意のcustom CSS／Widget、非収束レイアウト、全入力／視覚状態と他コンポーネントの不足は[6工程](completion-plan.md)で継続します。共有CIの公開repo除外とクラウド接続保留を維持し、Workflow起動・実Batch往復は未実施です。API呼出・費用は0、GitHub mainが本番反映先です。Webホスティング・pub.dev公開は行っていません。

## Dropdown開閉遷移の追加検証（2026-10-16）

ソースSHAは `a2f76504685cdb5b317acf362a2e2bc04f534baa`。静的解析0件、ライブラリ160件・デモ11件が成功し、Web・Windows・Androidのリリースビルドが成功しました。追加11テストで150msの開始／中間／終了、面全体のscale .95→1とopacity 0→1、公式のcubic-bezier(.4, 0, .2, 1)、親子の終了・二重実行防止、キーボード即時切替、親の中央揃え・上側反転・RTL、終了途中／通知内の再表示、hover待機の取消、破棄、動作低減設定時も継続するユーザー指定を確認しています。

RawMenuAnchorへ移し、終了アニメーション中もoverlayを保持します。終了開始時に操作・focus・意味情報を無効化し、post-frameで届く項目callbackも再実行しません。Enter／Spaceでの開閉・選択とEsc、プログラムのcloseは即時、pointerと矢印表示は150msです。onOpenChangedは開始時、MenuController.isOpenは終了中もtrueです。日本語デモを更新しました。実Chromeで発見したpointer表示後のEscを、階層ごとの終了処理で修正しました。[API対応と制限](dropdown-api-mapping.md)を参照してください。

実Chromeの時間制御による新規10項目、既存Dropdown 12項目、LayerDialog 24項目、合計46項目が成功しました。1280／320pxのLight/Darkと390px、LayerDialogの639／640px境界も含みます。実行時エラー0件。全URL監査は106 URL・108条件、実行時エラー0件、SDKのIntlV8BreakIteratorが108件です。

公式SHA `7e0ff40` のCSS・ソースと32条件を比較しました。Light/Dark、1200／320px、LTR／RTLの親と横submenuについて、開く遷移の開始・64ms・128ms・完了後の固定した面領域と影の8px文脈を比較しています。全32組の完了後の寸法が0.1 CSS px以内でした。threshold 0.1の画像差分は0.00〜3.68%です。原本の全viewport PNGも保持し、切出し・タイミング条件・hashをJSONに記録しました。影・icon・文字に加え、RTL行の物理的な字下げ・checkbox・shortcut位置の差も残り、閉じる全位相／全状態の認証や承認済み視覚ゲートとは扱いません。同期済みSHAは進めていません。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- dropdown_gallery_mobile：78 / 100 / 81 / 100。実行警告0件。
- dropdown_gallery_desktop：98 / 96 / 81 / 100。実行警告0件。
- dropdown_mobile：90 / 100 / 81 / 100。実行警告0件。
- dropdown_desktop：100 / 100 / 81 / 100。実行警告0件。

非スコア項目・DiagnosticsもJSONのdropdown_motionへ保持しています。SDKのIntl呼出・未配布のSkWasm map、起動負荷・転送量、Desktopでviewport端に切れたSidebarの意味情報などが残り、全100点は未達です。機能・意味情報の抑制やSDK改造は行いません。Linux／macOS／iOSの今回ビルド、全物理実機・screen readerは未検証です。

全submenu衝突規則・継承イベント理由・任意portalなどと他群の不足は[6工程](completion-plan.md)で継続します。共有CIの公開repo除外とクラウド接続保留を維持し、Workflow起動・実Batch往復は未実施です。API呼出・費用0、GitHub mainが本番反映先です。Webホスティング・pub.dev公開は行っていません。

## Dropdown RTL行の追加検証（2026-10-16）

ソースSHAは `8df20b746e539a1aa991716c0bc37f18ffbbaec7`。静的解析0件、ライブラリ168件・デモ11件が成功し、Web・Windows・Androidのリリースビルドが成功しました。追加8テストで同梱Interを読み込み、物理leftの字下げ／見出し／icon、14pxのcheckbox slot内に置く12pxのcheck、shortcut／radio checkと通常selectedの配置差、右向きcaretとRTLの左／右矢印とfocus移動前の戻るキー、制御値と意味情報、2倍文字とrich childの方向・収まりを確認しました。

公式はpl-8／left-2／ml-autoという物理CSSを使います。RTLで余白を反転させず、shortcut・radio check・caretを文字に隣接させ、通常selectedはLTRでも隣接させました。caretの描画は公式と同じ右向きで、RTLでは左矢印で子を開き右矢印で戻ります。日本語デモには「表示方向：左から右／右から左」の切替を追加し、選択状態を維持します。[API対応と制限](dropdown-api-mapping.md)を参照してください。

実Chromeの新規RTL 10項目、時間制御 10項目、既存Dropdown 12項目、LayerDialog 24項目、合計56項目が成功しました。1280／320pxのLight/Darkと390px、LayerDialogの639／640px境界を含みます。実行時エラー0件。全URL監査は106 URL・108条件、実行時エラー0件、SDKのIntlV8BreakIteratorが108件です。

公式SHA `7e0ff40` と48条件を比較しました。公式側は文書のdirに加えてBase UIのDirectionProviderを指定し、論理配置とキー方向もRTLに揃えています。Light/Dark、1200／320pxのLTR・RTL root、1200pxのLTR・RTL submenuについて、開く遷移の開始・64ms・128ms・完了後を比較しています。全48組の完了後の位置・寸法が0.1 CSS px以内でした。threshold 0.1の画像差分は0.00〜2.90%です。全viewport PNGと、固定した面＋影8pxの切出しPNG・hash・経過時間を保持しています。公式の文字・icon・indicatorの相対座標もsource-layout.jsonから保持しました。影・icon・文字などの描画差は残り、全状態認証や承認済み視覚ゲートとは扱いません。同期済みSHAは進めていません。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- dropdown_gallery_mobile：77 / 100 / 81 / 100。実行警告0件。
- dropdown_gallery_desktop：98 / 96 / 81 / 100。実行警告0件。
- dropdown_mobile：95 / 100 / 81 / 100。実行警告0件。
- dropdown_desktop：100 / 100 / 81 / 100。実行警告0件。

非スコア項目・DiagnosticsもJSONのdropdown_rtlへ保持しています。SDKのIntl呼出・未配布SkWasm map、起動負荷・転送量、Desktopのviewport端で切れたSidebarの意味情報などが残り、全100点は未達です。初回のAndroidビルドではSDK command-line toolsとSDK metadataのXML版の不一致警告がありましたが、リリースAPKは成功しました。SDK／DOMの改造や機能・意味情報の抑制は行いません。Linux／macOS／iOSの今回ビルド、全物理実機・screen readerは未検証です。

全submenu衝突規則・継承イベント理由・任意portal／triggerと他群の不足は[6工程](completion-plan.md)で継続します。共有CIの公開repo除外とクラウド接続保留を維持し、Workflow起動・実Batch往復は未実施です。API呼出・費用0、GitHub mainが本番反映先です。Webホスティング・pub.dev公開は行っていません。

## Dropdown衝突配置の追加検証（2026-10-16）

ソースSHAは `7bdf141b791eb557f8270c14e87daa7d701e6270`。静的解析0件、ライブラリ180件・デモ11件、Web・Windows・Androidのリリースビルドが成功しました。追加12テストでLTR／RTLの横反転優先、上下配置の8px間隔と論理揃え、横配置の末尾揃え、rootの高さ制約とscroll、端末の安全領域、rich childの実測高さによるroot反転を確認しています。

左右に幅がある間は横配置を維持し、start／end揃えとshiftを試します。両側が狭いときだけ下／上を試し、上下では8px間隔・配置に応じた変形原点を使います。既定の衝突余白は公式と同じ5px。rootは大きい空き領域で実測してから側を選び、起点を覆わずスクロールします。日本語デモの案内と[API対応](dropdown-api-mapping.md)を更新しました。

公式SHA `7e0ff40` との48条件（Light/Dark・LTR/RTL、1200／700／600／320px、短い500／400px、移動したanchor、長い子メニュー）でrootと子の位置・寸法・配置方向が一致しました。最大座標／寸法差は0.000000 CSS px、許容値は0.1 CSS pxです。子のsurface画像のthreshold 0.1差分は2.17〜9.05%です。スクロール時にmenu内容の意味情報へpaddingを足すだけでは面が6px大きく見えるため、clip／scroll viewportそのものを測定します。全viewport画像・切出し・hashと公式fixtureを記録しました。影・icon・文字等の差は残り、承認済み視覚ゲートや全状態認証とは扱いません。

新規比較の各48条件で子を矢印で開く／戻るとEscを確認し、既存のDropdown・motion・RTL・LayerDialogは計56項目成功しました。実行時エラー0件。全URLの実Chrome CDP監査は106 URL・108条件、実行時エラー0件、SDKのIntlV8BreakIteratorが108件です。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- dropdown_gallery_mobile：77 / 100 / 81 / 100。実行警告0件。
- dropdown_gallery_desktop：95 / 96 / 81 / 100。実行警告0件。
- dropdown_mobile：95 / 100 / 81 / 100。実行警告0件。
- dropdown_desktop：100 / 100 / 81 / 100。実行警告0件。

非スコア監査・DiagnosticsもJSONのdropdown_positioningへ保持しています。SDKのIntl呼出・未配布SkWasm map、起動負荷・転送量、Desktop Sidebarのviewport端の小さい意味情報が残り、全100点・Issues 0件は未達です。Linux／macOS／iOSの今回ビルド、全物理実機・screen readerは未検証です。

Floating UIのMIT原文を第三者表記とパッケージLICENSEへ追加し、Base UIの表記対象をmenu配置にも広げました。ライセンスのみの増分ビルド後も比較済みWasmのhashは不変で、Web／Windows／Android配布のNOTICESへ新表記が入ることを確認しています。

任意境界・sticky・開いたままのresize／anchor追従、custom submenu寸法、全イベント理由／APIと他群の不足は[6工程](completion-plan.md)で継続します。同期済みSHAと承認済み視覚ゲートは進めていません。shared-ciの最新README／setup／登録設定は前回と同じblobで、公開repoの除外とクラウド接続保留を維持しています。Workflow起動・実Batch往復は未実施、API呼出・費用0です。GitHub mainが本番反映先です。

## Dropdown表示中の追従の追加検証（2026-10-17）

ソースSHAは `faaccd206beae338b163ea302e1a3c6d3c77f1d2`。静的解析0件、ライブラリ192件・デモ11件、Web・Windows・Androidリリースビルドが成功しました。新規12テストでLTR／RTLのリサイズ、paint transformによる3階層移動、祖先のanimated scroll、scroll中のresize、外部controllerの終了とresize時post-frame終了、長い子のキーボード上の高さ制約、項目数変更、停止中のframe要求なし・破棄を確認しました。

RawMenuAnchorのサイズ変更・祖先scrollによる自動close要求を扱い、表示中に配置を更新します。選択・focus・開閉状態・進行中の遷移を作り直しません。子は独立OverlayEntryの意味情報を保ち、layout後のgeometry変化だけで再配置します。Scaffoldが除去したViewのキーボード／notch余白を回復し、キーボードとの間に5pxを確保します。MediaQueryの文字倍率は継承します。SDK／DOMの改造と常時Tickerの追加は行っていません。[API対応](dropdown-api-mapping.md)。

公式SHA `7e0ff40` と実ChromeのLight/Dark・LTR/RTL、1200／390pxからの開始、2／3階層の表示、起点移動・祖先scroll・320／1200×600pxへのresize・子12項目追加という40状態を比較しました。全40状態の位置・寸法が0.1 CSS px以内で、最大差は0.000000 CSS pxでした。通知の選択値と開いた階層を維持し、Escで終了しました。子surfaceの画像差分（threshold 0.1）は1.69〜5.82%です。表示開始の遷移を待ってから追従操作を測定しており、遷移中の全フレーム比較ではありません。

既定衝突の48条件も再比較して一致しました。公式の既存静止画像を再利用し、今回のWasmとのhash・比較元fixtureと実行スクリプト・全viewport／切出しPNGを保持しています。既存Dropdown・motion・RTL・LayerDialogは計56項目が成功しました。全URLの実Chrome CDP監査は106 URL・108条件、実行時エラー0件、SDKのIntlV8BreakIteratorが108件です。新規比較の8コンテキストにもSDKの同Issueが8件残ります。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- dropdown_gallery_mobile：73 / 100 / 81 / 100。実行警告0件。
- dropdown_gallery_desktop：97 / 96 / 81 / 100。実行警告0件。
- dropdown_mobile：93 / 100 / 81 / 100。実行警告0件。
- dropdown_desktop：100 / 100 / 81 / 100。実行警告0件。
- dropdown_tracking_mobile：88 / 100 / 81 / 100。実行警告0件。
- dropdown_tracking_desktop：100 / 100 / 81 / 100。実行警告0件。

非スコア監査・DiagnosticsもJSONのdropdown_trackingへ保持しました。SDKのIntl呼出・未配布SkWasm map、起動負荷・転送量、Desktop Sidebarのviewport端の操作領域が残り、全100点・Issues 0件は未達です。AndroidにはSDK tool／metadata XML版の不一致警告がありましたが、APKは成功しました。Linux／macOS／iOSの今回ビルド、全物理実機・screen readerは未検証です。キーボードはWidget testのView Insetsで検証しました。

任意境界・sticky・anchorがclip領域から消えた場合の全hide規則、rich child寸法と全イベント／API・描画状態の認証は残ります。画像は診断用で、完全再現や承認済み視覚ゲートとは扱いません。同期済みSHAは進めず、shared-ciの最新README／setup／登録設定のblobが前回と同じことを確認し、公開repo除外・クラウド接続保留を維持しました。実Batch往復は未実施、API呼出・費用0です。GitHub mainが本番反映先です。

## Dropdown配置境界・隠れた起点の追加検証（2026-10-17）

ソースSHAは `8f6a628a0f2dbc4ea61451cb8030bc257eef0947`。静的解析0件、ライブラリ200件・デモ11件、Web・Windows・Androidリリースビルドが成功しました。新規8テストは左右両方向の矩形境界・各辺の物理余白、長い子の高さ制約、境界更新後の子のprimary focus、2階層を開いたまま起点を部分／完全にclipして戻す操作、画面外の起点から離れないshiftを検証します。

公式Kumo／Base UI 1.9.0はanchorHiddenだけを理由に既定popupを自動close／非表示にしません。この仕様に合わせ、rootの縦位置を起点へ追従させ、横のshiftと子の縦shiftを起点につながる範囲へ制限しました。collisionBoundary（root overlay logical pxのRect）とcollisionPadding（物理EdgeInsets）は全階層へ適用します。画面との交差と端末の安全領域・キーボード余白を考慮し、移動した矩形は呼出側がrebuildで更新します。日本語デモに配置境界の切替を追加しました。[API対応](dropdown-api-mapping.md)。

実ChromeのLight/Dark・LTR/RTL、800×800px、既定viewport／内側矩形／画面外にはみ出す矩形＋非対称余白の12条件で、初期・境界40px縮小・部分clip・完全anchor clip・子の完全画面外・復帰の計72状態を公式SHA `7e0ff40` と比較しました。可視surfaceの位置・寸法は全72状態で0.1 CSS px以内（最大0.000000px）でした。選択を保持し、復帰後も2階層が開き、Escで終了します。画面全体の画像差分はthreshold 0.1で0.05〜1.22%です。影・glyph・focus描画などが残り、完全な視覚一致とは扱いません。

Flutterは完全に画面外の意味情報を省略し、部分表示の意味情報矩形をviewportに切り詰めます。ReactのDOM順とFlutterの座標による順序も異なるため、rootのlabelで階層を識別し、両者のviewport交差を比較しました。内部の開閉状態・画面外配置・focusはWidget testでも確認しています。物理screen readerでの同等性は未認証です。診断fixtureのCtrl+Alt B/Hは外側クリックを伴わずに配置を変更するためのもので、製品の操作APIではありません。

日本語ギャラリーの「配置境界」を切り替え、390px／1280pxの実Chromeでpopupが40pxの内側の境界＋5px余白に収まり、Escで終了することも確認しました。

既定配置48条件と表示中の追従40状態の回帰比較も成功しました。既存Dropdown・motion・RTL・LayerDialogの56項目が成功。全URL Chrome CDP監査は106 URL・108条件、実行時エラー0件、SDK IntlV8BreakIterator 108件です。新規比較の12コンテキストにも同じSDK Issueが12件残ります。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- dropdown_gallery_mobile：74 / 100 / 81 / 100。実行警告0件。
- dropdown_gallery_desktop：97 / 96 / 81 / 100。実行警告0件。
- dropdown_mobile：95 / 100 / 81 / 100。実行警告0件。
- dropdown_desktop：100 / 100 / 81 / 100。実行警告0件。
- dropdown_tracking_mobile：94 / 100 / 81 / 100。実行警告0件。
- dropdown_tracking_desktop：100 / 100 / 81 / 100。実行警告0件。

全非スコア監査・DiagnosticsをJSONのdropdown_boundaryへ保持しました。全100点・対応可能なIssues 0件は未達です。SDKのIntl呼出・未配布SkWasm map、自社の起動負荷・転送量とDesktop Sidebar端の操作領域が残ります。Linux／macOS／iOSの今回ビルド、全物理実機・screen readerは未検証です。Android APKは開発用署名です。

Element／複数境界・sticky・anchorHiddenの公開状態と独自render、rich child測定、全イベントと全入力・描画状態の認証は残ります。診断画像を承認済み視覚ゲートへ昇格せず、同期済みSHAも進めていません。shared-ciの最新README／setup／登録設定のblobが前回と同じこととWorkflow 0件を確認し、公開repo除外・クラウド接続保留を維持しました。実Batch往復は未実施、API呼出・費用0です。本番反映先はGitHub mainです。

## Dropdown sticky配置の追加検証（2026-10-17）

ソースSHAは `8cdb134ba3b4b7af619fff152bdb6e865791ff2b`。静的解析0件、ライブラリ212件・デモ11件、Web・Windows・Androidリリースビルドが成功しました。新規12テスト（関連計20件）で左右両方向の境界内保持、長い子、画面外の起点、表示中の切替とprimary focus・選択・階層保持、終了遷移の原点、キーボード上の高さ、狭い境界での指定幅維持、Home／Endでの項目表示と画面本体のscroll不変を確認しました。

sticky（既定false）をtrueにすると、親・子の両軸を可能な範囲で境界内へ移動し、境界全体の高さを利用します。上下に配置した面が起点に重なる場合の変形原点も調整します。明示widthは公式の固定幅と同様に維持し、境界より広い場合ははみ出すため呼出側で幅を指定してください。短いメニューではkeyboardで選択した行だけを最寄りのmenu ScrollPositionで見える位置へ移し、起点側の画面本体をスクロールしません。日本語デモへ保持／追従の切替を追加しました。[API対応](dropdown-api-mapping.md)。

公式SHA `7e0ff40` のKumoソース／CSS・Base UI 1.9.0を使い、実ChromeのLight/Dark・LTR/RTL、800／390px、通常境界・内側矩形・高さ200pxの矩形・起点を下へ300px移動した16条件を比較しました。起点の部分／完全clip、sticky off/on、復帰、横移動と復帰、子12件追加、境界縮小を含む176状態で可視位置・寸法が0.1 CSS px以内（最大0.000000px）でした。画面全体の画像差分はthreshold 0.1で0.00〜2.25%です。影・glyph・focusなどの差があり、完全な描画一致とは扱いません。

比較では項目のDOM surrogateへのfocus指定を使わず、文字検索・Home・矢印・Spaceで通知を無効にしてから子を開きました。文字検索の終了を600ms待ってSpaceを押しています。短いメニューで生じるfocusによるscrollも比較対象です。公式の画面外transform追跡にはIntersectionObserverの再観測があるため、横移動は1300ms待って静止位置を測定しました。Flutterが画面外の意味情報を省略する点は前節と同じです。sticky offですべての面が画面外へ出ても、onに戻した後の2階層復帰と選択保持を確認しています。全フレーム・物理screen readerの認証ではありません。

既定sticky=falseの境界比較72状態、既存Dropdown・motion・RTL・LayerDialog計56項目も成功しました。日本語ギャラリーは390／1280pxで切替・表示・Escを確認しました。全URLのChrome CDP監査は106 URL・108条件で実行時エラー0件、SDK IntlV8BreakIterator 108件です。新規比較16コンテキストにもSDKの同Issueが残ります。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- dropdown_gallery_mobile：76 / 100 / 81 / 100。実行警告0件。
- dropdown_gallery_desktop：98 / 96 / 81 / 100。実行警告0件。
- dropdown_mobile：91 / 100 / 81 / 100。実行警告0件。
- dropdown_desktop：100 / 100 / 81 / 100。実行警告0件。
- dropdown_tracking_mobile：94 / 100 / 81 / 100。実行警告0件。
- dropdown_tracking_desktop：100 / 100 / 81 / 100。実行警告0件。

非スコア項目・Diagnosticsを含む全監査をJSONのdropdown_stickyへ保持しました。全100点・Issues 0件は未達です。SDKのIntl・SkWasm map、自社の起動負荷・転送量とDesktop Sidebar端の操作領域が残ります。Linux／macOS／iOSの今回ビルド、物理実機・screen readerは未検証、Android APKは開発用署名です。

Element／複数境界・負の余白、rich child測定、全配置prop／イベント／portalと全描画状態の認証は残ります。公式はdisabled行にも矢印focusを移せますが現実装はskipし、500msの文字検索中のSpaceも公式は検索・現実装は実行という差があり、API対応表へ残課題を追記しました。同期済みSHAと承認済み視覚ゲートは進めていません。shared-ciの最新README／setup／登録設定のblob不変とWorkflow 0件を確認し、公開repo除外・クラウド接続保留を維持しました。Batch API呼出・費用は0、実往復は未実施。本番反映先はGitHub mainです。

## Dropdownキーボード操作の追加検証（2026-10-17）

ソースSHAは `492620a06433ec8f90f1958ce3e638d91d2cd754`。静的解析0件、ライブラリ236件・デモ11件、Web Wasm・Windows x64・Android APKのリリースビルドが成功しました。新規24テストで左右両方向のdisabled行への矢印／Home／End／文字検索、無効な通常行・checkbox・radio・submenuの非実行、disabledとfocusedの意味情報、表示中の無効／有効切替を確認しました。

500msの検索継続・失敗時リセット・複数単語・同じ頭文字の巡回・Space長押し後のkeyupを公式へ合わせました。検索中のSpaceは検索を続け、検索がない有効行では連続Spaceで操作できます。無効行のSpaceは無反応ですが検索には残ります。子へのfocus移動で親の検索を終了します。子の開始フレームでopacityが0でも意味情報を保持し、panelの競合するautofocusを除去して、矢印で開いた子の先頭行へfocusを移します。独立OverlayのFocusScopeは起点のnearestScopeへ接続し、ルートがfocusを再要求しても子の選択を維持します。終了中はreverseだけでなくdismissed状態も操作・意味情報を除外し、透明な最終フレームでの再出現とWebのfocus消失を防ぎます。日本語デモの説明も更新しました。[API対応](dropdown-api-mapping.md)。

公式SHA `7e0ff40` のKumo／CSS・Base UI 1.9.0と、実ChromeのLight/Dark・LTR/RTL・390／1200pxで比較しました。8条件・216状態で、無効行・検索中／検索前のSpace、時間経過、失敗検索、頭文字巡回、子の先頭focus、親へ戻った後のSpace、3階層の検索と選択、再表示時の選択保持を確認しました。Tabでアプリfocusへ入り、項目へのDOM focus指定は使いません。比較画像24組のpopup位置・寸法は最大0.000000 CSS px差、画面全体の画像差分はthreshold 0.1で0.34〜1.07%です。影・glyph・focusの描画差があり、完全一致は未達です。

**無効行のWeb DOM focusはSDK差が残ります。** アプリのprimary focusとリングは無効行へ移り、aria-disabled=trueも維持しますが、Flutter WebのFocusable.updateはdisabledノードへのDOM focusを除外するため、document.activeElementは直前の有効行に残ります。実Chrome比較はこの差を明示して記録し、次の矢印・文字検索・Enter／Spaceの無反応も確認しました。enabledと偽る対処やDOM／SDK改造は行っていません。物理screen readerでの影響と解消は未検証です。

既存Dropdown・motion・RTL・LayerDialogのChrome検査計56項目、日本語デモ390／1280pxの操作も成功しました。stickyの配置比較16条件・176状態も再実行し、可視位置・寸法は最大0.000000 CSS px差でした。全URLのCDP Audits.issueAdded監査は106 URL・108条件で実行時エラー0件、SDK IntlV8BreakIterator 108件でした。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- dropdown_gallery_mobile：65 / 100 / 81 / 100。実行警告0件。
- dropdown_gallery_desktop：95 / 96 / 81 / 100。実行警告0件。
- dropdown_mobile：94 / 100 / 81 / 100。実行警告0件。
- dropdown_desktop：100 / 100 / 81 / 100。実行警告0件。
- dropdown_tracking_mobile：91 / 100 / 81 / 100。実行警告0件。
- dropdown_tracking_desktop：100 / 100 / 81 / 100。実行警告0件。

追従サンプルのDesktopだけ初回にChrome traceのNO_NAVSTARTで失敗したため、その1条件だけ再実行しました。他の5条件の成功結果は再計測せず保持しています。

非スコア項目・Diagnosticsを含む全監査をJSONのdropdown_keyboardへ保持しました。全100点・Issues 0件は未達です。SDKのIntl・SkWasm map、自社の起動負荷・転送量とDesktop Sidebar端の操作領域が残ります。今回ソースのLinux／macOS／iOSビルド・物理実機・screen readerは未検証、Android APKは開発用署名です。全継承API・rich child・全描画状態の認証は未完了で、同期済みSHAと承認済み視覚ゲートは進めていません。shared-ciのREADME／setup／登録設定のblob不変とWorkflow 0件を確認し、公開repo除外・クラウド保留を維持しています。Batch API呼出・費用は0、実往復は未実施。本番反映先はGitHub mainです。

## Code構文強調の追加検証（2026-10-17）

ソースSHAは `ac81e59b45aa8c2f66d2fed234187ed90501de9c`。静的解析0件、ライブラリ266件・デモ12件、Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功しました。新規はライブラリ30件・デモ1件です。18言語の原文保持とLight/Darkの色分け、別名・言語制限・フォールバック、行番号と意味情報、2倍拡大とRTL、横スクロール、コピーの原文・ラベル・2秒の通知・失敗・応答順・破棄を確認しました。150msのフェードは動作低減設定でも維持します。[CodeのAPI対応](code-api-mapping.md)。

公式の固定SHAをShiki 4.0.2のJavaScriptエンジン、github-light / vesperと組み合わせ、実Chromeで18言語×Light/Darkの36条件と、1行・枠なし・行番号なし・横長・未知言語の各320／390／1200px×Light/Darkの30条件、計66条件を比較しました。両側の意味情報の原文・実コピー・成功表示・クリップボードを確認しています。Windows ChromeのLF→CRLF変換はそのまま記録し、改行以外は一致を要求します。

枠の位置・寸法は最大0.000000 CSS px差（許容1px）、画面全体の画像差分はthreshold 0.1で0.03〜0.46%でした。**枠の一致は全トークン・全色・文字幅の一致を意味しません。** 公式CSSの13px／行高21.125pxと、1行のコピーをコード直後に置く仕様へ修正しました。共有テーマからの誤ったフォント継承を防ぐ等幅Roboto Monoを同梱し、空になっていたリッチコードの読み上げ内容に原文を明示しています。Roboto MonoとOSフォント、re_highlightとShiki、HCLの全文法などの差が残ります。ロゴ等を含む全群の認証・同期済みSHA・視覚ゲートは進めていません。

日本語デモは390／1280px・Light/Darkの4条件で言語選択、行番号・枠・構文強調の切替とコピー通知を確認しました。全URLのCDP Audits.issueAdded監査は106 URL・108条件で実行時エラー0件、Issue 108件でした。分類はJSONに保持しています。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：76 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：97 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：90 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：100 / 100 / 81 / 100。実行警告0件。

全100点・Issues 0件は未達です。非スコア項目・Diagnosticsを含む全監査をJSONのcode_highlightedへ保持しました。SDK IntlV8BreakIterator・SkWasm mapと、自社の初期起動・転送量・操作領域などを残件として追跡します。Linux／macOS／iOS・物理実機・物理screen readerは今回ソースで未検証、Android APKは開発用署名です。shared-ciのREADME／setup／登録設定は前回と同じblob、Workflow 0件で、公開repo除外・クラウド保留を維持しています。Batch API呼出・費用は0、実往復は未実施。本番反映先はGitHub mainです。

従来のCode／CodeBlockにも原文の意味情報を設定し、Lighthouseで検出したラベル不足を修正しました。自動同期の対応表には公式の別入口src/code/の10ファイルとネイティブ実装を追加し、新規ファイルもCode群だけへ割り当てます。固定SHAのAPI一覧を補完し、同期済みSHAは維持しています。関連Pythonテスト19件はローカルの偽APIを含む検査であり、実際のBatch送信・クラウドCI・PR作成は実行していません。

## InlineCopyTextの追加検証（2026-10-18）

ソースSHAは `791716ba8e18a0a214b82a2e3a2fdea41894dd16`。静的解析0件、ライブラリ284件・デモ13件、Python同期テスト19件、Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功しました。新規はライブラリ18件・デモ1件です。[InlineCopyTextのAPI対応](inline-copy-api-mapping.md)に対応範囲を記載しています。通常のClipboardTextは今回の変更対象外です。

枠なしのコピー操作、6種類の文字・4サイズ、明示値とrich child、ラベル、無効・省略・キャンセル・失敗通知、親groupのhover／focusを追加しました。成功表示は1.5秒、再操作・並行完了・破棄を検証しています。Enterはkeydown、Spaceはkeyupで実行し、意味情報経由のクリック後も次のTabで兄弟へ移動します。150msのフェードは動作低減設定でも維持します。

公式 `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` と実Chromeで40条件・164状態を比較しました。Light/Dark、LTR/RTL、390／1200px、文字・サイズ・装飾・長文・無効・キャンセル・親groupを含み、両側の実クリップボードと成功表示を検証しました。Windows ChromeのLF→CRLF変換だけを許容します。既知の未分割長文を除き、ボタンの高さ差最大0.500000px・Y差0.250000px・比例文字の幅差0.015625px（許容1px）でした。等幅の幅差は最大8.437500pxで、判定対象外の診断値です。画面全体の画像差分はthreshold 0.1で0.02〜0.84%でした。**全画素・glyph・focus輪郭・全APIの一致は未認証です。** OS依存monospaceとの差と、truncate=falseの未分割長文のはみ出し／折り返し差を残件とし、同期済みSHAと承認済み視覚ゲートは維持しています。

日本語デモは390／1280px・Light/Darkの4条件で、明示値のコピー、長文・装飾・行グループ・中止・無効を実操作しました。全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件です。分類と全報告をJSONへ保持しています。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：69 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：97 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：94 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：100 / 100 / 81 / 100。実行警告0件。

全100点・Issues 0件は未達です。非スコア項目・Diagnosticsを含む全監査をJSONのinline_copy_textへ保持しました。SDKのIntlV8BreakIterator・SkWasm mapと、自社の起動・転送量・操作領域などは残件です。今回のDesktopのAccessibility指摘は、スクロール領域末尾で高さ2pxだけ露出するサイドバーの「グリッド」です。スクロール・キーボード到達性を保つ修正は未完了です。InlineCopyText単体のAccessibilityは両画面100でした。Linux／macOS／iOS・物理実機・screen readerは今回ソースで未検証、Android APKは開発用署名です。shared-ciのREADME／setup／登録設定は前回と同じblob、Workflow 0件で公開repo除外・クラウド保留を維持しています。Batch呼出と費用は0、更新検出からPR作成までの実往復は未実施です。本番反映先はGitHub mainです。

## ClipboardTextの追加検証（2026-10-19）

ソースSHAは `8ebfd1ca6f37de00c6a732bec38308c227717399`。静的解析0件、ライブラリ301件・デモ15件、Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功しました。新規はライブラリ17件・デモ2件です。[ClipboardTextのAPI対応](clipboard-api-mapping.md)に対応範囲と挙動変更を記載しています。

通常のClipboardTextを本文とコピー専用ボタンの入力欄へ置き換えました。3サイズ・別のコピー値、最後の成功から1.5秒の通知、200msのアイコン遷移、600msのhover tooltip、4方向の成功toastと350msの連打フィードバックを追加しています。keyboard・raw値・失敗・応答順・破棄・画面端反転・移動追従・表示中のtooltip切替を確認しました。実Chromeで本文選択機構が余分なTab停止位置になる問題を修正し、本文は原文の意味情報を保ちます。

公式 `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` と実Chromeで40条件・184状態を比較しました。Light/Dark、LTR/RTL、390／1200px、3サイズ、4方向のtooltip、長文・明示値・上下の画面端を含みます。両側でTab／Enter／Space、連打、成功中も固定の操作名、実クリップボードと通知の復帰を確認し、WindowsのLF→CRLFだけを許容します。枠・ボタン・本文行の最大位置・寸法差は0.281250px（許容1px）、画面全体の画像差分はthreshold 0.1で0.03〜0.18%でした。**文字・popup・影・選択UIを含む全画素・全挙動の一致は未認証です。** 同期済みSHA・承認済み視覚ゲートは進めていません。

日本語デモは390／1280px・Light/Darkの4条件で、明示値・長文のコピー、連打と通知切替、サイズと方向の選択を実操作しました。全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件でした。分類と全監査をJSONに保持しています。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：80 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：98 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：96 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：100 / 100 / 81 / 100。実行警告0件。

全100点・Issues 0件は未達です。非スコア項目・Diagnosticsを含む全報告はJSONのclipboard_textに保持しました。SDKのIntlV8BreakIterator・SkWasm map、自社の起動・転送量・スクロール末尾の操作領域などを残件として追跡します。Linux／macOS／iOS・物理実機・screen readerは今回ソースで未検証、Android APKは開発用署名です。shared-ciのREADME／setup／登録設定は前回と同じblob、Workflow 0件で公開repo除外・クラウド保留を維持しています。Batch呼出・費用は0、更新検出からPR作成までの実往復は未実施。本番反映先はGitHub mainです。

## Bannerの追加検証（2026-10-19）

ソースSHAは `9aa798a78ff889687af986546a413dc8d73a4749`。静的解析0件、ライブラリ315件・デモ17件、Python 20件が成功しました。新規は14／2／1件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドも成功しています。[BannerのAPI対応](banner-api-mapping.md)に対応範囲と挙動変更を記載しました。

title／descriptionの構造化本文、base／smの配置、4variant、色と26／20pxのサイズを継承するBanner.Actionを追加しました。compactのLinkは説明の行内へ配置します。ChromeでリンクのURL情報と余分なTab停止位置を修正し、見出しと説明の意味情報を分けました。Enterのkeydown・Spaceのkeyup、処理中／無効、旧形式の優先順位、RTL・文字拡大・日本語の閉じる操作も検査しています。

公式 `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` とChromeで68条件・262状態を比較しました。Light/Dark、390／1200px、LTR/RTL、4variant・2サイズ・3操作variant、リンク・タイトル／説明のみ・旧形式・長文・無効／処理中・アイコンのみ／複数操作を含みます。枠・操作・本文行の最大位置／寸法差は0.500000px（許容1px、compactリンクのHTML glyph矩形は公式行高で比較。未補正の高さ差は最大2pxで元の矩形も保持）、画面全体の画像差分はthreshold 0.1で0.02〜0.79%でした。**任意Widget・文字・下線・focus・影・アニメーションを含む全画素／全挙動の一致は未認証です。** 同期済みSHA・承認済み視覚ゲートは進めません。

日本語デモは390／1280px・Light/Darkの4条件で、種類／サイズ／操作variant・長文・処理中／無効・リンク・閉じる／再表示を実操作しました。全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件です。分類を含む全報告をJSONへ保持しました。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：74 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：97 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：92 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：100 / 100 / 81 / 100。実行警告0件。

全100点・Issues 0件は未達です。非スコア項目・Diagnosticsを含む全監査をJSONのbannerへ保持しています。SDKのIntlV8BreakIterator・SkWasm mapと、自社の起動・転送量・スクロール末尾の操作領域は残件です。Linux／macOS／iOS・物理実機・screen readerは今回ソースで未検証、Android APKは開発用署名です。shared-ciはREADME／setup／登録設定のblobが前回と同じで、公開repo除外・Workflow 0件・クラウド保留を維持しています。Batch呼出・費用は0、更新検出からPR作成までの実往復は未実施。本番反映先はGitHub mainです。

## Collapsibleの追加検証（2026-10-19）

ソースSHAは `a359f73cc133e6ec2320637dfb8f93d398b3a4e9`。静的解析0件、ライブラリ332件・デモ19件、Python20件が成功しました。新規は17／2件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドも成功しています。[CollapsibleのAPI対応](collapsible-api-mapping.md)に対応範囲と差異を記録しました。

Root／Trigger／Panelと標準表示、制御／非制御、開閉取消、disabledの継承・上書き、100msの高さ・fade・caretを追加しました。子の自然な寸法を保ち、keepMountedでは状態を保持し、通常は閉じ終わってから破棄します。初期openでは即時表示します。実Chromeで開き始めのaria-controls欠落を検出し、Panelの識別情報をクリップの外へ移し、登録後にexpandedとcontrolsNodesを同時更新する構成へ修正しました。最初の高さ0フレームの回帰テストを含みます。

公式 `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` とChromeで38条件・152状態を比較しました。Light/Dark、390／1200px、LTR/RTL、標準／無装飾／独自ボタン、初期開閉、制御／取消／無効、保持／破棄、長文・複数の子を含みます。実Tab・Enter・Spaceのkeyup、子の状態、展開情報と実DOM上の操作対象を検査しました。枠と起点の最大位置／寸法差は0.015625px（許容1px）、画面全体の画像差分はthreshold0.1で0.01〜1.25%です。**全画素・全状態の一致は未認証です。** 途中反転のCSS短縮規則、hiddenUntilFound／beforematchは残り、同期済みSHA・承認済み視覚ゲートは進めません。

日本語デモを390／1280px・Light/Darkの4条件で操作しました。実キー入力とfocus後の値で入力値の保持／破棄を判定し、開閉取消、無効化、独自ボタン、外部制御と動的説明を確認しています。再表示直後の非focus DOM入力はvalueが空で、focus後に保持値へ同期する挙動を観測しました。描画とWidget状態は保持されますが、読み上げ側の値同期は未認証です。全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件。分類を含む報告をJSONへ保持しています。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：75 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：99 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：95 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：94 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア項目・警告・提案・Diagnosticsを含む全監査をJSONのcollapsibleへ保持しています。SDK由来のIntlV8BreakIterator・SkWasm map、自社の起動・転送量・スクロール末尾の操作領域は残件です。Linux／macOS／iOS・物理実機・screen readerは今回ソースで未検証、Android APKは開発用署名です。shared-ciの最新README／setup／登録設定のblobは前回と一致し、公開repo除外・Workflow0件・クラウド保留を維持します。Batch呼出・費用は0、更新検出からPR作成までの実往復は未実施。本番反映先はGitHub mainです。

## Emptyの追加検証（2026-10-19）

ソースSHAは `16ed97fc754021339d06551067f6d5146f5c7f68`。静的解析0件、ライブラリ345件・デモ21件、Python20件が成功しました。新規は13／2件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドも成功しています。[EmptyのAPI対応](empty-api-mapping.md)に対応範囲と差異を記録しました。

3サイズ、説明の有無によるh2、任意図版／追加内容、横スクロールできるコマンドと全文コピーを追加しました。成功完了から1秒の表示期限を管理し、最新の試行だけを反映します。古い非同期結果や破棄後の完了は無視します。繰返し成功では400msのチェック表示アニメーションを再起動せず期限だけ延長します。自動アイコンをなくし、既存の空リスト／チャートにも標準のEmpty表示を適用します。

公式 `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` とChromeで38条件・222状態を比較しました。Light/Dark、390／1200px、LTR/RTL、3サイズ・説明有無、図版、操作1個／複数、長文・長いコマンド・説明幅上限を含みます。実Tab・Enter・Spaceのkeyup、生のクリップボード読戻しと操作callbackを検査しました。外枠・見出しのY／高さ・コピー操作の高さの最大差は0.000000px（許容1px）、画面全体の画像差分はthreshold0.1で0.04〜1.23%です。**全画素・全状態の一致は未認証です。** text-balance・OS等幅フォント・コピーの横位置・選択とアニメーションの位相比較は残り、未補正の矩形も保持します。同期済みSHA・承認済み視覚ゲートは進めません。

日本語デモを390／1280px・Light/Darkの4条件で操作しました。3サイズ・任意内容の切替、2回のコピー全文読戻しと作成操作を確認しています。全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件。分類を含む報告をJSONへ保持しています。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：79 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：93 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：94 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：100 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア項目・警告・提案・Diagnosticsを含む全監査をJSONのemptyへ保持しています。SDK由来のIntlV8BreakIterator・SkWasm map、自社の起動・転送量・一覧末尾の操作領域は残件です。Linux／macOS／iOS・物理実機・screen readerは今回ソースで未検証、Android APKは開発用署名です。Android SDKのXML v4を旧ツールが読む世代差の警告が出ましたが、ビルドは成功しています。SDK／ビルドツールの更新は今回のUI変更へ混在させず、警告を保持します。shared-ciの最新README／setup／登録設定のblobは前回と一致し、公開repo除外・Workflow0件・クラウド保留を維持します。Batch呼出・費用は0、更新検出からPR作成までの実往復は未実施。本番反映先はGitHub mainです。

## Breadcrumbsの追加検証（2026-10-22）

ソースSHAは `9f62236aaf804b3dab7049734c4f6ee1ba810c1d`。静的解析0件、ライブラリ357件・デモ23件、Python20件が成功しました。新規は12／2件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドも成功しています。[BreadcrumbsのAPI対応](breadcrumbs-api-mapping.md)に対応範囲と差異を記録しました。

組み合わせAPI、2サイズ、viewport640px未満の省略、祖先を縮めず現在ページだけ切り詰める単一行配置、読み込み表示とコピー操作を追加しました。実Chromeでコンパクトサイズの行高とコピーアイコンの大きさの差を検出し、公式の実測値へ修正しました。Webのfragmentリンクがqueryを失ってデモを再読込する問題も修正しました。コピーは最新の成功から2秒、繰返し成功で期限を延長し、古い非同期結果と破棄後の完了を無視します。

公式 `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` とChromeで46条件・300状態を比較しました。最新観測 `947065ad39694fdc688b1128cc9c360f566a4f73` でもBreadcrumbs／SkeletonLineのソース差分はありません。Light/Dark、390／640／1200px、LTR/RTL、2サイズ、項目数・長文・読み込み・アイコン・追加内容・コピーなし／空値・狭いdesktopを含みます。実Tab・Enter・Spaceのkeyup、リンクhref・ポインタ操作・query維持と生のクリップボード読戻しを検査しました。外枠・nav・リンク・現在ページ・コピー操作の矩形の最大差は0.281250px（許容1px）、画面全体の画像差分はthreshold0.1で0.01〜0.67%です。**全画素・全状態の一致は未認証です。** loadingの乱数・位相、focus時の追加可視化、tooltipとクリップ外操作は残り、未補正の矩形を保持します。同期済みSHA・承認済み視覚ゲートは進めません。

日本語デモを390／1280px・Light/Darkの4条件で操作しました。サイズ・読み込み・アイコン・長文・RTL・コピー有無の切替、リンクcallbackと2回の全文コピーを確認しています。全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件。分類を含む報告をJSONへ保持しています。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：70 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：93 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：96 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：94 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア項目・警告・提案・Diagnosticsを含む全監査をJSONのbreadcrumbsへ保持しています。SDK由来のIntlV8BreakIterator・SkWasm map、自社の起動・転送量・一覧末尾の操作領域は残件です。Linux／macOS／iOS・物理実機・screen readerは今回ソースで未検証、Android APKは開発用署名です。ビルド警告はJSONへ保持します。shared-ciの最新README／setup／登録設定は更新されていましたが、公開repo除外・Workflow0件・クラウド保留を維持します。Batch呼出・費用は0、更新検出からPR作成までの実往復は未実施。本番反映先はGitHub mainです。

SDKの非推奨API利用はSDK側の修正・更新、SkWasmのmap不足は対応するengineビルド成果物が必要です。警告の隠蔽や架空のmap作成は行いません。起動・転送量と一覧末尾「グリッド」の224×2pxにクリップされた操作領域は、自社側で対応可能な残件として継続します。

## Badgeの追加検証（2026-10-22）

ソースSHAは `afc5b82d6b72a5385ceccf5b1df7676551601b11`。静的解析0件、ライブラリ369件・デモ25件、Python20件が成功しました。新規は12／2件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドも成功しています。[BadgeのAPI対応](badge-api-mapping.md)に対応範囲と差異を記録しました。

全17variantの既存配色を維持し、リンク祖先のhoverに連動する文字色の外側ring、beta破線の保持、任意アイコンの12px枠、文字拡大時の行枠、狭幅で縮めない単一行と空ラベルを追加修正しました。SteyLink／SteyBreadcrumbsLinkがscopeを伝え、任意リンクも明示scopeで利用できます。日本語デモは長いリンク内容を横スクロールで操作できます。

公式 `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` とChromeで132条件・318状態を比較しました。最新観測 `947065ad39694fdc688b1128cc9c360f566a4f73` でもBadgeソース差分はありません。Light/Dark、全variantのfilled／dot／icon、祖先余白のhover・exit・実Tab／Enter／Space・pointer、空・長文・文字拡大・RTLを含みます。Badgeと外枠の矩形の最大差は0.015625px（許容1px）。画面全体の画像差分はthreshold0.1で0.00〜0.51%、Badge領域の差分は0.00〜7.89%です。矩形・部分画像の差は補正せず保持し、**全画素・全状態の一致は未認証です。** 破線・glyph・focus等の差を残し、同期済みSHAと承認済み視覚ゲートは進めません。

日本語デモを390／1280px・Light/Darkの4条件で操作しました。variant・dot・icon・リンク・RTL・長文の切替と2回のcallbackを確認しています。全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件。分類と非スコア項目を含むLighthouseの全監査をJSONのbadgeへ保持しています。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：82 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：98 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：96 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：95 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。SDK生成loaderのIntlV8BreakIteratorはSDK側の修正・更新、SkWasm mapは対応するengine成果物が必要です。警告を隠蔽したり架空のmapを作成したりしません。自社側の起動・転送量と一覧末尾の小さい操作領域も対応可能な残件です。Linux／macOS／iOS・物理実機・screen readerは今回ソースで未検証、Android APKは開発用署名です。shared-ciの最新README／setup／登録設定blobは前回と同じで、公開repo除外・Workflow0件・クラウド保留を維持します。Batch呼出・費用は0、更新検出からPR作成までの実往復は未実施。本番反映先はGitHub mainです。

## Loader／SkeletonLineの追加検証（2026-10-22）

ソースSHA `dac48690e59ad2f99f2cbd241b67cc2b66e4f35b`。静的解析0件、ライブラリ376件・デモ26件、Python20件が成功しました。新規は7／1件です。画像出力用defineを付けた8件も成功しています。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功しました。[API対応](loader-api-mapping.md)に仕様と残件を保持します。

円形Loaderの3サイズpresetとstatusを追加し、数値サイズAPIと色継承を維持しました。SkeletonLineは8px・2px角丸、整数の乱数幅・小数2桁の時間、開始遅延・範囲変更時の再選択・blockHeightを追加し、既存width／heightを維持します。Breadcrumbsの読み込み表示も同じ部品を使用します。

公式 `947065ad39694fdc688b1128cc9c360f566a4f73` のLoader修正はinline styleからSVG属性への寸法移動です。native側はSVGを使わず、最新公式の16／24／32／45pxとボタン内14／16pxの実装と、既存の中央配置テストも維持します。固定時刻比較はLight/Dark・4サイズ・0／375／750／1125／1499／1500／2000／3000／5999／6000msの80フレーム、SkeletonLineの2テーマ・5時点の10フレーム、計90フレームです。Flutter widgetテストのsoftware rasterと公式SVG SMIL／CSSを比較し、差分率は160×96px領域・threshold0.1で0.000〜0.026%です。**これはFlutter Webの全位相・全画素の一致認証ではありません。**

実ChromeのWeb版は別に18条件を検査しました。サイズ0ではFlutter Webがstatusを意味情報から除外し、SVGのDOM保持とは異なることを確認しています。preset・45／0px・半透明色・RTL・skeleton・blockHeight、statusと動作低減設定でもアニメーションが進むことを確認しています。日本語デモは390／1280px・Light/Darkの4条件でサイズ・色・RTL・再作成を操作しました。全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件です。

Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：79 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：93 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：69 / 100 / 100 / 100。実行警告0件。
- isolated_desktop：98 / 100 / 100 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDK生成loaderのIntlV8BreakIteratorはSDK側の更新、SkWasm mapは一致するengine成果物が必要です。自社の起動・転送量・一覧末尾の操作領域も残件です。Linux／macOS／iOS・物理実機・screen readerは今回ソースで未検証、Android APKは開発用署名です。shared-ciの登録設定は更新されましたが公開repo除外・未登録を確認し、Workflow0件・クラウド保留を維持します。Batch呼出・費用は0、実際の更新検出→PRの往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。

## Paginationの追加検証（2026-10-22）

ソースSHA `6cd18e381dcf3fd3b6a5372a98506961ed314e40`。静的解析0件、ライブラリ388件・デモ28件、Python20件が成功しました。新規は12／2件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功しました。[API対応](pagination-api-mapping.md)に仕様と残件を保持します。

Info／PageSize／Separator／Controlsを組み合わせるAPI、入力・全ページ選択、full／simple、既知／不明の総件数、境界ボタンと日本語ラベルを追加しました。既存totalPages呼出を維持します。公式最新の文字列下書き・ASCII整数の検証・空データでも最大ページ1・範囲外ページの次操作無効化を反映しています。Enter確定後のWeb入力接続の再作成を避け、繰返し入力を検証しました。デモの意味情報用inputにborder-boxを指定し、ブラウザ既定の枠・余白による操作領域の拡張も修正しました。

公式 `947065ad39694fdc688b1128cc9c360f566a4f73` のPaginationと比較しました。fixtureのInputGroup／Selectは既存比較SHA `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` です。実Chrome 155.0.8059.86でLight/Dark、先頭・中間・末尾・空・範囲外、simple、不明な総件数、入力／選択、件数変更、RTL・狭い親を含む26条件・62状態を検査しました。無効値10種類の連続入力、Enter／Tab、範囲補正・矢印・最終ページのキーボード操作と通知回数を比較しています。

全条件のnav／host／各ボタン／入力欄の矩形は1px以内で、基準の不一致は0状態でした。Selectの連結角丸・focusの重なり・popup全体の描画は未認証です。操作群周辺の画素差はthreshold0.1で0.599〜2.948%です。**全画素・全focus・全構成の一致認証ではありません。** 日本語デモは390／1280px・Light/Darkの4条件で入力・境界・不明総数・選択・件数変更・空結果・RTLを操作しました。入力の識別子・履歴・テーマの既存ナビゲーション検査も成功しています。

全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件です。Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：77 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：93 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：96 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：94 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDK生成loaderのIntlV8BreakIterator、SkWasm map、自社の起動・転送量・一覧末尾の操作領域は残件です。Selectの連結描画・combobox／option相当の意味情報・全focus・screen readerの認証も残ります。Linux／macOS／iOS・物理実機は今回ソースで未検証、Android APKは開発用署名です。shared-ci最新設定はprivate-only・公開repo未登録、Workflow0件とクラウド保留を維持します。Batch呼出・費用は0、実際の更新検出→PRの往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。

## Meterの追加検証（2026-10-22）

ソースSHA `1814cae2b6e63b1135e18c26767715c2ab8d0353`。静的解析0件、ライブラリ400件・デモ30件、Python20件が成功しました。新規は12／2件、制御画像出力用define付きの13件も成功しています。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功しました。[API対応](meter-api-mapping.md)に仕様と残件を保持します。

min／max・NaN／無限大の補正、customValue／showValue、locale／NumberFormat、読み上げテキスト関数、8pxトラック・余白と300msのTailwind ease-out、RTLを追加しました。既存のlabel省略・toneを維持します。公式のMeter本体は既存比較SHAから差分なし、最新947065aとBase UI1.9.0の継承挙動を確認しました。狭幅での長いラベルの折り返しを修正しています。日本語デモは入力と値変更ボタンで操作し、標準Sliderの透明overlayによるWeb意味情報のポインター遮断を避けています。このSDK挙動の根本対応はSliderの残作業です。

実Chrome 155.0.8059.86でLight/Darkの50条件を比較しました。0／25／65／100、上下限外、NaN・±Infinity、offset／負の値域、非表示・独自値・書式・de／fr・RTL・160px長文・色・読み上げcallbackを含みます。メーター／親の矩形とバーの着色幅はすべて1px以内でした。要素領域の画素差はthreshold0.1で0.908〜4.541%です。

固定時刻の比較は25→75の変化、Light/Dark・LTR/RTL・0／75／150／225／300msの20フレームです。公式CSSのtransitionを停止して時刻指定し、Flutter widgetのsoftware rasterと比較しました。幅差は1px以内、320×120px領域の画素差は0.404〜0.471%です。**Flutter Webの全フレーム一致や全画素の認証ではありません。** Web側は動作低減設定でも幅が変化することを別に2条件で確認しています。日本語デモは390／1280px・Light/Darkの4条件で値・値域・独自表示・非表示・書式・色・長文・RTL・範囲外を操作しました。

全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件です。Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：81 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：93 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：97 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：94 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDK生成loaderのIntlV8BreakIterator、SkWasm map、自社の起動・転送量・一覧末尾の操作領域は残件です。FlutterのprogressBar＋数値範囲・aria-descriptionと、公式meter＋aria-valuetextの意味情報は異なります。NumberFormatの全locale／丸め・CSS反転時の短縮規則・screen reader・任意構成の認証も残ります。Linux／macOS／iOS・物理実機は今回ソースで未検証、Android APKは開発用署名です。shared-ci最新設定はprivate-only・公開repo未登録、Workflow0件とクラウド保留を維持します。Batch呼出・費用は0、実際の更新検出→PRの往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。

## Sliderの追加検証（2026-10-22）

ソースSHA `c385ceb244eaa3377639ed484bdecb4147fb87e2`。静的解析0件、ライブラリ417件・デモ32件の計449件とPython20件が成功しました。新規は17／2件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功しました。[API対応](slider-api-mapping.md)に仕様と残件を保持します。

Material SliderをFlutterの描画・Focus・Semantics・ポインター処理へ置き換えました。複数つまみ・push／swap／none・最小間隔・刻み値・Shift／Page／Home／End・取消・変更と確定通知・制御／非制御・NumberFormat・RTLを追加しています。値バッジは常時表示し、base32px／sm24px、初期表示では不要なフォーカス枠を出さずTab／矢印で表示します。Meterで観測した全画面透明overlayによる隣接ボタンの遮断を解消しました。Meterデモ自体は前回の数値入力とボタンを維持します。公式Slider本体は既存比較SHAから差分なし、最新947065aとBase UI1.9.0の継承挙動を参照しました。

実Chrome 155.0.8059.86でLight/Darkの44条件・206状態を公式と比較しました。上下限・scalar／range／3つまみ・小サイズ・無効・ラベル省略・端の揃え方・160px幅・小数／負の値域・de書式・RTL・非制御・取消・値を更新しない制御を含みます。ドラッグの往復・確定・Tab／Shift+Tab・矢印／Shift・Page Down・Home／End・繰返し上限・隣接ボタンについて値と通知回数が一致しました。親と有効つまみの矩形は1px以内、実行時エラー0件です。領域の画素差はthreshold0.1で0.068〜0.721%で、**全画素・全体の視覚認証ではありません。** 無効時のWeb役割と代理の数値属性は既知差として除外し、読み上げ値の文字列を比較します。名前の欠落は別検査で記録します。

日本語デモは390／1280px・Light/Darkの4条件で、単一値の変更・確定、隣接ボタン、範囲・小数・最小間隔・RTL・取消・無効を操作しました。別のLight/Dark・単一／範囲／無効の6条件でChromeのアクセシビリティツリーも確認しました。SDKがラベルを親ノードへ付けて内部入力へ関連付けないため、Web入力の名前は空で、Lighthouseのlabel検査に失敗します。公開APIだけでは修正できない差として記録します。ポインター後にSDKの内部range入力が500msだけ無効になるため、有効化を待ってキー操作を検証します。製品の待機処理やDOMの改変は加えていません。

全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件です。Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：82 / 94 / 81 / 100。実行警告0件。
- gallery_desktop：93 / 90 / 81 / 100。実行警告0件。
- isolated_mobile：94 / 94 / 81 / 100。実行警告0件。
- isolated_desktop：87 / 94 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDK loaderのIntlV8BreakIterator、SkWasm map、自社の起動・転送量・一覧末尾の操作領域は残件です。Flutter Webの数値属性は実値ではなく相対増減用の代理値で、実値はaria-valuetextへ渡します。無効時のDOM slider役割・HTML Form連携・全書式・任意構成・文字拡大・タッチ競合・screen readerも未認証です。Linux／macOS／iOS・物理実機は今回ソースで未検証、Windows／Androidはビルドのみ、APKは開発用署名です。shared-ciはprivate-only・公開repo未登録、Workflow0件とクラウド保留を維持します。Batch呼出・費用は0、実際の更新検出→PRの往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。

## LayerCard／Surfaceの追加検証（2026-10-22）

ソースSHA `697201f088ac8d2629fc5d945647e1c9ca264339`。静的解析0件、ライブラリ431件・デモ34件の計465件とPython20件が成功しました。新規は14／2件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功しました。[API対応](layer-card-api-mapping.md)に仕様と残件を保持します。

単層のbase背景・8px角丸・shadow-xs・lineリング、多層Rootのelevated背景・hairlineリングとPrimary／Secondaryを追加しました。Primaryの物理方向の右12px余白・8px間隔、Secondaryの上下−8px余白、後続フッターより手前に描画するPrimaryの配置とクリック判定に対応します。読み上げ順と入力内容は維持します。既存header／footerは各セクションへ変換し、明示paddingを保持します。Surfaceは公式同様に非推奨の互換APIで、既定の角丸0・overflow-visible、colorの2値が同じ描画であることを保持します。日本語ギャラリーはカードを二重に重ねない表示にしています。最新公式947065aの両ソースは7e0ff40から差分なしです。

実Chrome 155.0.8059.86でLight/Dark・Card／Surfaceの76条件を公式と比較しました。単層・多層・Primaryだけ・header省略・footer・複数本文・既存API・余白／角丸・160px長文・RTL・font18pxの継承・はみ出しを含みます。RootとPrimaryの矩形は1px以内、フッターと重なるPrimaryの背景色も一致し、実行時エラー0件です。Secondaryのクリップされた意味情報矩形は別に記録します。装飾のみのFlutter比較枠はSDKがgroup役割を省くため、同じ実寸の意味情報ノードを取得します。領域の画素差はthreshold0.1で0.000〜3.679%です。**全画素・全体の視覚認証ではありません。** 参照と候補のInter-Regular.ttfのSHA一致と、Chromeの実際のInter-Regular使用を確認していますが、文字を含む描画の画素差は残ります。

日本語デモはLayerCard／Surface・390／1280px・Light/Darkの8条件で、カード内のボタン、長文・RTL・角丸・footer、単層／既存APIへの切替、Surface color、はみ出し表示と隣接ボタンを操作しました。Widgetテストでは負の余白のクリック領域、Primaryの手前描画に対応するクリック順、入力保持、160px／文字倍率2とintrinsic heightも検査しています。

全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件です。Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_card_mobile：83 / 100 / 81 / 100。実行警告0件。
- gallery_card_desktop：93 / 96 / 81 / 100。実行警告0件。
- gallery_surface_mobile：82 / 100 / 81 / 100。実行警告0件。
- gallery_surface_desktop：93 / 96 / 81 / 100。実行警告0件。
- isolated_card_mobile：70 / 100 / 81 / 100。実行警告0件。
- isolated_card_desktop：100 / 100 / 81 / 100。実行警告0件。
- isolated_surface_mobile：94 / 100 / 81 / 100。実行警告0件。
- isolated_surface_desktop：100 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDK loaderのIntlV8BreakIterator、SkWasm map、自社の起動・転送量・一覧の操作領域は残件です。任意のflex構成・文字拡大・全画素・screen reader、Surfaceの親境界外へのhit testも未認証です。Linux／macOS／iOS・物理実機は今回ソースで未検証、Windows／Androidはビルドのみ、APKは開発用署名です。shared-ciは最新設定でもprivate-only・公開repo未登録、Workflow0件とクラウド保留を維持します。Batch呼出・費用は0、実際の更新検出→PRの往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。

## Tabsの追加検証（2026-10-22）

ソースSHA `45c904fa780d263f28b13bc4c915e87e8571a36d`。静的解析0件、ライブラリ451件・デモ36件の計487件とPython20件が成功しました。新規は20／2件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功し、4つの製品ソースと生成Wasm source mapの埋め込み内容の一致を確認しました。[API対応](tabs-api-mapping.md)に仕様と残件を保持します。

Tabsを実測幅に基づく描画へ置き換え、segmented／underline・base／sm、制御／非制御、初期値・削除時のfallback、任意ラベル、手動／即時選択を追加しました。既定の矢印操作はfocusのみで、Enter／Spaceで選択します。従来の即時選択はactivateOnFocus=trueで維持できます。200msの選択表示は途中位置からの再開と動作低減設定でも動く仕様に対応します。overflowの150ms表示、幅に応じたボタン移動、48pxの表示余白、3px超のマウスドラッグとクリック抑制、RTLも追加しています。公式947065aのTabsとstylesは7e0ff40から差分なし、依存挙動の参照はBase UI1.9.0です。

実Chrome 155.0.8059.86でLight/Darkの48条件・112状態を公式と比較しました。2種類・2サイズ、hover、手動／即時選択、RTL、非制御、凍結した制御値、rich label、160px／320pxのoverflow、ドラッグ、末尾の表示、初期選択、存在しない値と空配列を含みます。表示枠と収まるタブの矩形は1px以内、選択値・通知回数は一致し、実行時エラー0件です。overflowでクリップされる意味情報矩形は別に記録します。画素差はthreshold0.1で2.626〜7.283%でした。Inter Regular／MediumのファイルSHAは参照と同一ですが、文字・影などの描画差は残ります。**全画素・全体の視覚認証ではありません。**

Light/Dark・LTR/RTL・2種類の40フレームで、0／50／100／150／200msの公式CSS transitionとネイティブWidgetのsoftware rasterを比較しました。選択表示の矩形差は最大0.073px、画素差は2.321〜3.418%です。Flutter Webと公式を同時撮影した位相比較ではなく、全サイズ・反転・smooth scrollの経路を認証するものでもありません。Widgetテストでは実際のplatform disableAnimationsフラグでも200ms遷移が残ることを確認します。

日本語デモは390／1280px・Light/Darkの4条件で、手動の矢印／Enter、8つの切替、非制御・RTLの即時選択と無効項目のスキップ、図形付きラベル、隣接ボタンを操作しました。最初の4条件検査中にWasmのfunction signature mismatchが1件発生し、スタックは未取得です。その後の同一4条件と追加8周で再現しませんでしたが、原因未特定・未解消として記録します。成功した再検査だけで解消済みとは扱いません。

Flutterの公開Semantics APIではtablist／tab・選択状態・名前を設定します。SDKのAccessibilityFocusManager.stopManagingは古いtabindex=0を削除せず、矢印操作後に複数項目が残るため、Web DOMのroving tabindexは未達です。SDKのSemanticTabもenabled=falseをaria-disabledへ変換しません。Flutter内のFocus traversal・無効項目のスキップと、実ChromeのTabキーで隣接操作へ抜ける挙動は成功していますが、DOM／screen readerの全認証とは分けます。公式RTL overflowでは初期の右ボタンがscrollLeft0のまま動かないことを確認し、Flutterは左への移動・右への復帰を可能にしています。この差は一致として集計しません。

全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件（IntlV8BreakIterator）でした。Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：80 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：92 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：94 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：94 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDK loaderのIntlV8BreakIterator、SkWasm map、自社の起動・転送量・一覧の操作領域に加え、TabsのSDK意味情報と未特定のWasmエラーも残件です。任意render／リンク・CSS指定、文字拡大・タッチ慣性・全画素・screen readerも未認証です。Linux／macOS／iOS・物理実機は今回ソースで未検証、Windows／Androidはビルドのみ、APKは開発用署名です。shared-ciは最新設定でもprivate-only・公開repo未登録、Workflow0件とクラウド保留を維持します。Batch呼出・費用は0、実際の更新検出→PRの往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。

## Input／InputAreaの追加検証（2026-10-22）

ソースSHA `afcabb15e1e7df9639c0388f2f8cad57e7890d0a`。静的解析0件、ライブラリ470件・デモ39件の計509件とPython20件が成功しました。新規は19／3件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功し、4つの製品ソースとWasm source mapの埋め込み内容の一致を確認しました。[API対応](input-api-mapping.md)に仕様と残件を保持します。

InputはFlutter TextFieldの編集機能を維持し、Materialの枠遷移から外側の即時リングを分離しました。4サイズ・12px／16pxと14px／21pxの行高、単一行の上下中央、errorのdanger色、disabledのinactive色へ対応します。value／defaultValue／controllerの所有とfocusの所有、両通知名、ラベル操作・日本語の任意表記／情報ボタン名も追加しています。InputAreaは既定2行と内容／幅に応じた伸縮、最小・最大行数と内部スクロールに対応し、既存Textareaの4行は互換のため保持します。公式947065aでの変更はdisabledクラスのinactive修正で、InputArea／Field／styleは7e0ff40から差分なしです。

実Chrome 155.0.8059.86でLight/Darkの60条件・78状態を公式と比較しました。4サイズの通常／focus／disabled、エラー、readOnly、制御と拒否された編集、RTL・160px幅、labelのクリック／required／optional、説明／エラーだけ、明示standard、InputAreaの固定行・4サイズ・auto伸縮／最大行数／狭幅折返しを含みます。枠全体の矩形は1px以内、値・通知／確定回数は一致し、実行時エラー0件です。Inputの単一行文字位置はWidgetテストでも実際のEditableText座標を検査します。画素差はthreshold0.1で0.000〜11.358%でした。同一Inter Regular／MediumのSHAも確認しましたが、文字・caret・選択・影などの差は残り、**全画素・全体の視覚認証ではありません。**

比較用の公式bare textareaにはid／nameがないため、公式側でFormEmptyIdAndNameAttributesForInputErrorが16件発生しました。候補側は各条件のSDK IntlV8BreakIteratorだけで、これらは本番デモの全URL監査と分けて記録します。比較では先に隣接ボタンへfocusをそろえ、SDKのroute既定focusによる差と各操作状態を分けます。実際の初期focusは別に記録します。ラベルはSDKの透明な意味情報spanを直接click対象にできないため、実際の表示位置へマウスクリックし、編集欄のDOM focusを確認しました。自動fillはクリック後の編集接続を待って実行します。ラベル／説明／エラーの意味情報属性とHTML Form・ValidityStateの全等価性は認証しません。

日本語デモは390／1280px・Light/Darkの4条件で、情報表示と外側クリックによる終了、日本語入力／Enter、4サイズ、error・制御・自動複数行・RTL・任意表記、パスワード表示の秘匿、readOnly／disabledと隣接ボタンを操作しました。今回の成功した検査で実行時エラーは0件ですが、前段階のTabsで記録した原因未特定のWasmエラーを解消済みとは扱いません。

全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件でした。Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：78 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：99 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：95 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：100 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDK loaderのIntlV8BreakIterator・SkWasm map、自社の起動・転送量・一覧の操作領域、前段階のSDK意味情報は残件です。Form／全HTML type／構造化validation、IME・composing・Undo／補完・文字拡大・screen reader・InputGroup複合構成も未認証です。ブラウザは実Chromeのみで他主要ブラウザと旧2世代は未検証、Linux／macOS／iOS・物理実機も今回ソースで未検証、Windows／Androidはビルドのみ、APKは開発用署名です。shared-ciは最新設定でもprivate-only・公開repo未登録、Workflow0件とクラウド保留を維持します。Batch呼出・費用は0、実際の更新検出→PRの往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。

## InputGroupの追加検証（2026-10-22）

ソースSHA `76329d1ba5fa617750b29c4f3c8dbe74ba3e88b9`。静的解析0件、ライブラリ490件・デモ42件の計532件とPython20件が成功しました。新規は20／3件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功し、5つの製品ソースとWasm source mapの埋め込み内容が一致しました。[API対応](input-group-api-mapping.md)に仕様と残件を保持します。

Input／Addon／Suffix／Button、共有・個別・混合枠、4サイズ、1pxの境界共有・focus描画順、補助アイコン・ボタン、接尾辞に応じた入力幅、Fieldと無効状態の継承を追加しました。動的な形式変更でも入力値・focusを保ち、従来child/addon/suffixのRowを保持します。画像比較で見つけたButton.styleの優先順を修正し、内側角丸とborder分の余白を有効にしました。Paginationにも使うためLight/Darkの既存比較を追加実行しています。公式InputGroupの6ソースは7e0ff40から947065aまで差分なしです。

実Chrome 155.0.8059.86でLight/Darkの112条件・126状態を公式と比較しました。各4サイズの7構成、primary／destructive、focus・編集と拒否・消去・実行・hover、label／required／optional、error／disabled、RTL、狭幅・空値・text addon・leading hybridを含みます。枠全体の矩形は1px以内、値・通知／操作回数は一致し、完走時の実行時エラー0件です。個別入力・ボタンのDOM矩形と意味情報も診断として保持します。画素差はthreshold0.1で0.000〜7.576%でした。公式入力はWindowsのSegoe UI、候補は配布済みInterを使うため文字・内容幅に差があります。**全画素・全体の視覚認証ではありません。**

日本語デモは390／1280px・Light/Darkの4条件で、日本語入力、3形式での値保持、消去・実行、4サイズ、補助テキスト・error・RTL・任意表記、readOnly／disabledと隣接操作を確認しました。初回にdark390でSkWasmのmemory access out of boundsを1件記録しました。4条件の操作は完走し、操作段階を付けた再現検査4条件と更新後の検査はエラー0件ですが、原因・解消は未確定です。stackと当時のWasm SHA、過去のTabsの一過性エラーを保持し、解消済みとは扱いません。

全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件でした。Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：78 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：93 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：94 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：94 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDK loaderのIntlV8BreakIterator・SkWasm map、自社の起動・転送量・一覧の操作領域、DOMのfocus／値代理とレンダラの一過性エラーは残件です。rich tooltipと4方向指定・任意構成・Form／IME・screen reader・全画素も未認証です。他主要ブラウザと旧2世代、Linux／macOS／iOS・物理実機は今回ソースで未検証。Windows／Androidはビルドのみ、APKは開発用署名です。shared-ciは最新設定でもprivate-only・公開repo未登録、Workflow0件とクラウド保留を維持します。Batch呼出・費用は0、実際の更新検出→PRの往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。

## SensitiveInputの追加検証（2026-10-22）

ソースSHA `78a08445ab6f199b6a3edb53f17080c27c0afd94`。静的解析0件、ライブラリ512件・デモ45件の計557件とPython20件が成功しました。新規は22／3件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功し、4つの製品ソースとWasm source mapの埋め込み内容が一致しました。[API対応](sensitive-input-api-mapping.md)に仕様と残件を保持します。

固定8文字の伏字、masked／revealed／empty、マウス・Enter／Spaceでの表示、Escape・入力blurでの再マスク、値／選択／controllerの所有、自動全選択を無効にした初期キャレット、4サイズ・Field・readOnly／disabledを追加しました。上端のコピー操作はOverlayPortalで枠の外も操作可能にし、150msのfade・2秒の成功通知・古い試行と破棄後の通知の抑止、失敗callbackを検証しています。公式の入力blurだけにある処理に合わせ、コピーにfocusを移してから外へ移る場合は表示を保持することがあります。目の図形はPhosphor RegularのPathをMIT notice付きで使用します。非表示の目はSemanticsから除外し、隠す操作後は外枠へfocusを返します。コピーは上側4pxの透明な領域で24pxのhit areaを確保し、目も外枠内で最大24pxへ広げ、可視の図形を維持しています。readOnlyでの表示に遅れた旧blurが上書きしないよう、外枠へ意図的に移したfocusと、SDKだけが移したfocusを編集開始と混同しないよう保護しました。親のfocus用Semanticsが空欄のクリックを遮らないよう、伏字操作へfocusを結び付け、RTLの伏字位置も修正しました。公式SensitiveInputとcopy hookは7e0ff40から947065aまで差分なしです。

実Chrome 155.0.8059.86でLight/Darkの74条件・102状態を公式と比較しました。4サイズの伏字／hover／表示／disabled、Enter／Escape／Space、blur、伏字と表示状態でのコピー・2秒後の復帰、目のボタン、制御／拒否／非制御／空からの編集、readOnly、Fieldのlabel／required／optional・errorと明示default、RTL／160px幅、空欄、説明のみとラベル操作を含みます。値・通知回数と表示状態が一致し、外枠の矩形差は1px以内、完走時の実行時エラー0件です。実際のClipboard APIで架空のサンプル値が一致しました。画素差はthreshold0.1で0.000〜11.068%でした。RTLのコピーと目の操作も含みます。コピーの長い読み上げ名の透明DOMテキストが目の操作を覆う問題は、短いCopy／コピーに揃えて修正しました。製品のDOMを直接変更する対策は追加していません。copy tabを含む外枠上24pxも比較し、同じInter Regular／MediumのSHA一致を確認しましたが、全画素・全体の認証ではありません。

日本語デモは390／1280px・Light/Darkの4条件で、日本語の表示／入力／Escape、実際のコピーと値の二重表示防止、4サイズ・エラー／RTL／任意／制御切替、空欄とサンプル再設定、readOnly／非表示／disabledと隣接操作を確認しました。画面の状態表示は文字数と操作回数だけにしています。過去のTabsとInputGroupの一過性SkWasmエラーは原因未確定のまま記録を保持し、今回の成功で解消済みとは扱いません。

全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件でした。Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：80 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：92 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：94 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：100 / 100 / 81 / 100。実行警告0件。

SensitiveInput単体はMobile／DesktopともAccessibility100点で、修正前のlabel-content-name-mismatchとtarget-sizeの指摘が解消しました。ギャラリーDesktopのtarget-sizeは既存の一覧側に残ります。全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDKのIntlV8BreakIterator・SkWasm map、自社の起動・転送量・一覧の操作領域、全DOM意味情報と過去のレンダラエラーは残件です。全HTML／Form／ValidityState・rich Field／全IME・screen reader・全画素は未認証です。他主要ブラウザと旧2世代、Linux／macOS／iOS・物理実機は今回ソースで未検証。Windows／Androidはビルドのみ、APKは開発用署名です。shared-ciは最新README・setup・coverageを確認してもprivate-only・公開repo未登録、Workflow0件とクラウド保留を維持します。Batch呼出・費用は0、実際の更新検出→PRの往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。

## TagInputの追加検証（2026-10-22）

ソースSHA `529e2d03d6532b46b2cb946d0c95d0a7b6f8286f`。静的解析0件、ライブラリ539件・デモ48件の計587件とPython20件が成功しました。新規は27／3件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功し、4つの製品ソースとWasm source mapの埋め込み内容が一致しました。[API対応](tag-input-api-mapping.md)に仕様と残件を保持します。

タグ一覧と入力途中の文字を分離し、制御／非制御・重複除外・検証／上限による途中採用と失敗した残りの保持を追加しました。Enter／カンマ／Tab／Backspace・入力blur、変換中の確定抑止、翻訳ラベル・Field・readOnly／disabledに対応します。選択範囲を考慮した実Clipboardの貼り付け、古い試行・編集後・破棄後の結果抑止を検証しました。24pxのタグと残り幅へ伸びる最小128pxの入力を同じ枠へ折り返して配置し、長いタグを省略します。入力名へ隣のタグ本文が混ざる問題をSemanticsの分離で修正し、マウス／WebのSemantics経由の削除操作では入力blurによる確定を抑止しfocusを戻します。矢印・Home／EndとShift選択をFlutter標準の編集アクションへ接続し、Webの貼り付けが選択範囲へ挿入されることを確認しました。空欄Enter／software doneではタグを通知しません。SDKの初期focusだけで空欄確定が通知される差も抑止しました。既存onChanged／validate／maxTagsを維持し、既定の可視ラベル・placeholderと空欄確定通知は公式に揃えています。

実Chrome 155.0.8059.86でLight/Darkの66条件・132状態を公式947065aと比較しました。標準／hover／focus、160／280px・長いタグ・RTL、空／無効／readOnly、Field／errorと明示standard、各確定キー・末尾削除・個別削除・blur、上限・途中検証、キャレット末尾／選択範囲／区切りなし／改行付きの実貼り付け、拒否する制御側／非制御／ラベル操作を含みます。採用済み配列・通知回数・入力途中の文字が一致し、外枠の矩形差は1px以内、実行時エラー0件でした。画素差はthreshold0.1で0.314〜5.666%、同じInter Regular／MediumのSHA一致を確認しましたが、全画素の認証ではありません。blurやField挿入後の非focus DOM代理値が遅れるため、両方へfocusを戻して実際のdraftを読みます。初期focus・DOM属性は別途記録し、disabled時にtextboxのAX役割がないSDKの差も残します。

日本語デモは390／1280px・Light/Darkの4条件で、日本語の追加／削除・重複、改行付き実貼り付けと上限失敗の残り、翻訳した検証エラー、空欄／再設定・RTL／制御／必須切替、readOnly／disabledと隣接操作を確認しました。HTML FormDataのhidden input、ネイティブのrequired制約検証・ValidityState・rich Field／matchは非対応です。Safari固有の生keyCode229はFlutter公開KeyEventに存在せず、TextEditingValue.composingの変換中処理をテストしています。全IME／Undo／物理タッチとscreen readerの認証は残ります。過去のTabsとInputGroupの一過性SkWasmエラーは原因未確定のまま保持し、今回の成功で解消済みとは扱いません。

全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件でした。Lighthouse（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：76 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：98 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：95 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：100 / 100 / 81 / 100。実行警告0件。

TagInput単体はMobile／DesktopともAccessibility100点でした。ギャラリーDesktopには既存の一覧側のtarget-sizeが残ります。全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDKのIntlV8BreakIterator、自社の起動・転送量・一覧の操作領域、全DOM意味情報と過去のレンダラエラーは残件です。今回のvalid-source-mapsは4条件とも成功しました。過去のSkWasm map診断は当時の記録を維持し、今回の指摘なしで全般的な解消とは扱いません。他主要ブラウザと旧2世代、Linux／macOS／iOS・物理実機は今回ソースで未検証。Windows／Androidはビルドのみ、APKは開発用署名です。shared-ciの最新README・setup・coverageでもprivate-only・公開repo未登録、Workflow0件とクラウド保留を維持します。Batch呼出・費用は0、更新検出→PRの実往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。

## Textの追加検証（2026-10-22）

ソースSHA `c454230615511014a70b01ce4aa0ed2d3a19d454`。静的解析0件、ライブラリ550件・デモ50件の計600件とPython20件が成功しました。新規は11／2件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功し、4つの製品ソースとWasm source mapの埋め込み内容が一致しました。[API対応](text-api-mapping.md)に仕様と残件を保持します。

本文・補足・成功・エラー・等幅2種・見出し4種と4サイズを追加しました。本文は12／13／14／16px、等幅は13／14pxで、太さと色は実際のCSSに従います。本文と等幅は親のfontSize×heightの計算済み行高を継承します。通常見出しは16px／行高24px・lgは20px／28px、旧variantは30／36・24／32・16／24です。装飾と見出し階層を分離し、headingLevel1〜6を明示した場合だけ意味情報の見出しになります。元のStey heading引数・subtle・boldは互換を維持します。rich span・省略時の全文Semantics・RTL・2倍の文字拡大・空文字の高さ0を追加し、日本語操作ボタンの名前にも現在値を含めました。Flutter Webは見出し要素の作成後にレベル変更を反映しないため、headingLevel変更時にSemantics境界を再作成し、DOMの直接変更なしで階層を更新します。

実Chrome 155.0.8059.86でLight/Darkの94条件を公式947065aと比較しました。本文4種×4サイズ、見出しと等幅の既定／lg、medium・継承した太さ、120px折り返し／省略、RTL、親32px行高、rich span、見出しレベル指定、2倍表示と空文字を含みます。全文・見出しレベルが一致し、外枠の矩形差は1px以内、実行時エラー0件でした。画素差はthreshold0.1で0.000〜12.816%です。Inter Regular／Medium／SemiBoldのSHA一致を確認しましたが、等幅は公式のOS書体とネイティブの既存OFL Roboto Monoが異なります。今回の最大差はRTLのアラビア語混在の条件で、差の原因の切り分けは未完了です。全画素の認証とは扱いません。参照側はflexでinline要素をblock化して矩形比較し、全inline／block formattingを認証したものではありません。CSSzoomとFlutter TextScalerによる拡大条件を比較しています。空文字でも比較枠を取得できるよう両側のfixtureに上下1pxの余白を追加し、文字自身の高さは0のままです。

日本語デモは390／1280px・Light/Darkの4条件で、10種類・4サイズの切替、見出しレベル1〜6と解除、medium・省略・狭幅・RTL・部分強調・200%表示、隣接操作を確認しました。HTMLの全as要素・UA装飾・label関連付け・空白圧縮／preformatted・選択／コピーの互換は非対応または未認証です。任意フォント・全長文／rich span・物理screen readerも残ります。過去のTabsとInputGroupの一過性SkWasmエラーは原因未確定のまま保持し、今回の成功で解消済みとは扱いません。

全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件でした。Lighthouseはギャラリーと単体の既定body表示を対象とし、全色・全背景の認証ではありません（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：78 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：97 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：94 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：100 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDKのIntlV8BreakIterator、自社の起動・転送量・一覧の操作領域、全意味情報と過去のレンダラエラーは残件です。source mapの今回の指摘有無もJSONへ記録し、過去のSkWasm map診断は保持します。他主要ブラウザと旧2世代、Linux／macOS／iOS・物理実機は今回ソースで未検証。Windows／Androidはビルドのみ、APKは開発用署名です。shared-ciの最新README・setup・coverageでもprivate-only・公開repo未登録、Workflow0件とクラウド保留を維持します。Batch呼出・費用は0、更新検出→PRの実往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。

## Linkの追加検証（2026-10-22）

ソースSHA `b147900ed6a631b04533244a627f29ffcf5d11bd`。静的解析0件、ライブラリ562件・デモ52件の計614件とPython20件が成功しました。新規は12／2件です。Web Wasm＋JavaScriptフォールバック・Windows x64・Android APKのリリースビルドが成功し、5つの製品ソースとWasm source mapの埋め込み内容が一致しました。[API対応](link-api-mapping.md)に仕様と残件を保持します。

inline／current／plainをボタンの余白なしで実装し、書体・行高・currentの色継承、Light35%／Dark65%の下線とhover、plain70%の文字・アイコン色を追加しました。外部アイコンは公式の24単位パス・1em・線幅1.75／2、間隔0.1875emです。ProviderはUriとtargetをアプリへ渡し、個別onPressedを優先します。Enter／pointerは一度だけ実行、Space／Shift+Spaceは周囲をページスクロールします。disabledは公式propでなくSteyの拡張で、実行・focus・hrefを抑止します。直接のText／RichTextは単語の最小幅を保持し、2倍・狭幅でも単語を途中で分断しません。LayoutBuilderなどはintrinsic測定を要求せず標準レイアウトを保持します。親の外側のhit test全般は未認証です。Bannerの旧Linkコピーを削除して同じ実装を再利用し、元のimportと引数を維持しました。

実Chrome 155.0.8059.86で50条件・各idle／hover／focusの150組を公式947065aと比較しました。Light／Dark、3variant、外部アイコン、親色、16px、120pxの長文折り返し、RTL、2倍・180px、無効、直接Badgeを含みます。pointer／Enterの一度の実行、Spaceの非実行、無効と隣接操作を確認し、リンク矩形の差は1px以内、実行時エラー0件でした。画素差はthreshold0.1で0.847〜24.407%です。Inter3書体のSHA一致を確認しましたが、下線のoffset／thickness／skip-inkとUA focus、Badgeの丸いfocus枠は一致認証していません。比較の成功は画素一致を意味しません。

日本語デモは390／1280px・Light／Darkの4条件で、3種類切替・Provider操作・無効時抑止・外部アイコン・狭幅・RTL・200%表示、Badgeと隣接操作を確認しました。無効化後にChromeが隣接した通常文字をAX上でまとめるため、無効化のchecked状態とAX全文を照合します。Flutter Web SDKはhrefのないaにlink役割を付与せず、無効化したリンクとonPressedだけのリンクはChrome上で通常文字になります。aria-disabledも完全には出ません。ダミーhrefやDOM変更で隠さず残件に保持し、有効なBadgeデモには実際のfragment hrefを指定しました。targetはアプリへの情報でDOM属性ではなく、rel／download・中クリック・修飾キー・全ルーター動作も未認証です。

全URLのCDP Audits.issueAdded監査は106 URL・108条件、実行時エラー0件・Issue 108件でした。Lighthouseはギャラリーと単体の既定inline表示のMobile／Desktopを対象とし、全色・全背景・全遷移の認証ではありません（Performance / Accessibility / Best practices / SEO）：

- gallery_mobile：49 / 100 / 81 / 100。実行警告0件。
- gallery_desktop：97 / 96 / 81 / 100。実行警告0件。
- isolated_mobile：92 / 100 / 81 / 100。実行警告0件。
- isolated_desktop：97 / 100 / 81 / 100。実行警告0件。

全100点・Issues0件は未達です。非スコア・警告・提案・Diagnosticsを含む全監査をJSONへ保持します。SDK非推奨API、起動・転送量・一覧操作領域、全意味情報と過去のレンダラエラーは残件です。他主要ブラウザと旧2世代、Linux／macOS／iOS・物理実機は今回ソースで未検証。Windows／Androidはビルドのみ、APKは開発用署名です。shared-ciの最新README・setup・coverageでもprivate-only・公開repo未登録、Workflow0件とクラウド保留を維持します。Batch呼出・費用は0、更新検出→PRの実往復は未実施。同期済みSHA・承認済み視覚ゲートは進めません。本番反映先はGitHub mainです。
