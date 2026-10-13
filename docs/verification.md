# 検証結果（2026-10-13）

これは開発プレビューの検証記録です。依頼の全完了条件は未達です。

## 成功した検証

- Flutter 3.47.0 / Dart 3.13.0で `flutter analyze`：指摘0。
- ライブラリのWidget test：42件成功。キーボード、無効／loading、入力の重複しない読み上げ、フォームのrequired／optionalとエラー、Loaderの合成周期と動作低減設定、秘密表示、タグ、タブ、検索候補、ダイアログ、折り畳み、カレンダー3モードと年境界、Sidebarの読み上げ名・ドラッグの上下限・左右のキーボード操作・sliding viewsの入力保持と非表示画面のフォーカス／読み上げ除外、CommandPaletteのグループ・無効項目・Ctrl+Enter・検索・強調・loading・Escapeを検証。
- デモtest：5件成功。52群をLight/Dark・390px/1280pxで描画し、例外とoverflowを検査。
- Python同期テスト：18件成功。予約前保存、再試行を合算した予算上限、受付不明時停止、失敗要求だけの再処理と成功結果の保存、競合とパス制限、ドキュメント更新時のAI不使用、再処理防止、ライセンス変更時停止、提案適用からPR作成までの模擬フロー。
- Webリリースビルド成功。Wasm＋JavaScriptフォールバック、ローカル配信、ソースマップ、`-O4`。生成mapへビルド入力ソースを埋め込み、Flutter loader mapも配信。
- Windowsリリースビルド成功。このWindows PCで起動、ボタンの反応、disabled／loadingの無反応、Light/Dark、状態保持を実操作で確認。
- AndroidリリースAPK成功（開発用署名、49.6MB）。API 36エミュレーターで起動、ボタンの反応、disabled／loadingの無反応、Light/Dark、状態保持、実行時エラー0件を確認。
- Linuxリリースビルド成功。Ubuntu 24.04.5 x64の専用コンテナ／Xvfb仮想画面／ソフトウェア描画で起動、ボタンの反応、disabled／loadingの無反応、Light/Dark、状態保持を操作して確認。GTKの設定スキーマとアクセシビリティbusを用意した後は、実行ログにエラーはありません。物理Linux PCや全機能・screen readerの実操作検証は未実施です。

Checkbox／Switchの追加10テストとRadioの追加5テストで、親の部分選択復元・無効な子の扱い・混合状態・ラベルtooltip・Space／Enter、150msの遷移、カードとsegmented、制御状態、RTLと文字拡大を検査しています。

実ChromeでもLight/Darkで、Checkbox／SwitchのpointerとSpace、Radioのカード／segmented・左右矢印・無効項目スキップ・循環を確認しました。
混合CheckboxのWeb読み上げ状態は後述のSDK問題が残ります。

最新のビルド・起動・操作は同じ範囲ではありません。各検証のソースSHAは別添JSONに記録し、WindowsのCheckbox操作、Androidのボタン操作、Linuxのボタン操作の後に加えたRadioの表示修正は、全native環境で操作確認済みとは扱いません。

模擬フローではネットワーク／課金／GitHub書き込みをfakeにしているため、実OpenAI APIや実同期PRの成功は示しません。

## 完全再現の未達

49コンポーネント群＋3ブロックの一覧は upstream/inventory.json に記録。
51群に基本のネイティブ実装と操作例を用意しましたが、全プロパティ・全状態・全複合部品との一致は未認証です。
特にSidebarのpeeking・mobile sheet・全複合API、CommandPaletteの全複合API、汎用ChartのECharts全option、Sankeyのdrilldown、Globeの地形、CodeHighlightedの構文強調、フォームの全検証match等が残っています。Sidebarのリサイズとsliding viewsは実装・操作テスト済みですが、全仕様の再現とは扱いません。旧Code／CodeBlockは公式の透明背景／10px padding・6px radius・borderへ修正。
CloudflareLogo／PoweredByCloudflareのアセットは公式商標ガイドラインにより書面許可待ちです。

公式固定SHAのButton/Badge/Inputを152サンプル（Buttonの6variant×5状態とサイズ／形状、Badge全variantのfilled／dotを含む）で描画し、実Flutter描画とピクセル比較しました。
この旧152サンプルは比較環境のReactが19.3.0で、公式lockfileの19.2.0より新しい版でした。予備比較として記録を保持しますが、公式固定依存での全認証とは扱いません。
今回のCheckbox／Switchの144サンプルとRadioの32サンプルでは、React／React DOM 19.2.0、Base UI 1.9.0、Phosphor 2.1.10、Tailwind 4.3.3を公式lockfileと一致させています。主要依存と候補Wasmのハッシュを各サンプルへ記録しました。
Checkbox／Switchの描画領域の差分は最大約8.95%、Radioは最大約21.6%で、完全一致の認証ではありません。Radioはグループ無効化時の濃さと、円の物理pixel位置を公式描画に合わせて修正しました。文字・線のラスタライズを含む差分が残ります。

フォント、ボタンのグラデーション、色の混合、寸法、外側ring、Hintの標準文字間隔を修正しました。43色×Light/Darkの86トークンを公式CSSのブラウザ描画と比較し、背景へ合成後の各色成分は1以内の差でした。Tailwindの値は公式lockfileと同じ4.3.3のpaletteを参照し、var()のfallbackを誤って優先しないよう修正しました。
Browserの標準root font-sizeは16pxを維持し、Flutterの文字スケール計算が誤って0.875倍になる問題を修正しました。標準font-sizeを20pxへ変更した場合にも、文字とボタンが拡大することを実Chromeで確認済みです。
loading画像は公式とFlutterのアニメーション位相を同期しておらず、周期と操作性は別のWidget testで検査しています。静止画像の差分には描画エンジンの文字・線のラスタライズ差も含みます。
最終差分と品質監査は [計測記録](verification-record.json) を参照。
全面積に対する差分比率だけでは小さなコンポーネントの一致を証明できず、全状態の機能比較も必要です。
背景以外の描画を囲む領域でも差分を算出しました。文字だけのghostボタンでは、その狭い領域の差分が約21%あり、画像全体の差分率が小さいことを「完全一致」とは扱いません。
承認済みの全コンポーネント視覚基準は未整備で、upstream/visual-fixtures.json は空です。
この状態の自動同期は視覚ゲートで停止することを確認しています。全52群×Light/Darkの104組が揃わない場合も失敗として扱い、一部の基準だけでは成功にしません。104組の揃いだけで全状態の再現を認証するものではありません。

## Web品質

実Google Chromeで52群×Light/Darkの104 URLをCDP Audits.issueAddedで監査しました。
読み上げ名の自社実装、生成入力要素の一意ID、URL履歴を修正し、Mobileアクセシビリティ100／SEO100を確認。
コンポーネント／テーマのURL保存とブラウザの戻る／進むを実操作で確認。
最新のLighthouseはMobile：Performance 80 / Accessibility 100 / Best practices 81 / SEO 100、Desktop：99 / 96 / 81 / 100です。実行警告はありません。非スコア項目を含む全監査指摘を別添JSONに記録しています。

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
Webデモはローカルで検証済み、公開ホスティングは未設定です。pub.devへは公開していません。
