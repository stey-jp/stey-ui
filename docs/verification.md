# 検証結果（2026-10-13）

これは開発プレビューの検証記録です。依頼の全完了条件は未達です。

## 成功した検証

- Flutter 3.47.0 / Dart 3.13.0で `flutter analyze`：指摘0。
- ライブラリのWidget test：19件成功。キーボード、無効／loading、入力、秘密表示、タグ、タブ、検索候補、ダイアログ、折り畳み、カレンダー3モードと年境界、Sidebarの読み上げ名、CommandPaletteのグループ・無効項目・Ctrl+Enter・検索・強調・loading・Escapeを検証。
- デモtest：5件成功。52群をLight/Dark・390px/1280pxで描画し、例外とoverflowを検査。
- Python同期テスト：13件成功。予約前保存、予算上限、受付不明時停止、失敗要求だけの再処理、競合とパス制限、提案適用からPR作成までの模擬フロー。
- Webリリースビルド成功。Wasm＋JavaScriptフォールバック、ローカル配信、ソースマップ、`-O4`。生成mapへビルド入力ソースを埋め込み、Flutter loader mapも配信。
- Windowsリリースビルド成功。製品の実機起動／操作は未検証。
- shared-ci中央テスト85件、設定検査、coverage contract、actionlint、GitHub Verify shared CI成功。中央mainとローカルmainのSHA一致を確認。

模擬フローではネットワーク／課金／GitHub書き込みをfakeにしているため、実OpenAI APIや実同期PRの成功は示しません。

## 完全再現の未達

49コンポーネント群＋3ブロックの一覧は upstream/inventory.json に記録。
51群に基本のネイティブ実装と操作例を用意しましたが、全プロパティ・全状態・全複合部品との一致は未認証です。
特にSidebarのリサイズ／sliding views、CommandPaletteの全複合API、汎用ChartのECharts全option、Sankeyのdrilldown、Globeの地形、CodeHighlightedの構文強調、フォームの全検証match等が残っています。旧Code／CodeBlockは公式の透明背景／10px padding・6px radius・borderへ修正。
CloudflareLogo／PoweredByCloudflareのアセットは公式商標ガイドラインにより書面許可待ちです。

公式固定SHAのButton/Badge/Inputを20サンプルで描画し、実Flutter描画とピクセル比較しました。
フォント、ボタンのグラデーション、色の混合、寸法を修正しました。最終差分は別添の計測JSONを参照。
全面積に対する差分比率だけでは小さなコンポーネントの一致を証明できず、全状態の機能比較も必要です。
承認済みの全コンポーネント視覚基準は未整備で、upstream/visual-fixtures.json は空です。
この状態の自動同期は視覚ゲートで停止することを確認しています。

## Web品質

実Google Chromeで52群×Light/Darkの104 URLをCDP Audits.issueAddedで監査しました。
読み上げ名の自社実装を修正し、Mobileアクセシビリティ100／SEO100を確認。
最新のMobile/DesktopスコアとIssues数は別添JSONへ記録します。

残るエンジン由来の指摘：Flutter 3.47.0のbrowser detectionがIntl.v8BreakIteratorを参照するためDeprecationIssueが出ます。
生成main.dart.jsとCanvasKitの起動処理・配信サイズ・未使用コード・WASM source mapにもLighthouse指摘があります。
Flutter SDK改造や計測時だけの起動抑止、アクセシビリティ無効化はしていません。
4カテゴリ100／対応可能な全指摘0は未達です。

## プラットフォームと運用の未検証

macOS・Linux・Android・iOSのrunnerは生成済みで、ライブラリにdart:io/WebView/React依存はありません。
macOS/Linux/iOSのbuildおよび全OSの実機操作は未検証。AndroidはSDK license未承認です。
SDKライセンス承認や新しいクラウド接続は実行していません。

OpenAIキーはStey jpプロジェクトの制限付きキーとしてGitHub Secretsに保存済み。
誤作成したStey UIプロジェクトはArchive、値が表示された旧キーは失効、新しいキーへ置換済み。
実Batch送信→回収→PR作成は、ユーザー指定で共通CIクラウド接続が保留のため未検証・無効です。
Webデモはローカルで検証済み、公開ホスティングは未設定です。pub.devへは公開していません。
