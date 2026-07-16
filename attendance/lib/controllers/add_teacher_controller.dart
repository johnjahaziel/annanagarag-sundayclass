import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/main_class.dart';
import '../repositories/class_repository.dart';
import '../repositories/teacher_repository.dart';

/// Drives the Add Teacher screen: keeps the username in sync with the name
/// field until the user opts to edit it manually, streams the Assigned
/// Class options from the `class` collection, and saves through
/// [TeacherRepository].
class AddTeacherController extends GetxController {
  AddTeacherController({
    TeacherRepository? teacherRepository,
    ClassRepository? classRepository,
  }) : _teacherRepository = teacherRepository ?? TeacherRepository(),
       _classRepository = classRepository ?? ClassRepository();

  final TeacherRepository _teacherRepository;
  final ClassRepository _classRepository;

  static const genderOptions = ['Male', 'Female'];

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();

  final isUsernameEditable = false.obs;

  final RxnString selectedGender = RxnString();
  final RxnString selectedAssignedClass = RxnString();

  final mainClasses = <MainClass>[].obs;
  final isLoadingMainClasses = false.obs;
  final mainClassesError = RxnString();

  final Rx<File?> selectedImage = Rx<File?>(null);

  final isSaving = false.obs;

  StreamSubscription<List<MainClass>>? _mainClassesSubscription;

  /// The divisions across every main class, in the same order shown in the
  /// Homepage's Class List — the assigned class is a specific division
  /// (e.g. "Beginner 1"), not just the main class.
  List<String> get assignedClassOptions =>
      mainClasses.expand((mainClass) => mainClass.divisions).toList();

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(_onNameChanged);
    _subscribeToMainClasses();
  }

  void _subscribeToMainClasses() {
    isLoadingMainClasses.value = true;
    _mainClassesSubscription = _classRepository.streamMainClasses().listen(
      (classes) {
        mainClasses.value = classes;
        isLoadingMainClasses.value = false;
        mainClassesError.value = null;
      },
      onError: (Object error) {
        isLoadingMainClasses.value = false;
        mainClassesError.value = 'Failed to load classes: $error';
      },
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = File(image.path);
    }
  }

  void _onNameChanged() {
    if (!isUsernameEditable.value) {
      usernameController.text = TeacherRepository.suggestUsername(
        nameController.text,
      );
    }
  }

  /// Toggles the username field between auto-generated (read-only) and
  /// manually editable. Re-deriving from the name when locking back.
  void toggleUsernameEditable() {
    isUsernameEditable.value = !isUsernameEditable.value;
    if (!isUsernameEditable.value) {
      usernameController.text = TeacherRepository.suggestUsername(
        nameController.text,
      );
    }
  }

  /// Saves the new teacher. Rethrows repository errors so the view can
  /// show an appropriate snackbar; always clears [isSaving].
  Future<void> save() async {
    isSaving.value = true;
    try {
      await _teacherRepository.createTeacher(
        name: nameController.text,
        username: usernameController.text,
        gender: selectedGender.value!,
        phone: phoneController.text,
        assignedClass: selectedAssignedClass.value!,
        role: 'Teacher',
        status: 'Active',
        photoFile: selectedImage.value,
      );
      _resetForm();
    } finally {
      isSaving.value = false;
    }
  }

  void _resetForm() {
    nameController.clear();
    usernameController.clear();
    phoneController.clear();
    isUsernameEditable.value = false;
    selectedGender.value = null;
    selectedAssignedClass.value = null;
    selectedImage.value = null;
  }

  @override
  void onClose() {
    nameController.removeListener(_onNameChanged);
    nameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    _mainClassesSubscription?.cancel();
    super.onClose();
  }
}
