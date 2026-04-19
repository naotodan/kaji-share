import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/chore_store.dart';
import '../models/chore_item.dart';

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
                  Text('ホームのカレンダーから追加してください',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              itemCount: store.chores.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _ChoreRow(chore: store.chores[i]),
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
      title: Text(chore.name,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Text(
          '${chore.points} pt',
          style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
