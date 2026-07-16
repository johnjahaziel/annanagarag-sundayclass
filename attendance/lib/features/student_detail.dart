import 'package:flutter/material.dart';

import '../models/report_models.dart';
import '../models/student.dart';
import '../repositories/reports_repository.dart';
import 'detail_widgets.dart';
import 'reports/report_widgets.dart';

/// Shows every stored detail about a single student, plus their
/// attendance summary and history.
class StudentDetail extends StatefulWidget {
  const StudentDetail({super.key, required this.student});

  final Student student;

  @override
  State<StudentDetail> createState() => _StudentDetailState();
}

class _StudentDetailState extends State<StudentDetail> {
  final _reportsRepository = ReportsRepository();
  late Future<StudentReportSummary> _future;

  static const _accentColor = Color(0xFF26A69A);

  @override
  void initState() {
    super.initState();
    _future = _reportsRepository.getStudentReport(widget.student);
  }

  void _reload() {
    setState(() {
      _future = _reportsRepository.getStudentReport(widget.student);
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final dob = student.dob;
    final createdAt = student.createdAt;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: _accentColor,
        elevation: 0,
        title: const Text(
          'Student Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DetailHeader(
              name: student.name,
              accentColor: _accentColor,
              photoUrl: student.photoUrl,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      StatusChip(isActive: student.isActive),
                    ],
                  ),
                  const Divider(height: 24),
                  DetailRow(
                    icon: Icons.wc,
                    label: 'Gender',
                    value: student.gender,
                    accentColor: _accentColor,
                  ),
                  DetailRow(
                    icon: Icons.cake,
                    label: 'Date of Birth',
                    value: '${dob.day}/${dob.month}/${dob.year}',
                    accentColor: _accentColor,
                  ),
                  DetailRow(
                    icon: Icons.people,
                    label: 'Parent Name',
                    value: student.parentName,
                    accentColor: _accentColor,
                  ),
                  DetailRow(
                    icon: Icons.phone,
                    label: 'Parent Phone',
                    value: student.parentPhone,
                    accentColor: _accentColor,
                  ),
                  DetailRow(
                    icon: Icons.class_,
                    label: 'Assigned Class',
                    value: student.assignedClass,
                    accentColor: _accentColor,
                  ),
                  if (createdAt != null)
                    DetailRow(
                      icon: Icons.event,
                      label: 'Registered On',
                      value:
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                      accentColor: _accentColor,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildAttendanceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 16,
                  color: _accentColor,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<StudentReportSummary>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const ReportLoadingState();
              }
              if (snapshot.hasError) {
                return ReportErrorState(
                  error: snapshot.error,
                  onRetry: _reload,
                );
              }
              final summary = snapshot.data!;
              if (summary.history.isEmpty) {
                return const ReportEmptyState(
                  message: 'No attendance recorded for this student yet.',
                  icon: Icons.event_busy_rounded,
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ReportStatCard(
                          label: "This Month",
                          value:
                              '${summary.thisMonthPercentage.toStringAsFixed(0)}%',
                          icon: Icons.calendar_month_rounded,
                          color: percentageColor(summary.thisMonthPercentage),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ReportStatCard(
                          label: 'Total Present',
                          value: '${summary.totalPresents}',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF26A69A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ReportStatCard(
                          label: 'Total Absent',
                          value: '${summary.totalAbsents}',
                          icon: Icons.cancel_rounded,
                          color: const Color(0xFFEF6C00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'History',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in summary.history)
                    _HistoryRow(entry: entry),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final StudentAttendanceHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isPresent = entry.status == 'Present';
    final color = isPresent
        ? const Color(0xFF26A69A)
        : const Color(0xFFEF6C00);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${entry.date.day}/${entry.date.month}/${entry.date.year}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E3A5F),
              ),
            ),
          ),
          Text(
            entry.status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
