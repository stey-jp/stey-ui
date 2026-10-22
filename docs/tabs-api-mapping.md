# TabsのAPI対応

公式 `947065ad39694fdc688b1128cc9c360f566a4f73` のTabsとBase UI 1.9.0を参照します。Tabsのソースは比較SHA `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` から変更されていません。React・WebViewへの実行時依存はありません。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| tabs | List<SteyTab> | valueとlabel。空配列は表示なし。valueは一意 |
| TabsItem.label | label／child／semanticLabel | labelが標準文字列。任意childは表示を置換、読み上げ名はsemanticLabelまたはlabel |
| value | value | 制御モード。コールバックだけでは表示値を変更しない |
| selectedValue | selectedValue | 非制御モードの初期値。省略時は先頭。後から初期値だけ変更しても選択は変えない |
| onValueChange | onValueChange／onChanged | 選択変更の通知。既存onChangedも保持。両方指定すれば各1回通知 |
| activateOnFocus | activateOnFocus | falseが既定。矢印はfocusのみ、Enter／Spaceで選択。trueならfocusで選択 |
| variant | segmented／underline | 区切り型と下線型 |
| size | SteySize.base／sm | 下記実測値。xs／lgなどは互換用にbaseとして扱う |
| labels.scrollStart／scrollEnd | SteyTabsLabels | 物理方向の左／右ボタンのラベル。日本語環境では日本語既定値 |
| aria-label相当 | label | tablistの名前。日本語環境の既定は「タブ」 |
| overflow-control | 内部のネイティブボタン | segmentedのみ。150ms表示切替、残り幅の有無でfocus／操作対象から除外 |
| 既存disabled | SteyTab.disabled | Flutter側の拡張を維持。focus移動は飛ばし、選択しない。公式TabsItemの公開引数にはない |
| 旧SteyMenuBar | 非推奨alias | SteyTabsへ委譲。既存tabs／value／onChangedを保持 |

以前のFlutter実装の「矢印で常に即時選択」は公式の既定へ変更しています。従来の即時選択を維持する場合は `activateOnFocus: true` を指定してください。値を制御する場合は通知を受けて親側のvalueを更新します。コールバックを省略した制御値は読み取り専用として保持します。存在しない非制御の初期値／削除された選択値は利用可能な先頭へ戻し、一度通知します。制御値が存在しない場合は選択表示を隠します。

| 種類 | Root高 | Tab高 | 左右余白 | 文字／行高 | Indicator |
| --- | ---: | ---: | ---: | ---: | --- |
| segmented base | 36px | 32px | 10px | 14／21px | Tabの実測矩形、角丸6px |
| segmented sm | 26px | 22px | 8px | 12／16px | Tabの実測矩形、角丸4px |
| underline base | 30px | 24px | 8px | 14／21px | 底辺の上に2px |
| underline sm | 26px | 20px | 6px | 12／16px | 底辺の上に2px |

segmentedは上下2px・左右2pxの内側余白、recessed背景、hairlineの70%リング、baseの選択表示とshadow-smを使います。underlineは16px間隔、hairline底辺、brandの選択表示を使います。文字はInter Medium。タブのhover色は即時です。見出し文字列だけで幅を推定せず、childを含めた実測矩形から200ms・cubic-bezier(.4,0,.2,1)で選択表示を動かします。途中変更時は現在位置から開始します。動作低減設定でも明示した時間で動きます。

左右矢印はRTLで逆転し、先頭／末尾を循環します。Home／Endで両端へ移動し、上下矢印やCtrl／Alt／Meta付きキーでは選択を変えません。Spaceはkeyupで選択します。FlutterのFocusNodeとtraversalでは現在の1項目をTab移動の入口にします。無効項目は移動・選択の対象外です。

親で有限の幅を与えて使用します。幅を超える内容は横スクロールし、focus／クリックしたタブを48pxのscroll paddingで表示範囲へ近づけます。スクロールボタンの距離は、viewportに収まるタブの丸めた幅の合計です。ネイティブのsmooth移動は300ms easeOutで、ブラウザのscrollIntoViewの全経路と一致する保証はありません。マウスは3pxを超える横移動でドラッグへ切り替え、直後のクリックによる選択を抑制します。タッチにはFlutterの標準横スクロールを使います。

**公式との既知の差**：公式のoverflow検出はRTLの負のscrollLeftを0に丸めるため、初期表示で右ボタンが出ても動かないケースがあります。Flutterは物理的に左へ移動できるとき左ボタン、右へ戻れるとき右ボタンを表示します。この差を公式との一致として扱いません。矢印ボタンのhover色の補間、ブラウザ固有のsmooth scroll、CSS transitionの反転規則は未認証です。

**Flutter Web SDKの制約**：公開Semantics APIでtablist／tab／選択状態／名前とfocusを設定しています。SDKはfocus可能でなくなった既存DOMノードからtabindexを削除せず、矢印操作後に複数のtabindex=0が残ります。初期状態の入口は1項目ですが、Web DOMのroving tabindexは未達です。無効tabへのenabled=falseもaria-disabledへ変換されません。DOMを書き換えたり、読み上げ対象を隠したり、意味情報ノードを都度再作成する対策は採っていません。Flutter内の移動・選択と、実際のTabキーで次のボタンへ抜ける動作は別に確認します。物理screen readerの認証は残ります。

任意のHTML属性・className／listClassName／indicatorClassName、TabsItem.render／nativeButton、リンクとしてのタブ、DOMイベントの完全な置換はありません。公式ラッパーは水平リストのみを公開し、Tabs.Panelや縦方向の引数は公開していません。任意Widgetのラベルは標準の文字・focus・選択の扱いを保持し、内部の別操作を重ねる用途は対象外です。文字拡大・任意child・タッチ慣性・全画素・全物理実機は未認証です。

日本語デモは `?component=tabs`。小さいサイズ・下線・focusで選択・タブ数・RTL・非制御・無効項目・図形付きラベルを切り替えられます。旧MenuBarのデモもこの操作画面を使います。比較用 `?sample=tabs` はmode／variant／size／value／uncontrolled／frozen／activate／rich／many／empty／host／directionに対応します。比較の成功は全ライブラリの再現認証ではなく、同期済みSHAと承認済み視覚ゲートは進めません。

日本語デモの最初の実Chrome検査でWasmの `function signature mismatch` が1件発生しました。スタック未取得のため原因は未特定です。その後の同一4条件と追加8周では再現せず、解消済みとは扱いません。
