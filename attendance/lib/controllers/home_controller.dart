import 'package:get/get.dart';

import '../models/admin.dart';
import '../models/main_class.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../repositories/admin_repository.dart';
import '../repositories/class_repository.dart';
import '../repositories/student_repository.dart';
import '../repositories/teacher_repository.dart';

/// Loads the data shown on the Homepage dashboard: the stat counts
/// (teachers, students, classes, admins) and the Class List panel.
class HomeController extends GetxController {
  HomeController({
    ClassRepository? classRepository,
    TeacherRepository? teacherRepository,
    StudentRepository? studentRepository,
    AdminRepository? adminRepository,
  }) : _classRepository = classRepository ?? ClassRepository(),
       _teacherRepository = teacherRepository ?? TeacherRepository(),
       _studentRepository = studentRepository ?? StudentRepository(),
       _adminRepository = adminRepository ?? AdminRepository();

  final ClassRepository _classRepository;
  final TeacherRepository _teacherRepository;
  final StudentRepository _studentRepository;
  final AdminRepository _adminRepository;

  final mainClasses = <MainClass>[].obs;
  final teachers = <Teacher>[].obs;
  final students = <Student>[].obs;
  final admins = <Admin>[].obs;

  final isLoading = false.obs;
  final loadError = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Refreshes the dashboard if it's currently live (i.e. this controller
  /// is registered with GetX) — called by the Add Teacher/Student/Class/
  /// Admin controllers right after a successful save, so the Homepage's
  /// stat counts and Class List panel pick up the new record immediately
  /// on return, without restarting the app or a manual pull-to-refresh.
  /// A no-op if the Homepage isn't currently on screen.
  static void refreshIfRegistered() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().loadDashboardData();
    }
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      final results = await Future.wait([
        _classRepository.getMainClasses(),
        _teacherRepository.getTeachers(),
        _studentRepository.getStudents(),
        _adminRepository.getAdmins(),
      ]);
      mainClasses.value = results[0] as List<MainClass>;
      teachers.value = results[1] as List<Teacher>;
      students.value = results[2] as List<Student>;
      admins.value = results[3] as List<Admin>;
    } catch (e) {
      loadError.value = 'Failed to load dashboard data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// All class names across every main class, in display order — a main
  /// class's divisions if it has any, otherwise the main class itself. See
  /// [MainClass.displayClassNames].
  List<String> get divisionNames =>
      mainClasses.expand((mainClass) => mainClass.displayClassNames).toList();

  // Excludes any legacy teacher docs with role "Admin" from before admins
  // got their own collection.
  int get teacherCount =>
      teachers.where((teacher) => teacher.role != 'Admin').length;

  int get adminCount => admins.length;

  int get studentCount => students.length;

  int get classCount => divisionNames.length;
}
