import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/add_teacher_controller.dart';

class AddTeacher extends StatefulWidget {
  const AddTeacher({super.key});

  @override
  State<AddTeacher> createState() => _AddTeacherState();
}

class _AddTeacherState extends State<AddTeacher> {
  final _formKey = GlobalKey<FormState>();
  late final AddTeacherController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AddTeacherController());
  }

  @override
  void dispose() {
    Get.delete<AddTeacherController>();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final formValid = _formKey.currentState!.validate();
    if (!formValid) return;

    try {
      await controller.save();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Teacher added successfully!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save teacher: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7E57C2),
        elevation: 0,
        title: const Text(
          'Add Teacher',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ButtonTheme(
            alignedDropdown: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Section
                Center(
                  child: Obx(() {
                    final image = controller.selectedImage.value;
                    return Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF7E57C2,
                              ).withValues(alpha: 0.3),
                              width: 3,
                            ),
                            color: image == null
                                ? const Color(
                                    0xFF7E57C2,
                                  ).withValues(alpha: 0.1)
                                : null,
                            image: image != null
                                ? DecorationImage(
                                    image: FileImage(image),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: image == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Color(0xFF7E57C2),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: controller.pickImage,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Upload Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7E57C2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 30),

                // Name Field
                _buildLabel('Name'),
                TextFormField(
                  controller: controller.nameController,
                  decoration: _buildInputDecoration(
                    'Enter full name',
                    Icons.badge,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Username Field (auto-generated, editable via icon)
                _buildLabel('Username'),
                Obx(
                  () => TextFormField(
                    controller: controller.usernameController,
                    readOnly: !controller.isUsernameEditable.value,
                    decoration:
                        _buildInputDecoration(
                          'Auto-generated from name',
                          Icons.alternate_email,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isUsernameEditable.value
                                  ? Icons.lock_open
                                  : Icons.edit,
                              color: const Color(0xFF7E57C2),
                            ),
                            tooltip: controller.isUsernameEditable.value
                                ? 'Lock (revert to auto-generated)'
                                : 'Edit username manually',
                            onPressed: controller.toggleUsernameEditable,
                          ),
                        ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Gender Dropdown
                _buildLabel('Gender'),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedGender.value,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: const Color(0xFFF7F9FC),
                    decoration: _buildInputDecoration('Select gender', Icons.wc),
                    items: AddTeacherController.genderOptions.map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        controller.selectedGender.value = value,
                    validator: (value) {
                      if (value == null) return 'Please select a gender';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Phone Field
                _buildLabel('Phone'),
                TextFormField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration(
                    'Enter phone number',
                    Icons.phone,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Assigned Class Dropdown (divisions, same list shown in
                // the Homepage's Class List, live from the `class`
                // collection)
                _buildLabel('Assigned Class'),
                Obx(() {
                  if (controller.isLoadingMainClasses.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }
                  if (controller.mainClassesError.value != null) {
                    return Text(
                      controller.mainClassesError.value!,
                      style: const TextStyle(color: Colors.redAccent),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    value: controller.selectedAssignedClass.value,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: const Color(0xFFF7F9FC),
                    decoration: _buildInputDecoration(
                      'Select class',
                      Icons.class_,
                    ),
                    items: controller.assignedClassOptions.map((division) {
                      return DropdownMenuItem(
                        value: division,
                        child: Text(division),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        controller.selectedAssignedClass.value = value,
                    validator: (value) {
                      if (value == null) return 'Please select a class';
                      return null;
                    },
                  );
                }),
                const SizedBox(height: 18),

                // Service Dropdown
                _buildLabel('Service'),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedService.value,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: const Color(0xFFF7F9FC),
                    decoration: _buildInputDecoration(
                      'Select service',
                      Icons.church,
                    ),
                    items: AddTeacherController.serviceOptions.map((service) {
                      return DropdownMenuItem(
                        value: service,
                        child: Text(service),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        controller.selectedService.value = value,
                    validator: (value) {
                      if (value == null) return 'Please select a service';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7E57C2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isSaving.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Add Teacher',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF7E57C2),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7E57C2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E3A5F),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF7E57C2)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7E57C2), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
