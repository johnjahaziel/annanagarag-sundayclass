import 'package:attendance/controllers/login_controller.dart';
import 'package:attendance/models/admin.dart';
import 'package:attendance/models/teacher.dart';
import 'package:attendance/repositories/admin_repository.dart';
import 'package:attendance/repositories/teacher_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for [AdminRepository] without touching real Firestore.
class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository({this.admin});

  final Admin? admin;

  @override
  Future<Admin?> getByUsername(String username) async {
    final normalized = AdminRepository.normalizeUsername(username);
    if (admin != null && admin!.username == normalized) return admin;
    return null;
  }
}

/// Stands in for [TeacherRepository] without touching real Firestore.
class _FakeTeacherRepository extends TeacherRepository {
  _FakeTeacherRepository({this.teacher});

  final Teacher? teacher;

  @override
  Future<Teacher?> getByUsername(String username) async {
    final normalized = TeacherRepository.normalizeUsername(username);
    if (teacher != null && teacher!.username == normalized) return teacher;
    return null;
  }
}

const _admin = Admin(
  id: 'admin-doc-1',
  adminId: 'ADM001',
  name: 'Ada Admin',
  username: 'adaadmin',
  phone: '1234567890',
  gender: 'Female',
  role: 'Admin',
  isActive: true,
);

const _teacher = Teacher(
  id: 'teacher-doc-1',
  teacherId: 'TCH001',
  name: 'Tom Teacher',
  username: 'tomteacher',
  gender: 'Male',
  phone: '0987654321',
  assignedClass: 'Beginner 1',
  role: 'Teacher',
  status: 'Active',
  isActive: true,
  service: 'Service 1',
);

void main() {
  setUp(() {
    // login() persists a session via SharedPreferences on success.
    SharedPreferences.setMockInitialValues({});
  });

  group('LoginController', () {
    test('starts with an empty username field', () {
      final controller = LoginController(
        adminRepository: _FakeAdminRepository(),
        teacherRepository: _FakeTeacherRepository(),
      );
      expect(controller.usernameController.text, isEmpty);
    });

    test('throws InvalidUsernameException when nobody matches', () async {
      final controller = LoginController(
        adminRepository: _FakeAdminRepository(),
        teacherRepository: _FakeTeacherRepository(),
      );
      controller.usernameController.text = 'nobody';

      expect(controller.login(), throwsA(isA<InvalidUsernameException>()));
    });

    test('logs in a matching admin', () async {
      final controller = LoginController(
        adminRepository: _FakeAdminRepository(admin: _admin),
        teacherRepository: _FakeTeacherRepository(),
      );
      controller.usernameController.text = 'AdaAdmin';

      final session = await controller.login();

      expect(session.role, 'Admin');
      expect(session.username, 'adaadmin');
      expect(session.docId, 'admin-doc-1');
    });

    test('falls back to a matching teacher when no admin matches', () async {
      final controller = LoginController(
        adminRepository: _FakeAdminRepository(),
        teacherRepository: _FakeTeacherRepository(teacher: _teacher),
      );
      controller.usernameController.text = 'tomteacher';

      final session = await controller.login();

      expect(session.role, 'Teacher');
      expect(session.docId, 'teacher-doc-1');
    });
  });
}
