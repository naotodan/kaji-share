import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chore_item.dart';
import '../models/chore_record.dart';
import '../models/person.dart';

class ChoreStore extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  List<ChoreItem> chores = [];
  List<ChoreRecord> records = [];

  late final void Function() _choresUnsub;
  late final void Function() _recordsUnsub;

  ChoreStore() {
    _listenToChores();
    _listenToRecords();
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
      chores = snap.docs.map(ChoreItem.fromDoc).toList();
      notifyListeners();
    });
    _choresUnsub = sub.cancel;
  }

  void _listenToRecords() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);
    final sub = _db
        .collection('records')
        .where('recordedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .listen((snap) {
      records = snap.docs.map(ChoreRecord.fromDoc).toList();
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

  void recordChore(ChoreItem chore, Person person) {
    _db.collection('records').add(
      ChoreRecord(
        choreId: chore.id ?? '',
        choreName: chore.name,
        points: chore.points,
        person: person,
      ).toMap(),
    );
  }

  // MARK: - Computed

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
}
