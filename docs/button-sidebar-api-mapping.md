# Button・Sidebar階層のAPI対応

参照はKumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a`。
Buttonの変更元は `cdb7e0f`、Sidebar.MenuSubの変更元は `17d094e` です。

| 公式の仕様 | Flutter側 | 留意点 |
| --- | --- | --- |
| 文字の光学的な位置 | SteyButton | xs/smは0.5px、base/lgは1px上げる。先頭icon／Loaderは中央へ戻す |
| icon＋文字の左padding | SteyButton(icon: ..., child: ...) | 通常paddingから2px減らす。公式のpl指定に合わせて物理的な左側へ適用 |
| icon component / element | IconData由来のIcon / 任意Widget | 未指定サイズのIconは文字サイズ12/14pxへ追従し、明示サイズ・色は保持 |
| 文字のない条件付きchildren | 空のText／Text.rich、SizedBox.shrink | 持ち上げ・非対称padding・余分なgapを適用しない。任意Widgetの内部までは判定しない |
| square / circle | SteyButtonShape | 寸法を維持。xsの14px枠へ大きいiconを収め、中央に配置 |
| サイズ別gap | SteyButton | xs/sm 4px、base 6px、lg 8px。emphasisの内部行は公式同様6px |
| Sidebar.MenuSub | SteySidebarMenuSub | 左padding 28px、ガイド位置19px、幅1px、上下1px。listの意味情報を公開 |
| Sidebar.MenuSubItem | SteySidebarMenuSubItem | listItemを公開。MenuSubが未指定の子を自動で包み、二重には包まない |
| Sidebar.MenuSubButton | SteySidebarMenuSubButton | 高さ34px、文字13px、角丸8px。selected／onPressed／focusNode／semanticLabelに対応 |
| 階層の開閉・選択 | SteySidebarItem(children: ...) | 既存APIを維持。各階層のガイド、展開状態、現在項目を反映 |
| ResizeHandleのhidden / sm:block | SteySidebar(resizable: true) | 公式と同じ640px以上のviewportで表示。線とdesktopの操作幅は維持 |

ガイドはIgnorePointerとExcludeSemanticsで操作・読み上げ対象から外し、
実際の子項目だけをlistItemとして公開します。DOMの後付け修正は行いません。
Webの現在項目はFlutterの意味情報によりaria-currentへ変換されます。

LinkButton独自の全prop、任意childrenを含む全レイアウト、全Sidebar parts、
全screen reader・物理実機・全視覚状態の認証は未完了です。
物理的な左右位置を含めた公式CSSとの照合であり、全コンポーネントの同期完了とは扱いません。
