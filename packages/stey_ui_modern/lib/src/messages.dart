import 'package:flutter/widgets.dart';

/// Internal control labels follow the nearest Flutter locale.
class SteyMessages {
  const SteyMessages._(this.japanese);
  final bool japanese;
  static const _english = SteyMessages._(false);
  static const _japanese = SteyMessages._(true);
  static SteyMessages of(BuildContext context) =>
      Localizations.maybeLocaleOf(context)?.languageCode == 'ja'
      ? _japanese
      : _english;

  String get loading => japanese ? '読み込み中' : 'Loading';
  String get closeDialog => japanese ? 'ダイアログを閉じる' : 'Close dialog';
  String get close => japanese ? '閉じる' : 'Close';
  String get cancel => japanese ? 'キャンセル' : 'Cancel';
  String get moreActions => japanese ? 'その他の操作' : 'More actions';
  String get copied => japanese ? 'コピーしました' : 'Copied';
  String copy(String text) => japanese ? '$textをコピー' : 'Copy $text';
  String show(String label) => japanese ? '$labelを表示' : 'Show $label';
  String hide(String label) => japanese ? '$labelを隠す' : 'Hide $label';
  String remove(String tag) => japanese ? '$tagを削除' : 'Remove $tag';
  String maxTags(int count) =>
      japanese ? 'タグは$count個までです' : 'Maximum $count tags';
  String get page => japanese ? 'ページ' : 'Page';
  String get resizeSidebar => japanese ? 'サイドバーの幅を変更' : 'Resize sidebar';
  String pixels(int count) => japanese ? '$countピクセル' : '$count pixels';
  String get searchResources => japanese ? 'リソースを検索' : 'Search resources';
  String get create => japanese ? '作成' : 'Create';
  String confirmDeletion(String name) =>
      japanese ? '削除するには$nameと入力してください。' : 'Type $name to confirm deletion.';
  String get resourceName => japanese ? 'リソース名' : 'Resource name';
  String get deleteResource => japanese ? 'リソースを削除' : 'Delete resource';
  String get searchCommands => japanese ? 'コマンドを検索' : 'Search commands';
  String get noResults => japanese ? '検索結果がありません' : 'No results found';
  String get noData => japanese ? 'データがありません' : 'No data available';
  String get rotateGlobeLeft => japanese ? '地球儀を左に回転' : 'Rotate globe left';
  String get rotateGlobeRight => japanese ? '地球儀を右に回転' : 'Rotate globe right';
  String series(int count) => japanese ? '$count系列' : '$count series';
  String flow(int nodes, int edges) => japanese
      ? '$nodes個のノードと$edges本の接続を持つフロー図'
      : 'Flow diagram with $nodes nodes and $edges connections';
}
