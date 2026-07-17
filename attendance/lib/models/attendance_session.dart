import 'package:cloud_firestore/cloud_firestore.dart';

/// One student's recorded attendance within an [AttendanceSession].
class AttendanceRecord {
  const AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.markedAt,
  });

  final String studentId;
  final String studentName;

  /// "Present" or "Absent". A student with no [AttendanceRecord] for the
  /// day is considered "Not Marked" — that's a derived state, not stored.
  final String status;
  final DateTime markedAt;

  factory AttendanceRecord.fromMap(String studentId, Map<String, dynamic> data) {
    return AttendanceRecord(
      // Prefer the stored studentId (present since this field was added);
      // fall back to the map key for older documents that predate it.
      studentId: data['studentId'] as String? ?? studentId,
      studentName: data['studentName'] as String? ?? '',
      status: data['status'] as String? ?? '',
      markedAt: (data['markedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Copies [studentId] and [studentName] from the student record at the
  /// time attendance is marked, so displaying attendance history never
  /// needs a second read from the `students` collection.
  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'studentName': studentName,
    'status': status,
    'markedAt': Timestamp.fromDate(markedAt),
  };
}

/// A single day's attendance for one class, stored as a document in the
/// `attendance` Firestore collection (id: `yyyyMMdd_classId`).
class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.date,
    required this.records,
    this.service,
  });

  final String id;
  final String classId;
  final String className;
  final String? teacherId;
  final String? teacherName;
  final DateTime date;

  /// Which Sunday service this session belongs to, if attendance is ever
  /// taken separately per service — see [Service]. Null for the
  /// whole-class sessions every current caller creates.
  final String? service;

  /// Keyed by studentId.
  final Map<String, AttendanceRecord> records;

  String? statusFor(String studentId) => records[studentId]?.status;

  int get presentCount =>
      records.values.where((record) => record.status == 'Present').length;

  int get absentCount =>
      records.values.where((record) => record.status == 'Absent').length;

  factory AttendanceSession.fromMap(String id, Map<String, dynamic> data) {
    final studentsData = (data['students'] as Map<String, dynamic>?) ?? {};
    final records = studentsData.map(
      (studentId, value) => MapEntry(
        studentId,
        AttendanceRecord.fromMap(studentId, value as Map<String, dynamic>),
      ),
    );
    return AttendanceSession(
      id: id,
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      teacherId: data['teacherId'] as String?,
      teacherName: data['teacherName'] as String?,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      service: data['service'] as String?,
      records: records,
    );
  }
}
