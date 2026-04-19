import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/chore_store.dart';
import '../models/person.dart';
import '../models/chore_record.dart';
import '../models/chore_item.dart';
import 'chore_form_sheet.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChoreStore>();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ホーム'),
        backgroundColor: Colors.grey[100],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left,
                    color: store.canGoPrevMonth ? null : Colors.grey[300]),
                onPressed: store.canGoPrevMonth ? store.prevMonth : null,
              ),
              Text(
                DateFormat('yyyy年M月').format(store.selectedMonth),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right,
                    color: store.canGoNextMonth ? null : Colors.grey[300]),
                onPressed: store.canGoNextMonth ? store.nextMonth : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          _RecentRecordsCard(store: store),
          const SizedBox(height: 12),
          _CalendarCard(
            records: store.records,
            chores: store.chores,
            selectedMonth: store.selectedMonth,
            onAddChore: () =>
                showChoreFormSheet(context, store: store),
          ),
          const SizedBox(height: 12),
          for (final person in Person.values)
            if (store.breakdownFor(person).isNotEmpty) ...[
              _BreakdownCard(person: person, store: store),
              const SizedBox(height: 12),
            ],
          _AnnualSummaryCard(store: store, currentYear: now.year),
          const SizedBox(height: 12),
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
  const _CalendarCard(
      {required this.records,
      required this.chores,
      required this.selectedMonth,
      required this.onAddChore});
  final List<ChoreRecord> records;
  final List<ChoreItem> chores;
  final DateTime selectedMonth;
  final VoidCallback onAddChore;

  static const double _dateColW = 42;
  static const double _addColW = 40;
  static const double _rowH = 38;
  static const int _maxFitCols = 6;

  static const List<String> _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    final Map<int, Map<String, List<Person>>> data = {};
    for (final r in records) {
      final d = r.recordedAt.toDate();
      if (d.year == selectedMonth.year && d.month == selectedMonth.month) {
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
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, constraints) {
              // 6列以内 → 利用可能幅いっぱい、7列以上 → 固定幅でスクロール
              final choreColW = chores.isNotEmpty && chores.length <= _maxFitCols
                  ? (constraints.maxWidth - _dateColW - _addColW) /
                      chores.length
                  : 52.0;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderRow(choreColW),
                    for (int day = 1; day <= daysInMonth; day++)
                      Container(
                        color: (selectedMonth.year == now.year &&
                                selectedMonth.month == now.month &&
                                day == now.day)
                            ? Colors.blue.withValues(alpha: 0.06)
                            : null,
                        child: _buildDayRow(day, now, data, choreColW),
                      ),
                  ],
                ),
              );
            }),
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

  Widget _buildHeaderRow(double choreColW) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1.0)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _dateColW,
            height: _rowH,
            child: const Center(
              child: Text('日付',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),
          ),
          ...chores.map((c) => Container(
                width: choreColW,
                height: _rowH,
                decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: Colors.grey.shade200, width: 0.5)),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  c.name,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              )),
          // 「+」追加ボタン列
          GestureDetector(
            onTap: onAddChore,
            child: Container(
              width: _addColW,
              height: _rowH,
              decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(
                        color: Colors.grey.shade200, width: 0.5)),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(int day, DateTime now,
      Map<int, Map<String, List<Person>>> data, double choreColW) {
    final isToday = selectedMonth.year == now.year &&
        selectedMonth.month == now.month &&
        day == now.day;
    final weekdayIndex =
        DateTime(selectedMonth.year, selectedMonth.month, day).weekday - 1;
    final isSun = weekdayIndex == 6;
    final isSat = weekdayIndex == 5;
    final dateColor = isToday
        ? Colors.blue
        : isSun
            ? Colors.red.shade400
            : isSat
                ? Colors.blue.shade300
                : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        border: Border(
            bottom:
                BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _dateColW,
            height: _rowH,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: dateColor,
                  ),
                ),
                Text(
                  _weekdays[weekdayIndex],
                  style: TextStyle(
                    fontSize: 9,
                    color: isSun
                        ? Colors.red.shade300
                        : isSat
                            ? Colors.blue.shade200
                            : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ...chores.map((c) {
            final persons = data[day]?[c.id] ?? [];
            return _choreCell(persons, choreColW);
          }),
        ],
      ),
    );
  }

  Widget _choreCell(List<Person> persons, double choreColW) {
    final hasHusband = persons.contains(Person.husband);
    final hasWife = persons.contains(Person.wife);
    return Container(
      width: choreColW,
      height: _rowH,
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(color: Colors.grey.shade200, width: 0.5)),
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

class _RecentRecordsCard extends StatelessWidget {
  const _RecentRecordsCard({required this.store});
  final ChoreStore store;

  @override
  Widget build(BuildContext context) {
    final records = store.records.take(10).toList();
    if (records.isEmpty) return const SizedBox();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('最近の記録',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          for (int i = 0; i < records.length; i++) ...[
            _RecordRow(record: records[i], store: store),
            if (i < records.length - 1)
              const Divider(height: 1, indent: 16),
          ],
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record, required this.store});
  final ChoreRecord record;
  final ChoreStore store;

  String get _dateLabel {
    final now = DateTime.now();
    final d = record.recordedAt.toDate();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return '今日';
    if (today.difference(day).inDays == 1) return '昨日';
    return '${d.month}/${d.day}';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('記録を削除'),
        content: Text('「${record.choreName}」の記録を削除しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                store.deleteRecord(record);
              },
              child: const Text('削除',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = record.person == Person.husband ? Colors.blue : Colors.pink;
    return ListTile(
      dense: true,
      leading: Text(record.person.icon,
          style: const TextStyle(fontSize: 24)),
      title: Text(record.choreName),
      subtitle: Text(_dateLabel,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('+${record.points} pt',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _AnnualSummaryCard extends StatelessWidget {
  const _AnnualSummaryCard({required this.store, required this.currentYear});
  final ChoreStore store;
  final int currentYear;

  @override
  Widget build(BuildContext context) {
    final summary = store.annualSummary;
    final now = DateTime.now();
    final visibleMonths =
        summary.where((s) => s.month <= now.month).toList();
    final maxPts = visibleMonths.fold(0, (m, s) {
      final max = s.husbandPoints > s.wifePoints
          ? s.husbandPoints
          : s.wifePoints;
      return max > m ? max : m;
    });

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text('$currentYear年 年間集計',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Legend row
                  Row(
                    children: [
                      const SizedBox(width: 36),
                      _dot(Colors.blue),
                      const SizedBox(width: 4),
                      const Text('夫',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 12),
                      _dot(Colors.pink),
                      const SizedBox(width: 4),
                      const Text('妻',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final s in visibleMonths) ...[
                    _MonthRow(s: s, maxPts: maxPts),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.s, required this.maxPts});
  final ({int month, int husbandPoints, int wifePoints}) s;
  final int maxPts;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          child: Text('${s.month}月',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(context, Colors.blue, s.husbandPoints),
              const SizedBox(height: 2),
              _bar(context, Colors.pink, s.wifePoints),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bar(BuildContext context, Color color, int pts) {
    final fraction = maxPts > 0 ? pts / maxPts : 0.0;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 44,
          child: Text('$pts pt',
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
