# BadgeのAPI対応

公式Kumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` のBadge、variant定義・テストとtheme-kumo.cssを参照します。最新観測 `947065ad39694fdc688b1128cc9c360f566a4f73` でもBadgeのソース差分はありません。

| 公式 | Flutter | 対応範囲 |
| --- | --- | --- |
| Badge / children | SteyBadge / child | 12px・medium・16px行高、左右8／上下2px、単一行・非縮小 |
| variant | SteyBadgeVariant | 公式定義に存在する17種類。destructiveはredと同じ旧名 |
| appearance | SteyBadgeAppearance | filled／dot。dotはvariantの背景・文字・borderを適用しない |
| dotColor（内部） | variantから選択 | success／warning／error／neutralだけ7pxの装飾dot、間隔6px |
| icon | Widget? | filledのみ。物理左余白6px、幅12px・行高の枠に12pxのglyph、間隔4px |
| beta／outline | 同名variant | 1pxのborderにより幅・高さが各2px増加。betaは破線 |
| a:hover祖先 | SteyBadgeLinkScope | 文字色の1px外側ring。dotのhairlineを置換、betaの破線は維持 |
| 既存拡張 | tone／dot／outline | 互換APIを維持。明示variantがtoneより優先 |

SteyLink／SteyBreadcrumbsLinkは祖先hoverのscopeを持ちます。任意のリンク実装は`SteyBadgeLinkScope(child: ...)`で囲んでください。scopeは意味情報・Tab停止点を増やさず、外側scopeのhoverも引き継ぎます。リンクの余白や兄弟上のhoverでもBadgeへ伝わり、色は即時切り替わります。リンク外のBadgeへ直接hoverしてもringは出ません。focusだけでは追加ringを出しません。

Badgeは操作部品ではなく状態を表す本文です。狭い親でも文字を省略せず固有幅を保持するため、親でスクロールやクリップなどの配置を選択してください。文字拡大時もglyphは12pxを保ち、iconの行枠と本文だけを拡大します。空のTextは空行を作りません。

## 差異と残件

- 公式の`bg-kumo-badge-teal-subtle`は参照CSSに定義がないため透明背景になります。意図を推測して別色にしません。
- `neutral-subtle`／`inverted`はコメントに記述がありますがvariant定義に存在しません。Flutterのenumへ追加していません。
- iconとdotは公式型でも併用できません。既存Flutter APIとの互換のためdotではiconを描画しません。
- CSS／className・任意DOM祖先・React Icon factoryは移植しません。任意Widget、複数行を内包するrich child、空白折畳み、browserの破線配置と文字rasterの完全一致は未認証です。
- リンク本体の全仕様は別の対応項目です。scope追加によってLinkProviderやHTML遷移を変更しません。
- 全画素・全状態・screen reader・実機とLinux／macOS／iOSの認証は残ります。同期済みSHAと承認済み視覚ゲートを進めません。

日本語デモ：`?component=badge&mode=light`。比較用`?sample=badge`はvariant、appearance、icon、link、scale、long、empty、host、direction、modeに対応します。
