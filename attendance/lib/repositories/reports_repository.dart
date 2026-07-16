import '../models/attendance_session.dart';
import '../models/report_models.dart';
import '../models/student.dart';
import 'attendance_repository.dart';
import 'student_repository.dart';

/// Aggregates data from [AttendanceRepository] and [StudentRepository]
/// into the report models used by the Reports module. All the Firestore
/// querying happens here — the UI just renders whatever these methods
/// return.
class ReportsRepository {
  ReportsRepository({
    AttendanceRepository? attendanceRepository,
    StudentRepository? studentRepository,
  }) : _attendanceRepository = attendanceRepository ?? AttendanceRepository(),
       _studentRepository = studentRepository ?? StudentRepository();

  final AttendanceRepository _attendanceRepository;
  final StudentRepository _studentRepository;

  /// Every Sunday that falls within [year]/[month], in chronological order.
  static List<DateTime> sundaysInMonth(int year, int month) {
    var day = DateTime(year, month, 1);
    while (day.weekday != DateTime.sunday) {
      day = day.add(const Duration(days: 1));
    }
    final sundays = <DateTime>[];
    while (day.month == month) {
      sundays.add(day);
      day = day.add(const Duration(days: 7));
    }
    return sundays;
  }

  Map<String, List<Student>> _groupByClass(List<Student> students) {
    final byClass = <String, List<Student>>{};
    for (final student in students) {
      byClass.putIfAbsent(student.assignedClass, () => []).add(student);
    }
    return byClass;
  }

  /// The attendance picture for [sunday] across every class.
  Future<WeeklyReport> getWeeklyReport(DateTime sunday) async {
    final dateOnly = DateTime(sunday.year, sunday.month, sunday.day);
    final results = await Future.wait([
      _attendanceRepository.getSessionsForDate(dateOnly),
      _studentRepository.getStudents(),
    ]);
    final sessions = results[0] as List<AttendanceSession>;
    final allStudents = results[1] as List<Student>;

    final sessionByClassId = {for (final s in sessions) s.classId: s};
    final studentsByClass = _groupByClass(allStudents);

    final classSummaries = <ClassAttendanceSummary>[];
    final studentEntries = <StudentAttendanceEntry>[];
    var totalPresent = 0;

    for (final entry in studentsByClass.entries) {
      final className = entry.key;
      final classId = AttendanceRepository.normalizeClassId(className);
      final session = sessionByClassId[classId];

      var present = 0;
      for (final student in entry.value) {
        final status = session?.statusFor(student.id) ?? 'Absent';
        if (status == 'Present') present++;
        studentEntries.add(
          StudentAttendanceEntry(
            studentId: student.id,
            studentName: student.name,
            className: className,
            status: status,
          ),
        );
      }

      classSummaries.add(
        ClassAttendanceSummary(
          className: className,
          total: entry.value.length,
          present: present,
        ),
      );
      totalPresent += present;
    }

    classSummaries.sort((a, b) => b.percentage.compareTo(a.percentage));
    studentEntries.sort((a, b) => a.studentName.compareTo(b.studentName));

    return WeeklyReport(
      date: dateOnly,
      totalStudents: allStudents.length,
      presentCount: totalPresent,
      classSummaries: classSummaries,
      studentEntries: studentEntries,
    );
  }

