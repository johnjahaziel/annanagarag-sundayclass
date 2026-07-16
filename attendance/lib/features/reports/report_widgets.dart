import 'package:flutter/material.dart';

/// Color-codes a percentage the same way everywhere in the Reports
/// module: healthy attendance is teal, borderline is amber, and low
/// attendance is orange/red — makes the numbers easy to read at a glance.
Color percentageColor(double percentage) {
  if (percentage >= 75) return const Color(0xFF26A69A);
  if (percentage >= 50) return const Color(0xFFFFA726);
  return const Color(0xFFEF5350);
}

/// A colorful stat tile — icon, big value, label — used for the
/// present/absent/total/percentage row at the top of a report.
class ReportStatCard extends StatelessWidget {
  const ReportStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

/// A labeled row with a linear progress bar and percentage — the main
/// "simple chart" used for class-wise and student-wise breakdowns.
class PercentageBar extends StatelessWidget {
  const PercentageBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.percentage,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final double percentage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = percentageColor(percentage);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1E3A5F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (percentage / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tiny bar chart for an attendance trend across a handful of dates —
/// no charting package needed for something this simple.
class MiniTrendChart extends StatelessWidget {
  const MiniTrendChart({
    super.key,
    required this.points,
    required this.labelFor,
  });

  final List<double> points;
  final String Function(int index) labelFor;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Not enough history yet for a trend.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      );
    }
    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < points.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${points[i].toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: percentageColor(points[i]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: (points[i] / 100 * 50).clamp(4, 50),
                        color: percentageColor(points[i]),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labelFor(i),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ReportLoadingState extends StatelessWidget {
  const ReportLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class ReportErrorState extends StatelessWidget {
  const ReportErrorState({super.key, required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            'Failed to load report: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class ReportEmptyState extends StatelessWidget {
  const ReportEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.insert_chart_outlined_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
