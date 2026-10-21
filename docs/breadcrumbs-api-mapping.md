# BreadcrumbsのAPI対応

公式Kumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` のBreadcrumb／Link／Current／Separator／ClipboardとSkeletonLine・useCopyFeedbackを参照します。最新確認SHA `947065ad39694fdc688b1128cc9c360f566a4f73` でもBreadcrumbsとSkeletonLineのソース変更はありません。比較用fixtureは元のSHAに固定します。

| 公式 | Flutter | 対応範囲 |
| --- | --- | --- |
| Breadcrumb / size | SteyBreadcrumbs / SteyBreadcrumbsSize | base=48px／14px／gap4、sm=40px／13px／gap2。物理右余白16px |
| children | children | 直接のLink／Current／Separatorと任意の追加内容を配置 |
| Link / href / icon | SteyBreadcrumbsLink / href / icon | 下線なし・subtle色・アイコン間隔4px。URLの意味情報とonPressedによる遷移 |
| Current / icon / loading | SteyBreadcrumbsCurrent | mediumの現在ページ。文字列だけ省略し、親リンクの幅を維持。loadingは125px枠内の8px skeleton |
| Separator | SteyBreadcrumbsSeparator | 24px、inactive色、1.5pxの右向きchevron。RTLでも反転しない |
| Clipboard / text | SteyBreadcrumbsClipboard / text | 26pxのghostコピー操作、12px Copy／bold Check（smの継承文字サイズ）。成功から2秒の表示 |
| aria-label / nav | semanticLabel / SemanticsRole.navigation | 日本語既定「パンくず」、英語既定breadcrumb |
| 任意追加内容 | childrenのその他Widget | モバイル省略時も末尾へ残す |
| 独自拡張 | copyActionLabel / tooltip / onCopied / onCopyError / focusNode | ラベル・focus・コピー結果の通知 |

画面幅が640px未満で、直接のLink／Currentが3個以上ある場合は`... → 最後から2番目 → 最後`の構成にします。省略記号と区切りは意味情報から除外します。判定は親の利用可能幅ではなくviewport幅です。2個以下なら渡された構成を維持します。祖先リンクは縮めず、Currentだけ残り幅へ縮小します。全体は単一行でクリップし、長い祖先によるはみ出しも折り返しません。

LinkはTabとEnterで操作します。Spaceでは遷移しません。Hrefは実URLの意味情報へ渡し、Flutterの画面遷移処理はonPressedに指定してください。Webの`#id`は現在のpath／queryを維持する絶対URLへ解決し、クリック時のデモ再読込を防ぎます。Webではhrefの標準遷移も発生するため、onPressedだけでブラウザ遷移を取り消すLinkProvider相当の制御は提供しません。既存の`items: List<SteyBreadcrumb>`も維持し、区切りを自動挿入します。onPressed／hrefのある項目はLink、それ以外はCurrentに対応します。itemsとchildrenは併用しません。

Clipboardは通常は透明ですが、元から存在しfocusと操作を受け付けます。親のhover時に150msで表示し、hoverを外すと同じ時間で消えます。キーボード操作性のため、Flutter側ではfocus中も表示します。公式CSSはgroup-hoverのみで、focus中に見えるとは限りません。コピーはEnterのkeydown・Spaceのkeyup、最新の非同期試行だけを反映し、再成功で2秒へ延長します。空文字はコピーしません。失敗時は成功表示を消し、破棄後の完了は無視します。

読み込み表示の幅は30〜100%、周期1.3〜1.7秒、開始遅延0〜0.5秒から作成時に選び、同じWidgetの再描画で保持します。背景・2px角丸・8px高さ・左右に通過するshimmerをネイティブ描画します。本タスクの指定により動作低減設定でもアニメーションを継続します。

## 残る差異

- Flutter 3.47にはHTMLの`aria-current=page`相当の公開プロパティがないため、Currentは選択状態と「現在のページ」のhintで表します。全screen readerでの対応は未認証です。
- Reactの直接child型判定に相当する範囲は、直接渡されたSteyBreadcrumbsLink／Current／Separatorです。任意ラッパーの内側を解析しません。CSS・ref・LinkProviderの全APIは提供しません。
- 公式はデスクトップ／モバイルのDOMを両方保持します。Flutterは表示構成を切り替えるため、境界をまたいだ子の状態保持を同一とは扱いません。
- 任意Widgetの幅測定、極端に長い祖先、クリップ外からのキーボード操作、ネイティブfocus枠、tooltip・文字・skeletonの乱数と位相を含む全画素比較は未認証です。
- Clipboardのfocus時の可視化はネイティブ側の操作性補完です。tooltipはFlutter標準の配置を使い、公式の全衝突規則は再現しません。
- Linux／macOS／iOS、物理端末、screen readerの検証は残ります。同期済みSHA・承認済み視覚ゲートは進めません。

日本語デモは`?component=breadcrumbs&mode=light`。比較用`?sample=breadcrumbs`はcrumbSize、count、long、loading、icon、copy（false）、empty、extra、host、direction、modeを指定できます。
