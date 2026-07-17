import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/main_class.dart';
import '../models/service.dart';
import '../repositories/class_repository.dart';
import '../repositories/student_repository.dart';

/// Drives the Add Student screen: streams the Assigned Class options from
/// the `class` collection and saves through [StudentRepository].
class AddStudentController extends GetxController {
  AddStudentController({
    StudentRepository? studentRepository,
    ClassRepository? classRepository,
  }) : _studentRepository = studentRepository ?? StudentRepository(),
       _classRepository = classRepository ?? ClassRepository();

  final StudentRepository _studentRepository;
  final ClassRepository _classRepository;

  static const genderOptions = ['Male', 'Female'];
  static const serviceOptions = Service.options;

  final nameController = TextEditingController();
  final parentNameController = TextEditingController();
  final parentPhoneController = TextEditingController();

  final RxnString selectedGender = RxnString();
  final RxnString selectedAssignedClass = RxnString();
  final RxnString selectedService = RxnString();
  final Rx<DateTime?> selectedDob = Rx<DateTime?>(null);

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

  void setDob(DateTime dob) {
    selectedDob.value = dob;
  }

  void clearDob() {
    selectedDob.value = null;
  }

  /// Saves the new student. Rethrows repository errors so the view can
  /// show an appropriate snackbar; always clears [isSaving].
  Future<void> save() async {
    isSaving.value = true;
    try {
      await _studentRepository.createStudent(
        name: nameController.text,
        gender: selectedGender.value!,
        dob: selectedDob.value!,
        parentName: parentNameController.text,
        parentPhone: parentPhoneController.text,
        assignedClass: selectedAssignedClass.value!,
        service: selectedService.value!,
        photoFile: selectedImage.value,
      );
      _resetForm();
    } finally {
      isSaving.value = false;
    }
  }

  void _resetForm() {
    nameController.clear();
    parentNameController.clear();
    parentPhoneController.clear();
    selectedGender.value = null;
    selectedAssignedClass.value = null;
    selectedService.value = null;
    selectedDob.value = null;
    selectedImage.value = null;
  }

  @override
  void onClose() {
    nameController.dispose();
    parentNameController.dispose();
    parentPhoneController.dispose();
    _mainClassesSubscription?.cancel();
    super.onClose();
  }
}
