# SelectのAPI対応

参照はKumo `f46e8bc9922c37dc1d3e7da779e589fe171df306` と公式固定依存のBase UIです。
FlutterのOverlayPortal・Focus・Semanticsを使い、MaterialのDropdownButtonから独立実装へ変更しています。

| 公式API | Flutter側 | 留意点 |
| --- | --- | --- |
| value / onValueChange | value / onChanged | 既存の単一選択API。親が値を更新するまで表示は変わらない |
| defaultValue | controlled: false / defaultValue | 明示的に内部管理を指定。制御nullと非制御を区別 |
| multiple / value[] | multiple / values / onValuesChanged | 複数選択はポップアップを開いたまま選択を切替 |
| multiple / defaultValue[] | controlled: false / defaultValues | 初期配列は内部へコピー |
| items object-map | options | 既存のMap<T, String> APIを維持 |
| items descriptor / Select.Option | entries / SteySelectOption<T> | disabledとWidget内容、読み上げ・文字検索用labelを指定 |
| Select.Group / GroupLabel / Separator | SteySelectGroup / SteySelectSeparator | Groupのlabelを見出しと意味情報へ反映 |
| renderValue | renderValue / renderValues | 値表示のWidget。空はplaceholder |
| label / aria-label | label / semanticLabel | hideLabel、required／optional、labelTooltipにも対応 |
| loading | loading | 128pxのskeleton。操作不可。loadingだけなら全体opacityは落とさない |
| disabled / readOnly | disabled / readOnly | readOnlyは一覧を閲覧でき、値の確定だけを禁止 |
| error / description | error / description | エラーを優先。validation matchは未対応 |
| size | SteySize | xs 20 / sm 26 / base 36 / lg 40px |
| side top/bottom | popupAbove | 画面端では空間を確認して反転 |
| align / alignOffset / sideOffset | popupAlignment / alignOffset / sideOffset | RTLのstart/endも解決。既定sideOffset 4px |
| collisionPadding | collisionPadding | 画面内の幅・高さへ制約。既定8px |
| onOpenChange | onOpenChanged | nativeの開閉通知。eventDetailsは未対応 |
| name / Form / eventDetails | 未対応 | submission、validation、取消・イベント原因の通知は今後照合 |
| render / container / anchor / positionMethod等 | 未対応 | 任意trigger、任意anchor、左右配置、指定境界、sticky、選択行との重ね合わせは未対応 |

上下矢印・Home／End・Enter／Space・Escape・Tab、閉じた単一Selectの文字検索、
開いた一覧の文字検索、無効項目、読み取り専用、外側クリック、フォーカス復帰を検査します。
Androidの戻る操作はPopScopeで開いた一覧を閉じます。API 36エミュレーターでも確認しました。
元のview metricsから画面内の安全領域を計算し、SafeArea配下でもシステム操作領域・キーボードとの重なりを避けます。
実機操作、Androidでの全選択操作は別途検証が必要です。

使用中のFlutter SDKはSemanticsRole.comboBoxのdebug検証処理が未実装で、
Webのlistbox／option役割も公開APIにありません。このためnativeのbutton／listと
選択・開閉の意味情報を使っています。SDKを改造したり、debugだけ役割を省いたりはしていません。
公式のWeb役割・関連付け・screen reader操作の完全一致は未達です。
ポップアップ幅は既定でtrigger幅、必要ならpopupWidthを指定します。公式の内容による自動幅拡大、
全配置・全幅・全状態・視覚の認証、rich contentと文字検索の全仕様は未完了です。
