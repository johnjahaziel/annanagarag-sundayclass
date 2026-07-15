import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../repositories/admin_repository.dart';

/// Drives the Add Admin screen and saves through [AdminRepository].
class AddAdminController extends GetxController {
  AddAdminController({AdminRepository? repository})
    : _repository = repository ?? AdminRepository();

  final AdminRepository _repository;

  static const genderOptions = ['Male', 'Female'];

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final RxnString selectedGender = RxnString();

  final Rx<File?> selectedImage = Rx<File?>(null);

  final isSaving = false.obs;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = File(image.path);
    }
  }

  /// Saves the new admin. Rethrows repository errors so the view can show
  /// an appropriate snackbar; always clears [isSaving].
  Future<void> save() async {
    isSaving.value = true;
    try {
      await _repository.createAdmin(
        name: nameController.text,
        phone: phoneController.text,
        gender: selectedGender.value!,
        photoFile: selectedImage.value,
      );
      _resetForm();
    } finally {
      isSaving.value = false;
    }
  }

  void _resetForm() {
    nameController.clear();
    phoneController.clear();
    selectedGender.value = null;
    selectedImage.value = null;
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
