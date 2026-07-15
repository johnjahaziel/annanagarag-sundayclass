import 'package:cloud_firestore/cloud_firestore.dart';

/// A teacher/admin record stored as a document in the `teachers` Firestore
/// collection.
class Teacher {
  const Teacher({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.username,
    required this.gender,
    required this.phone,
    required this.assignedClass,
    required this.role,
    required this.status,
    required this.isActive,
    this.photoUrl,
    this.createdAt,
  });

  /// The Firestore auto-generated document id.
  final String id;

  /// The human-facing sequential id, e.g. "TCH001".
  final String teacherId;
  final String name;
  final String username;
  final String gender;
  final String phone;
  final String assignedClass;
  final String role;
  final String status;
  final bool isActive;
  final String? photoUrl;
  final DateTime? createdAt;

  factory Teacher.fromMap(String id, Map<String, dynamic> data) {
    return Teacher(
      id: id,
      teacherId: data['teacherId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      username: data['username'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      assignedClass: data['assignedClass'] as String? ?? '',
      role: data['role'] as String? ?? '',
      status: data['status'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Teacher.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) => Teacher.fromMap(doc.id, doc.data());
}
