import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/auth_provider.dart';
import 'package:ecoscan/features/auth/ui/auth_widgets.dart';
import '../../../core/widgets/primary_button.dart';
import '../../home/ui/home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    /// Listen navigation
    ref.listen(authProvider, (previous, next) {
      final wasLoading = previous?.isLoading ?? false;

      if (wasLoading && !next.isLoading && next.error == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AuthTextField(
                controller: _emailController,
                label: "Email",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _passwordController,
                label: "Password",
                obscure: true,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                obscure: true,
              ),
              const SizedBox(height: 16),

              /// 🔴 Error Display
              if (authState.error != null) ...[
                Text(
                  authState.error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
              ],

              if (authState.isLoading)
                const CircularProgressIndicator()
              else
                PrimaryButton(
                  text: "Register",
                  onPressed: () {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();
                    final confirm =
                        _confirmPasswordController.text.trim();

                    if (email.isEmpty ||
                        password.isEmpty ||
                        confirm.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill all fields"),
                        ),
                      );
                      return;
                    }

                    if (password != confirm) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Passwords do not match"),
                        ),
                      );
                      return;
                    }

                    ref
                        .read(authProvider.notifier)
                        .register(email, password);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
