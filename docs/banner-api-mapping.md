# BannerのAPI対応

公式Kumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` のBanner／Banner.Actionを参照します。React・DOM・WebViewは使用しません。

| 公式 | Flutter | 対応範囲 |
| --- | --- | --- |
| title / description | title / description | Stringのタイトルと任意Widgetの説明。指定時は旧child／textより優先 |
| variant | SteyBannerVariant | defaultValue／alert／error／secondary。本文色とアイコンのaccent色を区別 |
| size | SteyBannerSize | baseは左右16・上下12px、gap12・角丸8。smは左右12・上下8px、gap8・角丸6 |
| icon | icon | 任意Widget。装飾アイコンとして読み上げ対象から除外。未指定なら表示しない |
| action | action | 任意Widgetまたは複数操作。baseは末尾、smのSteyLinkは本文内へ配置 |
| children / text | child / text | 旧形式。childが優先。構造化したtitle／descriptionがない場合はactionを使わない |
| Link.href | SteyLink.href | Uriを意味情報の実URLへ渡す。画面遷移は呼出側で処理 |
| Banner.Action | SteyBannerAction | primary／secondary／ghost。親の色とbase→sm=26px、sm→xs=20pxを継承 |
| ActionのButton props | onPressed / loading / icon / trailing / shape / semanticLabel / focusNode / autofocus | 既存SteyButtonを使用。disabledはonPressed:null。sizeは親からのみ指定 |
| role / aria-live | Semantics / liveRegion | 通常は読み上げを強制しない。必要時はliveRegion:trueまたは呼出側のSemanticsで指定 |
| ref / className / style | key / 配置Widget / ButtonStyle | HTML ref・CSSの再現は対象外。SteyButton.styleで操作部分の必要な描画を上書き |

baseはタイトル14px・説明13px、smは双方13pxです。構造化本文の行高は1.375、旧形式は1.5。タイトルはmedium、baseの説明との間隔は2pxです。smはタイトルと説明を同じ行へ配置し、狭い幅では折り返します。タイトルなしでは本文側に1pxの上余白を持たせます。公式ソースの寸法をSkillの一般的な14px規則より優先します。

操作ボタンのprimaryは公式accentのOKLCHによる白／黒との混色から生成したグラデーションを使います。secondaryはaccentの50%の枠、ghostは枠なし。hoverの背景変更は即時です。Tab・Enter、Spaceのkeyupで操作でき、処理中／無効時は実行しません。compactのリンクはボタンの余白を持たず、説明の行内に配置し、Enterで操作します。

```dart
SteyBanner(
  variant: SteyBannerVariant.alert,
  size: SteyBannerSize.sm,
  title: '設定の確認が必要です',
  description: const Text('保存前に公開先を確認してください。'),
  action: SteyBannerAction(
    onPressed: reviewSettings,
    child: const Text('確認する'),
  ),
);
```

既存のtone・onDismissも維持します。tone指定時の自動アイコンとsuccess色は互換用で、公式の追加variantではありません。variantの明示を優先します。onDismissのラベルはdismissLabelで変更でき、既定は日本語／英語です。従来の自動live regionは廃止し、必要時に明示します。

## 残る差異

- Flutterの任意Widgetのレイアウト、RichText内のリンク、選択UIはDOM／CSSと同一構造ではありません。HTMLのイベント詳細・全render構成は提供しません。
- compactリンクはHTMLではglyph矩形、Flutterでは行領域として意味情報を持ち、未補正の高さに差があります。比較は公式のcomputed line-heightを用い、元の矩形も記録します。
- ネイティブの文字計測、下線、外部リンクアイコン、focusの輪郭、ボタンの影、loadingの位相を含む全画素・全状態の一致は未認証です。
- 極端な狭幅、複数の大きな操作Widget、任意の埋め込み要素は呼出側で幅・スクロール・配置を調整してください。物理タッチ端末とscreen readerは未検証です。
- 同期済みSHA・承認済み視覚ゲートは進めません。

日本語デモは `?component=banner&mode=light`、比較用は `?sample=banner`。bannerVariant／bannerSize／actionVariant／action／title／description／long／legacy／icon／state／host／direction／modeを指定できます。
