import 'package:flutter/material.dart';

import '../repositories/student_repository.dart';
import 'people_list_screen.dart';
import 'student_detail.dart';

/// Shows every student — name, photo, and assigned class — reached from
/// the Homepage's "Students" stat card.
class StudentsList extends StatelessWidget {
  const StudentsList({super.key});

  @override
  Widget build(BuildContext context) {
    return PeopleListScreen(
      title: 'Students',
      accentColor: const Color(0xFF26A69A),
      icon: Icons.groups,
      emptyMessage: 'No students yet — add one to get started.',
      loader: () async {
        final students = await StudentRepository().getStudents();
        return students
            .map(
              (student) => PersonListItem(
                name: student.name,
                assignedClass: student.assignedClass,
                photoUrl: student.photoUrl,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentDetail(student: student),
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
