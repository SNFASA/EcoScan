import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../home/ui/home_screen.dart';
import '../logic/auth_provider.dart';
import 'register_screen.dart';
import '../../../services/firebase_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  FocusScope.of(context).unfocus();

  try {
    // 1️⃣ Login first
    await ref.read(authProvider.notifier).login(email, password);

    // 2️⃣ Get the logged-in user
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 3️⃣ Create Firestore document if it doesn't exist
      await FirebaseService().createUserIfNotExists(user);
    } else {
      throw Exception("Login succeeded but user is null");
    }

    // 4️⃣ Navigate to Home safely
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderSection(),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration("Email", Icons.email_outlined),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your email';
                                  if (!value.contains('@')) return 'Please enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your password';
                                  if (value.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(color: Colors.green[700]),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Login button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: authState.isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                  child: authState.isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text(
                                          "LOGIN",
                                          style: TextStyle(
                                              fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?", style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: _circleDeco(150, Colors.white.withAlpha((0.1 * 255).toInt())),
              ),
              Positioned(
                top: 50,
                left: -20,
                child: _circleDeco(100, Colors.white.withAlpha((0.05 * 255).toInt())),
              ),
              const Positioned(
                top: 80,
                left: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.eco, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text("Welcome Back",
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    Text("Sign in to continue your eco journey",
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green[700]),
      filled: true,
      fillColor: Colors.green.withAlpha((0.05 * 255).toInt()),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.green, width: 2)),
      errorBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 1)),
    );
  }

  Widget _circleDeco(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
