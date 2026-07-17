import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/add_class_controller.dart';

class AddClass extends StatefulWidget {
  const AddClass({super.key});

  @override
  State<AddClass> createState() => _AddClassState();
}

class _AddClassState extends State<AddClass> {
  final _formKey = GlobalKey<FormState>();
  late final AddClassController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AddClassController());
  }

  @override
  void dispose() {
    Get.delete<AddClassController>();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final formValid = _formKey.currentState!.validate();
    if (!formValid) return;

    final divisionsError = controller.validateDivisions();
    if (divisionsError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(divisionsError)));
      return;
    }

    final mainClassName = controller.isCreatingNewMainClass.value
        ? controller.newMainClassController.text.trim()
        : controller.selectedMainClassName;

    if (mainClassName == null || mainClassName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a main class')),
      );
      return;
    }

    try {
      await controller.save(mainClassName: mainClassName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save class: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        elevation: 0,
        title: const Text(
          'Add Class',
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
                const SizedBox(height: 30),

                // Icon Section
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00ACC1).withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.class_,
                      size: 50,
                      color: Color(0xFF00ACC1),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Main Class Section
                _buildLabel('Main Class'),
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
                  if (controller.loadError.value != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.loadError.value!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          TextButton(
                            onPressed: controller.loadMainClasses,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final dropdownValue = controller.isCreatingNewMainClass.value
                      ? kNewMainClassOption
                      : controller.selectedMainClassId.value;
                  return DropdownButtonFormField<String>(
                    value: dropdownValue,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: const Color(0xFFF7F9FC),
                    decoration: _buildInputDecoration(
                      'Select main class',
                      Icons.category,
                    ),
                    items: [
                      ...controller.mainClasses.map(
                        (mainClass) => DropdownMenuItem(
                          value: mainClass.id,
                          child: Text(mainClass.name),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: kNewMainClassOption,
                        child: Text('+ New Main Class'),
                      ),
                    ],
                    onChanged: controller.selectMainClass,
                    validator: (value) {
                      if (value == null) {
                        return 'Please select or create a main class';
                      }
                      return null;
                    },
                  );
                }),
                Obx(() {
                  if (!controller.isCreatingNewMainClass.value) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextFormField(
                      controller: controller.newMainClassController,
                      decoration: _buildInputDecoration(
                        'Enter new main class (e.g. Beginner)',
                        Icons.add_box,
                      ),
                      validator: (value) {
                        if (!controller.isCreatingNewMainClass.value) {
                          return null;
                        }
                        if (value == null || value.trim().isEmpty) {
                          return 'Main class name is required';
                        }
                        if (controller.isNewMainClassNameTaken) {
                          return 'This main class already exists';
                        }
                        return null;
                      },
                    ),
                  );
                }),
                const SizedBox(height: 18),

                // Class Divisions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('Class Divisions (optional)'),
                    IconButton(
                      onPressed: controller.addDivisionField,
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF00ACC1),
                      ),
                      tooltip: 'Add another division',
                    ),
                  ],
                ),
                Obx(
                  () => Column(
                    children: [
                      for (
                        var i = 0;
                        i < controller.divisionControllers.length;
                        i++
                      )
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller:
                                      controller.divisionControllers[i],
                                  decoration: _buildInputDecoration(
                                    'e.g. Beginner ${i + 1}',
                                    Icons.groups_2,
                                  ),
                                ),
                              ),
                              if (controller.divisionControllers.length > 1)
                                IconButton(
                                  onPressed: () =>
                                      controller.removeDivisionField(i),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Remove division',
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00ACC1),
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
                              'Add Class',
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
                        color: Color(0xFF00ACC1),
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
                        color: Color(0xFF00ACC1),
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
      prefixIcon: Icon(icon, color: const Color(0xFF00ACC1)),
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
        borderSide: const BorderSide(color: Color(0xFF00ACC1), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
