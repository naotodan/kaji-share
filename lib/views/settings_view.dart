import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/chore_store.dart';
import '../models/chore_item.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ChoreFormSheet(
          chore: chore, store: context.read<ChoreStore>()),
    );
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

class _ChoreFormSheet extends StatefulWidget {
  const _ChoreFormSheet({this.chore, required this.store});
  final ChoreItem? chore;
  final ChoreStore store;

  @override
  State<_ChoreFormSheet> createState() => _ChoreFormSheetState();
}

class _ChoreFormSheetState extends State<_ChoreFormSheet> {
  late final TextEditingController _nameCtrl;
  late int _points;

  bool get _isEdit => widget.chore != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.chore?.name ?? '');
    _points = widget.chore?.points ?? 10;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    if (_isEdit) {
      widget.store.updateChore(widget.chore!.copyWith(name: name, points: _points));
    } else {
      widget.store.addChore(name, _points);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? '家事を編集' : '家事を追加',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: '家事名',
                hintText: '例：料理、洗濯、掃除',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            const Text('ポイント:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3, 4, 5].map((pt) => GestureDetector(
                onTap: () => setState(() => _points = pt),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _points == pt ? Colors.orange : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange,
                      width: _points == pt ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text('$pt pt',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _points == pt ? Colors.white : Colors.orange)),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _points > 1 ? () => setState(() => _points--) : null,
                  color: Colors.orange,
                ),
                Text('$_points pt',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _points++),
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed:
                    _nameCtrl.text.trim().isEmpty ? null : _save,
                child: Text(
                  _isEdit ? '保存' : '追加',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
