# ClipboardTextのAPI対応

参照は公式Kumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` のClipboardText、Input／Button、Base UI 1.9のTooltip、Phosphor regular Copy／Checkです。

| 公式 | Flutter | 対応範囲 |
| --- | --- | --- |
| text | SteyClipboardText(text) | 読取専用の本文と右側のコピー専用ボタン。本文の押下ではコピーしない |
| textToCopy | textToCopy | 未指定なら本文。空文字・改行・タブ・Unicodeも原文を渡す |
| size | size: SteyClipboardSize | sm=26px、base=36px、既定lg=40px。本文は12／13／13px、行高16／15.294／15.294px、角丸6／8／8px |
| onCopy | onCopied | 書込成功後に通知。失敗は通知せず、既存の成功表示を維持 |
| labels.copyAction | copyActionLabel | 既定はLocaleに応じた「クリップボードにコピー」／Copy to clipboard。成功中もボタン名を維持 |
| tooltip | SteyClipboardTooltip | 未指定はアイコンとlive regionのみ。指定するとhover／keyboard tooltipと成功toastを表示 |
| tooltip.text / copiedText | tooltip.text / copiedText | Localeによる既定はコピー／コピーしました、Copy／Copied |
| tooltip.side | SteyClipboardSide | top／bottom／left／right。ボタンから8px、画面端では反転と位置補正 |
| ref / className | key / Flutterの配置Widget | HTML divやCSSクラスは提供しない |

`focusNode`・`autofocus`・`onCopyError`はFlutter側の追加APIです。公開コンストラクタのsizeはfieldSizeへ保持し、既存のSteyInlineCopyTextサブタイプとその文字サイズAPIを維持します。`SteyClipboardText(text, inline: true)`も維持します。

本文は一行で省略し、選択を可能にします。本文の意味情報は原文を明示し、選択機構の内部focusをWebのTab停止位置へ重複させません。コピーはEnterのkeydown／repeat、Spaceのkeyupで実行します。Spaceのrepeat・focus離脱後のkeyupは実行しません。

成功表示は最後の書込成功から1.5秒後に戻り、コピー／checkを200msでスライド・フェードします。並行要求は完了順で表示時間を更新します。Tooltipはhoverで600ms後、keyboard focusでは即時に表示し、Escape・focus離脱・hover離脱で閉じます。コピー時はtooltipを成功toastへ切り替え、連打時も各ボタンにつき一つを維持し、350msで拡大・復帰します。ユーザー指示により動作低減設定でもアニメーションを維持します。通知はOverlayPortalでスクロールや再配置へ追従します。

```dart
SteyClipboardText(
  'account_12345',
  textToCopy: 'account_complete_12345',
  size: SteyClipboardSize.lg,
  tooltip: const SteyClipboardTooltip(
    text: 'コピー',
    copiedText: 'コピーしました',
    side: SteyClipboardSide.top,
  ),
  onCopied: onCopied,
);
```

従来の簡易ボタンから、公式の入力欄へ表示を変更しています。通知時間は2秒から公式の1.5秒へ、成功中のボタン名は「コピーしました」への変更から固定の操作名へ変更しました。成功は別のlive regionで通知します。

## 残る差異

- 公式の本文monospace・通知のfont-sansに対して同梱Roboto Mono／Interを使うため、文字幅・glyph・アンチエイリアスに差があります。
- ネイティブの選択メニュー・クリップボード・focus輪郭・影と、HTML／CSSの描画は完全一致未認証です。Tooltipの意味情報はFlutterのtooltipプロパティへ対応し、HTMLのaria-describedbyの構造は再現しません。
- 各Widget内で通知を保持します。Base UIの外部toast manager、全衝突規則・複数通知のポータル構成・マウスをtooltipへ移す際のhover経路は完全対応していません。
- 古いブラウザ向けexecCommandフォールバックは追加せず、FlutterのClipboardを利用します。破棄後の書込完了は通知・状態変更を行いません。
- タッチ端末・物理screen reader・各OSの権限表示は未検証です。全イベント・全状態の視覚認証、同期済みSHA・視覚ゲートは進めません。

日本語デモは `?component=clipboard-text&mode=light`。比較用 `?sample=clipboard-text` はtext／value／fieldSize／host／tooltip／side／offsetY／direction／modeに対応します。
