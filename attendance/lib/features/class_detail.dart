import 'package:flutter/material.dart';

import '../models/student.dart';
import '../models/teacher.dart';
import '../repositories/student_repository.dart';
import '../repositories/teacher_repository.dart';
import 'student_detail.dart';
import 'teacher_detail.dart';

class _ClassDetailData {
  const _ClassDetailData({required this.teacher, required this.students});

  final Teacher? teacher;
  final List<Student> students;
}

class ClassDetail extends StatefulWidget {
  final String className;

  const ClassDetail({super.key, required this.className});

  @override
  State<ClassDetail> createState() => _ClassDetailState();
}

class _ClassDetailState extends State<ClassDetail> {
  final _teacherRepository = TeacherRepository();
  final _studentRepository = StudentRepository();
  late Future<_ClassDetailData> _future;

  static const _gradientColors = [Color(0xFF7E57C2), Color(0xFF5E35B1)];
  static const _accentColor = Color(0xFF5E35B1);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ClassDetailData> _load() async {
    final results = await Future.wait([
      _teacherRepository.getTeacherForClass(widget.className),
      _studentRepository.getStudentsForClass(widget.className),
    ]);
    return _ClassDetailData(
      teacher: results[0] as Teacher?,
      students: results[1] as List<Student>,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: FutureBuilder<_ClassDetailData>(
        future: _future,
        builder: (context, snapshot) {
          return SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, snapshot),
                Expanded(child: _buildBody(context, snapshot)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncSnapshot<_ClassDetailData> snapshot,
  ) {
    final isLoaded = snapshot.connectionState == ConnectionState.done;
    final studentCount = snapshot.data?.students.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            widget.className,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.groups, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                isLoaded
                    ? '${studentCount ?? 0} student${studentCount == 1 ? '' : 's'}'
                    : 'Loading…',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<_ClassDetailData> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _refresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final teacher = snapshot.data!.teacher;
    final students = snapshot.data!.students;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: _TeacherCard(
              teacher: teacher,
              onTap: teacher != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TeacherDetail(teacher: teacher),
                        ),
                      );
                    }
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_2_rounded,
                    size: 16,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Students',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ],
            ),
          ),
          if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.school_outlined, size: 48, color: Colors.black26),
                  SizedBox(height: 12),
                  Text(
                    'No students in this class yet.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            )
          else
            for (final student in students)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _StudentCard(
                  student: student,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentDetail(student: student),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}

/// Big card showing the assigned teacher's photo, name, and phone number.
class _TeacherCard extends StatelessWidget {
  final Teacher? teacher;
  final VoidCallback? onTap;

  const _TeacherCard({required this.teacher, required this.onTap});

  static const _accentColor = Color(0xFF5E35B1);

  @override
  Widget build(BuildContext context) {
    final teacher = this.teacher;
    final photoUrl = teacher?.photoUrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.3),
                      width: 3,
                    ),
                    color: _accentColor.withValues(alpha: 0.1),
                  ),
                  child: ClipOval(
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person,
                                  size: 34,
                                  color: _accentColor,
                                ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 34,
                            color: _accentColor,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Class Teacher',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        teacher?.name ?? 'No Teacher Assigned',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: teacher != null
                              ? const Color(0xFF1E3A5F)
                              : Colors.black45,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (teacher != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 14,
                              color: _accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              teacher.phone,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _accentColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (teacher != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black26,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width rectangular student card: photo, name, and status.
///
/// There's no daily attendance tracking implemented yet, so "status" here
/// reflects the student's own active/inactive field rather than a real
/// per-day attendance record.
class _StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const _StudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = student.isActive
        ? const Color(0xFF26A69A)
        : const Color(0xFFEF6C00);
    final statusIcon = student.isActive ? Icons.check_circle : Icons.cancel;
    final statusLabel = student.isActive ? 'Active' : 'Inactive';
    final photoUrl = student.photoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: ClipOval(
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(
                                  Icons.person,
                                  color: statusColor,
                                  size: 28,
                                ),
                          )
                        : Icon(Icons.person, color: statusColor, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A5F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
