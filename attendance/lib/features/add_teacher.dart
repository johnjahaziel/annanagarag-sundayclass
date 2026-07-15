import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddTeacher extends StatefulWidget {
  const AddTeacher({super.key});

  @override
  State<AddTeacher> createState() => _AddTeacherState();
}

class _AddTeacherState extends State<AddTeacher> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();

  // Dropdown values
  String? _selectedGender;
  String? _selectedClass;
  String? _selectedStatus;
  File? _selectedImage;

  final List<String> genders = ['Male', 'Female'];
  final List<String> classes = [
    'Beginner 1',
    'Beginner 2',
    'Beginner 3',
    'Beginner 4',
    'Beginner 5',
    'Intermediate 1',
    'Intermediate 2',
    'Advanced 1',
    'Advanced 2',
  ];
  final List<String> statusOptions = ['Yes', 'No'];

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Handle form submission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher added successfully!')),
      );
      // Here you would typically save the teacher data to your backend or database
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
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF7E57C2).withValues(alpha: 0.3),
                          width: 3,
                        ),
                        color: _selectedImage == null
                            ? const Color(0xFF7E57C2).withValues(alpha: 0.1)
                            : null,
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Color(0xFF7E57C2),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
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
                ),
              ),
              const SizedBox(height: 30),

              // Username Field
              _buildLabel('Username'),
              TextFormField(
                controller: _usernameController,
                decoration: _buildInputDecoration(
                  'Enter username',
                  Icons.person,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Name Field
              _buildLabel('Name'),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(
                  'Enter full name',
                  Icons.badge,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Gender Dropdown
              _buildLabel('Gender'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor: const Color(0xFFF7F9FC),
                  decoration: _buildInputDecoration('Select gender', Icons.wc),
                  items: genders.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(gender),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a gender';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Phone Field
              _buildLabel('Phone'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration(
                  'Enter phone number',
                  Icons.phone,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Assigned Class Dropdown
              _buildLabel('Assigned Class'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor: const Color(0xFFF7F9FC),
                  decoration: _buildInputDecoration(
                    'Select class',
                    Icons.class_,
                  ),
                  items: classes.map((className) {
                    return DropdownMenuItem(
                      value: className,
                      child: Text(className),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a class';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Role Field
              _buildLabel('Role'),
              TextFormField(
                controller: _roleController,
                decoration: _buildInputDecoration(
                  'e.g., Instructor, Assistant',
                  Icons.assignment_ind,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Role is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Status (isActive) Dropdown
              _buildLabel('Status (Active)'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor: const Color(0xFFF7F9FC),
                  decoration: _buildInputDecoration(
                    'Select status',
                    Icons.toggle_on,
                  ),
                  items: statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a status';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7E57C2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Teacher',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                    side: const BorderSide(color: Color(0xFF7E57C2), width: 2),
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
