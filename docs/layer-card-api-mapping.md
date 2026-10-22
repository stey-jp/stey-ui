# LayerCard／SurfaceのAPI対応

公式 `947065ad39694fdc688b1128cc9c360f566a4f73` のLayerCard／Surfaceを参照します。両コンポーネントは既存比較SHA `7e0ff40546f08405d05bc9754f0ff0fd009ece0a` から変更されていません。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| LayerCardの通常children | SteyLayerCard(child:) | 単層。base背景、8px角丸、shadow-xs、lineの外側1pxリング。既定paddingなし |
| LayerCardの複数children | SteyLayerCard.layers(children:) | 直接の子にPrimary／Secondaryがあれば多層を選択 |
| LayerCard.Primary | SteyLayerCardPrimary | childまたはchildren。Columnの8px間隔、base背景、8px角丸、fillの外側1pxリング |
| Primaryの余白 | padding | 既定：左16・上16・右12・下16px。RTLでも左右を入れ替えない |
| LayerCard.Secondary | SteyLayerCardSecondary | childまたはchildren。Rowの8px間隔、elevated背景、14px・medium・subtle |
| Secondaryの余白 | padding | 既定16px。上下各−8pxの外側余白を独立実装 |
| RootのclassNameによる余白・角丸・overflow | padding／borderRadius／clipBehavior | Flutterの指定。単層／多層とも既定は8px、Clip.antiAlias |
| Primaryの装飾指定 | padding／borderRadius／clipBehavior | 独立した内側領域の設定 |
| aria-label相当 | semanticLabel | Root／Primary／SecondaryのSemanticsラベル |
| 既存Flutter header／footer | header／footer | Secondaryへ変換し、childをPrimaryへ配置。明示paddingは各領域へ適用 |
| 非推奨のSurface | SteySurface／SteySurface.layers | LayerCardを継承。既定は角丸0、Clip.none |
| Surface color | SteySurfaceColor.primary／secondary | 互換用の値を保持。公式同様、背景などの描画は変わらない |

多層Rootはelevated背景・hairlineリングを使い、単層の影を付けません。文字サイズ14px・行高21pxを継承元として設定します。Primaryは文字色・太さを継承します。Secondaryの実際の高さが53pxなら、上下の負の余白によりレイアウト上は37pxを消費します。Header／Primary／Footerの1行構成では37＋53＋37＝127pxです。

公式のPrimaryはposition:relativeにより、後続のSecondaryフッターより手前に描画されます。Flutterでもレイアウト・読み上げ順を維持し、描画とクリック判定だけPrimaryを手前にします。Secondaryの負の余白は実際の子の座標・意味情報・クリック領域を保持します。RootとPrimaryのクリップは別々に指定できます。

構成の検出は直接の子だけを対象にします。Dartのリストへspreadしたセクションは検出されますが、任意WidgetやColumnの内部を探索しません。React Fragmentの専用置換や共通基盤は作りません。単層を得るためにLayerCardを入れ子にする必要はありません。日本語デモも外側のカード枠を重ねない構成です。

以前のFlutter実装の独自の外側4px余白・12px角丸・常時多層表示は、公式の単層／多層仕様へ変更しています。header／footer／paddingの引数と任意Widgetの利用は維持します。通常childだけのカードは既定の余白がなくなるため、必要ならpaddingを明示してください。header／footerと併用したpaddingは従来どおり各セクションへ適用し、layersや通常単層のpaddingはRootへ適用します。

任意のHTML属性・className・render／asはFlutter APIに含めません。HTMLのdata-testid相当はFlutterのKey、意味情報はSemanticsを利用します。任意の複合行のflex縮小、長文・文字拡大の全構成、継承されたリンク装飾、全画素・screen reader・物理実機は未認証です。同一のInterフォントファイルとChromeでのInter-Regular使用を確認していますが、文字を含む描画の画素差は残ります。Surfaceで外側へ描画された子の操作はFlutterの親hit testに制限されるため、DOMのoverflow-visibleと全挙動の一致は認証しません。

日本語デモは `?component=layer-card` と `?component=surface`。単層／Primary・Secondary／既存header・footer／はみ出し表示、長文・RTL・角丸・フッターとカード内外のボタンを操作できます。Surfaceではcolorの2値も切り替えられます。

比較用 `?sample=layer-card` はkind（card／surface）・layout（simple／layered／primary／legacy／overflow）・padding／radius／header／footer／multiple／long／host／font／color／direction／modeに対応します。`?sample=surface` も使用できます。比較の親文字スタイルは既定14px・行高1.5とし、font=18で継承と多層Rootの上書きも確認します。同期済みSHAと承認済み視覚ゲートは進めません。
