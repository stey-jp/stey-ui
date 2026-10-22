# Stey UI

Flutter向けUIパッケージのMonorepo。最初のパッケージは `packages/stey_ui_modern`。
Cloudflare, Inc. の [Kumo](https://github.com/cloudflare/kumo) を参照した独立実装です。
React・WebViewへの実行時依存はありません。

**開発プレビューです。Kumoの全仕様・挙動・視覚の完全再現は未完了です。**
49コンポーネント群と3ブロックをソースから列挙し、51群にネイティブ実装とデモを用意しています。
Cloudflareロゴ群は書面による商標許可待ちです。詳細と未検証項目は
[対応表](upstream/inventory.json)、[再現チェックリスト](docs/parity-checklist.md)、[検証結果](docs/verification.md) を参照してください。
Materialの選択・日付・通知などを使った部分は、公式挙動との追加検証が必要です。
Checkbox／Switch／Radioのネイティブ描画と複合グループを実装しています。
APIの対応範囲と差異は [Checkbox／Switch](docs/checkable-api-mapping.md)、
[Radio](docs/radio-api-mapping.md) を参照してください。
Selectもネイティブのポップアップ、単一／複数選択、グループ、文字検索を実装しています。
既存の値管理APIを維持し、[SelectのAPI対応](docs/select-api-mapping.md)に差異を記録しています。
目次の階層表示・スクロール追跡・URLハッシュ連携を追加しています。
[目次のAPI対応](docs/table-of-contents-api-mapping.md)で利用方法と未検証範囲を確認できます。
Dropdownに階層メニュー・Checkbox／Radio選択・自動字下げ・キーボード操作と150msの開閉遷移を追加しています。
公式の物理余白に合わせたRTL行を実装し、日本語デモで表示方向を切り替えられます。
矩形の配置境界・各辺の余白を指定でき、表示中のresize・scrollと、起点が隠れた際の追従に対応します。
stickyによる境界内保持も指定でき、日本語デモで既定の追従と切り替えられます。
disabled行へのフォーカスと500msの文字検索・Space処理、階層間のキーボードフォーカスを追加対応しています。
日本語デモと[DropdownのAPI対応](docs/dropdown-api-mapping.md)で操作と制限を確認できます。
Buttonの文字位置・アイコン余白と、Sidebarの階層リスト・装飾ガイド・640pxでのリサイズ操作切替を追加対応しています。
[Button／SidebarのAPI対応](docs/button-sidebar-api-mapping.md)に適用範囲を記録しています。
LayerDialogを専用の多層表示とモバイルシートへ置き換え、主操作・関連メニュー・削除確認・処理中の終了制御を追加しています。
日本語デモと[LayerDialogのAPI対応](docs/layer-dialog-api-mapping.md)で操作と未対応範囲を確認できます。
ButtonGroupの連結境界・RTL・フォーカス描画と、Flowの余白付きアンカー・丸い接続線を追加しています。
[ButtonGroup／FlowのAPI対応](docs/group-flow-api-mapping.md)と[完成までの工程](docs/completion-plan.md)を参照してください。
FlowのList／Parallel構成からの自動接続、内容の実測、縦方向・中央・末尾揃えも追加しています。
[Flowの構成API](docs/flow-api-mapping.md)を参照してください。
canvasは公式と同じ倍率固定で、背景のパン・縦横wheel・はみ出し通知・スクロール表示に対応します。
Node.maxWidthで説明を折り返し、内容と幅の変化に合わせてノード・接続を再配置できます。
標準ノードは初期の利用可能幅と図の測定履歴にも対応し、親幅変更後の保持と再作成時の測定を日本語デモで確認できます。
固定した比較対象の後に検出した公式更新は、[最新差分レビュー](upstream/latest-review.json)に未対応事項と併せて記録します。
CodeHighlightedにDart製の構文強調、行番号・行の強調・コピーを追加しています。
日本語デモで18言語の識別子と表示を切り替えられます。[CodeのAPI対応](docs/code-api-mapping.md)にShikiとの文法・色分けの差と未対応範囲を記録しています。
InlineCopyTextに枠なし表示、明示したコピー値、hover・focus・行グループ、1.5秒の成功表示を追加しています。[InlineCopyTextのAPI対応](docs/inline-copy-api-mapping.md)を参照してください。
ClipboardTextも本文とコピー専用ボタンを持つ入力欄へ置き換え、3サイズ・別のコピー値・4方向の通知を追加しています。[ClipboardTextのAPI対応](docs/clipboard-api-mapping.md)と日本語デモで確認できます。

Bannerにもタイトル・説明・compact表示と色・サイズを引き継ぐ操作ボタンを追加しています。[BannerのAPI対応](docs/banner-api-mapping.md)と日本語デモを参照してください。

CollapsibleにRoot・Trigger・Panelの組み合わせ、制御／非制御、開閉取消、100msの標準表示を追加しています。日本語デモで入力内容の保持／破棄とボタン型の起点を操作できます。[CollapsibleのAPI対応](docs/collapsible-api-mapping.md)にページ内検索・反転時のCSS規則などの残件を記録しています。

Emptyに3サイズ、説明に応じた見出し、任意図版と追加操作、横スクロールできるコマンドと1秒のコピー成功表示を追加しています。[EmptyのAPI対応](docs/empty-api-mapping.md)と日本語デモで範囲と差異を確認できます。

Breadcrumbsに組み合わせAPI、2サイズ、640px未満の省略、現在ページの切詰め、読み込み表示とコピー操作を追加しています。[BreadcrumbsのAPI対応](docs/breadcrumbs-api-mapping.md)に意味情報・focus・任意構成の差を記録しています。

Badgeにリンク祖先のhover枠・12pxアイコン枠・単一行の幅保持と日本語操作デモを追加しています。[BadgeのAPI対応](docs/badge-api-mapping.md)に対応範囲と残件を記録しています。

Loaderに3サイズpreset・status、SkeletonLineに乱数幅・周期・遅延・blockHeightと日本語デモを追加しています。[LoaderのAPI対応](docs/loader-api-mapping.md)に最新公式との対応と未認証範囲を記載しています。

Paginationに組み合わせAPI、ページ番号の入力／選択、件数選択、総件数不明時の前後移動と日本語デモを追加しています。[PaginationのAPI対応](docs/pagination-api-mapping.md)に最新公式の入力検証と残件を記録しています。

Meterに値域・独自表示値・数値書式・300msの幅変化と日本語デモを追加しています。[MeterのAPI対応](docs/meter-api-mapping.md)に読み上げのSDK制約と未認証範囲を記録しています。

Sliderに複数つまみ・衝突方式・刻み値・確定通知・取消・RTLと日本語デモを追加しています。[SliderのAPI対応](docs/slider-api-mapping.md)に操作仕様とWebの意味情報に関するSDK制約を記録しています。

```text
packages/
  stey_ui_modern/     # 他のデザインパッケージから独立したFlutterライブラリ
apps/demo/           # Web・Windows・macOS・Linux・Android・iOS用ギャラリー
upstream/            # 参照SHA、全コンポーネント対応表、費用設定、視覚比較定義
tools/               # 製品固有の差分処理・Batch同期・回帰テスト・監査
```

将来の `stey_ui_pixel` は独立パッケージとして追加できます。不要な共通UI基盤は置いていません。
pub.devへは公開していません。

## 使用例

Flutter 3.47.0 / Dart 3.13以上。Git依存の `path: packages/stey_ui_modern` を指定して使用します。

```dart
import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: SteyTheme(
    brightness: Brightness.light,
    child: Scaffold(
      body: SteyButton(
        variant: SteyButtonVariant.primary,
        onPressed: save,
        child: const Text('Save'),
      ),
    ),
  ),
);
```

デモはルートで `flutter pub get`、`cd apps/demo`、`flutter run -d chrome`。
デモの表示・操作ラベル・日時UIは日本語です。日本語名と英語のコンポーネント名で検索できます。
見出しには英語名も併記し、公式との視覚比較用の `?sample=...` は英語の比較文言を保持しています。
検索・テーマ切替・コンポーネント操作・公式デモ／固定SHAソースへの比較リンクを備えます。
直接URLは `?component=button&mode=dark` の形式です。
選択とテーマをURLへ保存し、戻る／進むで復元します。
リリースデモはWasm＋JavaScriptフォールバックで生成します。
Web検証ツールを `npm ci --ignore-scripts` で用意し、ビルド後は
`python tools/prepare_web_artifacts.py`、ローカル配信は
`python tools/serve_demo.py --cross-origin-isolated`。Wasmの並列描画には
COOP `same-origin` とCOEP `credentialless` を配信環境へ設定します。
[Flutter公式Wasm仕様](https://docs.flutter.dev/platform-integration/web/wasm)

## 検証

ルートで `flutter pub get --enforce-lockfile`、`flutter analyze --no-pub` を実行します。
ライブラリ・デモの各ディレクトリで `flutter test --no-pub`、
ルートで `python -m unittest discover -s tools -p 'test_*.py'` を実行します。
Webのリリースビルドは `apps/demo` で
`flutter build web --wasm --release --no-pub --source-maps --no-web-resources-cdn -O4`。
Android／Windowsのリリースビルドは `apps/demo` で、それぞれ
`flutter build apk --release --no-pub`／`flutter build windows --release --no-pub`。
Linuxの開発環境では `flutter build linux --release --no-pub`。
Androidのエミュレーター操作検証は `python tools/smoke_android.py --device <device-id>`。
APKは開発用署名を使用し、ストア公開向けの署名設定は含めません。
有効なGitHub Workflowは配置していません。

## Kumo同期

[同期仕様](docs/synchronization.md) を参照してください。日次検出・非同期Batch送信・別実行の回収・
秘密を持たない検証・成功時のみ通常pushとPR作成、という構成です。mainの自動マージはありません。

`OPENAI_API_KEY` はこのリポジトリのGitHub Secretsに保存します。デモへは渡しません。
モデルは軽微な変更にGPT-4.1 nano、複雑な変更にGPT-5.4 mini。Batch料金は通常APIの50%です。
[公式Batch仕様](https://developers.openai.com/api/docs/guides/batch)

初期上限は月5米ドル・1同期0.50米ドル・2試行。価格情報は90日で再確認を要求します。
変更がなければAIを呼びません。待機のためにRunnerを稼働させません。
同期は完全な公式視覚比較データとクラウド接続が揃うまで有効化しません。

## ライセンス

[MIT](LICENSE)。派生するデザイントークンのCloudflare著作権表示は
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) とパッケージのLICENSEに保持しています。
Cloudflare®とKumoはCloudflare, Inc. の商標であり、本プロジェクトに提携・推奨関係はありません。
ロゴは [公式商標ガイドライン](https://www.cloudflare.com/trademark/) に従い、書面許可なしでは配布しません。
