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
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _classCollection =>
      _firestore.collection('class');

  /// The Firestore document id for a given main class name.
  static String normalizeId(String mainClassName) =>
      mainClassName.trim().toLowerCase();

  /// Returns a user-facing validation message for [rawDivisions], or null
  /// when they're all non-empty and free of duplicates (case-insensitive).
  static String? validateDivisionNames(List<String> rawDivisions) {
    final trimmed = rawDivisions.map((d) => d.trim()).toList();
    if (trimmed.isEmpty || trimmed.any((d) => d.isEmpty)) {
      return 'Division names cannot be empty';
    }
    final lowerCased = trimmed.map((d) => d.toLowerCase()).toList();
    if (lowerCased.toSet().length != lowerCased.length) {
      return 'Duplicate division names are not allowed';
    }
    return null;
  }

  /// Loads every main class document.
  Future<List<MainClass>> getMainClasses() async {
    final snapshot = await _classCollection.orderBy('name').get();
    return snapshot.docs.map(MainClass.fromFirestore).toList();
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

    final trimmedDivisions = divisions.map((d) => d.trim()).toList();
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
      for (final division in newDivisions.map((d) => d.trim())) {
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
