import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student.dart';
import '../services/cloudinary_service.dart';

/// Data access layer for the `students` Firestore collection.
class StudentRepository {
  StudentRepository({
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

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection('students');

  static const _studentIdPrefix = 'STU';
  static const _studentIdDigits = 3;

  /// Loads every student document, ordered by their sequential studentId.
  Future<List<Student>> getStudents() async {
    final snapshot = await _studentsCollection.orderBy('studentId').get();
    return snapshot.docs.map(Student.fromFirestore).toList();
  }

  /// All students assigned to [assignedClass] (a division, e.g.
  /// "Beginner 1").
  Future<List<Student>> getStudentsForClass(String assignedClass) async {
    final snapshot = await _studentsCollection
        .where('assignedClass', isEqualTo: assignedClass)
        .get();
    return snapshot.docs.map(Student.fromFirestore).toList();
  }

  /// All students assigned to [className] for [service] (see [Service]).
  /// Both are equality filters, so this never needs a composite Firestore
  /// index.
  Future<List<Student>> getStudentsForClassAndService({
    required String className,
    required String service,
  }) async {
    final snapshot = await _studentsCollection
        .where('assignedClass', isEqualTo: className)
        .where('service', isEqualTo: service)
        .get();
    return snapshot.docs.map(Student.fromFirestore).toList();
  }

  Future<String> _generateNextStudentId() async {
    final snapshot = await _studentsCollection
        .orderBy('studentId', descending: true)
        .limit(1)
        .get();

    var nextNumber = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()['studentId'] as String? ?? '';
      final match = RegExp(r'(\d+)$').firstMatch(lastId);
      if (match != null) {
        nextNumber = int.parse(match.group(1)!) + 1;
      }
    }
    return '$_studentIdPrefix${nextNumber.toString().padLeft(_studentIdDigits, '0')}';
  }

  /// Creates a new student document. If [photoFile] is provided, it's
  /// uploaded to Cloudinary first (unsigned, via [CloudinaryService]) and
  /// its `secure_url` saved as `photoUrl`.
  Future<Student> createStudent({
    required String name,
    required String gender,
    required DateTime dob,
    required String parentName,
    required String parentPhone,
    required String assignedClass,
    required String service,
    File? photoFile,
  }) async {
    final studentId = await _generateNextStudentId();
    final trimmedName = name.trim();
    final trimmedParentName = parentName.trim();
    final trimmedParentPhone = parentPhone.trim();
    // Only the date matters for a birthday — drop any time-of-day so what's
    // stored (and read back) is just day/month/year.
    final dateOnlyDob = DateTime(dob.year, dob.month, dob.day);

    String? photoUrl;
    if (photoFile != null) {
      photoUrl = await _cloudinaryService.uploadStudentPhoto(
        photoFile,
        trimmedName,
      );
    }

    final docRef = await _studentsCollection.add({
      'studentId': studentId,
      'name': trimmedName,
      'gender': gender,
      'dob': Timestamp.fromDate(dateOnlyDob),
      'parentName': trimmedParentName,
      'parentPhone': trimmedParentPhone,
      'assignedClass': assignedClass,
      'isActive': true,
      'service': service,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return Student(
      id: docRef.id,
      studentId: studentId,
      name: trimmedName,
      gender: gender,
      dob: dateOnlyDob,
      parentName: trimmedParentName,
      parentPhone: trimmedParentPhone,
      assignedClass: assignedClass,
      isActive: true,
      service: service,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );
  }

  /// Uploads a new photo for an existing student and updates only the
  /// `photoUrl` field on their document.
  ///
  /// [docId] is the student's Firestore document id ([Student.id]), not
  /// their sequential `studentId` (e.g. "STU001").
  Future<String> updateStudentPhoto({
    required String docId,
    required String name,
    required File photoFile,
  }) async {
    final photoUrl = await _cloudinaryService.uploadStudentPhoto(
      photoFile,
      name,
    );
    await _studentsCollection.doc(docId).update({'photoUrl': photoUrl});
    return photoUrl;
  }
}
