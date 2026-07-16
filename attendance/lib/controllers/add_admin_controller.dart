import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../repositories/admin_repository.dart';

/// Drives the Add Admin screen and saves through [AdminRepository]. Keeps
/// the username in sync with the name field until the user opts to edit
/// it manually, same as [AddTeacherController].
class AddAdminController extends GetxController {
  AddAdminController({AdminRepository? repository})
    : _repository = repository ?? AdminRepository();

  final AdminRepository _repository;

  static const genderOptions = ['Male', 'Female'];

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();

  final isUsernameEditable = false.obs;

  final RxnString selectedGender = RxnString();

  final Rx<File?> selectedImage = Rx<File?>(null);

  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(_onNameChanged);
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
      usernameController.text = AdminRepository.suggestUsername(
        nameController.text,
      );
    }
  }

  /// Toggles the username field between auto-generated (read-only) and
  /// manually editable. Re-deriving from the name when locking back.
  void toggleUsernameEditable() {
    isUsernameEditable.value = !isUsernameEditable.value;
    if (!isUsernameEditable.value) {
      usernameController.text = AdminRepository.suggestUsername(
        nameController.text,
      );
    }
  }

  /// Saves the new admin. Rethrows repository errors so the view can show
  /// an appropriate snackbar; always clears [isSaving].
  Future<void> save() async {
    isSaving.value = true;
    try {
      await _repository.createAdmin(
        name: nameController.text,
        username: usernameController.text,
        phone: phoneController.text,
        gender: selectedGender.value!,
        role: 'Admin',
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
    selectedImage.value = null;
  }

  @override
  void onClose() {
    nameController.removeListener(_onNameChanged);
    nameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
