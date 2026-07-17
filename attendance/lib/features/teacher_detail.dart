import 'package:flutter/material.dart';

import '../models/teacher.dart';
import 'detail_widgets.dart';

/// Shows every stored detail about a single teacher.
class TeacherDetail extends StatelessWidget {
  const TeacherDetail({super.key, required this.teacher});

  final Teacher teacher;

  static const _accentColor = Color(0xFF7E57C2);

  @override
  Widget build(BuildContext context) {
    final createdAt = teacher.createdAt;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: _accentColor,
        elevation: 0,
        title: const Text(
          'Teacher Details',
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
              name: teacher.name,
              accentColor: _accentColor,
              photoUrl: teacher.photoUrl,
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
                      StatusChip(isActive: teacher.isActive),
                    ],
                  ),
                  const Divider(height: 24),
                  DetailRow(
                    icon: Icons.alternate_email,
                    label: 'Username',
                    value: teacher.username,
                    accentColor: _accentColor,
                  ),
                  DetailRow(
                    icon: Icons.wc,
                    label: 'Gender',
                    value: teacher.gender,
                    accentColor: _accentColor,
                  ),
                  DetailRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: teacher.phone,
                    accentColor: _accentColor,
                  ),
                  DetailRow(
                    icon: Icons.class_,
                    label: 'Assigned Class',
                    value: teacher.assignedClass,
                    accentColor: _accentColor,
                  ),
                  DetailRow(
                    icon: Icons.church,
                    label: 'Service',
                    value: teacher.service,
                    accentColor: _accentColor,
                  ),
                  DetailRow(
                    icon: Icons.assignment_ind,
                    label: 'Role',
                    value: teacher.role,
                    accentColor: _accentColor,
                  ),
                  if (createdAt != null)
                    DetailRow(
                      icon: Icons.event,
                      label: 'Joined On',
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
