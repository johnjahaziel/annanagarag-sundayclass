import 'package:flutter/material.dart';

import '../../models/report_models.dart';
import '../../repositories/reports_repository.dart';
import 'report_widgets.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "For a selected month, calculate attendance using only the Sundays in
/// that month" — class-wise %, student %, best/lowest class, top
/// students.
class MonthlyReportView extends StatefulWidget {
  const MonthlyReportView({super.key});

  @override
  State<MonthlyReportView> createState() => _MonthlyReportViewState();
}

class _MonthlyReportViewState extends State<MonthlyReportView> {
  final _repository = ReportsRepository();
  late int _year;
  late int _month;
  String? _selectedService;
  late Future<MonthlyReport> _future;

  static const _accentColor = Color(0xFF7E57C2);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _future = _repository.getMonthlyReport(
      _year,
      _month,
      service: _selectedService,
    );
  }

  void _reload() {
    setState(() {
      _future = _repository.getMonthlyReport(
        _year,
        _month,
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

  void _shiftMonth(int delta) {
    setState(() {
      var newMonth = _month + delta;
      var newYear = _year;
      if (newMonth < 1) {
        newMonth = 12;
        newYear--;
      } else if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      }
      _month = newMonth;
      _year = newYear;
    });
    _reload();
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
          _buildMonthSelector(),
          const SizedBox(height: 12),
          ServiceFilterChips(
            selected: _selectedService,
            onChanged: _onServiceChanged,
            color: _accentColor,
          ),
          const SizedBox(height: 16),
          FutureBuilder<MonthlyReport>(
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
              if (report.classStats.isEmpty) {
                return const ReportEmptyState(
                  message:
                      'No students found yet — add students to see monthly attendance.',
                  icon: Icons.calendar_month_outlined,
                );
              }
              return Column(
                children: [
                  _buildHighlights(report),
                  const SizedBox(height: 24),
                  _buildClassWise(report),
                  const SizedBox(height: 24),
                  _buildTopStudents(report),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _shiftMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded, color: _accentColor),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${_monthNames[_month - 1]} $_year',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _shiftMonth(1),
            icon: const Icon(Icons.chevron_right_rounded, color: _accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights(MonthlyReport report) {
    final best = report.bestClass;
    final lowest = report.lowestClass;
    return Row(
      children: [
        Expanded(
          child: _HighlightCard(
            icon: Icons.emoji_events_rounded,
            label: 'Best Attendance',
            title: best?.className ?? '—',
            value: best == null ? '—' : '${best.percentage.toStringAsFixed(0)}%',
            color: const Color(0xFF26A69A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HighlightCard(
            icon: Icons.trending_down_rounded,
            label: 'Needs Attention',
            title: lowest?.className ?? '—',
            value: lowest == null
                ? '—'
                : '${lowest.percentage.toStringAsFixed(0)}%',
            color: const Color(0xFFEF6C00),
          ),
        ),
      ],
    );
  }

  Widget _buildClassWise(MonthlyReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Class-wise Attendance'),
        const SizedBox(height: 4),
        Text(
          '${report.sundays.length} Sunday${report.sundays.length == 1 ? '' : 's'} this month',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        for (final stat in report.classStats)
          PercentageBar(
            title: stat.className,
            subtitle: '${stat.presentTotal}/${stat.possibleTotal} present marks',
            percentage: stat.percentage,
          ),
      ],
    );
  }

  Widget _buildTopStudents(MonthlyReport report) {
    final topStudents = report.topStudents();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Top Attending Students'),
        const SizedBox(height: 10),
        for (final stat in topStudents)
          PercentageBar(
            title: stat.studentName,
            subtitle: '${stat.className} • ${stat.presentCount}/${stat.totalSundays} Sundays',
            percentage: stat.percentage,
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E3A5F),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E3A5F),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
