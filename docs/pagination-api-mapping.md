# PaginationのAPI対応

公式 `947065ad39694fdc688b1128cc9c360f566a4f73` のPaginationソース・単体／ブラウザテストを参照します。比較用React fixtureのInputGroup／Select依存は既存比較SHA `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` です。ライブラリ全体の同期済みSHAは進めません。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| Pagination page／setPage | SteyPagination page／onChanged | 制御型。既定ページ1。更新は親側で反映 |
| perPage／totalCount／hasNextPage | 同名の引数 | 既知の総件数を優先。最大ページは切上げ、空データでも最小1 |
| childrenによる構成 | child | Info／Separator／PageSize／ControlsをRow・Wrap等で配置 |
| Pagination.Info children関数 | SteyPaginationInfo(builder: ...) | page／perPage／totalCount／maxPage／pageShowingRangeを渡す。通常は総件数が正の時だけ表示 |
| Pagination.PageSize | SteyPaginationPageSize | 既定25／50／100／250。value／onChanged／options、任意label、showLabel=falseでラベルと余白を省略 |
| Pagination.Controls | SteyPaginationControls | full／simple、input／dropdown。総件数不明かつhasNextPage指定時は前後ボタンのみ |
| Pagination.Separator | SteyPaginationSeparator | 幅1・高さ24px、左右8px。装飾として意味情報から除外 |
| labels | SteyPaginationLabels | navigation／firstPage／previousPage／nextPage／lastPage／pageNumber／pageSize |
| 既存Flutter API | totalPages／label／infoBuilder | 従来の呼出を保持。totalPagesはperPage省略時に1件単位の総件数へ変換 |

入力は文字列で保持し、Enterまたはblurで前後の空白を除いてASCII整数だけを確定します。空欄・小数・符号・指数・16進・全角数字などは元のページへ戻し、通知しません。有効な0・過大値は1〜最大ページへ補正します。有効入力は同じ値でも通知します。巨大な整数はBigIntで安全に補正します。親のpageが変わった時だけ下書きを置換し、同値の再描画では保持します。外部から最大ページを超えるpageが与えられた場合も次／最後を無効にします。

PageSize単体はページを自動リセットしません。日本語デモでは親側で1ページへ戻します。全ページ選択は公式同様に列挙するため、大量ページには入力式を使用してください。日本語localeでは既定のラベルと件数表示を翻訳し、labels／builderで明示指定できます。旧形式のInfoだけlive regionを付け、Controlsをnavigation landmarkとして公開します。

操作群は高さ36px、矢印16px、入力50px、ボタン42pxと1px重なりを使用します。Flutter標準のTextField・TextButtonと独自描画、既存のネイティブSelectで実装し、React／WebViewへ実行時依存しません。

未認証範囲はSelectの連結角丸・ポップアップ寸法／意味情報、focus描画の重なり、文字／矢印の全画素、任意構成・拡大・screen reader・全実機です。DOM属性・className・React型は提供しません。RTLは物理的な矢印方向を維持し、連結枠の全描画は追加比較が必要です。全体の視覚・挙動ゲートを合格扱いにはしません。

日本語デモは `?component=pagination&mode=light`。比較用 `?sample=pagination` はpage／perPage／total／unknown／next／controls／selector／compound／direction／host／modeに対応します。
