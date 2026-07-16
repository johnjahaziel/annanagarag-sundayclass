import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';
import 'homepage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  late final LoginController controller;

  static const _accentColor = Color(0xFF5E35B1);

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoginController());
  }

  @override
  void dispose() {
    Get.delete<LoginController>();
    super.dispose();
  }

  Future<void> _login() async {
    final formValid = _formKey.currentState!.validate();
    if (!formValid) return;

    try {
      await controller.login();
      if (!mounted) return;
      Get.offAll(() => const Homepage());
    } on InvalidUsernameException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid username')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF3E0),
              Color(0xFFE1F5FE),
              Color(0xFFE8F5E9),
              Color(0xFFF3E5F5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Card(
                    elevation: 10,
                    shadowColor: _accentColor.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    color: Colors.white.withValues(alpha: 0.96),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFE082),
                                  Color(0xFFFFB74D),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFB74D,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.diversity_3_rounded,
                              size: 42,
                              color: Color(0xFFEF6C00),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Welcome Back!',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _accentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in with your username to manage\nyour Sunday School classes',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, height: 1.4),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: controller.usernameController,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              prefixIcon: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF7E57C2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF3E5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: Obx(
                              () => ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00ACC1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: controller.isLoading.value
                                    ? null
                                    : _login,
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
