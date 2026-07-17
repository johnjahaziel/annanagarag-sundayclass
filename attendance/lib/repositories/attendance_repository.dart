import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_session.dart';

/// Data access layer for the `attendance` Firestore collection.
///
/// Attendance is taken separately per service: each document is one
/// class's attendance for one service on one day, keyed by
/// `<yyyyMMdd>_<classId>_<serviceId>` so marking attendance twice for the
/// same class/service/day overwrites the same document instead of
/// creating duplicates, while Service 1 and Service 2 for the same class
/// on the same day are always two independent documents.
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

  /// A stable id derived from a service name, e.g. "Service 1" ->
  /// "service1" (all non-alphanumeric characters stripped, not replaced
  /// with an underscore — that's what keeps `sessionId` reading as
  /// `..._service1` rather than `..._service_1`).
  static String normalizeService(String service) =>
      service.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static String yyyyMMdd(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  /// Builds a session id, e.g. `20260717_beginner_1_service1`.
  static String sessionId(String classId, DateTime date, String service) {
    return '${yyyyMMdd(date)}_${classId}_${normalizeService(service)}';
  }

  /// The attendance session for [className]'s [service] on [date], or
  /// null if nothing has been marked for that class/service/day yet.
  Future<AttendanceSession?> getSessionForDate({
    required String className,
    required DateTime date,
    required String service,
  }) async {
    final classId = normalizeClassId(className);
    final id = sessionId(classId, date, service);
    final doc = await _attendanceCollection.doc(id).get();
    final data = doc.data();
    if (data == null) return null;
    return AttendanceSession.fromMap(doc.id, data);
  }

  /// Every attendance session for a single day (e.g. a chosen Sunday),
  /// across the whole `attendance` collection. Pass [service] to narrow
  /// to just that service.
  ///
  /// Filters on `date` alone, or `date` + `service` (two equality
  /// clauses), so this never needs a composite Firestore index — Firestore
  /// serves multi-field queries without one as long as every clause is an
  /// equality clause.
  Future<List<AttendanceSession>> getSessionsForDate(
    DateTime date, {
    String? service,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    Query<Map<String, dynamic>> query = _attendanceCollection.where(
      'date',
      isEqualTo: Timestamp.fromDate(dateOnly),
    );
    if (service != null) {
      query = query.where('service', isEqualTo: service);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => AttendanceSession.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Every attendance session within [year]/[month], across the whole
  /// `attendance` collection. Pass [service] to narrow to just that
  /// service.
  ///
  /// The Firestore query itself only ever filters on `date` (two range
  /// clauses on the same field — no composite index needed). [service],
  /// when given, is applied client-side afterward instead of as a third
  /// `where` clause, because combining a range filter on one field with
  /// an equality filter on a *different* field is exactly the case that
  /// *does* require a composite index — and the local list here is small
  /// enough (a handful of classes × 2 services × ~4-5 Sundays) that
  /// filtering in Dart costs nothing noticeable.
  Future<List<AttendanceSession>> getSessionsForMonth(
    int year,
    int month, {
    String? service,
  }) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(
      month == 12 ? year + 1 : year,
      month == 12 ? 1 : month + 1,
      1,
    );
    final snapshot = await _attendanceCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    final sessions = snapshot.docs
        .map((doc) => AttendanceSession.fromMap(doc.id, doc.data()))
        .toList();
    if (service == null) return sessions;
    return sessions.where((session) => session.service == service).toList();
  }

  /// Every recorded session for a single class (e.g. "Beginner 1"), across
  /// every service and its entire history.
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

  /// Creates or overwrites the attendance session for [className]'s
  /// [service] on [date] with [records] (keyed by studentId). Safe to
  /// call repeatedly for the same class/service/day — each call replaces
  /// the previous one entirely, so editing a day's attendance is just
  /// calling this again. Service 1 and Service 2 are always independent
  /// documents, so saving one never touches the other.
  Future<AttendanceSession> saveSession({
    required String className,
    required String service,
    required String? teacherId,
    required String? teacherName,
    required DateTime date,
    required Map<String, AttendanceRecord> records,
  }) async {
    final classId = normalizeClassId(className);
    final id = sessionId(classId, date, service);
    final dateOnly = DateTime(date.year, date.month, date.day);

    await _attendanceCollection.doc(id).set({
      'classId': classId,
      'className': className,
      'service': service,
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
      service: service,
      teacherId: teacherId,
      teacherName: teacherName,
      date: dateOnly,
      records: records,
    );
  }
}
