import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class DropdownExample extends StatefulWidget {
  const DropdownExample({
    super.key,
    this.fixture = false,
    this.extraItems = 0,
    this.collisionBoundary,
    this.collisionPadding = const EdgeInsets.all(5),
    this.sticky = false,
  });
  final bool fixture;
  final int extraItems;
  final Rect? collisionBoundary;
  final EdgeInsets collisionPadding;
  final bool sticky;
  @override
  State<DropdownExample> createState() => _DropdownExampleState();
}

class _DropdownExampleState extends State<DropdownExample> {
  bool alerts = true, rtl = false, bounded = false;
  bool? sticky;
  String environment = 'production';
  String lastAction = '';
  int actions = 0;
  String text(String ja, String en) => widget.fixture ? en : ja;
  void action(String label) => setState(() {
    lastAction = label;
    actions++;
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      Directionality(
        textDirection: rtl ? TextDirection.rtl : Directionality.of(context),
        child: SteyDropdownMenu(
          label: text('操作メニュー', 'Actions'),
          width: 224,
          collisionBoundary: bounded
              ? (Offset.zero & MediaQuery.sizeOf(context)).deflate(40)
              : widget.collisionBoundary,
          collisionPadding: widget.collisionPadding,
          sticky: sticky ?? widget.sticky,
          items: [
            SteyMenuGroup(
              text('プロジェクト', 'Project'),
              children: [
                SteyMenuItem(
                  text('編集', 'Edit'),
                  icon: Icons.edit_outlined,
                  shortcut: '⌘E',
                  onPressed: () => action(text('編集', 'Edit')),
                ),
                SteyMenuItem(
                  text('複製', 'Duplicate'),
                  onPressed: () => action(text('複製', 'Duplicate')),
                ),
                SteyMenuItem(
                  text('移動', 'Move'),
                  leading: const Icon(Icons.drive_file_move_outlined),
                  children: [
                    SteyMenuItem(
                      text('個人アカウント', 'Personal account'),
                      onPressed: () =>
                          action(text('個人アカウントへ移動', 'Move to personal')),
                    ),
                    SteyMenuItem(
                      text('チームアカウント', 'Team account'),
                      onPressed: () =>
                          action(text('チームアカウントへ移動', 'Move to team')),
                    ),
                    for (var i = 0; i < widget.extraItems; i++)
                      SteyMenuItem(
                        text('アカウント ${i + 1}', 'Account ${i + 1}'),
                        onPressed: () =>
                            action(text('アカウント ${i + 1}', 'Account ${i + 1}')),
                      ),
                    SteyMenuItem(
                      text('詳細', 'More'),
                      children: [
                        SteyMenuItem(
                          text('新しいフォルダー', 'New folder'),
                          onPressed: () =>
                              action(text('フォルダーを作成', 'Create folder')),
                        ),
                      ],
                    ),
                  ],
                ),
                SteyMenuItem(
                  text('利用不可', 'Unavailable'),
                  disabled: true,
                  onPressed: () => action('disabled'),
                ),
              ],
            ),
            const SteyMenuSeparator(),
            SteyMenuCheckboxItem(
              text('通知を受け取る', 'Receive alerts'),
              value: alerts,
              closeOnActivate: false,
              onChanged: (value) => setState(() => alerts = value),
            ),
            SteyMenuGroup(
              text('環境', 'Environment'),
              children: [
                for (final entry in {
                  'production': text('本番', 'Production'),
                  'staging': text('ステージング', 'Staging'),
                }.entries)
                  SteyMenuRadioItem(
                    entry.value,
                    value: entry.key,
                    groupValue: environment,
                    closeOnActivate: false,
                    onChanged: (value) => setState(() => environment = value),
                  ),
              ],
            ),
            const SteyMenuSeparator(),
            SteyMenuItem(
              text('削除', 'Delete'),
              destructive: true,
              onPressed: () => action(text('削除', 'Delete')),
            ),
          ],
          child: Text(text('操作', 'Actions')),
        ),
      ),
      if (!widget.fixture) ...[
        SteyButton(
          onPressed: () => setState(() => rtl = !rtl),
          child: Text(rtl ? '表示方向：右から左' : '表示方向：左から右'),
        ),
        SteyButton(
          onPressed: () => setState(() => bounded = !bounded),
          child: Text(bounded ? '配置境界：画面の内側40px' : '配置境界：画面全体'),
        ),
        SteyButton(
          onPressed: () => setState(() => sticky = !(sticky ?? widget.sticky)),
          child: Text(
            (sticky ?? widget.sticky) ? '起点が隠れたとき：境界内に保持' : '起点が隠れたとき：起点に追従',
          ),
        ),
        const SteyText(
          '移動のサブメニュー、通知と環境の選択、キーボードの矢印・文字検索を操作できます。'
          '利用不可の行にもフォーカスできますが、実行はできません。'
          '文字検索中のSpaceは検索を続け、500ms入力がない状態でSpaceを押すと選択した項目を実行します。'
          '画面端では子メニューの左右を反転し、両側が狭い場合は下または上へ配置します。'
          '開いたままウィンドウを変更したり、親の一覧をスクロールすると配置が追従します。'
          '配置境界と各辺の余白を指定でき、起点が隠れてもメニューは開いた状態を保ちます。'
          '境界内に保持へ切り替えると、起点が隠れた後もメニューを境界内に表示します。'
          'ポインターでの開閉は150msで拡縮・透過し、Enter・Spaceでの選択とEscでの終了は即時に切り替わります。',
        ),
        SteyText(
          '通知：${alerts ? '有効' : '無効'}／環境：${environment == 'production' ? '本番' : 'ステージング'}',
        ),
        SteyText(actions == 0 ? '操作はまだありません。' : '最後の操作：$lastAction（$actions回）'),
      ],
    ],
  );
}
