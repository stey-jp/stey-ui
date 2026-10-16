# DropdownのAPI対応

参照はKumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` のDropdownです。
FlutterのRawMenuAnchor・OverlayEntry・MenuItemButtonを使い、React／WebViewには依存しません。

| 公式API | Flutter側 | 留意点 |
| --- | --- | --- |
| Root / Trigger / Content | SteyDropdownMenu(items, child) | 既存のitems APIを維持。triggerはSteyButton |
| open / onOpenChange | MenuController / onOpenChanged | controllerから開閉可能。イベント原因・取消は未対応 |
| Item / onClick | SteyMenuItem / onPressed | disabled、destructive、child、shortcutに対応 |
| RTL行レイアウト | 物理left余白／check、ml-auto相当 | 左32pxの字下げ・左8pxの14px check slotを方向で反転しない。RTLではshortcut・radio check・子のcaretを文字の隣に配置。caretは公式と同じ右向き、開くキーはRTLで左矢印。戻るキーはfocus移動待ち中でも最上位の子を閉じる |
| icon component / element | icon: IconData / leading: Widget | 16pxの共通slot。独自Widgetの色指定を保持 |
| Item / Label / SubTriggerの自動字下げ | 同一popup内のiconを検出 | 閉じたsubmenuのiconは親の判定へ含めない。insetの明示指定も可能 |
| Group / Label / Separator | SteyMenuGroup / SteyMenuSeparator | グループごとの読み上げ名。ラベルと区切りは選択対象外 |
| CheckboxItem | SteyMenuCheckboxItem(value, onChanged) | 親が更新する制御値。closeOnActivate: falseで開いたまま選択 |
| RadioGroup / RadioItem / Indicator | SteyMenuRadioItem<T>(value, groupValue, onChanged) | 排他的な選択状態とcheckを表示。親がgroupValueを更新 |
| Sub / SubTrigger / SubContent | SteyMenuItem(children: ...) | 複数階層、開いた親のhighlight、hoverの100ms待機 |
| LinkItem | SteyMenuItem(href, onPressed) | URLの意味情報を付与。実際の遷移はonPressedで呼出側が実装 |
| sideOffset / alignOffset | 同名引数 | root既定8px、横submenu既定2px。横のstartでは先頭行、endでは末尾行を親行に合わせる。上下へ回り込む子は8pxの間隔・論理start／end揃え |
| 開閉遷移 | 親／子の面全体を150msでscale .95→1・opacity 0→1 | ring・影も同時に変化。CSS既定のcubic-bezier(.4, 0, .2, 1)、解決後の配置原点を使用。親は既定の中央揃え、子は先頭揃え。終了中はmountを維持し、操作・focus・意味情報を無効化 |
| data-instant | Enter／Spaceでの開閉・項目選択、Esc、プログラムによるclose | これらは即時。上下・左右矢印による表示、pointerでの選択・外側押下は遷移を使用。システムBackとTabもnative操作として即時終了 |
| popup className / width | width | 指定幅、既定最小144px。既定の衝突余白5pxと端末の安全領域を考慮。左右反転・start/end反転を試し、両側が狭い子は下／上へ回り込む。空き高さでスクロールし、rootは選択した上下の側に収める |
| anchor追従 / autoUpdate | 標準Overlayのlayout情報と子のgeometry観測 | 開いたままのviewport変更、祖先scroll、paint transform、子項目数変更に追従。開閉状態・選択・focus・150ms遷移を作り直さない。SDKによるサイズ変更／祖先scrollの自動close要求を抑え、Esc・外側押下・controller closeは維持 |
| collisionBoundary / collisionPadding | Rect? / EdgeInsets | root overlayのlogical pxによる矩形をviewportと交差し、各辺の非負の物理余白を適用。既定はviewport・5px。全階層へ適用し、矩形変更のrebuildでも選択とfocusを維持。Element／複数境界と負のpaddingは未対応 |
| sticky | bool（既定false） | trueは親・子を可能な範囲で配置境界内に保ち、起点が隠れても表示を維持。高さは境界全体の空き領域で制約し、重なる場合の変形原点を調整。開いたままの切替でも選択・focus・階層を維持 |
| anchorHidden / limitShift | 起点との接続を維持するshift | 公式の既定スタイルはanchorHiddenでも自動close／非表示にしない。起点がclipされてもメニューを維持し、横のshiftは起点から離れない範囲へ制限。縦のroot配置は起点を追従。anchorHiddenの公開状態・独自renderによる表示制御は未対応 |
| Portal / Positioner / Popup / render / container | 未対応 | 任意anchor、portal先、CSS表現の互換APIは未実装。triggerBuilderによるnative trigger指定は可能 |

上下矢印、Home／End、繰り返し文字を含む文字検索、Enter／Space、Escape、
左右矢印によるsubmenuの開閉、RTL、disabled、外側クリック、Androidの戻る通知をWidget testで検査します。
Webにはmenu／menuitem／menuitemcheckbox／menuitemradioとchecked／expandedを公開します。
物理実機・全screen readerの操作は未検証です。

既定のsubmenu衝突処理を追加しました。横の配置を優先し、両側で主軸の幅が不足するときだけ上下を試します。横のどちらかに幅がある場合は縦位置のshift／高さ制約で収めます。上下では解決した側に合わせて8pxの間隔と変形原点を使います。
Element／複数の衝突境界、すべてのBase UI継承prop、portal、描画エンジンをまたぐ影・icon・文字の完全一致は未完了です。
画像比較は診断用サンプルであり、承認済み視覚ゲートや全状態の認証ではありません。
同期済みSHAは進めていません。

子メニューを独立したOverlayEntryへ配置し、nested OverlayPortalで発生したWebの意味情報消失を避けています。TapRegionをrootと共有し、子項目の選択で外側クリック扱いにならないようにしています。DOM／SDKの改造は行っていません。任意のrich contentによる寸法とpointerの斜め移動の全仕様は未認証です。

RawMenuAnchorは150ms後までoverlayを保持し、onOpenChangedは遷移の開始時に通知します。MenuController.isOpenは終了アニメーションの間もtrueです。終了中の再表示と通知内での再表示は古い完了処理で閉じないように扱います。終了開始後に遅延したMenuItemButton callbackが届いても再実行しません。動作低減設定でも遷移を実行する点は、ユーザーのグローバル指示による公式との差異です。任意portal・すべての継承イベント理由／衝突配置の認証は残ります。

RTLの行レイアウトを同梱Interによる8テストで検証します。物理余白・グループ見出し・icon有無・shortcut／radio／通常selectedの配置、子メニューのキーとcaret、制御値と意味情報の更新、2倍文字拡大とrich childの方向を含みます。公式のselectedは隣接、radio indicatorは物理auto marginという違いも維持します。全Base UI APIと全入力／描画状態の認証は未完了です。

RTL診断の公式fixtureには文書のdirとBase UIのDirectionProviderを両方指定します。CSSだけのRTLではBase UIの論理配置・キーボード文脈がLTRのままになるため、行の描画と子メニューの挙動を同じ条件で比較します。React／Base UIは比較用fixtureだけの依存で、Flutterパッケージには含めません。

子のgeometry観測は、開いている間の実際の描画フレームにだけ参加します。変化がなければ新しいフレームを要求せず、最後の子が閉じる／破棄されると観測を解除します。RawMenuAnchorの既存のフレーム観測を増やす常時Tickerは追加しません。独立Overlayのため階層ごとの再配置はlayout後に順次反映されます。任意のclip形状・custom renderでの全hide規則、custom childの自動寸法と全実機のフレーム単位比較は未認証です。

Root overlayの衝突領域では、anchor側のMediaQueryに加えてFlutter Viewの物理padding／viewInsetsをlogical pxへ換算して使います。Scaffoldがbodyから除去したキーボード・notch余白も保持し、長い子メニューをその空き領域でスクロールさせます。呼出側の文字倍率などはMediaQueryから継承します。

collisionBoundaryは移動・resize後の矩形を呼出側で更新してください。独立root overlayへの配置は、公式の既定body portalと同様に、anchor側ScrollViewのclipでpopup自体を切り取りません。完全に隠れた起点を理由とする独自の自動終了は追加していません。[公式Kumo](https://github.com/cloudflare/kumo/blob/7e0ff40546f08405d05bc9754f0ff0fd009ece0a/packages/kumo/src/components/dropdown/dropdown.tsx)とBase UI 1.9.0のuseAnchorPositioning／hideMiddlewareを参照しています。

stickyは全階層で共通です。rootでは選択した上下の側から境界内へ移動し、子では左右反転・上下への回り込みを選んだ後に両軸を境界内へ移動します。falseは起点と接する範囲にshiftを制限する既定動作を維持します。任意のrich childの測定・全配置propとの組合せは未認証です。

明示したwidthは公式の固定幅と同様に維持します。境界がそれより狭い場合は境界外へ出ることがあり、呼出側で収まる幅を指定してください。幅を省略したrootは利用可能幅に制約します。短いメニュー内でキーボードの選択先が隠れる場合、そのメニュー内だけを必要な分だけスクロールします。画面本体のscroll位置は変更しません。

公式Base UIの既定はdisabled行にも矢印キーでfocusを移せます。現実装はFlutter標準のdisabled focusを維持してその行をskipするため、この点の互換性は未完了です。無効な操作は実行しません。sticky比較では両者に同じ文字検索・Home・矢印・Spaceを送り、同じ選択行と値にそろえて配置を検証します。

公式は500msの文字検索中にSpaceを押すと検索文字として扱います。現実装のSpaceは項目の実行となるため、検索継続中のSpace仕様も残課題です。sticky比較は文字検索の終了を600ms待ち、Spaceで選択してから配置を測定します。