  /// The attendance picture for [year]/[month], calculated using only the
  /// Sundays that fall within it.
  Future<MonthlyReport> getMonthlyReport(int year, int month) async {
    final sundays = sundaysInMonth(year, month);
    final results = await Future.wait([
      _attendanceRepository.getSessionsForMonth(year, month),
      _studentRepository.getStudents(),
    ]);
    final sessions = results[0] as List<AttendanceSession>;
    final allStudents = results[1] as List<Student>;

    final sessionByClassAndDate = {
      for (final s in sessions)
        '${s.classId}_${AttendanceRepository.yyyyMMdd(s.date)}': s,
    };
    final studentsByClass = _groupByClass(allStudents);

    final classStats = <ClassMonthlyStat>[];
    final studentStats = <StudentMonthlyStat>[];

    for (final entry in studentsByClass.entries) {
      final className = entry.key;
      final classId = AttendanceRepository.normalizeClassId(className);
      var classPresentTotal = 0;

      for (final student in entry.value) {
        var studentPresent = 0;
        for (final sunday in sundays) {
          final key =
              '${classId}_${AttendanceRepository.yyyyMMdd(sunday)}';
          final session = sessionByClassAndDate[key];
          final status = session?.statusFor(student.id) ?? 'Absent';
          if (status == 'Present') {
            studentPresent++;
            classPresentTotal++;
          }
        }
        studentStats.add(
          StudentMonthlyStat(
            studentId: student.id,
            studentName: student.name,
            className: className,
            presentCount: studentPresent,
            totalSundays: sundays.length,
          ),
        );
      }

      classStats.add(
        ClassMonthlyStat(
          className: className,
          presentTotal: classPresentTotal,
          possibleTotal: entry.value.length * sundays.length,
        ),
      );
    }

    classStats.sort((a, b) => b.percentage.compareTo(a.percentage));
    studentStats.sort((a, b) => b.percentage.compareTo(a.percentage));

    return MonthlyReport(
      year: year,
      month: month,
      sundays: sundays,
      classStats: classStats,
      studentStats: studentStats,
    );
  }

  /// The attendance summary shown on a student's details page: this
  /// month's percentage, all-time present/absent totals, and history.
  Future<StudentReportSummary> getStudentReport(Student student) async {
    final now = DateTime.now();
    final results = await Future.wait([
      getMonthlyReport(now.year, now.month),
      _attendanceRepository.getSessionsForClass(student.assignedClass),
    ]);
    final monthly = results[0] as MonthlyReport;
    final allSessions = results[1] as List<AttendanceSession>;

    double thisMonthPercentage = 0;
    for (final stat in monthly.studentStats) {
      if (stat.studentId == student.id) {
        thisMonthPercentage = stat.percentage;
        break;
      }
    }

    var totalPresents = 0;
    var totalAbsents = 0;
    final history = <StudentAttendanceHistoryEntry>[];
    for (final session in allSessions) {
      final status = session.statusFor(student.id);
      if (status == null) continue;
      if (status == 'Present') {
        totalPresents++;
      } else {
        totalAbsents++;
      }
      history.add(
        StudentAttendanceHistoryEntry(
          date: session.date,
          status: status,
          className: session.className,
        ),
      );
    }
    history.sort((a, b) => b.date.compareTo(a.date));

    return StudentReportSummary(
      thisMonthPercentage: thisMonthPercentage,
      totalPresents: totalPresents,
      totalAbsents: totalAbsents,
      history: history,
    );
  }

  /// The attendance summary shown for a single class: student count,
  /// this month's average attendance, and a trend across its last few
  /// recorded Sundays.
  Future<ClassReportSummary> getClassReport(String className) async {
    final now = DateTime.now();
    final results = await Future.wait([
      _studentRepository.getStudentsForClass(className),
      _attendanceRepository.getSessionsForClass(className),
      getMonthlyReport(now.year, now.month),
    ]);
    final students = results[0] as List<Student>;
    final allSessions = results[1] as List<AttendanceSession>;
    final monthly = results[2] as MonthlyReport;

    var averageMonthlyPercentage = 0.0;
    for (final stat in monthly.classStats) {
      if (stat.className == className) {
        averageMonthlyPercentage = stat.percentage;
        break;
      }
    }

    final sortedSessions = [...allSessions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentSessions = sortedSessions.take(6).toList().reversed.toList();
    final trend = recentSessions.map((session) {
      final total = students.length;
      final present = students
          .where((student) => session.statusFor(student.id) == 'Present')
          .length;
      return ClassTrendPoint(
        date: session.date,
        percentage: total == 0 ? 0 : present / total * 100,
      );
    }).toList();

    return ClassReportSummary(
      className: className,
      studentCount: students.length,
      averageMonthlyPercentage: averageMonthlyPercentage,
      trend: trend,
    );
  }
}
