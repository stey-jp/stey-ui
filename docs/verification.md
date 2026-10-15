# 検証結果（Button／Sidebar更新：2026-10-16）

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
