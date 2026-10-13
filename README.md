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

## 検証と共通CI

検査コマンドは `stey-jp/shared-ci` の中央policyに登録します。
導入後のローカル全検査は `shared-ci check --level full`、フック設定は `shared-ci init`。
手動で実行する場合はライブラリ・デモの各ディレクトリで `flutter test`、ルートで `flutter analyze`。

公開Stey UIから非公開shared-ciを呼ぶクラウド接続はユーザー指定で保留中です。
有効なGitHub Workflowはまだ配置していません。共通呼び出し案は [docs/workflows](docs/workflows)、
共通実装は shared-ci の `project-stey-ui-kumo-sync.yml` に保存します。
Runner/stepsをこのリポジトリへ複製しません。

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
