// One-off demo-data seeder: creates one teacher and ten students for every
// class division currently in Firestore, with no photos. Run once against a
// real device with:
//   flutter test integration_test/seed_demo_data_test.dart -d <device_id>
// Re-running it will create *another* batch of demo teachers/students
// (creation isn't idempotent), so only run it as many times as you actually
// want duplicated demo data.
import 'package:attendance/firebase_options.dart';
import 'package:attendance/repositories/class_repository.dart';
import 'package:attendance/repositories/student_repository.dart';
import 'package:attendance/repositories/teacher_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'seed one demo teacher and ten demo students per division',
    (tester) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final classRepository = ClassRepository();
      final teacherRepository = TeacherRepository();
      final studentRepository = StudentRepository();

      final mainClasses = await classRepository.getMainClasses();
      expect(
        mainClasses,
        isNotEmpty,
        reason: 'No main classes found in Firestore — add classes first.',
      );

      var teacherCount = 0;
      var studentCount = 0;
      var personIndex = 0;
      final failures = <String>[];

      String phoneFor(int index) =>
          '9${(100000000 + index).toString().padLeft(9, '0')}';

      for (final mainClass in mainClasses) {
        for (final division in mainClass.divisions) {
          // One teacher per division.
          personIndex++;
          final teacherName = 'Demo Teacher $division';
          try {
            await teacherRepository.createTeacher(
              name: teacherName,
              username: TeacherRepository.suggestUsername(teacherName),
              gender: personIndex.isEven ? 'Female' : 'Male',
              phone: phoneFor(personIndex),
              assignedClass: division,
              role: 'Teacher',
              status: 'Active',
            );
            teacherCount++;
          } catch (e) {
            failures.add('Teacher for $division: $e');
          }

          // Ten students per division.
          for (var i = 1; i <= 10; i++) {
            personIndex++;
            final studentName = 'Demo Student $division-$i';
            final age = 4 + (i % 9); // ages 4-12
            final dob = DateTime(
              DateTime.now().year - age,
              ((i - 1) % 12) + 1,
              ((i * 7) % 28) + 1,
            );
            try {
              await studentRepository.createStudent(
                name: studentName,
                gender: i.isEven ? 'Female' : 'Male',
                dob: dob,
                parentName: 'Demo Parent $division-$i',
                parentPhone: phoneFor(personIndex),
                assignedClass: division,
              );
              studentCount++;
            } catch (e) {
              failures.add('Student $studentName: $e');
            }
          }
        }
      }

      final divisionCount = mainClasses
          .expand((mainClass) => mainClass.divisions)
          .length;
      // ignore: avoid_print
      print(
        'Seeded $teacherCount teacher(s) and $studentCount student(s) '
        'across $divisionCount division(s).',
      );
      if (failures.isNotEmpty) {
        // ignore: avoid_print
        print('Failures (${failures.length}):\n${failures.join('\n')}');
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
