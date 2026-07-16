import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/add_admin_controller.dart';

class AddAdmin extends StatefulWidget {
  const AddAdmin({super.key});

  @override
  State<AddAdmin> createState() => _AddAdminState();
}

class _AddAdminState extends State<AddAdmin> {
  final _formKey = GlobalKey<FormState>();
  late final AddAdminController controller;

  static const _accentColor = Color(0xFFEC407A);

  @override
  void initState() {
    super.initState();
    controller = Get.put(AddAdminController());
  }

  @override
  void dispose() {
    Get.delete<AddAdminController>();
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
      ).showSnackBar(const SnackBar(content: Text('Admin added successfully!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save admin: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: _accentColor,
        elevation: 0,
        title: const Text(
          'Add Admin',
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
                              color: _accentColor.withValues(alpha: 0.3),
                              width: 3,
                            ),
                            color: image == null
                                ? _accentColor.withValues(alpha: 0.1)
                                : null,
                            image: image != null
                                ? DecorationImage(
                                    image: FileImage(image),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: image == null
                              ? Icon(
                                  Icons.admin_panel_settings,
                                  size: 50,
                                  color: _accentColor,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: controller.pickImage,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Upload Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
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
                              color: _accentColor,
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

                // Gender Dropdown
                _buildLabel('Gender'),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedGender.value,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: const Color(0xFFF7F9FC),
                    decoration: _buildInputDecoration('Select gender', Icons.wc),
                    items: AddAdminController.genderOptions.map((gender) {
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
                        backgroundColor: _accentColor,
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
                              'Add Admin',
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
                      side: const BorderSide(color: _accentColor, width: 2),
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
                        color: _accentColor,
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
      prefixIcon: Icon(icon, color: _accentColor),
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
        borderSide: const BorderSide(color: _accentColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
