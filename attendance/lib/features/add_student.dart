import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/add_student_controller.dart';

class AddStudent extends StatefulWidget {
  const AddStudent({super.key});

  @override
  State<AddStudent> createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  final _formKey = GlobalKey<FormState>();
  late final AddStudentController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AddStudentController());
  }

  @override
  void dispose() {
    Get.delete<AddStudentController>();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDob.value ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7E57C2),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E3A5F),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setDob(picked);
    }
  }

  Future<void> _submitForm() async {
    final formValid = _formKey.currentState!.validate();
    if (!formValid) return;

    try {
      await controller.save();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Student added successfully!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save student: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        title: const Text(
          'Add Student',
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
                                0xFF26A69A,
                              ).withValues(alpha: 0.3),
                              width: 3,
                            ),
                            color: image == null
                                ? const Color(
                                    0xFF26A69A,
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
                                  color: Color(0xFF26A69A),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: controller.pickImage,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Upload Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF26A69A),
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
                    'Enter student name',
                    Icons.person,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
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
                    items: AddStudentController.genderOptions.map((gender) {
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

                // Date of Birth Field
                _buildLabel('Date of Birth'),
                Obx(() {
                  final dob = controller.selectedDob.value;
                  return TextFormField(
                    key: ValueKey(dob),
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: InputDecoration(
                      hintText: dob != null
                          ? '${dob.day}/${dob.month}/${dob.year}'
                          : 'Select date of birth',
                      prefixIcon: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF26A69A),
                      ),
                      suffixIcon: dob != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: controller.clearDob,
                            )
                          : null,
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
                        borderSide: const BorderSide(
                          color: Color(0xFF26A69A),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) {
                      if (controller.selectedDob.value == null) {
                        return 'Please select a date of birth';
                      }
                      return null;
                    },
                  );
                }),
                const SizedBox(height: 18),

                // Parent Name Field
                _buildLabel('Parent Name'),
                TextFormField(
                  controller: controller.parentNameController,
                  decoration: _buildInputDecoration(
                    'Enter parent/guardian name',
                    Icons.people,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Parent name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Parent Phone Field
                _buildLabel('Parent Phone'),
                TextFormField(
                  controller: controller.parentPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration(
                    'Enter parent phone number',
                    Icons.phone,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Parent phone number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Assigned Class Dropdown (divisions, same list shown in
                // the Homepage's Class List, live from the `class`
                // collection)
                _buildLabel('Class'),
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
                        backgroundColor: const Color(0xFF26A69A),
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
                              'Add Student',
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
                        color: Color(0xFF26A69A),
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
                        color: Color(0xFF26A69A),
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
      prefixIcon: Icon(icon, color: const Color(0xFF26A69A)),
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
        borderSide: const BorderSide(color: Color(0xFF26A69A), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
