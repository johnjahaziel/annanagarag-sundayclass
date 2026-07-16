import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_session.dart';

/// Data access layer for the `attendance` Firestore collection.
///
/// Each document is one class's attendance for one day, keyed by
/// `<yyyyMMdd>_<classId>` so marking attendance twice for the same class
/// and day overwrites the same document instead of creating duplicates.
class AttendanceRepository {
  AttendanceRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Resolved lazily so constructing this repository before
  // Firebase.initializeApp() has run doesn't throw outside a try/catch.
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _attendanceCollection =>
      _firestore.collection('attendance');

  /// A stable id derived from a class/division name (e.g. "Beginner 1"),
  /// since divisions aren't otherwise assigned a dedicated Firestore id.
  static String normalizeClassId(String className) =>
      className.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  static String yyyyMMdd(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  static String sessionId(String classId, DateTime date) =>
      '${yyyyMMdd(date)}_$classId';

  /// The attendance session for [className] on [date], or null if nothing
  /// has been marked for that day yet.
  Future<AttendanceSession?> getSessionForDate({
    required String className,
    required DateTime date,
  }) async {
    final classId = normalizeClassId(className);
    final id = sessionId(classId, date);
    final doc = await _attendanceCollection.doc(id).get();
    final data = doc.data();
    if (data == null) return null;
    return AttendanceSession.fromMap(doc.id, data);
  }

  /// Every class's attendance session for a single day (e.g. a chosen
  /// Sunday), across the whole `attendance` collection.
  ///
  /// Filters on `date` alone (a single equality clause) so this never
  /// needs a composite Firestore index.
  Future<List<AttendanceSession>> getSessionsForDate(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final snapshot = await _attendanceCollection
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .get();
    return snapshot.docs
        .map((doc) => AttendanceSession.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Every class's attendance sessions within [year]/[month], across the
  /// whole `attendance` collection.
  ///
  /// Filters on `date` alone (two range clauses on the same field) so
  /// this never needs a composite Firestore index.
  Future<List<AttendanceSession>> getSessionsForMonth(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(month == 12 ? year + 1 : year, month == 12 ? 1 : month + 1, 1);
    final snapshot = await _attendanceCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snapshot.docs
        .map((doc) => AttendanceSession.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Every recorded session for a single class (e.g. "Beginner 1"),
  /// across its entire history.
  ///
  /// Filters on `classId` alone (a single equality clause) so this never
  /// needs a composite Firestore index. Not sorted or limited server-side
  /// — callers should sort/take what they need after fetching, since
  /// adding `orderBy('date')` here would combine with the `classId`
  /// equality filter and require a composite index.
  Future<List<AttendanceSession>> getSessionsForClass(String className) async {
    final classId = normalizeClassId(className);
    final snapshot = await _attendanceCollection
        .where('classId', isEqualTo: classId)
        .get();
    return snapshot.docs
        .map((doc) => AttendanceSession.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Creates or overwrites the attendance session for [className] on
  /// [date] with [records] (keyed by studentId). Safe to call repeatedly
  /// for the same day — each call replaces the previous one entirely, so
  /// editing a day's attendance is just calling this again.
  Future<AttendanceSession> saveSession({
    required String className,
    required String? teacherId,
    required String? teacherName,
    required DateTime date,
    required Map<String, AttendanceRecord> records,
  }) async {
    final classId = normalizeClassId(className);
    final id = sessionId(classId, date);
    final dateOnly = DateTime(date.year, date.month, date.day);

    await _attendanceCollection.doc(id).set({
      'classId': classId,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'date': Timestamp.fromDate(dateOnly),
      'students': records.map(
        (studentId, record) => MapEntry(studentId, record.toMap()),
      ),
    });

    return AttendanceSession(
      id: id,
      classId: classId,
      className: className,
      teacherId: teacherId,
      teacherName: teacherName,
      date: dateOnly,
      records: records,
    );
  }
}
