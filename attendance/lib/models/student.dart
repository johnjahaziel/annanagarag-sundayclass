import 'package:cloud_firestore/cloud_firestore.dart';

/// A student record stored as a document in the `students` Firestore
/// collection.
class Student {
  const Student({
    required this.id,
    required this.studentId,
    required this.name,
    required this.gender,
    required this.dob,
    required this.parentName,
    required this.parentPhone,
    required this.assignedClass,
    required this.isActive,
    required this.service,
    this.photoUrl,
    this.createdAt,
  });

  /// The Firestore auto-generated document id.
  final String id;

  /// The human-facing sequential id, e.g. "STU001".
  final String studentId;
  final String name;
  final String gender;
  final DateTime dob;
  final String parentName;
  final String parentPhone;
  final String assignedClass;
  final bool isActive;

  /// Which Sunday service this student is assigned to — see [Service].
  final String service;
  final String? photoUrl;
  final DateTime? createdAt;

  factory Student.fromMap(String id, Map<String, dynamic> data) {
    return Student(
      id: id,
      studentId: data['studentId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      dob: (data['dob'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentName: data['parentName'] as String? ?? '',
      parentPhone: data['parentPhone'] as String? ?? '',
      assignedClass: data['assignedClass'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      service: data['service'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Student.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) => Student.fromMap(doc.id, doc.data());
}
