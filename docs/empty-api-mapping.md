# EmptyのAPI対応

公式Kumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` のEmpty、Text、Button、useCopyFeedbackを参照します。FlutterのWidget・描画・Clipboardで独立実装します。

| 公式 | Flutter | 対応範囲 |
| --- | --- | --- |
| title | title | 必須文字列。意味情報はh2相当 |
| description | description | null／空文字は省略。指定時は見出し20px・semibold、未指定時は14px・subtle・通常ウェイト |
| size | SteyEmptySize | sm／base／lg、既定base |
| icon | illustration | 任意Widget。装飾として意味情報から除外。省略時はアイコンなし |
| contents | contents | 任意の追加内容。ボタン・リンク・複数操作を配置可能 |
| commandLine | commandLine | null／空文字は省略。生の全文をコピー。長いコマンドは横スクロール |
| Copy command | copyActionLabel | 既定は日本語／英語のコピー名。成功時も名前は維持 |
| copy feedback | 内部状態 | 最新の試行だけが成功・失敗を反映。成功完了から1秒表示、再成功で延長 |
| className | 配置Widget | HTML／CSS APIは提供しない |
| 独自拡張 | onCopied / onCopyError | 現在の試行が成功／失敗した時だけ通知 |

外側は幅いっぱい、角丸12px・1pxのfill境界・control背景です。水平／垂直余白と要素間隔はsmが24／32／16px、baseが40／64／24px、lgが48／80／32px。見出しと説明の間隔は10px。説明は最大560px・中央揃え・14px／行高1.5です。見出しの行高は説明あり1.4、なし1.5です。寸法は公式ソースをSkillの一般規則より優先します。

コマンドは高さ40px、内容幅の最大80%、角丸8px。overlay背景・白い境界・lineの外側ring・小さい影を公式どおり使います。この白い境界は公式が明示する例外です。物理左12／右8pxの余白、gap8px、26pxのghostコピー操作、16pxのCopy／Checkを使います。`$`は選択・読み上げ対象から除外し、コマンド本文だけ選択できます。Tabはコピー操作へ移動し、Enterのkeydown・Spaceのkeyupでコピーします。

成功チェックは400ms ease-outのscale／opacityアニメーションで表示し、連続成功ではアニメーションを再起動せず表示期限だけ延長します。失敗時はチェックを消し、古い成功／失敗は無視します。破棄後の完了は反映しません。コマンドの変更だけでは成功表示をリセットしない点も公式のhookと同じです。動作低減設定でも本タスクの指定に従ってアニメーションを維持します。

従来のactionとIconData型のiconは維持し、contents／illustrationを優先します。iconの自動表示は廃止し、省略時を公式に合わせます。これにより既存の空のリスト・チャートにも標準のEmpty枠が表示されます。

## 残る差異

- CSSのtext-balanceを再現する改行エンジンはありません。Flutterの通常改行で、説明を中央揃えにします。フォント・日本語・任意Widget・選択メニューの全視覚比較は未認証です。
- コマンドはパッケージ内のSteyCodeMono、公式はOSのui-monospaceを使用します。文字幅と自然幅・コピー操作の横位置に差が残ります。比較には未補正の矩形も記録します。
- Chromeは公式のoverflow領域を自動でTab移動先に追加する場合があります。Flutter側もSelectionAreaのWeb意味情報に追加のTab停止位置を持つ場合があります。通常のWidgetの移動先とDOMの移動先には差があり、ブラウザの停止位置まで同一にはしません。比較では実際のTab移動でコピー操作への到達を確認します。
- 文字拡大時はコマンドを必要な行高まで広げ、操作性を保ちます。公式の固定40pxから変わる場合があります。外側には有限の横幅が必要です。
- クリップボードの権限・失敗内容はプラットフォームが管理します。成功通知は公式同様アイコン表示が中心で、自動toastは追加しません。デモの操作回数表示はデモ側で管理します。
- 物理タッチ端末、screen reader、Linux／macOS／iOSでの操作と、全中間フレームの位相比較は残ります。同期済みSHA・承認済み視覚ゲートは進めません。

日本語デモは`?component=empty&mode=light`。比較用`?sample=empty`はemptySize、description（none）、command（none／long）、icon、actions、multiple、long、host、direction、modeを指定できます。
