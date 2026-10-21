# Loader／SkeletonLineのAPI対応

Loaderは最新観測 `947065ad39694fdc688b1128cc9c360f566a4f73` を参照します。修正コミット `bfb4140ea91b7945efcc137139d6887422ecec11` はSVGのinline styleを廃止しサイズ属性で寸法を指定します。ネイティブ側は元からWidget寸法を指定し、SVGを使用しません。回転・線の伸縮の仕様は変更されていません。SkeletonLineは同じSHAのソースとCSSを参照します。

| 公式 | Flutter | 対応 |
| --- | --- | --- |
| Loader size sm／base／lg | SteyLoader.preset(size: SteyLoaderSize...) | 16／24／32px |
| Loader size number | SteyLoader(size: ...) | 従来の数値APIを維持。45px・0も検査 |
| role=status／aria-label | SemanticsRole.status／label | 公開SDKのstatusを使用。既定Loadingは日本語localeで「読み込み中」へ翻訳 |
| currentColor | color／DefaultTextStyle | 明示色を優先し、親の文字色を継承。半透明色も保持 |
| SVG circle／SMIL | CustomPainter／AnimationController | 半径9.5、線幅2、round cap。回転2秒、dasharray／dashoffset1.5秒、6秒で合成周期が一致 |
| SkeletonLineの乱数引数 | 同名のmin／max引数 | 幅30〜100%整数、周期1.3〜1.7秒、遅延0〜0.5秒。時間は小数2桁 |
| blockHeight | blockHeight | 行を指定高の領域内で縦中央、方向の先頭へ配置 |
| skeleton CSS | native painter | 8px高・2px角丸。Light/Darkの背景とshimmer、物理左から右へ移動 |
| 既存Flutter拡張 | width／height | 絶対幅と線の太さ。指定widthは乱数による幅より優先 |

SkeletonLineの乱数は6個の範囲引数が変わった場合だけ再選択します。親の再描画・width／height／blockHeight変更では保持します。遅延後にease-in-outのshimmerを繰り返し、パラメータ更新と破棄時に古いタイマーを取り消します。装飾として意味情報から除外します。Breadcrumbsの読み込み表示もこの実装を使います。

動作低減設定でもアニメーションを実行するユーザー指定を維持します。CSS／className・Reactの型やSVG属性、文字列単位のblockHeightは提供しません。ネイティブのsize・height等は非負の有限寸法、時間範囲は有効な値を指定してください。未制約の親では幅125pxを乱数幅の基準にし、boundedな親では利用可能幅を使います。

固定位相の比較はFlutter widgetテストのsoftware rasterと公式SVG SMIL／CSSを用い、Web版は別に寸法・status・動作を確認します。**これをFlutter Webの全フレームの一致とは扱いません。** サイズ0ではFlutter Webの意味情報からstatusが除外され、SVGのDOM保持とは異なります。全screen reader・実機、Linux／macOS／iOS、任意合成・CSS・全画素の認証は残ります。同期済みSHAと承認済み視覚ゲートは進めません。

日本語デモは`?component=loader&mode=light`。比較用`?sample=loader`はsize、color（red）、kind（skeleton）、block、minWidth／maxWidth、direction、label、modeに対応します。
