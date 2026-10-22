# TagInputのAPI対応

参照：Cloudflare Kumo `947065ad39694fdc688b1128cc9c360f566a4f73`、Base UI 1.9.0。
最新のreadOnly・選択範囲への貼り付け修正を含みます。Flutter標準の編集・Clipboard APIとネイティブの折り返し配置で実装します。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| value / defaultValue / onValueChange | 同名 | 制御／非制御。入力途中の文字はタグ一覧と別に保持。制御側が変更を拒否しても確定後の入力は消える |
| validateValue(value, acceptedValues) | 同名 | その時点までの採用済み配列を渡す。途中失敗までのタグを採用し、残りを`, `で連結して入力へ残す |
| maxValues | 同名 | 重複を除いた後に上限判定し、検証関数より先に通知 |
| labels | SteyTagInputLabels | 入力名・削除名・検証失敗・上限通知。未指定分は英語／日本語の既定値 |
| Enter / comma / Tab / Backspace | Focusのキー処理 | Enter・カンマ・成功Tabは入力内へfocusを保持。失敗Tabは移動し、blurで再試行。空欄Backspaceは末尾タグを除去し、空欄Enterでは通知しない。矢印・Home／EndとShift選択はFlutter標準の編集アクションへ接続 |
| composition / keyCode229 | TextEditingValue.composing | 変換中はキー確定しない。Safariの生keyCode229はFlutterの公開KeyEventにないため同一イベントを認証できない |
| onPaste | onPaste / native Clipboard | カンマ・改行のある貼り付けは現在の選択範囲へ挿入して確定。区切りのない文字は入力途中の文字へ挿入。ショートカットと選択ツールバーに対応 |
| onBlur / onKeyDown / onChange | onBlur / onKeyEvent / onDraftChange | blurと貼り付けはfalse、キーはhandledで標準処理を取消。DartのイベントAPIでありDOMイベントの互換型ではない |
| disabled / readOnly | enabled=false / readOnly | readOnlyはfocus・選択可能、追加・削除・貼り付け・blur確定を抑止。削除ボタンは無効 |
| required | required | タグが空のとき編集欄の必須Semanticsを設定。readOnlyを含むHTML制約検証・willValidateは非対応 |
| label / description / error / labelTooltip | 同名 | 外部errorを内部通知より優先。入力名をタグ本文と分離。ラベル操作で編集欄へfocus |
| variant | SteyInputVariant | 未指定時はerrorで自動選択、standard明示でエラー枠を抑止 |
| flex-wrap / truncate | 専用のネイティブ配置 | 24pxタグ、8px横間隔・6px行間、最小128pxの入力が行の残り幅へ伸びる。狭幅・RTL・長いタグを対象。TextFieldTapRegionでマウス削除時に入力途中の文字を確定させない |
| name / form / hidden inputs | 未対応 | ブラウザのFormDataへタグごとのhidden inputを生成しない。Flutter側はonValueChangeの採用済み配列を利用 |
| forwardedRef | focusNode | 外部FocusNodeの所有権を維持。HTMLElementやValidityStateの参照ではない |

旧Steyの`onChanged`・`validate`・`maxTags`は互換入口として維持します。新しい`maxValues`を優先し、`validate`の独自エラー文も保持します。既定の可視ラベル`Tags`とplaceholder`Add a tag`は公式に合わせて省略し、ラベル未指定の入力名は`Add tag`／`タグを追加`です。空欄確定・重複だけの確定でも通知する点も公式に合わせています。

非同期Clipboard読取中の再操作・編集・無効化・破棄後は古い結果を適用しません。公式の同期pasteイベントとの同時性の違いは残ります。全DOM属性・rich Fieldと構造化validation match・Undo／IME／モバイルの貼り付け経路・物理screen reader・全画素／全プラットフォームは未認証です。検証の範囲と実測値は[検証結果](verification.md)に保持します。

Flutter Webの無効な編集欄はAXのtextbox役割がないことがあり、非focus時のDOM代理値も実際のcontrollerから遅れる場合があります。診断では初期focusを別に記録し、操作後のdraftは両方の編集欄へfocusを戻して比較します。公式のdescription／内部errorだけを持つ空ラベルFieldでは入力のaccessible nameが空になる場合がありますが、ネイティブは指定した名前を保持します。完全なDOM／AX一致とは扱いません。
