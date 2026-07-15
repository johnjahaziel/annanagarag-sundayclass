import 'package:flutter/material.dart';

import '../models/student.dart';
import 'detail_widgets.dart';

/// Shows every stored detail about a single student.
class StudentDetail extends StatelessWidget {
  const StudentDetail({super.key, required this.student});

  final Student student;

  static const _accentColor = Color(0xFF26A69A);

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}
