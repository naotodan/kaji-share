import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/chore_store.dart';
import '../models/person.dart';
import '../models/chore_record.dart';
import '../models/chore_item.dart';

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
          _CalendarCard(records: store.records, chores: store.chores),
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
  const _CalendarCard({required this.records, required this.chores});
  final List<ChoreRecord> records;
  final List<ChoreItem> chores;

  static const double _dateColW = 36;
  static const double _choreColW = 56;
  static const double _rowH = 32;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // day -> choreId -> persons
    final Map<int, Map<String, List<Person>>> data = {};
    for (final r in records) {
      final d = r.recordedAt.toDate();
      if (d.year == now.year && d.month == now.month) {
        data.putIfAbsent(d.day, () => {});
        data[d.day]!.putIfAbsent(r.choreId, () => []).add(r.person);
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
            const Text('カレンダー',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  _buildRow(
                    dateWidget: _headerCell(_dateColW, '日付'),
                    choreWidgets: chores
                        .map((c) => _choreHeaderCell(_choreColW, c.name))
                        .toList(),
                    isHeader: true,
                  ),
                  // Day rows
                  for (int day = 1; day <= daysInMonth; day++)
                    Container(
                      color: day == now.day
                          ? Colors.blue.withValues(alpha: 0.06)
                          : null,
                      child: _buildRow(
                        dateWidget: _dateCell(day, now),
                        choreWidgets: chores.map((c) {
                          final persons = data[day]?[c.id] ?? [];
                          return _choreCell(_choreColW, persons);
                        }).toList(),
                      ),
                    ),
                ],
              ),
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

  Widget _buildRow({
    required Widget dateWidget,
    required List<Widget> choreWidgets,
    bool isHeader = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isHeader ? Colors.grey.shade300 : Colors.grey.shade200,
            width: isHeader ? 1.0 : 0.5,
          ),
        ),
        color: isHeader ? Colors.grey.shade50 : null,
      ),
      child: Row(children: [dateWidget, ...choreWidgets]),
    );
  }

  Widget _headerCell(double width, String text) {
    return SizedBox(
      width: width,
      height: _rowH,
      child: Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
      ),
    );
  }

  Widget _choreHeaderCell(double width, String text) {
    return Container(
      width: width,
      height: _rowH,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _dateCell(int day, DateTime now) {
    final isToday = day == now.day;
    final weekday = DateTime(now.year, now.month, day).weekday;
    final color = isToday
        ? Colors.blue
        : weekday == 7
            ? Colors.red.shade400
            : weekday == 6
                ? Colors.blue.shade300
                : Colors.black87;
    return SizedBox(
      width: _dateColW,
      height: _rowH,
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _choreCell(double width, List<Person> persons) {
    final hasHusband = persons.contains(Person.husband);
    final hasWife = persons.contains(Person.wife);
    return Container(
      width: width,
      height: _rowH,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      alignment: Alignment.center,
      child: persons.isEmpty
          ? null
          : hasHusband && hasWife
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('○',
                        style: TextStyle(
                            color: Colors.blue.shade400,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    Text('○',
                        style: TextStyle(
                            color: Colors.pink.shade400,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                )
              : Text(
                  '○',
                  style: TextStyle(
                    color: hasHusband
                        ? Colors.blue.shade400
                        : Colors.pink.shade400,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
