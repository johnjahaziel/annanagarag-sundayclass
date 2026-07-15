import 'package:flutter/material.dart';

import '../repositories/teacher_repository.dart';
import 'people_list_screen.dart';
import 'teacher_detail.dart';

/// Shows every teacher (role "Teacher") — name, photo, and assigned class —
/// reached from the Homepage's "Teachers" stat card.
class TeachersList extends StatelessWidget {
  const TeachersList({super.key});

  @override
  Widget build(BuildContext context) {
    return PeopleListScreen(
      title: 'Teachers',
      accentColor: const Color(0xFF7E57C2),
      icon: Icons.school,
      emptyMessage: 'No teachers yet — add one to get started.',
      loader: () async {
        final teachers = await TeacherRepository().getTeachers();
        return teachers
            .where((teacher) => teacher.role != 'Admin')
            .map(
              (teacher) => PersonListItem(
                name: teacher.name,
                assignedClass: teacher.assignedClass,
                photoUrl: teacher.photoUrl,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeacherDetail(teacher: teacher),
                    ),
                  );
                },
              ),
            )
            .toList();
      },
    );
  }
}
