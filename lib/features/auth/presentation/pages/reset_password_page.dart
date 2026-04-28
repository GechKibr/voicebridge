import 'package:flutter/material.dart';

import 'forgot_password_page.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatelessWidget {
  final String? token;

  const ResetPasswordPage({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Reset your password',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'This flow now uses OTP verification. Start the OTP reset to continue.',
                style: TextStyle(color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  );
                },
                child: const Text('Start OTP Reset'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
