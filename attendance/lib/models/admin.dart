import 'package:cloud_firestore/cloud_firestore.dart';

/// An admin record stored as a document in the `admins` Firestore
/// collection.
class Admin {
  const Admin({
    required this.id,
    required this.adminId,
    required this.name,
    required this.username,
    required this.phone,
    required this.gender,
    required this.role,
    required this.isActive,
    this.photoUrl,
    this.createdAt,
  });

  /// The Firestore auto-generated document id.
  final String id;

  /// The human-facing sequential id, e.g. "ADM001".
  final String adminId;
  final String name;
  final String username;
  final String phone;
  final String gender;

  /// Always "Admin" — kept alongside [Teacher.role] so both collections
  /// share the same field name/shape.
  final String role;
  final bool isActive;
  final String? photoUrl;
  final DateTime? createdAt;

  factory Admin.fromMap(String id, Map<String, dynamic> data) {
    return Admin(
      id: id,
      adminId: data['adminId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      username: data['username'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      role: data['role'] as String? ?? 'Admin',
      isActive: data['isActive'] as bool? ?? true,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Admin.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      Admin.fromMap(doc.id, doc.data());
}
