# CodeのAPI対応

参照はKumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` の `src/components/code`、`src/code`、`src/styles/kumo.css`。従来の `SteyCode`／`SteyCodeBlock` は維持し、構文強調を別Widgetとして追加しています。React・Shiki・WebViewの実行時依存はありません。

| 公式 | Flutter | 対応範囲 |
| --- | --- | --- |
| Code / CodeBlock | SteyCode / SteyCodeBlock | 従来の選択可能なプレーンコード。構文強調は行わない。原文を読み上げラベルへ明示 |
| CodeHighlighted.code / lang | SteyCodeHighlighted(code, lang: ...) | 原文を保つ選択可能なコード。横スクロール、折り返しなし |
| variant=default / plain | standard / plain | 既定は枠・角丸6px・余白16px。plainは枠・余白なし。固定参照のCSSに合わせ13px／行高21.125px |
| showLineNumbers | showLineNumbers | 複数行のみ。1始まり、横スクロールから独立、読み上げ対象外 |
| highlightLines | highlightLines | 1始まり。範囲外と重複を無視。解析不能時は背景強調なし |
| showCopyButton | showCopyButton | 1行はコードの直後、複数行は右上。コピー内容に行番号を含めない |
| copyLabel / copiedLabel | 同名の引数 | Widgetの指定を共有設定より優先。既定Copy / Copied!、デモは日本語 |
| ShikiProvider | SteyCodeHighlighting | 言語設定とラベルの共有。highlighter=nullでプレーン表示 |
| languages / aliases | SteyCodeHighlighter(languages: ...) | 18識別子と公式の別名。大文字は受け付けず、mdxも対象外 |
| async copy feedback | Clipboard + 2秒の通知 | 最新の試行を優先、再コピーでタイマー更新、破棄後の応答を無視。失敗はonCopyErrorへ通知 |

```dart
SteyCodeHighlighting(
  highlighter: SteyCodeHighlighter(languages: ['js', 'json']),
  copyLabel: 'コピー',
  copiedLabel: 'コピーしました',
  child: const SteyCodeHighlighted(
    'const answer = 42;\nconsole.log(answer);',
    lang: 'js',
    showLineNumbers: true,
    highlightLines: [2],
    showCopyButton: true,
  ),
);
```

識別子はjavascript / typescript / jsx / tsx / json / jsonc / html / css / python / yaml / markdown / graphql / sql / bash / shell / diff / hcl / toml。別名はjs/cjs/mjs、ts/cts/mts、sh/zsh、yml、py、md、gqlです。未指定の共有設定は標準解析器を使い、未知の言語・共有設定の対象外言語・解析失敗時は原文を表示します。

## 残る差異

- 解析器はMITのre_highlight 0.0.3（Highlight.js 11.9.0のDart移植）で、公式ShikiのTextMate解析とは異なります。github-light / vesperの色を意味分類へ対応させていますが、トークン境界・分類・全色の一致は未達です。
- JSX/TSXはJavaScript/TypeScript内のXML、JSONCはJSONのコメント対応、TOMLはINI文法を利用します。HCLは基本のブロック・属性・コメント・文字列・数値の独自文法で、ヒアドキュメントや完全な式・補間には未対応です。18言語の完全な文法互換を意味しません。
- 解析は同期で初回利用時に文法を登録し、結果をcode/lang/theme/解析器ごとに保持します。ShikiのJS/Wasmエンジン指定、サーバー用コンポーネント、非同期バンドル読込APIは提供しません。巨大ファイルの解析時間・メモリ上限は未検証です。
- コピーは150msのフェードでhover、コピー成功中に加え、キーボードfocusでも可視化します。動作低減設定でも遷移を維持します。原文の選択・OSの選択メニュー・クリップボード権限はFlutterとプラットフォームの実装に従います。Windows ChromeはOSとの境界で改行をCRLFへ変換します。物理端末の読み上げと選択メニューは未検証です。
- 等幅表示をプラットフォーム間で保つためOFLのRoboto Monoを同梱しています。公式のOS依存monospaceとはglyph・文字幅に差があります。リッチコードには原文をsemanticsLabelとして与え、空の読み上げ内容を避けます。スクロールバー、選択描画などの差も残ります。全状態の視覚認証・同期済みSHAの更新は行っていません。

日本語デモは `?component=code&mode=light`、比較用は `?sample=code-highlighted&lang=javascript&mode=light`。比較用のlang/code/width/variant/numbers/highlight/copy/fallbackはURLで指定できます。検証結果は[検証記録](verification.md)へ追記します。

同期の対応表は従来の `src/components/code/` に加え `src/code/` をCode群へ割り当てます。新しい文法ファイルもこの群だけへ振り分けます。API一覧には従来の固定SHAのソースを追加し、同期済みSHAは進めていません。クラウドの接続保留も維持します。
