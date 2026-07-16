import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/teacher.dart';
import '../services/cloudinary_service.dart';

/// Thrown when creating a teacher whose username already belongs to
/// another teacher document.
class UsernameAlreadyTakenException implements Exception {
  UsernameAlreadyTakenException(this.username);

  final String username;

  @override
  String toString() => 'Username "$username" is already taken.';
}

/// Data access layer for the `teachers` Firestore collection.
class TeacherRepository {
  TeacherRepository({
    FirebaseFirestore? firestore,
    CloudinaryService? cloudinaryService,
  }) : _firestoreOverride = firestore,
       _cloudinaryService = cloudinaryService ?? CloudinaryService();

  final FirebaseFirestore? _firestoreOverride;
  final CloudinaryService _cloudinaryService;

  // Resolved lazily so constructing this repository before
  // Firebase.initializeApp() has run doesn't throw outside a try/catch.
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _teachersCollection =>
      _firestore.collection('teachers');

  static const _teacherIdPrefix = 'TCH';
  static const _teacherIdDigits = 3;

  static String normalizeUsername(String username) =>
      username.trim().toLowerCase();

  /// Derives a username from a full name, e.g. "John Jahaziel" ->
  /// "johnjahaziel" (lower-cased, alphanumeric characters only).
  static String suggestUsername(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Whether [username] is already used by another teacher document.
  Future<bool> isUsernameTaken(String username) async {
    final normalized = normalizeUsername(username);
    if (normalized.isEmpty) return false;
    final snapshot = await _teachersCollection
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Loads every teacher document, ordered by their sequential teacherId.
  Future<List<Teacher>> getTeachers() async {
    final snapshot = await _teachersCollection.orderBy('teacherId').get();
    return snapshot.docs.map(Teacher.fromFirestore).toList();
  }

  /// The teacher with this [username], or null if none matches — used for
  /// the username-based login flow.
  Future<Teacher?> getByUsername(String username) async {
    final normalized = normalizeUsername(username);
    if (normalized.isEmpty) return null;
    final snapshot = await _teachersCollection
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Teacher.fromFirestore(snapshot.docs.first);
  }

  /// The teacher assigned to [assignedClass] (a division, e.g.
  /// "Beginner 1"), or null if none is assigned. If more than one somehow
  /// matches, the first is returned.
  Future<Teacher?> getTeacherForClass(String assignedClass) async {
    final snapshot = await _teachersCollection
        .where('assignedClass', isEqualTo: assignedClass)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Teacher.fromFirestore(snapshot.docs.first);
  }

  Future<String> _generateNextTeacherId() async {
    final snapshot = await _teachersCollection
        .orderBy('teacherId', descending: true)
        .limit(1)
        .get();

    var nextNumber = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()['teacherId'] as String? ?? '';
      final match = RegExp(r'(\d+)$').firstMatch(lastId);
      if (match != null) {
        nextNumber = int.parse(match.group(1)!) + 1;
      }
    }
    return '$_teacherIdPrefix${nextNumber.toString().padLeft(_teacherIdDigits, '0')}';
  }

  /// Creates a new teacher document. If [photoFile] is provided, it's
  /// uploaded to Cloudinary first (unsigned, via [CloudinaryService]) and
  /// its `secure_url` saved as `photoUrl`.
  ///
  /// Throws [UsernameAlreadyTakenException] if [username] is already in use.
  Future<Teacher> createTeacher({
    required String name,
    required String username,
    required String gender,
    required String phone,
    required String assignedClass,
    required String role,
    required String status,
    File? photoFile,
  }) async {
    final normalizedUsername = normalizeUsername(username);
    if (await isUsernameTaken(normalizedUsername)) {
      throw UsernameAlreadyTakenException(normalizedUsername);
    }

    final teacherId = await _generateNextTeacherId();
    final isActive = status == 'Active';
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();

    String? photoUrl;
    if (photoFile != null) {
      photoUrl = await _cloudinaryService.uploadTeacherPhoto(
        photoFile,
        normalizedUsername,
      );
    }

    final docRef = await _teachersCollection.add({
      'teacherId': teacherId,
      'name': trimmedName,
      'username': normalizedUsername,
      'gender': gender,
      'phone': trimmedPhone,
      'assignedClass': assignedClass,
      'role': role,
      'status': status,
      'isActive': isActive,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return Teacher(
      id: docRef.id,
      teacherId: teacherId,
      name: trimmedName,
      username: normalizedUsername,
      gender: gender,
      phone: trimmedPhone,
      assignedClass: assignedClass,
      role: role,
      status: status,
      isActive: isActive,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );
  }

  /// Uploads a new photo for an existing teacher and updates only the
  /// `photoUrl` field on their document — the rest of the teacher's data
  /// (name, username, assigned class, etc.) is left untouched.
  ///
  /// [docId] is the teacher's Firestore document id ([Teacher.id]), not
  /// their sequential `teacherId` (e.g. "TCH001").
  Future<String> updateTeacherPhoto({
    required String docId,
    required String username,
    required File photoFile,
  }) async {
    final photoUrl = await _cloudinaryService.uploadTeacherPhoto(
      photoFile,
      normalizeUsername(username),
    );
    await _teachersCollection.doc(docId).update({'photoUrl': photoUrl});
    return photoUrl;
  }
}
