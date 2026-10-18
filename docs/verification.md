# 検証結果（Collapsible：2026-10-19）

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
