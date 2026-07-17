import 'package:flutter/material.dart';

import '../../models/main_class.dart';
import '../../models/report_models.dart';
import '../../models/student.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/class_repository.dart';
import '../../repositories/reports_repository.dart';
import '../../repositories/student_repository.dart';
import 'report_widgets.dart';

class _ClassReportRow {
  const _ClassReportRow({
    required this.className,
    required this.studentCount,
    required this.averageMonthlyPercentage,
    required this.trend,
  });

  final String className;
  final int studentCount;
  final double averageMonthlyPercentage;
  final List<ClassTrendPoint> trend;
}

/// "For each class: student count, average monthly attendance, and
/// attendance trend for the last few Sundays."
class ClassAttendanceReportView extends StatefulWidget {
  const ClassAttendanceReportView({super.key});

  @override
  State<ClassAttendanceReportView> createState() =>
      _ClassAttendanceReportViewState();
}

class _ClassAttendanceReportViewState
    extends State<ClassAttendanceReportView> {
  final _classRepository = ClassRepository();
  final _studentRepository = StudentRepository();
  final _attendanceRepository = AttendanceRepository();
  final _reportsRepository = ReportsRepository();
  late Future<List<_ClassReportRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_ClassReportRow>> _load() async {
    final now = DateTime.now();
    final results = await Future.wait([
      _classRepository.getMainClasses(),
      _studentRepository.getStudents(),
      _reportsRepository.getMonthlyReport(now.year, now.month),
    ]);
    final mainClasses = results[0] as List<MainClass>;
    final allStudents = results[1] as List<Student>;
    final monthly = results[2] as MonthlyReport;

    final divisions = mainClasses
        .expand((mainClass) => mainClass.displayClassNames)
        .toList();

    final percentageByClass = {
      for (final stat in monthly.classStats) stat.className: stat.percentage,
    };

    final sessionsPerClass = await Future.wait(
      divisions.map(_attendanceRepository.getSessionsForClass),
    );

    final rows = <_ClassReportRow>[];
    for (var i = 0; i < divisions.length; i++) {
      final className = divisions[i];
      final classStudents = allStudents
          .where((student) => student.assignedClass == className)
          .toList();

      final sortedSessions = [...sessionsPerClass[i]]
        ..sort((a, b) => b.date.compareTo(a.date));
      final recentSessions = sortedSessions.take(6).toList().reversed.toList();
      final trend = recentSessions.map((session) {
        final total = classStudents.length;
        final present = classStudents
            .where((student) => session.statusFor(student.id) == 'Present')
            .length;
        return ClassTrendPoint(
          date: session.date,
          percentage: total == 0 ? 0 : present / total * 100,
        );
      }).toList();

      rows.add(
        _ClassReportRow(
          className: className,
          studentCount: classStudents.length,
          averageMonthlyPercentage: percentageByClass[className] ?? 0,
          trend: trend,
        ),
      );
    }
    return rows;
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await _future;
      },
      child: FutureBuilder<List<_ClassReportRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ReportLoadingState();
          }
          if (snapshot.hasError) {
            return ListView(
              children: [
                ReportErrorState(error: snapshot.error, onRetry: _reload),
              ],
            );
          }
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return const ReportEmptyState(
              message: 'No classes yet — add one to get started.',
              icon: Icons.class_outlined,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [for (final row in rows) _ClassReportCard(row: row)],
          );
        },
      ),
    );
  }
}

class _ClassReportCard extends StatelessWidget {
  const _ClassReportCard({required this.row});

  final _ClassReportRow row;

  @override
  Widget build(BuildContext context) {
    final color = percentageColor(row.averageMonthlyPercentage);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.class_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.className,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    Text(
                      '${row.studentCount} student${row.studentCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${row.averageMonthlyPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Last few Sundays',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          MiniTrendChart(
            points: row.trend.map((point) => point.percentage).toList(),
            labelFor: (index) => '${row.trend[index].date.day}/${row.trend[index].date.month}',
          ),
        ],
      ),
    );
  }
}
