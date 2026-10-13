# Stey UI

Flutter向けUIパッケージのMonorepo。最初のパッケージは `packages/stey_ui_modern`。
Cloudflare, Inc. の [Kumo](https://github.com/cloudflare/kumo) を参照した独立実装です。
React・WebViewへの実行時依存はありません。

**開発プレビューです。Kumoの全仕様・挙動・視覚の完全再現は未完了です。**
49コンポーネント群と3ブロックをソースから列挙し、51群にネイティブ実装とデモを用意しています。
Cloudflareロゴ群は書面による商標許可待ちです。詳細と未検証項目は
[対応表](upstream/inventory.json)、[検証結果](docs/verification.md) を参照してください。
Materialの選択・日付・通知などを使った部分は、公式挙動との追加検証が必要です。

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
Android／Windowsのリリースビルドは `apps/demo` で、それぞれ
`flutter build apk --release --no-pub`／`flutter build windows --release --no-pub`。
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
