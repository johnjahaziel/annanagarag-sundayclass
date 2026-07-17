// Development-only runner for DummyDataSeeder. Run once against a real
// device to populate demo teachers/students for every class division and
// both services:
//   flutter test integration_test/dummy_data_seeder_test.dart -d <device_id>
//
// Safe to run again later — DummyDataSeeder skips any class/service slot
// that's already been seeded (or, for teachers, already has a real one
// assigned) instead of creating duplicates.
//
// To remove this feature entirely before production, delete this file and
// lib/services/dummy_data_seeder.dart — nothing else references either.
import 'package:attendance/firebase_options.dart';
import 'package:attendance/services/dummy_data_seeder.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('seed dummy teachers and students for every class/service', (
    tester,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final summary = await DummyDataSeeder().seedAll();

    expect(summary.failures, isEmpty, reason: summary.failures.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 15)));
}
