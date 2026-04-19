import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/chore_store.dart';
import '../models/person.dart';
import '../models/chore_record.dart';

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
          _CalendarCard(records: store.records),
          const SizedBox(height: 12),
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

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.records});
  final List<ChoreRecord> records;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7;

    final recordsByDay = <int, List<ChoreRecord>>{};
    for (final r in records) {
      final d = r.recordedAt.toDate();
      if (d.year == now.year && d.month == now.month) {
        recordsByDay.putIfAbsent(d.day, () => []).add(r);
      }
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('カレンダー',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Row(
              children: ['日', '月', '火', '水', '木', '金', '土']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: firstWeekday + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstWeekday) return const SizedBox();
                final day = index - firstWeekday + 1;
                final dayRecords = recordsByDay[day] ?? [];
                final hasHusband =
                    dayRecords.any((r) => r.person == Person.husband);
                final hasWife =
                    dayRecords.any((r) => r.person == Person.wife);
                final isToday = day == now.day;

                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.blue.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(color: Colors.blue, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isToday ? Colors.blue : null)),
                      if (hasHusband || hasWife)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasHusband)
                              Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle)),
                            if (hasHusband && hasWife)
                              const SizedBox(width: 2),
                            if (hasWife)
                              Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                      color: Colors.pink,
                                      shape: BoxShape.circle)),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _Legend(color: Colors.blue, label: '👨 夫'),
                const SizedBox(width: 12),
                _Legend(color: Colors.pink, label: '👩 妻'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
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
