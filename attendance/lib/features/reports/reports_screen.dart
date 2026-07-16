import 'package:flutter/material.dart';

import 'class_attendance_report_view.dart';
import 'monthly_report_view.dart';
import 'student_attendance_report_view.dart';
import 'weekly_report_view.dart';

/// The Reports hub — reached from the Homepage's Reports box. Holds all
/// four report sections as tabs so "Weekly Report"/"Monthly Report" on
/// the Homepage can jump straight to their tab, while Student/Class
/// reports stay one swipe away.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  static const _accentColor = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: _accentColor,
          elevation: 0,
          title: const Text(
            'Reports',
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
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.calendar_view_week_rounded), text: 'Weekly'),
              Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Monthly'),
              Tab(icon: Icon(Icons.emoji_people_rounded), text: 'Students'),
              Tab(icon: Icon(Icons.groups_rounded), text: 'Classes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WeeklyReportView(),
            MonthlyReportView(),
            StudentAttendanceReportView(),
            ClassAttendanceReportView(),
          ],
        ),
      ),
    );
  }
}
