import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chore_item.dart';
import '../models/chore_record.dart';
import '../models/person.dart';

class ChoreStore extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  List<ChoreItem> chores = [];
  List<ChoreRecord> _yearRecords = [];

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime get selectedMonth => _selectedMonth;

  late final void Function() _choresUnsub;
  late final void Function() _recordsUnsub;

  ChoreStore() {
    _listenToChores();
    _listenToRecords();
  }

  // Records filtered to the selected month
  List<ChoreRecord> get records => _yearRecords.where((r) {
        final d = r.recordedAt.toDate();
        return d.year == _selectedMonth.year && d.month == _selectedMonth.month;
      }).toList();

  bool get canGoPrevMonth {
    final now = DateTime.now();
    return !(_selectedMonth.year == now.year && _selectedMonth.month == 1);
  }

  bool get canGoNextMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month < now.month;
  }

  void prevMonth() {
    if (!canGoPrevMonth) return;
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    if (!canGoNextMonth) return;
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    notifyListeners();
  }

  @override
  void dispose() {
    _choresUnsub();
    _recordsUnsub();
    super.dispose();
  }

  void _listenToChores() {
    final sub = _db
        .collection('chores')
        .orderBy('createdAt')
        .snapshots()
        .listen((snap) {
      if (snap.docs.isEmpty) {
        _seedDefaultChores();
        return;
      }
      chores = snap.docs.map(ChoreItem.fromDoc).toList();
      notifyListeners();
    });
    _choresUnsub = sub.cancel;
  }

  void _seedDefaultChores() {
    const defaults = [
      ('料理', 3),
      ('買い物', 2),
      ('洗濯', 2),
      ('炊飯', 1),
      ('ごみ捨て', 1),
    ];
    for (final (name, points) in defaults) {
      addChore(name, points);
    }
  }

  void _listenToRecords() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final sub = _db
        .collection('records')
        .where('recordedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .listen((snap) {
      _yearRecords = snap.docs.map(ChoreRecord.fromDoc).toList();
      notifyListeners();
    });
    _recordsUnsub = sub.cancel;
  }

  // MARK: - CRUD

  void addChore(String name, int points) {
    _db.collection('chores').add(ChoreItem(name: name, points: points).toMap());
  }

  void updateChore(ChoreItem chore) {
    if (chore.id == null) return;
    _db.collection('chores').doc(chore.id).update(chore.toMap());
  }

  void deleteChore(ChoreItem chore) {
    if (chore.id == null) return;
    _db.collection('chores').doc(chore.id!).delete();
  }

  void deleteRecord(ChoreRecord record) {
    if (record.id == null) return;
    _db.collection('records').doc(record.id!).delete();
  }

  void recordChore(ChoreItem chore, Person person,
      {DateTime? date, int? overridePoints}) {
    final ts = date != null ? Timestamp.fromDate(date) : Timestamp.now();
    _db.collection('records').add(
      ChoreRecord(
        choreId: chore.id ?? '',
        choreName: chore.name,
        points: overridePoints ?? chore.points,
        person: person,
        recordedAt: ts,
      ).toMap(),
    );
  }

  // MARK: - Computed (monthly)

  int pointsFor(Person person) =>
      records.where((r) => r.person == person).fold(0, (s, r) => s + r.points);

  List<({String name, int count, int points})> breakdownFor(Person person) {
    final filtered = records.where((r) => r.person == person).toList();
    final grouped = <String, List<ChoreRecord>>{};
    for (final r in filtered) {
      grouped.putIfAbsent(r.choreName, () => []).add(r);
    }
    final result = grouped.entries
        .map((e) => (
              name: e.key,
              count: e.value.length,
              points: e.value.fold(0, (s, r) => s + r.points),
            ))
        .toList();
    result.sort((a, b) => b.points.compareTo(a.points));
    return result;
  }

  // MARK: - Annual summary (current year)

  List<({int month, int husbandPoints, int wifePoints})> get annualSummary {
    final map = <int, List<int>>{};
    for (final r in _yearRecords) {
      final m = r.recordedAt.toDate().month;
      map.putIfAbsent(m, () => [0, 0]);
      if (r.person == Person.husband) {
        map[m]![0] += r.points;
      } else {
        map[m]![1] += r.points;
      }
    }
    return List.generate(12, (i) {
      final m = i + 1;
      final pts = map[m] ?? [0, 0];
      return (month: m, husbandPoints: pts[0], wifePoints: pts[1]);
    });
  }
}
