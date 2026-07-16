/// Plain data models for the Reports module. Deliberately UI-free — a
/// future PDF export or WhatsApp share feature can format these directly
/// without re-deriving anything from widget state.
library;

/// One class's attendance for a single [WeeklyReport] date.
class ClassAttendanceSummary {
  const ClassAttendanceSummary({
    required this.className,
    required this.total,
    required this.present,
  });

  final String className;
  final int total;
  final int present;

  int get absent => total - present;

  double get percentage => total == 0 ? 0 : present / total * 100;
}

/// One student's attendance for a single [WeeklyReport] date.
class StudentAttendanceEntry {
  const StudentAttendanceEntry({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.status,
  });

  final String studentId;
  final String studentName;
  final String className;

  /// "Present" or "Absent".
  final String status;
}

/// The full attendance picture for a single Sunday, across every class.
class WeeklyReport {
  const WeeklyReport({
    required this.date,
    required this.totalStudents,
    required this.presentCount,
    required this.classSummaries,
    required this.studentEntries,
  });

  final DateTime date;
  final int totalStudents;
  final int presentCount;
  final List<ClassAttendanceSummary> classSummaries;
  final List<StudentAttendanceEntry> studentEntries;

  int get absentCount => totalStudents - presentCount;

  double get attendancePercentage =>
      totalStudents == 0 ? 0 : presentCount / totalStudents * 100;
}

/// One class's attendance across every Sunday in a [MonthlyReport].
class ClassMonthlyStat {
  const ClassMonthlyStat({
    required this.className,
    required this.presentTotal,
    required this.possibleTotal,
  });

  final String className;

  /// Sum of present marks across every student and every Sunday.
  final int presentTotal;

  /// studentCount * sundayCount — the maximum possible present marks.
  final int possibleTotal;

  double get percentage =>
      possibleTotal == 0 ? 0 : presentTotal / possibleTotal * 100;
}

/// One student's attendance across every Sunday in a [MonthlyReport].
class StudentMonthlyStat {
  const StudentMonthlyStat({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.presentCount,
    required this.totalSundays,
  });

  final String studentId;
  final String studentName;
  final String className;
  final int presentCount;
  final int totalSundays;

  double get percentage =>
      totalSundays == 0 ? 0 : presentCount / totalSundays * 100;
}

/// The full attendance picture for a calendar month, calculated using
/// only the Sundays that fall within it.
class MonthlyReport {
  const MonthlyReport({
    required this.year,
    required this.month,
    required this.sundays,
    required this.classStats,
    required this.studentStats,
  });

  final int year;
  final int month;
  final List<DateTime> sundays;
  final List<ClassMonthlyStat> classStats;
  final List<StudentMonthlyStat> studentStats;

  ClassMonthlyStat? get bestClass =>
      classStats.isEmpty ? null : classStats.first;

  ClassMonthlyStat? get lowestClass =>
      classStats.isEmpty ? null : classStats.last;

  List<StudentMonthlyStat> topStudents({int count = 5}) =>
      studentStats.take(count).toList();
}

/// One past session's outcome for a single student, used to render
/// [StudentReportSummary.history].
class StudentAttendanceHistoryEntry {
  const StudentAttendanceHistoryEntry({
    required this.date,
    required this.status,
    required this.className,
  });

  final DateTime date;
  final String status;
  final String className;
}

/// The attendance summary shown on a Student Details page.
class StudentReportSummary {
  const StudentReportSummary({
    required this.thisMonthPercentage,
    required this.totalPresents,
    required this.totalAbsents,
    required this.history,
  });

  final double thisMonthPercentage;
  final int totalPresents;
  final int totalAbsents;

  /// Most recent first.
  final List<StudentAttendanceHistoryEntry> history;
}

/// One Sunday's attendance percentage for a class, a single point in a
/// [ClassReportSummary.trend].
class ClassTrendPoint {
  const ClassTrendPoint({required this.date, required this.percentage});

  final DateTime date;
  final double percentage;
}

/// The attendance summary shown for a single class in the Class
/// Attendance Report.
class ClassReportSummary {
  const ClassReportSummary({
    required this.className,
    required this.studentCount,
    required this.averageMonthlyPercentage,
    required this.trend,
  });

  final String className;
  final int studentCount;
  final double averageMonthlyPercentage;

  /// Oldest first, most recent last — last few Sundays with data.
  final List<ClassTrendPoint> trend;
}
