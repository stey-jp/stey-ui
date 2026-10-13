# RadioのAPI対応

参照はKumo `f46e8bc9922c37dc1d3e7da779e589fe171df306` のRadio.Group／Item／Legendです。
FlutterのRawRadioとRadioGroupを使い、表示はKumoの寸法・色・状態に合わせて独立実装しています。

| 公式API | Flutter側 | 留意点 |
| --- | --- | --- |
| Radio / Radio.Group | SteyRadioGroup<T> | 既存optionsと、新しいchildrenのどちらかを指定 |
| value / defaultValue | value / defaultValue | 制御／非制御。制御状態のnullを明示するAPIは未対応 |
| onValueChange | onChanged | eventDetails、cancel、native eventは未対応 |
| disabled | disabled | グループ全体を無効化。inlineは公式と同じく明示的なItem.disabledだけを薄くする |
| appearance default/card/segmented | SteyRadioAppearance.inline/card/segmented | segmentedはGroup専用。cardは縦結合／横二列 |
| orientation | Axis.vertical/horizontal | inlineの横配置は折返し。segmentedは常に一列 |
| controlPosition start/end | controlFirst true/false | 未指定はinlineで前、cardで後ろ |
| legend / Radio.Legend | legend / SteyRadioLegend | visuallyHiddenでもグループの読み上げ名を保持 |
| error / description | error / description | 両方を表示。任意Widgetのグループ説明は未対応 |
| Radio.Item.value | SteyRadioItem<T>.value | String以外の値も使用可能 |
| Radio.Item.label | label / labelWidget | Widgetラベルでもlabelを読み上げ名として指定 |
| Radio.Item.description | description | cardだけに表示。任意Widgetの説明は未対応 |
| Radio.Item.disabled | disabled | 無効項目は矢印操作でスキップ |
| Radio.Item.variant | SteyRadioVariant.standard/error | errorの選択色・ringを公式ソースと照合 |
| Radio.Item.appearance | appearance | inline/cardの個別上書き。segmented上書きは不可 |
| name / HTML form submission | 未対応 | Flutter Formとの統合と検証仕様は今後照合 |
| className / ref / DOM props | 未対応 | nativeのfocusNode等へ対応付け。任意CSSは受け取らない |

Widget testで、ラベルからの選択、制御状態、無効項目、矢印での循環、Space、
カードの奇数項目・RTL・文字拡大・Widgetラベル、segmentedを確認しました。
Webリリースも実Chromeで、カード／segmentedの選択と左右矢印の循環・無効項目スキップを確認しました。

公式の拡張hit area、全複合API、全幅・状態の視覚認証、screen reader実操作、
フォーム連携、動的な項目変更と全プラットフォームの入力差は未検証です。
Flutter Webにはlistbox／option等の役割に制約があるため、全体のアクセシビリティ一致は別途照合します。
