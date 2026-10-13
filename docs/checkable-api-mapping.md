# Checkbox / SwitchのAPI対応

参照はKumo `f46e8bc9922c37dc1d3e7da779e589fe171df306` の実装と、公式lockfileに対応するBase UI型・動作です。
FlutterのAPI名は既存のStey UIとの互換を維持しています。Reactの実行時依存はありません。

| 公式API | Flutter側 | 留意点 |
| --- | --- | --- |
| Checkbox.checked / Switch.checked | value | 既存の値管理API。親から値を渡すと制御状態 |
| defaultChecked（継承） | defaultValue | 省略時false。値を渡さない場合は内部で更新 |
| onCheckedChange | onChanged | 新しい値を通知。公式のeventDetails/cancel等は未対応 |
| disabled | enabled: false | 単体の既存APIでは、値あり・callbackなしも無効として扱う |
| indeterminate | SteyCheckbox.indeterminate | 操作でchecked=trueを通知。親が混合状態を解除する |
| parent（Base UI継承） | SteyCheckbox.parent | Group.allValuesが必要。無効な子の選択を維持し、部分選択を復元 |
| Checkbox.variant default/error | SteyCheckboxVariant.standard/error | 選択済みringの優先順も公式render/CSSで確認 |
| Switch.variant default/neutral | SteySwitchVariant.standard/neutral | neutral-150/850が固定SHAで未定義の箇所はブラウザ実描画に従う |
| label / aria-label | label / semanticLabel | 現在は文字列。任意ReactNodeに相当するWidgetラベルは未対応 |
| labelTooltip | labelTooltip | 情報ボタンをタッチ・keyboardで開く。公式との全tooltip比較は未完了 |
| aria-labelledby | semanticLabel | 意味情報上の名前は渡せるが、任意外部ラベルとの関連付けAPIは未対応 |
| required / optional indicator | required | falseを明示するとoptional表示。表示文言と読み上げの全比較は未完了 |
| controlFirst | controlFirst | 単体とItemの前後配置。cardは既定で後ろ |
| Switch.size sm/base/lg | SteySwitchSize.sm/base/lg | 32×16 / 36×18 / 40×20 |
| Switch.transitioning / aria-busy | transitioning / busyLabel | nativeのhintに通知。Flutter SDKに直接aria-busy相当がないため完全一致ではない |
| name / HTML form submission | 未対応 | Flutter Formとの統合と検証仕様は今後照合 |
| className / render / DOM props | 未対応 | Web固有値をそのまま受け取るAPIは作らず、必要な視覚・機能をFlutter側へ対応付ける |

| 複合API | Flutter側 | 留意点 |
| --- | --- | --- |
| Checkbox.Group | SteyCheckboxGroup | value/defaultValue、onChanged、allValues、disabled、legend/error/description、orientation、appearance、controlFirst |
| Checkbox.Item | SteyCheckboxItem | valueはGroup内の識別値、checkedは個別上書き、indeterminate/disabled/variant/appearance/description/onChanged |
| Checkbox.Legend | SteyCheckboxLegend | visuallyHiddenでもGroupの名前を保持。任意CSSや任意Widget内容は未対応 |
| Switch.Group | SteySwitchGroup | disabled、legend/error/description、controlFirst。各Itemが値を保持 |
| Switch.Item | SteySwitchItem | value/defaultValue/onChanged、disabled、variant、size、transitioning |
| Switch.Legend | SteySwitchLegend | visuallyHiddenでもGroupの名前を保持 |

制御状態のnullを表す既存Checkbox.tristateは、false→true→null→falseの互換動作を維持します。
Kumoのindeterminateとは分けて扱います。

未認証の事項: 公式の拡張hit area、入力イベント詳細・キャンセル、任意内容、フォーム連携、親子のアクセシビリティ関連付け、スクリーンリーダー実操作、全幅・全状態・アニメーション位相を揃えた比較。
Flutter Web 3.47.0では混合状態が意味情報のCheckedState.mixedになっていても、WebエンジンのSemanticCheckable.updateがaria-checkedをtrue/falseで上書きします。実Chromeでfalseになることを確認しています。
DOMを後から書き換える対策は採用していません。
