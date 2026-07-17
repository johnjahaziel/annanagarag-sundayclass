import 'package:flutter/material.dart';

import '../models/attendance_session.dart';
import '../models/service.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/student_repository.dart';
import '../repositories/teacher_repository.dart';
import 'student_detail.dart';
import 'take_attendance.dart';
import 'teacher_detail.dart';

class _ClassDetailData {
  const _ClassDetailData({
    required this.service1Teacher,
    required this.service2Teacher,
    required this.service1Students,
    required this.service2Students,
    required this.service1Session,
    required this.service2Session,
  });

  final Teacher? service1Teacher;
  final Teacher? service2Teacher;
  final List<Student> service1Students;
  final List<Student> service2Students;

  /// Each service has its own attendance session for today — Service 1
  /// and Service 2 are always independent documents (see
  /// [AttendanceRepository.sessionId]), so marking one never touches the
  /// other.
  final AttendanceSession? service1Session;
  final AttendanceSession? service2Session;

  int get totalStudentCount =>
      service1Students.length + service2Students.length;
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
  final _attendanceRepository = AttendanceRepository();
  late Future<_ClassDetailData> _future;

  static const _gradientColors = [Color(0xFF7E57C2), Color(0xFFAB47BC)];
  static const _accentColor = Color(0xFF5E35B1);
  static const _presentColor = Color(0xFF26A69A);
  static const _absentColor = Color(0xFFEF6C00);
  static const _takeAttendanceColor = Color(0xFF26C6DA);
  static const _service1Color = Color(0xFF29B6F6);
  static const _service2Color = Color(0xFFAB47BC);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ClassDetailData> _load() async {
    final today = DateTime.now();
    final results = await Future.wait([
      _teacherRepository.getTeacherForClassAndService(
        assignedClass: widget.className,
        service: Service.one,
      ),
      _teacherRepository.getTeacherForClassAndService(
        assignedClass: widget.className,
        service: Service.two,
      ),
      _studentRepository.getStudentsForClassAndService(
        className: widget.className,
        service: Service.one,
      ),
      _studentRepository.getStudentsForClassAndService(
        className: widget.className,
        service: Service.two,
      ),
      _attendanceRepository.getSessionForDate(
        className: widget.className,
        date: today,
        service: Service.one,
      ),
      _attendanceRepository.getSessionForDate(
        className: widget.className,
        date: today,
        service: Service.two,
      ),
    ]);
    return _ClassDetailData(
      service1Teacher: results[0] as Teacher?,
      service2Teacher: results[1] as Teacher?,
      service1Students: results[2] as List<Student>,
      service2Students: results[3] as List<Student>,
      service1Session: results[4] as AttendanceSession?,
      service2Session: results[5] as AttendanceSession?,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _openTakeAttendance({
    required String service,
    required Teacher? teacher,
    required List<Student> students,
    required AttendanceSession? session,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TakeAttendanceScreen(
          className: widget.className,
          service: service,
          students: students,
          teacher: teacher,
          existingSession: session,
        ),
      ),
    );
    if (result == true) {
      await _refresh();
    }
  }

  void _openTeacherDetail(Teacher teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherDetail(teacher: teacher)),
    );
  }

  void _openStudentDetail(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentDetail(student: student)),
    );
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
    final studentCount = snapshot.data?.totalStudentCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
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
                    color: Colors.white.withValues(alpha: 0.18),
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
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.className,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.groups, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                isLoaded
                    ? '${studentCount ?? 0} student${studentCount == 1 ? '' : 's'} · 2 services'
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

    final data = snapshot.data!;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: _gradientColors),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF1E3A5F),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(
                    icon: Icon(Icons.looks_one_rounded, color: _service1Color),
                    text: Service.one,
                  ),
                  Tab(
                    icon: Icon(Icons.looks_two_rounded, color: _service2Color),
                    text: Service.two,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ServiceSection(
                  accentColor: _service1Color,
                  presentColor: _presentColor,
                  absentColor: _absentColor,
                  takeAttendanceColor: _takeAttendanceColor,
                  teacher: data.service1Teacher,
                  students: data.service1Students,
                  session: data.service1Session,
                  onRefresh: _refresh,
                  onTeacherTap: _openTeacherDetail,
                  onStudentTap: _openStudentDetail,
                  onTakeAttendance: () => _openTakeAttendance(
                    service: Service.one,
                    teacher: data.service1Teacher,
                    students: data.service1Students,
                    session: data.service1Session,
                  ),
                ),
                _ServiceSection(
                  accentColor: _service2Color,
                  presentColor: _presentColor,
                  absentColor: _absentColor,
                  takeAttendanceColor: _takeAttendanceColor,
                  teacher: data.service2Teacher,
                  students: data.service2Students,
                  session: data.service2Session,
                  onRefresh: _refresh,
                  onTeacherTap: _openTeacherDetail,
                  onStudentTap: _openStudentDetail,
                  onTakeAttendance: () => _openTakeAttendance(
                    service: Service.two,
                    teacher: data.service2Teacher,
                    students: data.service2Students,
                    session: data.service2Session,
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

/// One service's tab body: that service's teacher card, today's
/// present/absent stats, a Take Attendance button scoped to just this
/// service, and that service's students — each pulled to refresh
/// independently.
class _ServiceSection extends StatelessWidget {
  const _ServiceSection({
    required this.accentColor,
    required this.presentColor,
    required this.absentColor,
    required this.takeAttendanceColor,
    required this.teacher,
    required this.students,
    required this.session,
    required this.onRefresh,
    required this.onTeacherTap,
    required this.onStudentTap,
    required this.onTakeAttendance,
  });

  final Color accentColor;
  final Color presentColor;
  final Color absentColor;
  final Color takeAttendanceColor;
  final Teacher? teacher;
  final List<Student> students;
  final AttendanceSession? session;
  final Future<void> Function() onRefresh;
  final ValueChanged<Teacher> onTeacherTap;
  final ValueChanged<Student> onStudentTap;
  final VoidCallback onTakeAttendance;

  @override
  Widget build(BuildContext context) {
    final teacher = this.teacher;
    final presentCount = session?.presentCount ?? 0;
    // Every student is either Present or Absent — a student with no
    // recorded status yet (including when no session exists at all) is
    // simply treated as Absent, so there's no third "not marked" bucket.
    final absentCount = students.length - presentCount;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          _TeacherCard(
            teacher: teacher,
            accentColor: accentColor,
            onTap: teacher != null ? () => onTeacherTap(teacher) : null,
          ),
          const SizedBox(height: 16),
          _StatsRow(
            total: students.length,
            present: presentCount,
            absent: absentCount,
            presentColor: presentColor,
            absentColor: absentColor,
          ),
          const SizedBox(height: 16),
          _TakeAttendanceButton(
            color: takeAttendanceColor,
            hasSession: session != null,
            totalCount: students.length,
            presentCount: presentCount,
            absentCount: absentCount,
            onTap: students.isEmpty ? null : onTakeAttendance,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_2_rounded,
                  size: 16,
                  color: accentColor,
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
          const SizedBox(height: 12),
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_people_rounded,
                    size: 48,
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No students in this service yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            )
          else
            for (var index = 0; index < students.length; index++)
              _AnimatedEntry(
                index: index,
                child: _StudentCard(
                  student: students[index],
                  status: session?.statusFor(students[index].id) ?? 'Absent',
                  onTap: () => onStudentTap(students[index]),
                ),
              ),
        ],
      ),
    );
  }
}

