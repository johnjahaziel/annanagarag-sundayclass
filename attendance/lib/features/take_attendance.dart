import 'package:flutter/material.dart';

import '../models/attendance_session.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../repositories/attendance_repository.dart';

/// Lets a teacher/admin mark (or edit) today's attendance for every
/// student in a class. Pops with `true` if attendance was saved, so the
/// caller knows to refresh.
class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({
    super.key,
    required this.className,
    required this.students,
    required this.teacher,
    this.existingSession,
  });

  final String className;
  final List<Student> students;
  final Teacher? teacher;
  final AttendanceSession? existingSession;

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final _repository = AttendanceRepository();
  late final Map<String, String> _statuses;
  bool _isSaving = false;

  static const _accentColor = Color(0xFF00ACC1);
  static const _presentColor = Color(0xFF26A69A);
  static const _absentColor = Color(0xFFEF6C00);

  @override
  void initState() {
    super.initState();
    // Every student is always Present or Absent — default to Absent so a
    // teacher only has to tap the ones who showed up, rather than mark
    // every student individually.
    _statuses = {
      for (final student in widget.students)
        student.id: widget.existingSession?.statusFor(student.id) ?? 'Absent',
    };
  }

  void _setStatus(String studentId, String status) {
    setState(() {
      _statuses[studentId] = status;
    });
  }

  void _markAllPresent() {
    setState(() {
      for (final student in widget.students) {
        _statuses[student.id] = 'Present';
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final records = <String, AttendanceRecord>{
        for (final student in widget.students)
          student.id: AttendanceRecord(
            studentId: student.id,
            studentName: student.name,
            status: _statuses[student.id]!,
            markedAt: now,
          ),
      };
      await _repository.saveSession(
        className: widget.className,
        teacherId: widget.teacher?.id,
        teacherName: widget.teacher?.name,
        date: now,
        records: records,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save attendance: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final presentCount = _statuses.values.where((s) => s == 'Present').length;
    final totalCount = widget.students.length;
    final absentCount = totalCount - presentCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: _accentColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Take Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.className,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _markAllPresent,
            icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
            label: const Text(
              'Mark all Present',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.event_available, size: 18, color: _accentColor),
                const SizedBox(width: 8),
                Text(
                  '${today.day}/${today.month}/${today.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const Spacer(),
                Icon(Icons.check_circle, size: 16, color: _presentColor),
                const SizedBox(width: 4),
                Text(
                  '$presentCount',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _presentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.cancel, size: 16, color: _absentColor),
                const SizedBox(width: 4),
                Text(
                  '$absentCount',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _absentColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.students.isEmpty
                ? const Center(
                    child: Text(
                      'No students in this class yet.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: widget.students.length,
                    itemBuilder: (context, index) {
                      final student = widget.students[index];
                      return _AttendanceRow(
                        student: student,
                        status: _statuses[student.id]!,
                        presentColor: _presentColor,
                        absentColor: _absentColor,
                        onSelect: (status) => _setStatus(student.id, status),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.student,
    required this.status,
    required this.presentColor,
    required this.absentColor,
    required this.onSelect,
  });

  final Student student;
  final String status;
  final Color presentColor;
  final Color absentColor;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final photoUrl = student.photoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF3E5F5),
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                            Icons.person,
                            color: Color(0xFF7E57C2),
                          ),
                    )
                  : const Icon(Icons.person, color: Color(0xFF7E57C2)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              student.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A5F),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'Present',
            icon: Icons.check_circle,
            color: presentColor,
            selected: status == 'Present',
            onTap: () => onSelect('Present'),
          ),
          const SizedBox(width: 6),
          _ToggleChip(
            label: 'Absent',
            icon: Icons.cancel,
            color: absentColor,
            selected: status == 'Absent',
            onTap: () => onSelect('Absent'),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : color,
        ),
      ),
    );
  }
}
