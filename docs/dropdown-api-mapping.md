# DropdownのAPI対応

参照はKumo `1846759162f8dd1cd6028738fceefd2e0cd97d66` のDropdownです。
FlutterのMenuAnchor・OverlayEntry・MenuItemButtonを使い、React／WebViewには依存しません。

| 公式API | Flutter側 | 留意点 |
| --- | --- | --- |
| Root / Trigger / Content | SteyDropdownMenu(items, child) | 既存のitems APIを維持。triggerはSteyButton |
| open / onOpenChange | MenuController / onOpenChanged | controllerから開閉可能。イベント原因・取消は未対応 |
| Item / onClick | SteyMenuItem / onPressed | disabled、destructive、child、shortcutに対応 |
| icon component / element | icon: IconData / leading: Widget | 16pxの共通slot。独自Widgetの色指定を保持 |
| Item / Label / SubTriggerの自動字下げ | 同一popup内のiconを検出 | 閉じたsubmenuのiconは親の判定へ含めない。insetの明示指定も可能 |
| Group / Label / Separator | SteyMenuGroup / SteyMenuSeparator | グループごとの読み上げ名。ラベルと区切りは選択対象外 |
| CheckboxItem | SteyMenuCheckboxItem(value, onChanged) | 親が更新する制御値。closeOnActivate: falseで開いたまま選択 |
| RadioGroup / RadioItem / Indicator | SteyMenuRadioItem<T>(value, groupValue, onChanged) | 排他的な選択状態とcheckを表示。親がgroupValueを更新 |
| Sub / SubTrigger / SubContent | SteyMenuItem(children: ...) | 複数階層、開いた親のhighlight、hoverの100ms待機 |
| LinkItem | SteyMenuItem(href, onPressed) | URLの意味情報を付与。実際の遷移はonPressedで呼出側が実装 |
| sideOffset / alignOffset | 同名引数 | root既定8px、横submenu既定2px。submenu先頭行の上端を親行に合わせる |
| popup className / width | width | 指定幅、既定最小144px。画面端では横方向の反転・安全領域への制約・縦スクロールを使用 |
| Portal / Positioner / Popup / render / container | 未対応 | 任意trigger、anchor、境界、portal先、CSS表現の互換APIは未実装 |

上下矢印、Home／End、繰り返し文字を含む文字検索、Enter／Space、Escape、
左右矢印によるsubmenuの開閉、RTL、disabled、外側クリック、Androidの戻る通知をWidget testで検査します。
Webにはmenu／menuitem／menuitemcheckbox／menuitemradioとchecked／expandedを公開します。
物理実機・全screen readerの操作は未検証です。

公式の150ms scale／opacityアニメーション、上下へ回り込むsubmenuの配置規則、
すべてのBase UI継承prop、portal／任意trigger、描画エンジンをまたぐ影・icon・文字の完全一致は未完了です。
画像比較は診断用サンプルであり、承認済み視覚ゲートや全状態の認証ではありません。
同期済みSHAは進めていません。

子メニューを独立したOverlayEntryへ配置し、nested OverlayPortalで発生したWebの意味情報消失を避けています。TapRegionをrootと共有し、子項目の選択で外側クリック扱いにならないようにしています。DOM／SDKの改造は行っていません。任意のrich contentによる寸法とpointerの斜め移動の全仕様は未認証です。
