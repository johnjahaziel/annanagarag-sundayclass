import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/class_repository.dart';
import '../repositories/teacher_repository.dart';

/// Counts returned by [DummyDataSeeder.seedAll], and printed as the final
/// log line.
class SeedSummary {
  const SeedSummary({
    required this.teachersCreated,
    required this.studentsCreated,
    required this.skipped,
    required this.failures,
  });

  final int teachersCreated;
  final int studentsCreated;
  final int skipped;

  /// One entry per record that failed to write (e.g. a transient network
  /// error) — a failure here doesn't stop the rest of the run.
  final List<String> failures;

  @override
  String toString() =>
      'Teachers created: $teachersCreated, '
      'Students created: $studentsCreated, '
      'Skipped: $skipped, '
      'Failed: ${failures.length}';
}

/// Development-only dummy data generator for the `teachers` and `students`
/// collections — for populating the app with demo records to look at, not
/// for anything a real user ever touches.
///
/// This is entirely separate from [TeacherRepository]/[StudentRepository]
/// and the real Add Teacher/Add Student forms: it writes straight to
/// Firestore with its own id sequencing and never touches
/// [CloudinaryService], so nothing in the real save path can be affected
/// by it. It only *reads* from the real repositories (to list classes and
/// to check whether a class/service already has a teacher), never writes
/// through them.
///
/// To remove this feature before shipping, delete this file and
/// `integration_test/dummy_data_seeder_test.dart` — nothing else
/// references either.
///
/// Every document this creates is tagged `isDummy: true` plus a
/// deterministic `seedKey` (e.g. `beginner_1_service_1_teacher`,
/// `beginner_1_service_1_student_3`). That's what makes [seedAll] safe to
/// run more than once: a slot that's already been seeded — or, for
/// teachers, already has a real one assigned — is skipped rather than
/// duplicated. The `isDummy` flag also makes it easy to bulk-delete all
/// seeded data later straight from the Firestore console.
class DummyDataSeeder {
  DummyDataSeeder({
    FirebaseFirestore? firestore,
    ClassRepository? classRepository,
    TeacherRepository? teacherRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _classRepository = classRepository ?? ClassRepository(),
       _teacherRepository = teacherRepository ?? TeacherRepository();

  final FirebaseFirestore _firestore;
  final ClassRepository _classRepository;
  final TeacherRepository _teacherRepository;

  /// One shared placeholder photo for every dummy record. Never uploaded
  /// anywhere (no Cloudinary involved) — just written straight into
  /// `photoUrl` as-is.
  static const demoPhotoUrl = 'https://i.pravatar.cc/300?img=12';

  static const _studentsPerSlot = 10;
  static const _teacherIdPrefix = 'TCH';
  static const _studentIdPrefix = 'STU';
  static const _idDigits = 3;

  static const _firstNames = [
    'Aarav', 'Vivaan', 'Aditya', 'Vihaan', 'Arjun',
    'Sai', 'Reyansh', 'Krishna', 'Ishaan', 'Rohan',
    'Ananya', 'Diya', 'Saanvi', 'Aadhya', 'Kiara',
    'Myra', 'Anika', 'Riya', 'Priya', 'Meera',
    'James', 'Daniel', 'Samuel', 'Joseph', 'Noah',
    'Grace', 'Hannah', 'Ruth', 'Esther', 'Ethan',
  ];

  static const _lastNames = [
    'Sharma', 'Kumar', 'Reddy', 'Iyer', 'Nair',
    'Menon', 'Pillai', 'Raj', 'Fernandes', "D'Souza",
    'Wilson', 'Thomas', 'Abraham', 'George', 'Mathew',
    'Jacob', 'Paul', 'John', 'Peter', 'Varghese',
  ];

  CollectionReference<Map<String, dynamic>> get _teachersCollection =>
      _firestore.collection('teachers');

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection('students');

  void _log(String message) {
    // ignore: avoid_print
    print('[DummyDataSeeder] $message');
  }

  String _nameFor(int index) {
    final first = _firstNames[index % _firstNames.length];
    final last =
        _lastNames[(index ~/ _firstNames.length) % _lastNames.length];
    return '$first $last';
  }

  String _phoneFor(int index) =>
      '9${(200000000 + index).toString().padLeft(9, '0')}';

  Future<bool> _seedKeyExists(
    CollectionReference<Map<String, dynamic>> collection,
    String seedKey,
  ) async {
    final snapshot = await collection
        .where('seedKey', isEqualTo: seedKey)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<String> _nextSequentialId(
    CollectionReference<Map<String, dynamic>> collection,
    String field,
    String prefix,
  ) async {
    final snapshot = await collection
        .orderBy(field, descending: true)
        .limit(1)
        .get();
    var nextNumber = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()[field] as String? ?? '';
      final match = RegExp(r'(\d+)$').firstMatch(lastId);
      if (match != null) {
        nextNumber = int.parse(match.group(1)!) + 1;
      }
    }
    return '$prefix${nextNumber.toString().padLeft(_idDigits, '0')}';
  }

  /// Seeds one teacher and ten students for every class division × service
  /// combination that doesn't already have them. Safe to run more than
  /// once.
  Future<SeedSummary> seedAll() async {
    final mainClasses = await _classRepository.getMainClasses();
    if (mainClasses.isEmpty) {
      _log('No classes found in Firestore — add classes before seeding.');
      return const SeedSummary(
        teachersCreated: 0,
        studentsCreated: 0,
        skipped: 0,
        failures: [],
      );
    }

    var teachersCreated = 0;
    var studentsCreated = 0;
    var skipped = 0;
    var nameIndex = 0;
    final failures = <String>[];

    for (final mainClass in mainClasses) {
      for (final division in mainClass.displayClassNames) {
        final classId = AttendanceRepository.normalizeClassId(division);

        for (final service in Service.options) {
          final serviceId = AttendanceRepository.normalizeService(service);

          // --- Teacher ---
          final teacherSeedKey = '${classId}_${serviceId}_teacher';
          final teacherAlreadySeeded = await _seedKeyExists(
            _teachersCollection,
            teacherSeedKey,
          );
          var skipTeacher = teacherAlreadySeeded;
          var skipReason = 'already seeded';
          if (!skipTeacher) {
            final existingTeacher = await _teacherRepository
                .getTeacherForClassAndService(
                  assignedClass: division,
                  service: service,
                );
            if (existingTeacher != null) {
              skipTeacher = true;
              skipReason = 'a teacher is already assigned';
            }
          }

          if (skipTeacher) {
            skipped++;
            _log(
              'Skipped teacher for "$division" ($service) — $skipReason.',
            );
          } else {
            nameIndex++;
            final name = _nameFor(nameIndex);
            try {
              final username =
                  '${TeacherRepository.suggestUsername(name)}$nameIndex';
              final teacherId = await _nextSequentialId(
                _teachersCollection,
                'teacherId',
                _teacherIdPrefix,
              );

              await _teachersCollection.add({
                'teacherId': teacherId,
                'name': name,
                'username': username,
                'gender': nameIndex.isEven ? 'Female' : 'Male',
                'phone': _phoneFor(nameIndex),
                'assignedClass': division,
                'service': service,
                'role': 'Teacher',
                'status': 'Active',
                'isActive': true,
                'photoUrl': demoPhotoUrl,
                'createdAt': FieldValue.serverTimestamp(),
                'isDummy': true,
                'seedKey': teacherSeedKey,
              });
              teachersCreated++;
              _log('Created teacher "$name" for "$division" ($service).');
            } catch (e) {
              failures.add('Teacher "$name" for "$division" ($service): $e');
            }
          }

          // --- Students ---
          var slotStudentsCreated = 0;
          var slotStudentsSkipped = 0;
          for (var i = 1; i <= _studentsPerSlot; i++) {
            final studentSeedKey = '${classId}_${serviceId}_student_$i';
            if (await _seedKeyExists(_studentsCollection, studentSeedKey)) {
              skipped++;
              slotStudentsSkipped++;
              continue;
            }

            nameIndex++;
            final name = _nameFor(nameIndex);
            try {
              final studentId = await _nextSequentialId(
                _studentsCollection,
                'studentId',
                _studentIdPrefix,
              );
              final age = 4 + (i % 9); // ages 4-12
              final dob = DateTime(
                DateTime.now().year - age,
                ((i - 1) % 12) + 1,
                ((i * 7) % 28) + 1,
              );

              await _studentsCollection.add({
                'studentId': studentId,
                'name': name,
                'gender': nameIndex.isEven ? 'Female' : 'Male',
                'dob': Timestamp.fromDate(dob),
                'parentName': _nameFor(nameIndex + 1000),
                'parentPhone': _phoneFor(nameIndex),
                'assignedClass': division,
                'service': service,
                'isActive': true,
                'photoUrl': demoPhotoUrl,
                'createdAt': FieldValue.serverTimestamp(),
                'isDummy': true,
                'seedKey': studentSeedKey,
              });
              studentsCreated++;
              slotStudentsCreated++;
            } catch (e) {
              failures.add('Student "$name" for "$division" ($service): $e');
            }
          }
          _log(
            'Students for "$division" ($service): '
            '$slotStudentsCreated created, $slotStudentsSkipped skipped.',
          );
        }
      }
    }

    final summary = SeedSummary(
      teachersCreated: teachersCreated,
      studentsCreated: studentsCreated,
      skipped: skipped,
      failures: failures,
    );
    _log('Done. $summary');
    if (failures.isNotEmpty) {
      _log('Failures:\n${failures.join('\n')}');
    }
    return summary;
  }
}
