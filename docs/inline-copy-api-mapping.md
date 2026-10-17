# InlineCopyTextのAPI対応

参照は公式Kumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` の `src/components/inline-copy-text/inline-copy-text.tsx`、同テスト、Text、Phosphor regular CopySimple／Checkです。

| 公式 | Flutter | 対応範囲 |
| --- | --- | --- |
| children=string | SteyInlineCopyText(text) | 枠・余白なし。既定はmono-secondary、文字13px／行高19.5px |
| value | value | 未指定なら表示テキスト。空文字・タブ・改行・Unicodeも原文を渡す |
| rich children + value | SteyInlineCopyText.rich(child, value: ...) | コピー値は必須。子へのpointer・focus・意味情報をコピー操作へ集約 |
| variant | SteyInlineCopyVariant | body / secondary / success / error / mono / monoSecondary |
| size / bold | SteyInlineCopySize / bold | xs=12、sm=13、base=14、lg=16px。monoは既定13px、lg=14px、boldなし |
| truncate=true | truncate=true | 1行・省略記号。アイコン14pxと間隔4pxを常に確保 |
| disabled | disabled | 表示を保ち、pointer・keyboard・意味情報の操作とfocusを無効化 |
| labels | copyActionLabel / copiedLabel | Localeに応じた日英の既定値。成功時にボタン名とlive regionを更新 |
| onCopy | onCopied | 書込成功後に通知 |
| onClick + preventDefault | onBeforeCopy | falseで書込・通知・既存タイマーの再設定を中止 |
| group-hover / group-focus-within | SteyInlineCopyGroup | 親のhover・子へのfocusでアイコンだけを表示。外側グループの状態も伝える |
| hover / focus-visible | MouseRegion / Flutter Focus | 自身へのhover・keyboard focusでmono-secondaryを既定色へ即時変更。copyアイコンは150msで表示 |
| copy feedback | Clipboard / Timer | checkへ即時切替、1.5秒後に復帰。再クリックで参照中タイマーを解除。並行要求は公式と同じ完了順 |
| ref | key / focusNode | ネイティブfocusノードを指定。DOMノードは提供しない |

Enterはkeydown、Spaceはkeyupで実行します。Spaceのrepeatやfocus離脱後のkeyupでは実行しません。成功のcheckとcopyで幅を変えません。Windows Chromeはクリップボードの境界でLFをCRLFへ変換します。

```dart
SteyInlineCopyGroup(
  child: SteyInlineCopyText(
    'account_12345',
    value: 'account_complete_12345',
    copyActionLabel: '完全なIDをコピー',
    copiedLabel: 'コピーしました',
    onCopied: onCopied,
  ),
);
```

既存の `SteyInlineCopyText(text, onCopied: ...)` と `SteyClipboardText(text, inline: true)` を維持します。前者は従来と同じSteyClipboardTextのサブタイプです。通常のClipboardTextの表示・2秒通知は変更していません。`onCopyError` はネイティブ側の失敗通知用の追加APIです。

## 残る差異

- 公式のOS依存monospaceに対しRoboto Monoを使います。短い等幅文字列の幅、glyph、アンチエイリアス、focus輪郭の描画に差があります。
- truncate=falseの長い未分割文字列は、CSSのmin-contentによるはみ出しとFlutterの折り返しが異なります。任意のrich childの組版は完全一致未認証です。
- CSSクラス・HTMLのas・DOMイベントの詳細はWidget・callback・focusNodeへ対応します。rich childの独立した対話操作には対応しません。
- 公式のmotion-reduce指定に対し、ユーザー指示に従い動作低減設定でも150msのfadeを維持します。
- 破棄後に完了した書込は通知・状態変更を行いません。全タイマーを破棄時に解除します。
- 物理screen reader・タッチ・各OSの権限表示、全イベント・全描画状態は未検証です。同期済みSHA・承認済み視覚ゲートは進めません。

日本語デモは `?component=inline-copy-text&mode=light`。比較用は `?sample=inline-copy-text` にtext/value/textVariant/textSize/host/rich/bold/disabled/truncate/cancel/group/direction/modeを指定できます。
