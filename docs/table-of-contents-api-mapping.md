# Table of ContentsのAPI対応

表示部品はKumo `f46e8bc9922c37dc1d3e7da779e589fe171df306`、追跡処理は不正ハッシュ修正後の `dc7c513f6f2db54aa6a0b58555b7fd9e413ee3b1` を参照しています。
Flutterの描画・Focus・Semantics・ScrollControllerで実装し、Webだけ標準JS interopでhashchangeを購読します。
ブラウザのDOMへ目次を別描画したり、React・WebViewを組み込んだりはしません。

| 公式API | Flutter側 | 動作 |
| --- | --- | --- |
| TableOfContents / aria-label | SteyTableOfContents / label | navigation領域。既存のitems / activeId / onSelectedも維持 |
| Title | SteyTableOfContentsTitle | 12px・600、下余白12px。公式CSSに合わせ大文字変換、字間0.3px |
| List | SteyTableOfContentsList | listの意味情報、2pxのガイド、行間8px |
| Item / active | SteyTableOfContentsItem / active | listItem内のlink、現在位置・URLの意味情報、青いガイド |
| href / onClick | href / onPressed | hrefはURL・意味情報、実際のスクロール／ルーティングはonPressedで接続 |
| children / render | child / focusNode | Widget内容・FocusNodeを指定可能。React要素のclone APIは使わない |
| Group | SteyTableOfContentsGroup | リンク付き・非リンクのラベル、子の字下げ。子の操作は親のcallbackを発火させない |
| useTableOfContentsActiveId | SteyTableOfContentsController | activeIdを公開するChangeNotifier |
| ids / root | sections / scrollController | 文書順のMap<String, GlobalKey>と単一の縦スクロールルート |
| offset | offset | ルート上端からの距離。追跡範囲とジャンプ先に適用 |
| selectSection | selectSection | 選択を固定。最後のscrollから150ms後に解除、次の追跡で更新 |
| trackHash | trackHash / syncFromFragment | Webは初期hash・hashchangeを購読。nativeのRouterからは明示的に渡す |
| anchorの標準スクロール | scrollToSection / scrollOnHashChange | Flutterの見出しへ移動。初期hashは即時、明示選択は既定300ms |

先頭の可視見出しをMap順で選び、見出しのない長い本文では直前の選択を保持します。
`%`・`%ZZ`・不正UTF-8は例外を外へ出さず、デコードできない場合は生のIDと照合します。
`50%-off`、`caf%C3%A9`、後続の有効なhashchangeにも対応します。二重デコードはしません。
controllerは履歴を直接書きません。デモはRouterでfragmentとcomponent／modeを保存します。
Flutter WebのPathUrlStrategyはincludeHashを有効にし、起動時にfragmentが消えないようにしています。
fragmentだけのhrefはWebで現在のURLに解決し、base hrefによるpath／queryの脱落を防ぎます。
Routerを同時更新する利用側は、その設定値から組み立てた完全なhrefを渡してください。デモもこの方法でテーマを保持します。
Flutter 3.47のWeb engineはURI通知を丸ごとデコードするため、デモのRouter通知境界で不正UTF-8のfragmentだけを保護します。
engineのデコード後に元のfragmentへ戻る形で渡し、`#%FF`もURL・クエリを保持します。SDK改造や例外の抑止は行いません。

`sections`のキーは見出しWidgetへ配置します。未mount／別ルートのキーは無視します。
項目追加はupdateSections、本文や見出しの配置変更はrefreshを呼びます。
controllerをdisposeするとイベント購読とタイマーを解除します。ScrollControllerの所有権は呼出元にあります。
Webのhistory.pushStateはhashchangeを出さないため、その操作を持つRouterはselectSectionまたはsyncFromFragmentも呼びます。

公式の実際のCSS計算値を優先し、本文は13px／行高20px、長いリンクは1行でクリップします。
一般的なkumo-designの本文14px・字間変更禁止の指針と異なる点は、ユーザー指定の公式再現を優先しています。
RTLではガイドと字下げを反転し、文字倍率に応じて行を拡張します。hoverの色は即時に切り替わります。

全プラットフォームでの実機・スクリーンリーダー操作、複雑なネスト／変形された見出し、
全状態の視覚認証は未完了です。任意hrefの外部遷移は利用側のonPressedで実装してください。
対応表のvisual_verified / behavior_verifiedと同期済みSHAは、これらが完了するまで進めません。