/// Fades and slides a child in, staggered by [index], for a lightweight
/// "list coming to life" feel on first load.
class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index * 40).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Big card showing a service's assigned teacher's photo, name, and phone
/// number — or a friendly "No Teacher Assigned" empty state.
class _TeacherCard extends StatelessWidget {
  final Teacher? teacher;
  final Color accentColor;
  final VoidCallback? onTap;

  const _TeacherCard({
    required this.teacher,
    required this.accentColor,
    required this.onTap,
  });

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
            color: accentColor.withValues(alpha: 0.1),
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
                      color: accentColor.withValues(alpha: 0.3),
                      width: 3,
                    ),
                    color: accentColor.withValues(alpha: 0.1),
                  ),
                  child: ClipOval(
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: 34,
                              color: accentColor,
                            ),
                          )
                        : Icon(Icons.person, size: 34, color: accentColor),
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
                            Icon(Icons.phone, size: 14, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              teacher.phone,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
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

/// Total / Present / Absent stat chips for today.
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.total,
    required this.present,
    required this.absent,
    required this.presentColor,
    required this.absentColor,
  });

  final int total;
  final int present;
  final int absent;
  final Color presentColor;
  final Color absentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Students',
            value: '$total',
            icon: Icons.groups_rounded,
            color: const Color(0xFF7E57C2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Present',
            value: '$present',
            icon: Icons.check_circle_rounded,
            color: presentColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Absent',
            value: '$absent',
            icon: Icons.cancel_rounded,
            color: absentColor,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Prominent CTA that either invites marking today's attendance, or — once
/// a session exists for today — summarizes it and offers to edit it.
class _TakeAttendanceButton extends StatelessWidget {
  const _TakeAttendanceButton({
    required this.color,
    required this.hasSession,
    required this.totalCount,
    required this.presentCount,
    required this.absentCount,
    required this.onTap,
  });

  final Color color;
  final bool hasSession;
  final int totalCount;
  final int presentCount;
  final int absentCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasSession
                        ? Icons.fact_check_rounded
                        : Icons.checklist_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSession
                            ? 'Attendance Marked Today'
                            : 'Take Attendance',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasSession
                            ? '$presentCount present · $absentCount absent — tap to edit'
                            : 'Tap to mark today\'s attendance',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width rectangular student card: photo, name, and today's
/// attendance status. Every student is either Present or Absent — a
/// student with no recorded status yet is treated as Absent by default.
class _StudentCard extends StatelessWidget {
  final Student student;
  final String status;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = status == 'Present';
    final statusColor = isPresent
        ? const Color(0xFF26A69A)
        : const Color(0xFFEF6C00);
    final statusIcon = isPresent ? Icons.check_circle : Icons.cancel;
    final statusLabel = isPresent ? 'Present' : 'Absent';
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
