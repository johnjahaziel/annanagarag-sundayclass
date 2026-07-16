import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin.dart';
import '../services/cloudinary_service.dart';
import 'teacher_repository.dart'
    show TeacherRepository, UsernameAlreadyTakenException;

/// Data access layer for the `admins` Firestore collection.
class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore, CloudinaryService? cloudinaryService})
    : _firestoreOverride = firestore,
      _cloudinaryService = cloudinaryService ?? CloudinaryService();

  final FirebaseFirestore? _firestoreOverride;
  final CloudinaryService _cloudinaryService;

  // Resolved lazily so constructing this repository before
  // Firebase.initializeApp() has run doesn't throw outside a try/catch.
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _adminsCollection =>
      _firestore.collection('admins');

  static const _adminIdPrefix = 'ADM';
  static const _adminIdDigits = 3;

  static String normalizeUsername(String username) =>
      TeacherRepository.normalizeUsername(username);

  /// Derives a username from a full name, e.g. "John Jahaziel" ->
  /// "johnjahaziel" (lower-cased, alphanumeric characters only).
  static String suggestUsername(String name) =>
      TeacherRepository.suggestUsername(name);

  /// Whether [username] is already used by another admin document.
  Future<bool> isUsernameTaken(String username) async {
    final normalized = normalizeUsername(username);
    if (normalized.isEmpty) return false;
    final snapshot = await _adminsCollection
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Loads every admin document, ordered by their sequential adminId.
  Future<List<Admin>> getAdmins() async {
    final snapshot = await _adminsCollection.orderBy('adminId').get();
    return snapshot.docs.map(Admin.fromFirestore).toList();
  }

  /// The admin with this [username], or null if none matches — used for
  /// the username-based login flow.
  Future<Admin?> getByUsername(String username) async {
    final normalized = normalizeUsername(username);
    if (normalized.isEmpty) return null;
    final snapshot = await _adminsCollection
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Admin.fromFirestore(snapshot.docs.first);
  }

  Future<String> _generateNextAdminId() async {
    final snapshot = await _adminsCollection
        .orderBy('adminId', descending: true)
        .limit(1)
        .get();

    var nextNumber = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()['adminId'] as String? ?? '';
      final match = RegExp(r'(\d+)$').firstMatch(lastId);
      if (match != null) {
        nextNumber = int.parse(match.group(1)!) + 1;
      }
    }
    return '$_adminIdPrefix${nextNumber.toString().padLeft(_adminIdDigits, '0')}';
  }

  /// Creates a new admin document. If [photoFile] is provided, it's
  /// uploaded to Cloudinary first (unsigned, via [CloudinaryService]) and
  /// its `secure_url` saved as `photoUrl`.
  ///
  /// Throws [UsernameAlreadyTakenException] if [username] is already in use.
  Future<Admin> createAdmin({
    required String name,
    required String username,
    required String phone,
    required String gender,
    required String role,
    File? photoFile,
  }) async {
    final normalizedUsername = normalizeUsername(username);
    if (await isUsernameTaken(normalizedUsername)) {
      throw UsernameAlreadyTakenException(normalizedUsername);
    }

    final adminId = await _generateNextAdminId();
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();

    String? photoUrl;
    if (photoFile != null) {
      photoUrl = await _cloudinaryService.uploadAdminPhoto(
        photoFile,
        trimmedName,
      );
    }

    final docRef = await _adminsCollection.add({
      'adminId': adminId,
      'name': trimmedName,
      'username': normalizedUsername,
      'phone': trimmedPhone,
      'gender': gender,
      'role': role,
      'isActive': true,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return Admin(
      id: docRef.id,
      adminId: adminId,
      name: trimmedName,
      username: normalizedUsername,
      phone: trimmedPhone,
      gender: gender,
      role: role,
      isActive: true,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );
  }

  /// Uploads a new photo for an existing admin and updates only the
  /// `photoUrl` field on their document.
  ///
  /// [docId] is the admin's Firestore document id ([Admin.id]), not their
  /// sequential `adminId` (e.g. "ADM001").
  Future<String> updateAdminPhoto({
    required String docId,
    required String name,
    required File photoFile,
  }) async {
    final photoUrl = await _cloudinaryService.uploadAdminPhoto(
      photoFile,
      name,
    );
    await _adminsCollection.doc(docId).update({'photoUrl': photoUrl});
    return photoUrl;
  }
}
