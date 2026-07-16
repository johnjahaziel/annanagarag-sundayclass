import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../repositories/admin_repository.dart';
import '../repositories/teacher_repository.dart';
import '../services/session_service.dart';

/// Thrown by [LoginController.login] when the entered username doesn't
/// match any admin or teacher.
class InvalidUsernameException implements Exception {
  @override
  String toString() => 'Invalid username';
}

/// Drives the username-only login screen: looks the username up in
/// `admins` first, then `teachers`, and persists a [UserSession] via
/// [SessionService] on success. Navigation is left to the view (same
/// pattern as the Add* screens), so this stays easy to test in isolation.
class LoginController extends GetxController {
  LoginController({
    AdminRepository? adminRepository,
    TeacherRepository? teacherRepository,
    SessionService? sessionService,
  }) : _adminRepository = adminRepository ?? AdminRepository(),
       _teacherRepository = teacherRepository ?? TeacherRepository(),
       _sessionService = sessionService ?? SessionService();

  final AdminRepository _adminRepository;
  final TeacherRepository _teacherRepository;
  final SessionService _sessionService;

  final usernameController = TextEditingController();
  final isLoading = false.obs;

  /// Looks up the entered username in `admins`, then `teachers`. Saves and
  /// returns a [UserSession] on a match; throws [InvalidUsernameException]
  /// if neither collection has it.
  Future<UserSession> login() async {
    isLoading.value = true;
    try {
      final username = usernameController.text.trim();

      final admin = await _adminRepository.getByUsername(username);
      if (admin != null) {
        final session = UserSession(
          username: admin.username,
          role: 'Admin',
          docId: admin.id,
          name: admin.name,
        );
        await _sessionService.saveSession(session);
        return session;
      }

      final teacher = await _teacherRepository.getByUsername(username);
      if (teacher != null) {
        final session = UserSession(
          username: teacher.username,
          role: 'Teacher',
          docId: teacher.id,
          name: teacher.name,
        );
        await _sessionService.saveSession(session);
        return session;
      }

      throw InvalidUsernameException();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    super.onClose();
  }
}
