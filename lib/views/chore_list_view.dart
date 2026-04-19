import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/chore_store.dart';
import '../models/chore_item.dart';
import '../models/person.dart';

class ChoreListView extends StatelessWidget {
  const ChoreListView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChoreStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('家事一覧')),
      body: store.chores.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('家事項目がありません',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('設定タブから追加してください',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              itemCount: store.chores.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) =>
                  _ChoreRow(chore: store.chores[i]),
            ),
    );
  }
}

class _ChoreRow extends StatelessWidget {
  const _ChoreRow({required this.chore});
  final ChoreItem chore;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(chore.name),
      subtitle: Text('${chore.points} pt'),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        onPressed: () => _showPersonPicker(context),
        child: const Text('やった！',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showPersonPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PersonPickerSheet(
          chore: chore, store: context.read<ChoreStore>()),
    );
  }
}

class _PersonPickerSheet extends StatefulWidget {
  const _PersonPickerSheet({required this.chore, required this.store});
  final ChoreItem chore;
  final ChoreStore store;

  @override
  State<_PersonPickerSheet> createState() => _PersonPickerSheetState();
}

class _PersonPickerSheetState extends State<_PersonPickerSheet> {
  bool _recorded = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 32),
              const Text('誰がやりましたか？',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(widget.chore.name,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 16)),
              Text('+${widget.chore.points} pt',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: Person.values
                    .map((person) => Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: _PersonButton(
                            person: person,
                            onTap: () {
                              widget.store
                                  .recordChore(widget.chore, person);
                              setState(() => _recorded = true);
                              Future.delayed(
                                  const Duration(milliseconds: 700), () {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              });
                            },
                          ),
                        ))
                    .toList(),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル',
                    style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 16),
            ],
          ),
          if (_recorded)
            Container(
              color: Colors.white.withValues(alpha: 0.93),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 72, color: Colors.green),
                    SizedBox(height: 12),
                    Text('記録しました！',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonButton extends StatelessWidget {
  const _PersonButton({required this.person, required this.onTap});
  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: person.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: person.color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(person.icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(
              person.displayName,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: person.color),
            ),
          ],
        ),
      ),
    );
  }
}
