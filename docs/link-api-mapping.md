# LinkのAPI対応

参照：Cloudflare Kumo `947065ad39694fdc688b1128cc9c360f566a4f73` の`link.tsx`、`link-provider.tsx`、`kumo-binding.css`。該当ソースは`7e0ff40`から差分なしです。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| inline（既定） | SteyLinkVariant.inline | link色・下線。親の書体、サイズ、太さ、行高を継承。ボタンの余白・最小高さを付けない |
| current | SteyLinkVariant.current | 親の文字色を継承する下線リンク |
| plain | SteyLinkVariant.plain | 下線なし。hover時はlink色の70%不透明度 |
| link-current | 下線の色 | Light35%／Dark65%、hoverで100%。即時更新。CSS transition-colorsの時間補間はSkillの指示に従い追加しない |
| Link.ExternalIcon | SteyLinkExternalIcon／external=true | 公式24単位のパスをCanvasで描画。1em、線幅Light1.75／Dark2。読み上げから除外。間隔0.1875em |
| href／LinkProvider | href／SteyLinkProvider | アプリのonNavigateへUriとtargetを渡す。onPressedを指定したリンクはそちらを優先。ライブラリ自身はURL起動・ルーターへ依存しない |
| target | target | Providerへ渡す遷移情報。アイコンだけでは別タブを指定しない。Flutter Webの生成DOMにtarget属性を追加するものではない |
| native anchor activation | FocusNode／Enter／pointer | 一度だけ実行。Space／Shift+Spaceは周囲をページスクロールし、リンクを実行しない。隣接操作とBadge祖先のhoverを維持 |
| inline-flex min-content | ネイティブの最小内容幅 | 直接のText／RichTextは単語＋アイコンの最小幅を保持し、狭い親で単語の途中を分割しない。親より広い内容の描画を許容するが、親の外側のhit test全般は未認証。LayoutBuilder等の任意Widgetはintrinsic測定を要求せず、そのWidgetの標準レイアウトを保持 |
| aria-label | semanticLabel | 子の意味情報に代わる読み上げ名。リンク自身はbuttonの役割を持たない |
| disabled | disabled／旧onPressed=null | 公式に専用propなし。Steyの無効化拡張として実行・focus・URLを抑止。色の減衰は追加しない |
| visited | 独自色なし | 公式にvisited専用スタイルなし。ブラウザの履歴・プライバシー動作全体はネイティブで再現しない |
| render／asChild／任意DOM・ref | Widget child／Key | 通常のWidget合成。任意HTMLタグやイベントのmerge、React Routerのrender propをエミュレートしない |

元の`child`・`onPressed`・`external`・`href`を保持し、`button.dart`からのexportも維持します。Bannerは専用の旧Linkコピーを削除し、同じLinkを使用します。ボタンの高さ／角丸を期待していた既存Linkの外観は、公式の文字リンクへ修正されます。

Flutter標準の文字装飾はCSSの`text-underline-offset:0.15em`・`text-decoration-thickness:0.0625em`・skip-inkと全画素一致しません。focusの枠もOS／ブラウザのUA outline全体を再現しません。CSSの直接子Badge用rounded-full、全選択／コピー・任意Widget構成と全フォントも未認証です。

Flutter Web SDKはlinkの意味情報を`a`として生成しますが、hrefのない操作リンクと、無効化でhrefを除いたリンクはChromeのAXツリーで通常文字になります。無効時のaria-disabledもSDKが完全には出力しません。ダミーURLやDOMの書き換えで隠さず、検証記録へ保持します。Webで有効なリンク役割が必要な場合は実際のhrefとアプリの遷移処理を設定します。Browser target／rel／download、修飾キー・中クリック・コンテキストメニューの全動作は未認証です。

比較対象は公式ソースの表示とアプリfixtureの操作です。disabledは公式propでなくfixture側の方針であることを区別します。全画素・物理screen reader・他ブラウザと全プラットフォームの検証は残ります。[検証結果](verification.md)に実測値を保持します。
