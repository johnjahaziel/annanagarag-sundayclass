import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/main_class.dart';

/// Thrown when trying to create a main class whose normalized name already
/// has a document in Firestore.
class ClassAlreadyExistsException implements Exception {
  ClassAlreadyExistsException(this.mainClassName);

  final String mainClassName;

  @override
  String toString() => 'A main class named "$mainClassName" already exists.';
}

/// Thrown when an operation targets a main class document that doesn't exist.
class ClassNotFoundException implements Exception {
  ClassNotFoundException(this.mainClassId);

  final String mainClassId;

  @override
  String toString() => 'Main class "$mainClassId" was not found.';
}

/// Thrown when a division name being added already exists on the target
/// main class.
class DuplicateDivisionException implements Exception {
  DuplicateDivisionException(this.divisionName);

  final String divisionName;

  @override
  String toString() => 'Division "$divisionName" already exists in this class.';
}

/// Data access layer for the `class` Firestore collection.
///
/// Each document represents a "main class" (Beginner, Intermediate, Youth,
/// ...) keyed by its normalized name, holding a `divisions` array of the
/// named sub-groups within it (Beginner 1, Beginner 2, ...).
class ClassRepository {
  ClassRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Resolved lazily (rather than in the constructor) so that constructing a
  // repository/controller before Firebase.initializeApp() has run doesn't
  // throw outside of a try/catch — the error instead surfaces from whichever
  // method actually touches Firestore, where callers already handle it.
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _classCollection =>
      _firestore.collection('class');

  /// The Firestore document id for a given main class name.
  static String normalizeId(String mainClassName) =>
      mainClassName.trim().toLowerCase();

  /// The order main classes should be displayed in (Sunday-school age
  /// groups, youngest to oldest), keyed by normalized id. Classes not on
  /// this list (e.g. a newly added one) are appended afterwards,
  /// alphabetically.
  static const List<String> _displayOrder = [
    'beginner',
    'primary',
    'junior',
    'inter',
  ];

  List<MainClass> _sortByDisplayOrder(List<MainClass> classes) {
    final ranked = <MainClass>[];
    final unranked = <MainClass>[];
    for (final mainClass in classes) {
      if (_displayOrder.contains(mainClass.id)) {
        ranked.add(mainClass);
      } else {
        unranked.add(mainClass);
      }
    }
    ranked.sort(
      (a, b) =>
          _displayOrder.indexOf(a.id).compareTo(_displayOrder.indexOf(b.id)),
    );
    unranked.sort((a, b) => a.name.compareTo(b.name));
    return [...ranked, ...unranked];
  }

  /// Returns a user-facing validation message for [rawDivisions], or null
  /// when the non-empty ones are free of duplicates (case-insensitive).
  /// Divisions are optional, so blank entries are ignored rather than
  /// rejected.
  static String? validateDivisionNames(List<String> rawDivisions) {
    final trimmed = rawDivisions
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();
    final lowerCased = trimmed.map((d) => d.toLowerCase()).toList();
    if (lowerCased.toSet().length != lowerCased.length) {
      return 'Duplicate division names are not allowed';
    }
    return null;
  }

  /// Loads every main class document, in [_displayOrder].
  Future<List<MainClass>> getMainClasses() async {
    final snapshot = await _classCollection.get();
    return _sortByDisplayOrder(
      snapshot.docs.map(MainClass.fromFirestore).toList(),
    );
  }

  /// Live view of every main class document in [_displayOrder], updating
  /// whenever one is added, renamed, or has divisions changed. Used by
  /// pickers (e.g. the Assigned Class dropdown) that should reflect new
  /// classes immediately.
  Stream<List<MainClass>> streamMainClasses() {
    return _classCollection.snapshots().map(
      (snapshot) => _sortByDisplayOrder(
        snapshot.docs.map(MainClass.fromFirestore).toList(),
      ),
    );
  }

  /// Creates a brand new main class document with its initial divisions.
  ///
  /// Throws [ClassAlreadyExistsException] if a document with the normalized
  /// name already exists, or [ArgumentError] if [divisions] is invalid.
  Future<MainClass> createMainClass({
    required String name,
    required List<String> divisions,
  }) async {
    final validationError = validateDivisionNames(divisions);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final trimmedName = name.trim();
    final docId = normalizeId(trimmedName);
    final docRef = _classCollection.doc(docId);

    final existing = await docRef.get();
    if (existing.exists) {
      throw ClassAlreadyExistsException(trimmedName);
    }

    final trimmedDivisions = divisions
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();
    await docRef.set({
      'name': trimmedName,
      'divisions': trimmedDivisions,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return MainClass(
      id: docId,
      name: trimmedName,
      divisions: trimmedDivisions,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Appends [newDivisions] to an existing main class's `divisions` array
  /// without overwriting the ones already there.
  ///
  /// Runs as a transaction so concurrent adds can't silently drop each
  /// other's divisions. Throws [ClassNotFoundException] if [mainClassId]
  /// doesn't exist, [DuplicateDivisionException] if any new division
  /// already exists on the class, or [ArgumentError] if [newDivisions]
  /// itself is invalid (empty/duplicate names).
  Future<MainClass> addDivisionsToClass({
    required String mainClassId,
    required List<String> newDivisions,
  }) async {
    final validationError = validateDivisionNames(newDivisions);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final docRef = _classCollection.doc(mainClassId);

    return _firestore.runTransaction<MainClass>((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) {
        throw ClassNotFoundException(mainClassId);
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final existingDivisions = List<String>.from(
        data['divisions'] as List? ?? const [],
      );
      final existingLower = existingDivisions
          .map((d) => d.toLowerCase())
          .toSet();

      final toAdd = <String>[];
      for (final division in newDivisions
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)) {
        final key = division.toLowerCase();
        if (existingLower.contains(key)) {
          throw DuplicateDivisionException(division);
        }
        existingLower.add(key);
        toAdd.add(division);
      }

      final updatedDivisions = [...existingDivisions, ...toAdd];
      tx.update(docRef, {'divisions': updatedDivisions});

      return MainClass(
        id: mainClassId,
        name: data['name'] as String? ?? mainClassId,
        divisions: updatedDivisions,
        isActive: data['isActive'] as bool? ?? true,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    });
  }

  /// Saves a class form submission: creates a new main class or appends
  /// divisions to an existing one, depending on [isNewMainClass].
  Future<MainClass> saveClass({
    required String mainClassName,
    required bool isNewMainClass,
    String? existingMainClassId,
    required List<String> divisions,
  }) {
    if (isNewMainClass) {
      return createMainClass(name: mainClassName, divisions: divisions);
    }
    final id = existingMainClassId ?? normalizeId(mainClassName);
    return addDivisionsToClass(mainClassId: id, newDivisions: divisions);
  }
}
