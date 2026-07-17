import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/main_class.dart';
import '../repositories/class_repository.dart';
import 'home_controller.dart';

/// Sentinel dropdown value representing the "+ New Main Class" option.
const String kNewMainClassOption = '__new_main_class__';

/// Drives the Add Class screen: loading main classes, toggling between
/// picking an existing one and creating a new one, managing the dynamic
/// list of division fields, and saving through [ClassRepository].
class AddClassController extends GetxController {
  AddClassController({ClassRepository? repository})
    : _repository = repository ?? ClassRepository();

  final ClassRepository _repository;

  final mainClasses = <MainClass>[].obs;
  final isLoadingMainClasses = false.obs;
  final isSaving = false.obs;
  final loadError = RxnString();

  final RxnString selectedMainClassId = RxnString();
  final isCreatingNewMainClass = false.obs;
  final newMainClassController = TextEditingController();

  final RxList<TextEditingController> divisionControllers =
      <TextEditingController>[TextEditingController()].obs;

  @override
  void onInit() {
    super.onInit();
    loadMainClasses();
  }

  Future<void> loadMainClasses() async {
    isLoadingMainClasses.value = true;
    loadError.value = null;
    try {
      mainClasses.value = await _repository.getMainClasses();
    } catch (e) {
      loadError.value = 'Failed to load main classes: $e';
    } finally {
      isLoadingMainClasses.value = false;
    }
  }

  void selectMainClass(String? value) {
    if (value == kNewMainClassOption) {
      isCreatingNewMainClass.value = true;
      selectedMainClassId.value = null;
    } else {
      isCreatingNewMainClass.value = false;
      selectedMainClassId.value = value;
    }
  }

  void addDivisionField() {
    divisionControllers.add(TextEditingController());
  }

  void removeDivisionField(int index) {
    if (divisionControllers.length <= 1) return;
    divisionControllers[index].dispose();
    divisionControllers.removeAt(index);
  }

  /// Client-side check mirroring [ClassRepository.validateDivisionNames],
  /// run before hitting Firestore so the user gets instant feedback.
  String? validateDivisions() {
    final names = divisionControllers.map((c) => c.text).toList();
    return ClassRepository.validateDivisionNames(names);
  }

  /// Resolves the name of the currently selected main class from the
  /// loaded list, or null if creating a new one / nothing selected.
  String? get selectedMainClassName {
    final id = selectedMainClassId.value;
    if (id == null) return null;
    for (final mainClass in mainClasses) {
      if (mainClass.id == id) return mainClass.name;
    }
    return null;
  }

  bool get isNewMainClassNameTaken {
    final normalized = ClassRepository.normalizeId(
      newMainClassController.text,
    );
    return mainClasses.any((mc) => mc.id == normalized);
  }

  /// Saves the form. Rethrows repository errors so the view can show an
  /// appropriate snackbar; always clears [isSaving] and, on success,
  /// resets the form and refreshes [mainClasses].
  Future<void> save({required String mainClassName}) async {
    isSaving.value = true;
    try {
      final divisions = divisionControllers.map((c) => c.text.trim()).toList();
      await _repository.saveClass(
        mainClassName: mainClassName,
        isNewMainClass: isCreatingNewMainClass.value,
        existingMainClassId: selectedMainClassId.value,
        divisions: divisions,
      );
      _resetForm();
      await loadMainClasses();
      HomeController.refreshIfRegistered();
    } finally {
      isSaving.value = false;
    }
  }

  void _resetForm() {
    isCreatingNewMainClass.value = false;
    selectedMainClassId.value = null;
    newMainClassController.clear();
    for (final controller in divisionControllers) {
      controller.dispose();
    }
    divisionControllers.assignAll([TextEditingController()]);
  }

  @override
  void onClose() {
    newMainClassController.dispose();
    for (final controller in divisionControllers) {
      controller.dispose();
    }
    super.onClose();
  }
}
