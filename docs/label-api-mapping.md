# LabelのAPI対応

参照：Cloudflare Kumo `947065ad39694fdc688b1128cc9c360f566a4f73` の`label.tsx`・`tooltip.tsx`とPhosphor regular Info。Label・Tooltipのソースは`7e0ff40`から差分なしです。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| children | SteyLabel(String)／SteyLabel.rich(Widget) | 通常の文字、Text.richや任意Widget。既定14px・medium・default色 |
| inline-flex／gap-1 | ネイティブ配置 | 本文・任意表示・情報ボタンを別要素として4px間隔で配置。単語の最小幅を保持し、折り返しは本文内で行う |
| showOptional | showOptional | 別要素・normal・subtle色。元のrequired=falseも維持。required=trueで星印を追加しない |
| optionalLabel | optionalLabel／optionalContent | Stringまたは任意Widgetで指定。nullは言語既定、空文字は空のまま。明示した英語は日本語へ置換しない |
| locale provider | Flutter locale | 任意表示と情報ボタン名は英語／日本語の既定。任意の翻訳Providerは未実装で、各引数で上書きする |
| tooltip | tooltip／tooltipContent | 文字または任意Widget。空文字は情報ボタンを生成しない。複合内容の読み上げ補足はtooltipSemanticLabelで渡す |
| tooltipAriaLabel | tooltipAriaLabel | 省略時はMore information／詳しい情報。明示値はそのまま保持 |
| asContent | asContent | 親の書体・サイズ・太さ・行高・色を継承。任意表示はnormalとsubtle、情報ボタンは独自のサイズと色を保持 |
| htmlFor | controlFocusNode／onTap | 本文と任意表示のpointer操作で入力欄にfocus。EditableTextではrequestKeyboardで入力接続の表示を要求する。編集中のWeb再操作の制約は下記に記録する。情報ボタンは独立。編集欄の読み上げ名はsemanticLabelで明示する。HTML ID・labelled-byの自動連結ではない |
| Info regular | ネイティブCanvas | 256単位の円・情報記号を描画。16px図版が14pxのxs squareボタンから外側に描画される公式の寸法を維持 |
| tooltip hover／focus | OverlayEntry・FocusNode・AnimationController | hover600ms、focus即時、150msのfade／scale、Escape／blur／外側操作で閉じる。情報ボタンとpopupの意味情報を分離し、Flutterの標準focus traversalでTab／Shift+Tabを処理。情報ボタンを再作成せず移動を保持 |
| tooltipの位置 | ネイティブ位置計算 | 起点から10px、角丸6px、padding10／6px・13px、矢印3パス、上下反転・左右の画面端補正。portalの描画位置を追跡 |
| safePolygon | 部分対応 | popupへ移る80msの猶予とpopup hoverで表示を維持。Base UIの軌跡による安全領域やProviderの遅延共有は未再現 |
| click／touch | 旧Stey互換で説明を開く | 公式Base UIのcloseOnClickと異なる。タップでも説明へ到達できる旧動作を維持し、公式一致として扱わない |
| className／任意DOM／ref | 未対応 | Flutter Widgetのスタイル・Key・FocusNodeで合成。Reactのイベント統合や任意HTMLタグをエミュレートしない |

元の`input.dart`からのexport、`required`・`weight`・`excludeTextSemantics`・`onTap`を維持します。任意表示を一つのTextSpanへ連結せず、公式の別要素へ修正しています。`excludeTextSemantics`は本文と任意表示を除外し、情報ボタンの名前を残します。`asContent`はHTMLのlabel要素を生成せず、操作や読み上げの関連付けを自動生成しません。

本文と任意表示がインラインWidgetを含まないText／RichTextの場合はネイティブTextPainterでmin-content／max-contentを測り、公式のflex-shrinkと同様に元の幅で重み付けして縮め、各要素の最小幅で止めます。情報ボタンの幅は固定します。フォールバックフォント読み込み後にSDKのintrinsic painterへ残る古い幅を避けるため、計測用TextPainterをその都度作成して破棄します。IntrinsicHeightを使うカードにも折り返した高さを返します。LayoutBuilder等の任意Widgetはintrinsic測定を要求せず、通常のFlexible配置を保持します。極端な狭幅・任意Widget・全長文・親の外側のhit testは未認証です。

Tooltip全体の複合API・遅延共有・safePolygon・全衝突規則・HTML aria-describedby／tooltip役割と物理screen readerは残件です。文字拡大はネイティブpopupにも適用します。比較fixtureでは親の文字サイズとtext-base変数を倍率に合わせ、固定のgap・情報ボタンを拡大しない文字拡大を再現します。Portalへ変数が継承されないため、拡大時のpopupは同一条件の一致認証としません。全画素・他ブラウザ／全プラットフォームも未認証です。[検証記録](verification.md)に実測値を保持します。

実Chromeでは、編集中の入力欄のLabelを再度pointer操作するとFlutter側のfocusとDOMの入力先が一致せず、キー入力が届かない差を確認しています。SDKのTextInputShowは編集中のshow要求を処理せず、requestKeyboardでも再表示できません。未focusからの関連付けと、すでに編集中の再操作を別に照合し、後者を失敗として記録します。強制blurやDOM書換えでIME・選択状態を損なう回避は追加しません。

日本語デモで設定変更後に200%・rich・狭幅・RTLを併用すると、任意表示からの入力にも不一致が残ります。条件別の実測は検証記録に保持します。アラビア語の自然幅・狭幅・拡大も比較対象とし、外枠の一致と全画素・全挙動の一致を分けて記録します。残る入力の不一致により、比較全体は合格扱いにしません。

日本語デモの200%表示では、併置したInputの固定高に対して日本語の入力文字が上下に切れることも確認しています。Label外枠の比較とは別のInputの拡大対応残件であり、文字倍率を下げて隠す対処はしていません。
