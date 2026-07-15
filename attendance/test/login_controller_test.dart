import 'package:attendance/controllers/controller.dart';
import 'package:attendance/features/homepage.dart';
import 'package:attendance/features/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('LoginController', () {
    late Controller controller;

    setUp(() {
      controller = Controller();
    });

    test('starts with empty username and password values', () {
      expect(controller.usernameController.text, isEmpty);
      expect(controller.passwordController.text, isEmpty);
      expect(controller.obscurePassword.value, isTrue);
    });

    test('toggles password visibility', () {
      controller.togglePasswordVisibility();
      expect(controller.obscurePassword.value, isFalse);
    });
  });

  testWidgets('tapping login navigates to homepage', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Login(),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'teacher');
    await tester.enterText(find.byType(TextField).at(1), '1234');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.byType(Homepage), findsOneWidget);
  });
}
