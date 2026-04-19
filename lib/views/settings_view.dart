import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/chore_store.dart';
import '../models/chore_item.dart';
import 'chore_form_sheet.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChoreStore>();
    final auth = context.read<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          _SectionHeader('家事項目'),
          ...store.chores.map((chore) => _ChoreSettingsItem(
                chore: chore,
                onEdit: () => _showForm(context, chore: chore),
                onDelete: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('削除確認'),
                      content: Text('「${chore.name}」を削除しますか？'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('キャンセル')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('削除',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (ok == true) store.deleteChore(chore);
                },
              )),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.green),
            title: const Text('家事を追加',
                style: TextStyle(color: Colors.green)),
            onTap: () => _showForm(context),
          ),
          const Divider(),
          _SectionHeader('アカウント'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('サインアウト',
                style: TextStyle(color: Colors.red)),
            onTap: auth.signOut,
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {ChoreItem? chore}) {
    showChoreFormSheet(context,
        chore: chore, store: context.read<ChoreStore>());
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _ChoreSettingsItem extends StatelessWidget {
  const _ChoreSettingsItem(
      {required this.chore,
      required this.onEdit,
      required this.onDelete});
  final ChoreItem chore;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(chore.name),
      subtitle: Text('${chore.points} pt'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete),
        ],
      ),
    );
  }
}

