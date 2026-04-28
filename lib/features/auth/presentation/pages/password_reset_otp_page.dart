import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../widgets/custom_text_field.dart';
import 'login_page.dart';

class PasswordResetOtpPage extends StatefulWidget {
  final String identifier;
  final String? maskedEmail;

  const PasswordResetOtpPage({
    super.key,
    required this.identifier,
    this.maskedEmail,
  });

  @override
  State<PasswordResetOtpPage> createState() => _PasswordResetOtpPageState();
}

class _PasswordResetOtpPageState extends State<PasswordResetOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = context.read<AuthController>();
    final otp = _otpController.text.trim();
    final password = _passwordController.text.trim();

    final verification = await controller.verifyPasswordResetOtp(
      identifier: widget.identifier,
      otp: otp,
    );

    if (!mounted) return;

    if (verification == null) {
      _showSnack(
        controller.errorMessage ?? 'OTP verification failed.',
        isSuccess: false,
      );
      return;
    }

    final success = await controller.resetPasswordWithOtp(
      resetToken: verification.resetToken,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      _otpController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _showSnack(
        'Password updated. Please sign in with your new password.',
        isSuccess: true,
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } else {
      _showSnack(
        controller.errorMessage ?? 'Unable to reset password.',
        isSuccess: false,
      );
    }
  }

  Future<void> _handleResendOtp() async {
    final controller = context.read<AuthController>();
    final result = await controller.requestPasswordReset(widget.identifier);

    if (!mounted) return;

    _showSnack(
      result?.message ?? controller.errorMessage ?? 'Unable to resend the OTP.',
      isSuccess: result != null,
    );
  }

  void _showSnack(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.maskedEmail?.trim().isNotEmpty == true
        ? 'Enter the OTP sent to ${widget.maskedEmail}.'
        : 'Enter the OTP we sent to your account.';

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reset your password',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _otpController,
                  label: 'OTP code',
                  prefixIcon: Icons.shield,
                  keyboardType: TextInputType.number,
                  helperText: 'Check your email or inbox for the 6-digit OTP.',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the OTP code';
                    }
                    if (value.trim().length < 4) {
                      return 'OTP looks too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'New password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a new password';
                    }
                    if (value.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm password',
                  prefixIcon: Icons.lock,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Confirm your password';
                    }
                    if (value.trim() != _passwordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Consumer<AuthController>(
                  builder: (context, controller, _) {
                    return FilledButton(
                      onPressed: controller.isLoading ? null : _handleReset,
                      child: controller.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Reset password'),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Consumer<AuthController>(
                  builder: (context, controller, _) {
                    return TextButton(
                      onPressed: controller.isLoading ? null : _handleResendOtp,
                      child: const Text('Resend OTP'),
                    );
                  },
                ),
                const SizedBox(height: 12),
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
      ),
    );
  }
}
