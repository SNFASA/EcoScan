import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/auth_provider.dart';
import '../../../core/widgets/primary_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authState.isLoading)
              const CircularProgressIndicator(),

            const SizedBox(height: 20),

            PrimaryButton(
              text: 'Login',
              onPressed: () {
                ref
                    .read(authProvider.notifier)
                    .login('test@mail.com', '123456');
              },
            ),
          ],
        ),
      ),
    );
  }
}
