# 完成までの工程

ユーザーが承認した6工程を継続します。全体は開発プレビューです。
52群中51群に部分実装とデモがあり、ロゴ1群は商標許可待ちです。
個別のテスト成功や診断画像だけで全体の再現完了とは扱いません。

1. **不足実装**：全群のAPI・複合構成・挙動を対応表に沿って埋める。
   ButtonGroupの連結、Flowのmargin付きアンカー・List/Parallel・自動寸法・縦配置を追加。
   Flowの境界付きパン・wheel・overflow通知・スクロール表示を追加。
   Node.maxWidthでの折り返しと再配置を追加。標準ノードの初期幅・測定履歴・再作成時の自動測定を追加。Dropdownの150ms開閉・即時切替、RTL行、既定の上下回り込み・高さ制約、表示中のresize／祖先scroll／anchor移動追従、矩形境界・各辺の余白・隠れた起点への追従とstickyによる境界内保持も追加。disabled行のfocusと500msの文字検索・Space処理にも対応。全custom／CSS・canvas入力の認証、DropdownのElement／複数境界・全hide規則／イベント、無効行のWeb DOM focus、LayerDialogの全Drawer挙動などは残る。
2. **全状態比較**：Light/Dark・画面幅・hover/focus/disabled/loading・動的内容を比較して修正する。
   診断画像を承認済み視覚ゲートと分け、完全検証後に同期済みSHAを進める。
3. **アクセシビリティとWeb品質**：キーボード・読み上げ・拡大を検証する。
   Lighthouse全100点と対応可能なDevTools Issues 0件は未達。SDK由来の制約も記録する。
4. **6プラットフォーム検証**：最新ソースのビルドと実機操作を確認する。
   Web／Windows／Androidビルドに加え、Linux／macOS／iOS環境と物理実機確認が必要。
5. **自動同期の実運用検証**：更新検出→Batch送信→別実行で回収→適用・検証→PRまで実際に通す。
   予算停止・重複防止・再試行・失敗記録も対象。クラウド接続は既存の保留指示を維持し、
   shared-ciの最新設定でも公開repoは対象外。方針変更前に独自Workflowを復活させない。
6. **デモ・文書・ライセンスの最終整備**：全日本語デモ、対応表、検証記録をそろえてmainへ反映する。
   ロゴ群は書面許可または対象範囲の判断が必要。pub.dev公開は行わない。

根拠は[検証記録](verification.md)、部品の不足は[再現チェックリスト](parity-checklist.md)に保持します。

不足実装の続きとしてCodeHighlightedを追加しました。18言語の識別子・別名、行番号、行強調、原文コピーと日本語デモを用意しています。[CodeのAPI対応](code-api-mapping.md)に記載のShikiとの解析・色分けの差、HCLの全文法などは残ります。

InlineCopyTextの枠なし表示・コピー値・rich child・keyboard・親group・1.5秒の通知も追加しています。[API対応](inline-copy-api-mapping.md)に文字幅・折り返し・実機の残件を保持します。

ClipboardTextにも専用入力欄・3サイズ・別のコピー値・keyboard・1.5秒の成功表示と4方向のtooltip／toastを追加しています。[API対応](clipboard-api-mapping.md)に選択・通知構成・視覚・実機の差を保持します。

Bannerに構造化本文・compact配置・inline Link・色とサイズを継承するBanner.Actionを追加しています。[API対応](banner-api-mapping.md)に継承API・任意Widget・描画・実機の残件を保持します。

Collapsibleに組み合わせ用Root／Trigger／Panel、制御／非制御、開閉取消、100msの標準表示と入力内容の保持／破棄を追加しています。[API対応](collapsible-api-mapping.md)にhiddenUntilFound／beforematch、CSSの反転規則、全視覚・実機の残件を保持します。

Emptyに3サイズ、見出し／説明、任意図版・追加操作、横スクロールとコマンド全文コピーを追加しています。[API対応](empty-api-mapping.md)にtext-balance・等幅文字・選択・全視覚・実機の残件を保持します。

Breadcrumbsに組み合わせAPI、2サイズ、640px未満の省略、Currentの切詰め・読み込み・コピーを追加しています。[API対応](breadcrumbs-api-mapping.md)にaria-current・focus・任意構成・全視覚・実機の残件を保持します。

Badgeにリンク祖先のhover枠・12pxアイコン枠・狭幅と空ラベルの処理、日本語デモを追加しています。[API対応](badge-api-mapping.md)に任意構成・破線・全視覚・実機の残件を保持します。

Loaderにpreset・status、SkeletonLineに乱数幅・時間・blockHeightと日本語デモを追加しています。[API対応](loader-api-mapping.md)に固定位相比較とWeb／実機の残件を保持します。

Paginationに組み合わせAPI、full／simple、入力／選択、件数選択、総件数不明時の移動と最新公式の入力検証を追加しています。[API対応](pagination-api-mapping.md)にSelectの連結描画・意味情報・全画素と実機の残件を保持します。

Meterに値域・独自表示・数値書式・300msの幅変化と日本語デモを追加しています。[API対応](meter-api-mapping.md)にmeterの意味情報に関するSDK制約・全画素と実機の残件を保持します。
