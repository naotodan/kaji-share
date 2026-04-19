import 'package:cloud_firestore/cloud_firestore.dart';

class ChoreItem {
  final String? id;
  final String name;
  final int points;
  final Timestamp createdAt;

  ChoreItem({
    this.id,
    required this.name,
    required this.points,
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  factory ChoreItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChoreItem(
      id: doc.id,
      name: data['name'] as String,
      points: data['points'] as int,
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'points': points,
        'createdAt': createdAt,
      };

  ChoreItem copyWith({String? name, int? points}) => ChoreItem(
        id: id,
        name: name ?? this.name,
        points: points ?? this.points,
        createdAt: createdAt,
      );
}
