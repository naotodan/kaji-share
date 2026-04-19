import 'package:cloud_firestore/cloud_firestore.dart';
import 'person.dart';

class ChoreRecord {
  final String? id;
  final String choreId;
  final String choreName;
  final int points;
  final Person person;
  final Timestamp recordedAt;

  ChoreRecord({
    this.id,
    required this.choreId,
    required this.choreName,
    required this.points,
    required this.person,
    Timestamp? recordedAt,
  }) : recordedAt = recordedAt ?? Timestamp.now();

  factory ChoreRecord.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChoreRecord(
      id: doc.id,
      choreId: data['choreId'] as String,
      choreName: data['choreName'] as String,
      points: data['points'] as int,
      person: Person.values.firstWhere((p) => p.name == data['person']),
      recordedAt: data['recordedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
        'choreId': choreId,
        'choreName': choreName,
        'points': points,
        'person': person.name,
        'recordedAt': recordedAt,
      };
}
