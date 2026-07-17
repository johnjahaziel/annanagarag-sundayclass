import 'package:cloud_firestore/cloud_firestore.dart';

/// A top-level class group (e.g. "Beginner", "Intermediate", "Youth"),
/// stored as a document in the `class` Firestore collection. Each one
/// contains a list of named divisions (e.g. "Beginner 1", "Beginner 2").
class MainClass {
  const MainClass({
    required this.id,
    required this.name,
    required this.divisions,
    required this.isActive,
    this.createdAt,
  });

  /// The Firestore document id — the normalized (trimmed, lower-cased) name.
  final String id;
  final String name;
  final List<String> divisions;
  final bool isActive;
  final DateTime? createdAt;

  /// The names to show for this main class wherever classes are listed or
  /// selected — its individual divisions if it has any (e.g. "Beginner 1",
  /// "Beginner 2"), otherwise just the main class itself (e.g. "Primary"),
  /// so a class with no divisions yet is still visible and selectable.
  List<String> get displayClassNames => divisions.isEmpty ? [name] : divisions;

  factory MainClass.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return MainClass(
      id: doc.id,
      name: data['name'] as String? ?? doc.id,
      divisions: List<String>.from(data['divisions'] as List? ?? const []),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
