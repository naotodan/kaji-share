import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/chore_store.dart';
import '../models/person.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChoreStore>();
    final month = DateFormat('yyyy年M月').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ホーム'),
        backgroundColor: Colors.grey[100],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(month,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PointCard(
                    person: Person.husband,
                    points: store.pointsFor(Person.husband)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PointCard(
                    person: Person.wife,
                    points: store.pointsFor(Person.wife)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final person in Person.values)
            if (store.breakdownFor(person).isNotEmpty) ...[
              _BreakdownCard(person: person, store: store),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({required this.person, required this.points});
  final Person person;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(person.icon, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 4),
            Text(person.displayName,
                style: const TextStyle(color: Colors.grey)),
            Text(
              '$points',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: person.color),
            ),
            const Text('ポイント',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.person, required this.store});
  final Person person;
  final ChoreStore store;

  @override
  Widget build(BuildContext context) {
    final items = store.breakdownFor(person);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Text(person.icon),
              const SizedBox(width: 6),
              Text('${person.displayName}の内訳',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
          const Divider(height: 1),
          for (int i = 0; i < items.length; i++) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Text(items[i].name)),
                  Text('${items[i].count}回',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 12),
                  Text('${items[i].points} pt',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: person.color)),
                ],
              ),
            ),
            if (i < items.length - 1) const Divider(height: 1, indent: 16),
          ],
        ],
      ),
    );
  }
}
