# CollapsibleのAPI対応

公式Kumo `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` とBase UI 1.9.0のソースを参照します。FlutterのWidget・描画・Focus・Semanticsで独立実装しています。

| 公式 | Flutter | 対応範囲 |
| --- | --- | --- |
| Collapsible / Root | SteyCollapsibleRoot | open指定は制御、未指定はdefaultOpenによる非制御。disabledを起点へ継承 |
| onOpenChange | onOpenChange | boolと変更詳細。reason:triggerPress、cancel()で取消。外部からのopen変更では呼ばない |
| Trigger | SteyCollapsibleTrigger | 無装飾の起点。任意child、disabledの明示指定で親を上書き |
| Trigger.render | builder | dataのopen・disabled・focusNode・onPressedを使ってSteyButtonなどを構成 |
| DefaultTrigger | SteyCollapsibleDefaultTrigger | 14px／行高1.5／medium、gap4、16pxの枠内に12pxのcaret。100ms ease-outで180度回転 |
| Panel | SteyCollapsiblePanel | 無装飾・即時開閉。既定では閉じると子を破棄 |
| DefaultPanel | SteyCollapsibleDefaultPanel | 高さと不透明度を100ms ease-outで変更。初期open時は即時表示 |
| Panel.keepMounted | keepMounted | 閉じても子の状態を保持。falseでは閉じ終わってから破棄 |
| Panelの子 | child / children | DefaultPanelは複数の子の間隔16px。childとchildrenの併用は不可 |
| id / aria-controls / aria-expanded | panelIdentifier / Semantics | 開いている間だけ起点からPanelへの関連を公開。IDの既定値はRootごとに生成 |
| ref / className / style | key / 配置Widget | HTML・CSS APIは提供しない。配置と装飾はWidgetで指定 |

DefaultPanelの上下の外余白は8px、物理左辺の枠2px、枠内の左余白16px・右4px・上下4pxです。RTLでも枠は左辺です。閉じる間は展開時に測った高さを使い、子の幅・自然な高さを保ちます。開いている間の動的な高さ変更にも追従します。

起点はTab・Enterのkeydown・Spaceのkeyupで操作します。Spaceのリピートでは開閉せず、focusが外れたら押下状態を解除します。閉じた子はfocus・意味情報・ポインター操作の対象から除きます。プログラムで閉じる際に子がfocusを持っていれば起点へ戻します。アニメーションは利用者の本タスクの指定に従い、動作低減設定でも継続します。

Panelの識別情報は高さのクリップの外に置き、最初のフレームの登録後にexpandedとcontrolsNodesを同時に公開します。Flutter 3.47ではcontrolsNodesだけを変えても意味情報の差分通知が送られないため、実際の展開状態と関連付けを同じ更新で伝えます。DOMの直接書換えやSDKの変更は行いません。

従来の`SteyCollapsible(open,onChanged,title,child)`は互換用の簡便な構成として維持し、keepMountedの既定値trueを保ちます。新しいRoot＋Panelの既定値は公式と同じfalseです。旧200ms表示は公式の100msへ変更し、閉じた保持内容はOffstageへ移します。

## 残る差異

- ブラウザのhiddenUntilFound／beforematchによるページ内検索からの自動展開は未実装です。対応したように見せるフラグは設けません。
- Reactのrender・ref・全HTMLイベント、CSS／React.Activityによる子アニメーション制御は提供しません。変更詳細のreason:noneは予約値で、beforematchの実動作はありません。
- 閉じ始めた時点で子のfocus・意味情報を除外します。公式DOMは閉じ終わるまでhiddenになりません。プログラムによる閉鎖時のfocus復帰もネイティブ側の補完です。
- 通常の100ms遷移と途中反転時の子の保持を検査します。反転時のCSSの短縮規則と全中間フレーム、文字計測、ブラウザ標準focus枠との全画素一致は未認証です。
- 組み合わせ用Rootのchildは呼出側でColumnなどへ配置します。横幅無制約や固定高の親では適切な制約・スクロールを指定してください。
- 物理タッチ端末・screen reader・Linux／macOS／iOSでの操作検証は残ります。同期済みSHAと承認済み視覚ゲートは進めません。
- Flutter Webでは保持した入力を再表示した直後、非focusの意味情報用DOM入力のvalueが空で、focus後に保持値へ同期することを観測しました。描画・Widgetの状態・focus後の入力値は保持されますが、読み上げ側の値同期は追加検証が必要です。デモの実操作検査は実キー入力とfocus後の値で判定し、DOMの値を直接書き換えて補正しません。

日本語デモは`?component=collapsible&mode=light`。比較用`?sample=collapsible`はkind（default／bare／custom）、open、controlled、cancel、state（disabled）、keep、input（状態保持カウンター）、long、multiple、host、direction、modeを指定できます。比較用カウンターは自動検証の観測用で、日本語の製品デモには表示しません。
