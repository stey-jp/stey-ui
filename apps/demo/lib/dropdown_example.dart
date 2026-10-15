import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

class DropdownExample extends StatefulWidget {
  const DropdownExample({super.key, this.fixture = false});
  final bool fixture;
  @override
  State<DropdownExample> createState() => _DropdownExampleState();
}

class _DropdownExampleState extends State<DropdownExample> {
  bool alerts = true;
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
      SteyDropdownMenu(
        label: text('操作メニュー', 'Actions'),
        width: 224,
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
      if (!widget.fixture) ...[
        const SteyText('移動のサブメニュー、通知と環境の選択、キーボードの矢印・文字検索を操作できます。'),
        SteyText(
          '通知：${alerts ? '有効' : '無効'}／環境：${environment == 'production' ? '本番' : 'ステージング'}',
        ),
        SteyText(actions == 0 ? '操作はまだありません。' : '最後の操作：$lastAction（$actions回）'),
      ],
    ],
  );
}
