import 'package:flutter/material.dart';

import '../../models/report_models.dart';
import '../../repositories/reports_repository.dart';
import 'report_widgets.dart';

/// "For a selected Sunday, show total/present/absent/percentage,
/// class-wise attendance, and student-wise attendance."
class WeeklyReportView extends StatefulWidget {
  const WeeklyReportView({super.key});

  @override
  State<WeeklyReportView> createState() => _WeeklyReportViewState();
}

class _WeeklyReportViewState extends State<WeeklyReportView> {
  final _repository = ReportsRepository();
  late DateTime _selectedSunday;
  String? _selectedService;
  late Future<WeeklyReport> _future;

  static const _accentColor = Color(0xFF00ACC1);

  @override
  void initState() {
    super.initState();
    _selectedSunday = _mostRecentSunday();
    _future = _repository.getWeeklyReport(
      _selectedSunday,
      service: _selectedService,
    );
  }

  DateTime _mostRecentSunday() {
    final now = DateTime.now();
    final diff = (now.weekday - DateTime.sunday) % 7;
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: diff));
  }

  void _reload() {
    setState(() {
      _future = _repository.getWeeklyReport(
        _selectedSunday,
        service: _selectedService,
      );
    });
  }

  void _onServiceChanged(String? service) {
    setState(() {
      _selectedService = service;
    });
    _reload();
  }

  Future<void> _pickSunday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedSunday,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      selectableDayPredicate: (date) => date.weekday == DateTime.sunday,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _accentColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedSunday = picked;
      });
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await _future;
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildDateSelector(),
          const SizedBox(height: 12),
          ServiceFilterChips(
            selected: _selectedService,
            onChanged: _onServiceChanged,
            color: _accentColor,
          ),
          const SizedBox(height: 16),
          FutureBuilder<WeeklyReport>(
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
              final report = snapshot.data!;
              if (report.totalStudents == 0) {
                return const ReportEmptyState(
                  message:
                      'No students found yet — add students to see weekly attendance.',
                  icon: Icons.groups_outlined,
                );
              }
              return Column(
                children: [
                  _buildSummary(report),
                  const SizedBox(height: 24),
                  _buildClassWise(report),
                  const SizedBox(height: 24),
                  _buildStudentWise(report),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _pickSunday,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: _accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_selectedSunday.day}/${_selectedSunday.month}/${_selectedSunday.year} (Sunday)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: _accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(WeeklyReport report) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        ReportStatCard(
          label: 'Total Students',
          value: '${report.totalStudents}',
          icon: Icons.groups_rounded,
          color: const Color(0xFF7E57C2),
        ),
        ReportStatCard(
          label: 'Attendance',
          value: '${report.attendancePercentage.toStringAsFixed(0)}%',
          icon: Icons.insights_rounded,
          color: percentageColor(report.attendancePercentage),
        ),
        ReportStatCard(
          label: 'Present',
          value: '${report.presentCount}',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF26A69A),
        ),
        ReportStatCard(
          label: 'Absent',
          value: '${report.absentCount}',
          icon: Icons.cancel_rounded,
          color: const Color(0xFFEF6C00),
        ),
      ],
    );
  }

  Widget _buildClassWise(WeeklyReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.class_rounded,
          title: 'Class-wise Attendance',
        ),
        const SizedBox(height: 10),
        for (final summary in report.classSummaries)
          PercentageBar(
            title: summary.className,
            subtitle: '${summary.present}/${summary.total} present',
            percentage: summary.percentage,
          ),
      ],
    );
  }

  Widget _buildStudentWise(WeeklyReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.checklist_rounded,
          title: 'Student-wise Attendance',
        ),
        const SizedBox(height: 10),
        for (final entry in report.studentEntries)
          _StudentStatusRow(entry: entry),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00ACC1).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF00ACC1)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
      ],
    );
  }
}

class _StudentStatusRow extends StatelessWidget {
  const _StudentStatusRow({required this.entry});

  final StudentAttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final isPresent = entry.status == 'Present';
    final color = isPresent
        ? const Color(0xFF26A69A)
        : const Color(0xFFEF6C00);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A5F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.className,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPresent ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
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
          ),
        ],
      ),
    );
  }
}
