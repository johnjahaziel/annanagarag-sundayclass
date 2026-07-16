import 'package:flutter/material.dart';

import '../../models/report_models.dart';
import '../../models/student.dart';
import '../../repositories/reports_repository.dart';
import '../../repositories/student_repository.dart';
import '../student_detail.dart';
import 'report_widgets.dart';

/// Browses every student's current-month attendance percentage. Tapping
/// a student opens their full [StudentDetail] page, which has its own
/// attendance history section.
class StudentAttendanceReportView extends StatefulWidget {
  const StudentAttendanceReportView({super.key});

  @override
  State<StudentAttendanceReportView> createState() =>
      _StudentAttendanceReportViewState();
}

class _StudentAttendanceReportViewState
    extends State<StudentAttendanceReportView> {
  final _reportsRepository = ReportsRepository();
  final _studentRepository = StudentRepository();
  late Future<_StudentReportData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentReportData> _load() async {
    final now = DateTime.now();
    final results = await Future.wait([
      _studentRepository.getStudents(),
      _reportsRepository.getMonthlyReport(now.year, now.month),
    ]);
    return _StudentReportData(
      students: results[0] as List<Student>,
      monthly: results[1] as MonthlyReport,
    );
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
      child: FutureBuilder<_StudentReportData>(
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
          final data = snapshot.data!;
          if (data.students.isEmpty) {
            return const ReportEmptyState(
              message: 'No students yet — add one to get started.',
              icon: Icons.groups_outlined,
            );
          }

          final statsByStudentId = {
            for (final stat in data.monthly.studentStats) stat.studentId: stat,
          };

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'This month\'s attendance, per student',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 12),
              for (final student in data.students)
                PercentageBar(
                  title: student.name,
                  subtitle: student.assignedClass,
                  percentage:
                      statsByStudentId[student.id]?.percentage ?? 0,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StudentDetail(student: student),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StudentReportData {
  const _StudentReportData({required this.students, required this.monthly});

  final List<Student> students;
  final MonthlyReport monthly;
}
